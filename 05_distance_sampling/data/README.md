# Distance sampling practical: simulated teaching data

**No file in this folder contains actual observations or population estimates
from Kyrgyzstan.** The species and field context come from the local protocols;
all numerical survey records are simulated. Values are deliberately sufficient
for an introductory model-fitting exercise and are not expected local densities,
recommended sample sizes, or evidence that either DS adaptation is field-validated.

## Files and reproducibility

- `monitor_line_transects.csv`: 40 independent line-survey snapshots, 2 km each;
  hypothetical region 100 km². Search extends 40 m on each side; the main analysis
  truncates at 30 m on each side. Available density is simulated at 30 animals/km².
  Twenty lines have Open habitat (half-normal detection scale 16 m); twenty have
  Shrubby habitat (scale 9 m). Available density is the same in both habitats.
- `golden_eagle_point_transects.csv`: 100 independent point-survey snapshots;
  hypothetical region 1,000 km². Search radius 1,200 m; main analysis radius
  1,000 m. Available density is simulated at 0.5 birds/km² and half-normal
  detection scale 600 m. Each completed point has effort 1.

From the course root:

```r
source("05_distance_sampling/code/simulate_distance_data.R")
source("05_distance_sampling/code/distance_sampling_practical.R")
```

Or, from the `05_distance_sampling` working directory:

```r
source("code/simulate_distance_data.R")
source("code/distance_sampling_practical.R")
```

The generator uses base R and seed 2026. The analysis requires `Distance`;
version 2.0.1 was used during development. The deck also requires `knitr`, Quarto,
and XeLaTeX. No package installation is run during rendering.

## Column definitions

| Column | Meaning |
|:--|:--|
| `Region.Label` | Identifier of the hypothetical region |
| `Area` | Region area in km², repeated on every row |
| `Sample.Label` | Unique line or point-survey identifier |
| `Effort` | Actual line length in km, or 1 for a completed point snapshot |
| `object` | Unique integer ID for an individual sighting |
| `distance` | Perpendicular distance (monitors) or horizontal radial distance (eagles), in m |
| `habitat` | Recorded habitat label; used as a monitor detection covariate |
| `status` | All teaching surveys are `complete` |

One row represents one detection. A **completed survey with no detections**
appears once with `object` and `distance` empty (read as `NA` in R).
An actual detection on the line/point can have distance 0; this is not a zero count.
A sighting with a missing distance is not an empty survey and must be resolved.

Survey metadata repeats for each detection. Sum effort once per survey, not over
all detection rows. Keep empty-survey placeholders in the flat file supplied to
`ds()`. Its truncation argument removes outer sightings while retaining sample
information. Do not manually subset the flat file to retained detections, which
could remove effort from samples whose only detections were in the excluded tail.

The dataset uses single-animal observations, so there is no `size` column.
Tracks, burrows, perches, nests, carcasses and uncertain species records are not
included in these individual-animal analyses. Repeat visits are not simulated;
real repeat surveys need explicit visit IDs and dependence-aware analysis.

## What was simulated?

For each sample, an independent Poisson number of available animals is simulated
within the searched strip or circle. Positions have uniform perpendicular
distances along lines; radial distances are generated as radius × sqrt(U),
accounting for increasing ring area. Animals are independently detected using a
half-normal curve with perfect detection at zero. Distances are rounded to 0.01 m
for storage; that numerical precision is not a field measurement recommendation.

These are idealised samples, not a mapped, finite population or GPS survey design.
Schematic maps in the deck illustrate field principles rather than these exact
sample coordinates. Neither boundaries, refuges, territoriality, terrain
obstruction, flying-bird movement nor observer response are simulated.

The resulting density and abundance estimates describe the **available-animal
population under standardised survey conditions**, conditional on representative
sampling and perfect near-line/near-point detection within that population.
No availability fraction has been estimated. Animals that were underground or
otherwise unavailable cannot be recovered by this distance-only correction.

The plain half-normal provides the main walkthrough. Model comparisons include
hazard-rate and habitat-dependent half-normal alternatives; the simple model is
not labelled the final best model after habitat is considered.

## Local context and image provenance

Source documents are in `65_BioCourse/slt_material`:

- Davletbakov A. T. (2026), *Monitor Lizard_AD.docx*: visual routes, sighting cards,
  separate indirect-sign records, seasonality, refuges and representativeness.
- Davletbakov A. T. & Koshkin M. A. (2026),
  *ENG_Golden Eagle_Methodological recommendations_AD.docx*: targeted nest/perch
  searches, observation stops, radial-distance and azimuth recording, and
  restrictions on nest visits and poor-weather surveys.
- *Review of national methodologies.docx*, sections 4 and 6: synthesis of these
  protocols and their limitations. The wider SLT folder was also scanned for
  relevant monitor/eagle material; the method review supplied the most relevant
  additional context.

The hypothetical DS design changes are explicitly distinguished from those
protocols. The monitor document's 20–30 m strip is not assumed to be a one-sided
DS distance. The example's search limit and truncation are new pilot choices.
The hypothetical eagle 2-minute settling/5-minute locating/snapshot sequence is
not a recommendation taken from the existing protocol or a validated timing rule.

Image assets in `../images/` are unmodified embedded document images:

- `desert-monitor-davletbakov.jpg`: monitor document, `word/media/image2.jpg`.
- `monitor-tracks-davletbakov.png`: monitor document, `word/media/image1.png`.
- `golden-eagle-davletbakov.jpg`: eagle document, `word/media/image1.jpg`.

Credit: **A. Davletbakov**, as requested for this course.

## Primary teaching resources

The R workflow follows the introductory level of the CREEM materials, adapted
to the local species rather than using their original animal datasets:

- [Line-transect R practical](https://distancesampling.org/online-course/02-detfns/R-prac/Pr2-instructions.html)
- [Model criticism R practical](https://distancesampling.org/online-course/03-criticism/R-prac/Pr3-instructions.html)
- [Point-transect R practical](https://distancesampling.org/online-course/05-points/R-prac/Pr5-instructions.html)
- [Survey design](https://distancesampling.org/online-course/06-design/designlanding.html)
- [Field methods](https://distancesampling.org/online-course/12-field/Mod12-2023-field.pdf)
- [Distance: ds](https://distancesampling.org/Distance/reference/ds.html)
- [Distance: convert_units](https://distancesampling.org/Distance/reference/convert_units.html)
- [Distance: gof_ds](https://distancesampling.org/Distance/reference/gof_ds.html)
