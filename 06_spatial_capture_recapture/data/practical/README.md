# Introductory SCR practical inputs

Used by `../../02_spatial_caprecap_practical.qmd`. Run the lecture's R code
from the `06_spatial_capture_recapture` folder, as Quarto does when rendering.
Install `secr` first; Quarto also uses `knitr`.

Student inputs:

- `snow_leopard_traps.csv`: 35 local camera coordinates from the module's
  `traps.csv`: trap ID, x and y (metres, UTM 43N), plus simulated `effort`
  (camera-days), `camera_type` (A/B) and `d2water` (100--10,000 metres).
  Camera types are balanced (18 A, 17 B); 29 cameras have 90 days of effort
  and six have 70--89 days. These columns use seed 20261021.
- `snow_leopard_captures.csv`: simulated Poisson encounter counts over one
  survey occasion. Each row is one encounter; repeated animal-camera rows
  contribute to the count. Columns: session, individual ID, occasion, trap ID.
  Camera-day effort is included in both simulation and model fitting.
- `snow_leopard_mask.csv`: x, y and actual terrain ruggedness (`tri`), in
  exactly the row order returned by the practical's `make.mask()` call
  (30 km buffer, 1.5 km spacing). The mask contains 1,645,425 ha.
- `pamir_alai_region.rds`: a separate reporting mask covering the full supplied
  Pamir-Alai survey polygon, with 1.5 km spacing and raw raster TRI covariates.
  Used with `region.N(sl_mod_tri, region = pamir_alai_region)` for regional
  extrapolation. It does not change the fitting mask or simulated population.

TRI is extracted directly from `../../data/spatial_covs/tri_KYRG.tif` at each
mask point in UTM 43N. Values are the original raster cell values, without
aggregation, scaling, imputation or synthetic terrain. The supplied mask TRI
ranges from 0.375 to 127.25.

Simulation:

- Exactly 30 animals in the full mask, including those never detected.
- Activity-centre probabilities proportional to
  exp((tri - mean(tri)) / sd(tri)), sampled using sim.popn with a fixed total.
  Scaling is used internally to define simulation weights; the student model
  uses the unscaled raster covariate, D ~ tri.
- Count detectors, one occasion, Poisson counts (binomN = 0), hazard half-normal
  encounter function (HHN), lambda0 = 4/90 encounters per camera-day at an
  activity centre (4 over 90 days), sigma = 6500 m. Counts are scaled by
  the camera-day usage read using binary.usage = FALSE. Camera type and
  distance to water have no generating effect; they are provided for later models.
- Population seed: 20261019; encounter seed: 20261020. No selection of datasets
  by model ranking. The result is 68 encounters of 9 detected animals.
- The buffer was enlarged from 15 to 30 km to accommodate the larger sigma.

Instructor audit files:

- `tri_scaling.csv`: raster mean and standard deviation used in simulation
  weights; not required for the student analysis.
- `simulated_activity_centres.csv`: all 30 simulated activity centres with
  animal IDs, including undetected individuals.
- `simulation_settings.csv`: population size, observed counts, generating
  encounter parameters, mask settings and random seeds.

To regenerate, run `Rscript code/prepare_intro_practical.R` from the module
folder. The prediction-mask slide uses `terra::rast` and `addCovariates` to add
the supplied TRI raster to the regional mask. Students therefore also need
`terra`; the Namkha preparation/model-fitting workflow is not required. The raw-TRI
model uses Nelder-Mead optimization to avoid overflowing trial steps on the
original covariate scale. Both models use the same Poisson count likelihood.

These practical files are separate from the module's earlier simulated root
CSVs. Those inputs and the Namkha/source materials are unchanged.
The slide sequence, text and workflow diagram are adapted from Ali Johnston's
MT5751 `L21-Spatial capture-recapture I - Demo.Rmd`, retaining the original
Metropolis presentation style and repeated slide builds. The models include D ~ tri, then lambda0 ~ camera_type and lambda0 ~ d2water
while retaining D ~ tri and sigma ~ 1. Distance to water is converted from
metres to kilometres when attaching detector covariates, before any model is fitted. AIC compares all
four candidates; the supplied CSV retains the original distances in metres.

The TRI map slide adds an uppercase `TRI` alias for plotting with
`plot(sl_mask, covariate = "TRI")`; the model continues to use `tri`.
The regional mask is rebuilt from `data/survey_area/pamir_alai_kyrgyzstan_utm43.gpkg`
and the original TRI raster during instructor preparation. The state-space slide
shows how to create this polygon mask with sf::st_read and make.mask; the
prediction-mask slide adds TRI using terra::rast and addCovariates. The
abundance slide also retains the matching prepared mask with its TRI covariates.
