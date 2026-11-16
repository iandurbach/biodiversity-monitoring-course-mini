SIMULATED desert-monitor SDM teaching inputs.
Not observations, climate data or a boundary for a real locality.
CRS: EPSG:32643; 100 x 80 cells; 1 km cell size.
records.csv: 300 verified simulated spring sightings, with duplicates.
bioclim.tif: BIO6 (minimum temperature of coldest month, degrees C)
and BIO12 (annual precipitation, mm); synthetic climate summaries.
survey_region.gpkg: an irregular fictional polygon.
region_mask.tif: 1 inside the polygon; NA outside.
Presences sampled with replacement under uniform recording effort.
Generating association: Gaussian intensity centred on BIO6=1.5 C
and BIO12=180 mm, with widths 2.5 C and 65 mm respectively.
These optima are teaching assumptions, not species knowledge.
simulation_truth.tif: relative RECORDING intensity for simulation audit
only; never supply it to an SDM as a predictor or an occupancy estimate.
Fixed holdout: training x < 550000; test x >= 552000; 2 km buffer.
Regenerate: Rscript code/simulate_monitor_sdm_data.R; seed 42026.
