# Simulated otter SDM data

Every record, coordinate, environmental value and river shape is fictional.
These files are for teaching, not ecological inference about Kyrgyzstan.

Run from `04_sdms`: `Rscript code/simulate_sdm_data.R`.
Seed: 41026. Requires `terra`. It overwrites only the named simulated inputs.

| File | Contents |
|---|---|
| otter_sdm_presences.csv | Student input: 156 prepared autumn 2025 presence locations, one per 500 m cell; projected x/y coordinates in metres |
| otter_records_raw.csv | 175 simulated sign records plus 5 deliberately problematic records |
| environment.tif | Three aligned layers: cover (%), elev_km (km), temperature (degrees C) |
| river_mask.tif | 1 for eligible corridor cells; NA elsewhere |
| simulation_domain.csv | Eligible cell IDs, projected coordinates and predictors, for inspecting the simulation |

Raster: 80 columns × 60 rows, 500 m cells, UTM 43N (EPSG:32643).
The student CSV coordinates are already UTM 43N (EPSG:32643), in metres.
Raw occurrence coordinates are WGS84 longitude/latitude (EPSG:4326).
Raster extent: easting 300000–340000 m; northing 4370000–4400000 m.
There are 804 eligible river cells. These are not real hydrographic features.

Record fields: `record_id`, `longitude`, `latitude`, `year`, `season`, `verified`,
`uncertainty_m`, `method`, `shoreline_m`, `highFlow`, `synthetic`.
The nominal 600 m shoreline search length and flow-day definition follow the
occupancy teaching module; they are not actual surveyed reaches. All rows are
synthetic, including excluded rows. Repeat coordinates are deliberately retained
in the raw file for the cell-aggregation exercise.

Presence locations are drawn with probabilities proportional to the hypothetical
site-use curve times constant detection, conditional on a fixed record budget.
There is no complete presence–absence census or repeat-visit history in these
files. Details and the relationship to occupancy are in
`../notes/design_and_sources.md` and the simulation source.

The practical loads `otter_sdm_presences.csv` directly. Its preparation is saved
for instructors in `../further_reading/course_notes/instructor/prepare_otter_sdm.R`; run from `04_sdms`
after regenerating the raw simulation. Quality filtering, coordinate projection,
mask checks and duplicate-cell removal happen before class. This is an
independent raster simulation, not a conversion of the occupancy-module surveys.
Raw inputs, preparation code and exclusion logs are omitted from the student pack.
