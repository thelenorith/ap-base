# Automated Blink Rejection: Analysis and Plan

## Problem Statement

Manual blinking is the most time-consuming step in image preparation (~30 min per night for 2 rigs). After `ap-cull-light` runs (HFR, RMS thresholds), remaining frames must be visually inspected for:

1. **Satellite/airplane trails** - rare, could defer to pixel rejection during integration
2. **Bad guiding / star trailing** - very common, very annoying
3. **Soft focus** - already addressed by HFR threshold in `ap-cull-light`
4. **Clouds** - common, time-consuming, somewhat subjective

If blink can be fully automated, the entire image prep pipeline becomes hands-off.

## Current Pipeline State

`ap-cull-light` currently evaluates two metrics from FITS headers:
- **HFR** (Half-Flux Radius) - catches soft focus
- **RMS** (arcsec) - catches plate solve failures / poor astrometry

These are header-only checks. No pixel data analysis is performed. The normalized headers available from `ap-common` also include `stars` (star count) which is not currently used for culling.

## Research Findings

### How the Community Handles This

**PixInsight SubframeSelector** measures per-frame: FWHM, Eccentricity, SNRWeight, Median (background), Stars, Noise, StarResidual. The approval/rejection expression approach (e.g., `FWHMSigma < 2 && SNRWeightSigma > -2`) uses **relative sigma-based thresholds within each dataset** rather than absolute values.

**WBPP Integration** (recent versions): SubframeSelector is now built into the Weighted Batch PreProcessing workflow. Key development: **PSFSignalWeight** is the recommended weighting metric. It uses hybrid PSF/aperture photometry and is:
- Dominated by FWHM (inversely proportional to FWHM^2 or higher)
- Robust against satellite trails (unlike raw SNR, which is inflated by trail pixels)
- Comprehensive: captures focus, guiding, transparency in one number

The community consensus is: **cull only the truly broken frames (aim for <5% rejection), weight everything else**. Over-culling (keeping only top 20%) throws away 80% of signal.

**Siril** offers: FWHM, wFWHM (weighted by star count - catches clouds), Roundness (FWHMy/FWHMx - catches guiding), Background level.

### Problem-Specific Detection Approaches

#### Bad Guiding / Star Trailing (Problem #2)

**Primary metric: Eccentricity**
- `e = sqrt(1 - b²/a²)` from elliptical PSF fits
- Values < 0.42 are imperceptible to most viewers
- Spikes indicate mount bumps, wind gusts, guiding failures
- Uniform elongation direction across field = guiding error (vs radial = optical)

**Your proposed approach** (register, pick a moderate star, compare regions) is essentially what eccentricity measurement does, but eccentricity generalizes it:
- Fit elliptical PSFs to many stars across the frame
- Median eccentricity of all stars = guiding quality metric
- No reference frame needed - each frame is self-contained
- Star trailing shows as elevated eccentricity in a consistent position angle

The advantage of eccentricity over your single-star-region approach: it's statistically robust (median of many stars), works without registration, and the metric is well-established with known thresholds.

#### Clouds (Problem #4)

**The baseline problem** (raised in follow-up): if all frames in a dataset have clouds, there's nothing "good" to compare against.

This is a real and important limitation of relative/sigma-based approaches. Several strategies:

1. **Absolute background level per optical system**: For a given camera + optic + filter + gain + exposure + temperature, the expected background ADU in clear sky conditions at a given altitude/azimuth is predictable. Bortle class / SQM at your site sets the floor. You can build a **reference table** over time: for each profile (optic+camera+filter+gain+exposure), record the background ADU from known-clear sessions. Then compare new sessions against that reference. If the entire session is elevated, flag it.

2. **Star count as absolute metric**: Clear sky at a given focal length / aperture / exposure will detect a predictable number of stars (plate-solved, so you know the field). If star count for the entire session is significantly lower than reference sessions on the same target (or similar galactic latitude), the session is suspect.

3. **Cross-filter comparison**: If shooting narrowband (Ha, OIII, SII), clouds affect all filters roughly equally. But if you have broadband + narrowband, broadband is hit much harder by light-polluted clouds. An anomalous divergence between filters hints at clouds.

4. **Temporal gradient within session**: Even when the whole session has some cloud, it rarely has *uniform* cloud. Background level and star count will vary. Frames with background > median + N*sigma of the session or stars < median - N*sigma are the worst ones.

5. **Physical model**: Given site latitude/longitude (already in headers), target RA/Dec, and observation time, you can compute target altitude. Background naturally increases at lower altitude (more atmosphere + LP). A frame-by-frame expected-background model could be constructed, and deviations from it indicate non-atmospheric transparency changes (i.e., clouds). This is the most principled approach but requires building the model.

6. **wFWHM (Siril's approach)**: FWHM weighted by star count. If clouds reduce detected stars, wFWHM worsens even if the FWHM of detected stars is unchanged. This is a relative metric but catches partial-session clouds well.

**Practical recommendation for the baseline problem**: Build a **profile reference database**. Each time a session completes and is manually confirmed as good (or automatically determined to be good), record the per-profile median background ADU, star count, and computed metrics. Future sessions compare against this reference. For a truly new profile with no reference, fall back to within-session relative analysis and flag the entire session for review if metrics look suspicious (high background variance, low star counts for the field).

### Satellite Trails (Problem #1)

Detection approaches ranked by practicality:
1. **PSFSignalWeight weighting** - trails don't inflate PSFSignalWeight, so pixel rejection during integration handles them. No frame rejection needed.
2. **Hough Transform** - classical line detection. Python: `skimage.transform.probabilistic_hough_line`. Detects bright linear features after background subtraction + edge detection.
3. **ASTRiDE** - contour tracing, handles curved and short streaks.
4. **Frame differencing** - subtract consecutive aligned frames; moving linear features remain.

Given your assessment that this is rare and can be deferred to integration, agree that it's lowest priority. Sigma clipping / Winsorized sigma clipping during stacking handles most satellite trails at the pixel level.

## Proposed Architecture: `ap-reject-blink`

A new project following the `ap-*` standards, positioned between `ap-cull-light` and manual blink in the pipeline. Named with "reject" rather than "cull" to distinguish: `ap-cull-light` uses header metadata, `ap-reject-blink` analyzes pixel data.

### Metrics to Compute (Per Frame)

| Metric | Detects | Method |
|--------|---------|--------|
| **Eccentricity** (median) | Bad guiding, star trailing | Elliptical PSF fit on detected stars |
| **Eccentricity** (std dev) | Optical tilt vs guiding | Variation across field |
| **Star count** | Clouds, haze, focus | Source detection (DAOStarFinder or SEP) |
| **Background ADU** (median) | Clouds, LP, dawn/dusk | Background estimation (photutils or SEP) |
| **Background spatial std** | Patchy clouds | Tile-based background variation |
| **FWHM** (median, from pixels) | Independent focus/seeing check | PSF fitting |
| **wFWHM** | Clouds + focus combined | FWHM weighted by star count |

### Rejection Strategy

Two modes:

**Mode 1: Relative (within-session sigma rejection)**
- Compute each metric for all frames in a dataset group (same profile + target + date + filter)
- Express each frame's metrics in sigma from the group median
- Reject frames beyond configurable sigma thresholds (default: 2.5 sigma)
- This handles: individual bad guiding frames, intermittent clouds, focus drift outliers

**Mode 2: Reference-based (absolute comparison)**
- Compare against a stored reference database of known-good metrics per profile
- Catches: entire cloudy sessions, systematic problems
- Reference DB built incrementally from confirmed-good sessions
- Falls back to Mode 1 when no reference exists, with a warning

### CLI Interface

```
ap-reject-blink <source_dir> <reject_dir> [options]

Options:
  --max-eccentricity FLOAT   Absolute eccentricity ceiling (default: 0.6)
  --sigma-eccentricity FLOAT Sigma threshold for eccentricity (default: 2.5)
  --sigma-stars FLOAT        Sigma threshold for star count (default: -2.5)
  --sigma-background FLOAT   Sigma threshold for background (default: 2.5)
  --reference-db PATH        Path to reference database (enables Mode 2)
  --update-reference          Update reference DB with this session's metrics
  --report PATH              Write per-frame metrics CSV for analysis
  --auto-accept-percent FLOAT Auto-accept threshold (like ap-cull-light)
  --debug / --dryrun / --quiet  Standard flags
```

### Dependencies

- `astropy` - FITS I/O, statistics (sigma_clip)
- `photutils` - Star detection (DAOStarFinder), background estimation (Background2D), PSF fitting
- `numpy` - Numerical operations
- `ap-common` - Metadata, file operations, constants

Optional / future:
- `scikit-image` - Hough Transform for satellite trail detection
- `sep` - Alternative faster source extraction

## Plan for Validation with Test Data

When you provide categorized rejected frames from last night, here's how we use them:

### Phase 1: Metric Extraction

1. Run metric extraction on **all** frames (both accepted and rejected)
2. Output a CSV with per-frame metrics:
   - filename, eccentricity_median, eccentricity_std, star_count, background_median, background_std, fwhm_median, wfwhm, hfr_header, rms_header
3. Include your rejection category label (guiding, clouds, trail, other) for rejected frames

### Phase 2: Analysis

1. Plot metric distributions: accepted vs rejected, color-coded by rejection reason
2. For each rejection reason, identify which metric(s) separate rejected from accepted
3. Determine optimal thresholds:
   - What sigma cutoff on eccentricity correctly flags guiding rejects?
   - What sigma cutoff on star_count/background correctly flags cloud rejects?
4. Compute confusion matrix: true positives, false positives, false negatives
5. Check: are there frames you rejected that metrics say are fine? (possible over-culling)
6. Check: are there frames you accepted that metrics flag? (possible under-culling)

### Phase 3: Iteration

1. Tune thresholds based on Phase 2 results
2. Test on additional datasets
3. Build initial reference database from known-good sessions

### What I Need From You

1. **All frames from last night** (both accepted and rejected) accessible on disk
2. **Labels**: for each rejected frame, the reason (guiding / clouds / trail / other)
3. **A known-good session** for the same profile (optic+camera+filter), if available, for reference baseline testing
4. Confirmation of the approach before building

## Key Design Decisions

### Why not just use PixInsight SubframeSelector?

- You want full automation in the pipeline (no manual PixInsight step)
- Python integration with existing ap-* tools
- Custom rejection logic (reference database, per-profile baselines)
- Reproducibility and version control of rejection parameters

### Why eccentricity over your proposed single-star-region approach?

Both aim at the same problem, but eccentricity:
- Is the established metric with known thresholds
- Uses all detected stars (statistically robust median)
- Doesn't require registration (self-contained per frame)
- Distinguishes guiding vs optical aberration (via spatial variation)

Your intuition about registration + comparison is sound for satellite trail detection (frame differencing), but for guiding, eccentricity is more direct and efficient.

### Why not defer everything to pixel rejection during stacking?

Pixel rejection (sigma clipping) during integration handles:
- Satellite trails (linear artifacts in a few frames)
- Cosmic rays (point artifacts in single frames)

It does NOT handle:
- Bad guiding (elongated stars in all pixels of the frame - not "outlier" pixels)
- Clouds (reduced signal across all pixels - not rejected by sigma clipping)
- Focus problems (same issue - affects all pixels uniformly)

Frame-level rejection is necessary for problems that affect the entire frame uniformly.

### Why "reject" not "cull"?

`ap-cull-light` uses header metadata (fast, no pixel reads). The new tool reads pixel data (slower, more computation). Different name clarifies the distinction. Could also be `ap-analyze-blink` or `ap-score-blink` depending on preference.
