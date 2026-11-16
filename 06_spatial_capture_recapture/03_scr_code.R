# Spatial capture-recapture (SCR): snow leopard practical code
# Run from the course root or 06_spatial_capture_recapture, preferably
# a section at a time in RStudio. The camera encounters are simulated.
# Install these packages once if needed:
# install.packages(c("secr", "terra", "sf"))
# In R, <- stores a result under a name; $ selects a named column.

## 1. Load packages and the prepared data -------------------------------

# library() makes the package's functions available in this session.
library(secr)
library(terra)
# dir.exists() chooses the path for either supported working directory.
lecture_dir <- if (dir.exists("06_spatial_capture_recapture")) {
  "06_spatial_capture_recapture"
} else {
  "."
}
# file.path() joins folder and file names without typing separators.
data_dir <- file.path(lecture_dir, "data", "practical")

# read.csv() loads one row per encounter or camera. A repeated
# animal-camera row is another encounter and contributes to the count.
sl_cap_data <- read.csv(file.path(data_dir, "snow_leopard_captures.csv"))
sl_trap_data <- read.csv(file.path(data_dir, "snow_leopard_traps.csv"))
# head() displays the first rows; nrow() counts all rows. unique()
# returns distinct individual IDs, so we can see how many were found.
head(sl_cap_data)
head(sl_trap_data)
nrow(sl_cap_data)
length(unique(sl_cap_data$id))


## 2. Make a traps object -----------------------------------------------

# Each camera has an ID, x/y coordinates in metres, and effort in
# active camera-days. table() shows how effort varies among cameras.
table(sl_trap_data$effort)
# A table[rows, columns] expression selects part of a data frame.
# Leaving rows blank keeps every camera; c(...) lists the columns.
# read.traps() turns this table into a special secr traps object.
# detector="count" allows repeated encounters at a camera during the
# one occasion. binary.usage=FALSE uses the numeric camera-day effort,
# so lambda0 is an encounter rate per active camera-day.
sl_traps <- read.traps(
  data = sl_trap_data[, c("trap", "x", "y", "effort")],
  trapID = "trap", detector = "count", binary.usage = FALSE
)
# usage() checks the effort stored in the converted object.
table(usage(sl_traps))
summary(sl_traps)
plot(sl_traps)

# The two additional camera variables were not part of read.traps().
# covariates() attaches them to the traps object for detection models.
# factor() treats camera type as a category; A is the reference level.
covariates(sl_traps)$camera_type <- factor(sl_trap_data$camera_type,
                                         levels = c("A", "B"))
# The CSV stores distance to water in metres. Divide by 1000 so the
# coefficient in the later model represents one kilometre of distance.
covariates(sl_traps)$d2water <- sl_trap_data$d2water / 1000
head(covariates(sl_traps))


## 3. Join individual encounters to the camera array --------------------

# Captures have session, individual ID, occasion and camera ID.
# fmt="trapID" tells secr that the last column identifies a camera
# in sl_traps; noccasions=1 means the full survey is one occasion.
sl_ch <- make.capthist(captures = sl_cap_data,
                       traps = sl_traps,
                       fmt = "trapID", noccasions = 1)
# summary() reports animals detected, encounters, recaptures and
# cameras visited. A map with tracks connects repeated detections
# of the same identified animal at different cameras. With only one
# occasion, the order of repeated encounters is unknown: these lines
# show which cameras shared an animal, not its actual travel route.
summary(sl_ch)
plot(sl_ch, tracks = TRUE)


## 4. Define the fitting mask and prediction region ---------------------

# An activity centre can lie beyond the camera array. The fitting
# mask represents possible centre locations when estimating density.
# suggest.buffer() offers a distance based on the encounter pattern;
# the slides use a conservative 30,000 m buffer. This diagnostic may
# warn that it approximates the encounter function with a half-normal.
suggest.buffer(object = sl_ch, detectfn = "HHN")
# make.mask() lays a grid of possible centre locations 1500 m apart.
# type="trapbuffer" retains locations within 30 km of any camera.
# Both buffer and spacing use the cameras' coordinate unit: metres.
sl_mask <- make.mask(traps = sl_traps, buffer = 30000,
                     spacing = 1500, type = "trapbuffer")
plot(sl_mask, cex = 0.5)
# add=TRUE overlays cameras and encounter tracks on the same plot.
plot(sl_traps, add = TRUE)
plot(sl_ch, tracks = TRUE, add = TRUE)

# The separate regional mask answers a different question: expected
# abundance over the full Pamir-Alai survey polygon. sf::st_read()
# opens its mapped boundary. :: calls a function from sf without
# attaching the whole package.
survey_area <- sf::st_read(
  file.path(lecture_dir, "data", "survey_area",
            "pamir_alai_kyrgyzstan_utm43.gpkg"),
  quiet = TRUE
)
# A polygon mask uses the same 1500 m grid spacing, clipped to the
# region boundary. It is for prediction, not for fitting the model.
pamir_alai_region <- make.mask(traps = sl_traps,
                               type = "polygon", poly = survey_area,
                               spacing = 1500)

# Terrain ruggedness index (TRI) is available as a raster. rast()
# reads it; addCovariates() extracts its value at each mask point.
# The raw covariate name "tri" must match D~tri in the model formula.
tri_raster <- terra::rast(file.path(lecture_dir, "data", "spatial_covs",
                                   "tri_KYRG.tif"))
# The file's layer is named "TRI". R names are case-sensitive, so
# rename it "tri" before adding it to BOTH masks used with D~tri.
names(tri_raster) <- "tri"
sl_mask <- addCovariates(sl_mask, tri_raster, columns = "tri")
pamir_alai_region <- addCovariates(pamir_alai_region, tri_raster)
# covariates() returns the mask table. Inspect its first rows and
# its ruggedness range before using it in a fitted model.
mask_data <- covariates(sl_mask)
head(mask_data)
range(mask_data$tri)

# Display the two masks and cameras in one map. The blue fitting mask
# extends around cameras; the grey reporting mask follows the polygon.
plot(pamir_alai_region, dots = FALSE, col = "grey85",
     polycol = "grey40")
plot(sl_mask, dots = FALSE, col = "lightsteelblue", add = TRUE)
plot(sl_traps, add = TRUE)


## 5. Fit the same four SCR models as the slides -------------------------

# secr.fit() combines encounters, camera effort, and the fitting mask.
# The three formulas describe density D, baseline encounter rate
# lambda0, and spatial encounter scale sigma. ~1 means constant.
# HHN is the hazard half-normal encounter function for these cameras.
# trace=FALSE avoids printing every optimisation step.
sl_mod <- secr.fit(capthist = sl_ch,
                   model = list(D ~ 1, lambda0 ~ 1, sigma ~ 1),
                   mask = sl_mask, detectfn = "HHN", trace = FALSE)
sl_mod

# Here density changes with TRI, while encounter rate and sigma stay
# constant. start=sl_mod supplies the first fit as a starting point;
# Nelder-Mead is used for the original, unscaled TRI values.
sl_mod_tri <- secr.fit(capthist = sl_ch,
                       model = list(D ~ tri, lambda0 ~ 1, sigma ~ 1),
                       mask = sl_mask, detectfn = "HHN",
                       start = sl_mod, method = "Nelder-Mead",
                       trace = FALSE)
# AIC() compares model support, accounting for the extra TRI term.
AIC(sl_mod, sl_mod_tri)

# Add camera type to baseline encounter rate. A is the reference
# category, so the fitted B coefficient compares B with A. Density
# still depends on TRI; sigma is shared by both camera types.
sl_mod_camera <- secr.fit(
  capthist = sl_ch,
  model = list(D ~ tri, lambda0 ~ camera_type, sigma ~ 1),
  mask = sl_mask, detectfn = "HHN",
  start = sl_mod_tri, method = "Nelder-Mead", trace = FALSE
)
# The fourth candidate uses distance to water instead of camera type
# as the encounter-rate covariate. d2water is in kilometres here.
sl_mod_water <- secr.fit(
  capthist = sl_ch,
  model = list(D ~ tri, lambda0 ~ d2water, sigma ~ 1),
  mask = sl_mask, detectfn = "HHN",
  start = sl_mod_tri, method = "Nelder-Mead", trace = FALSE
)
# Lower AIC means more support among these four models. It does not
# prove that a model captures every feature of the encounter data.
AIC(sl_mod, sl_mod_tri, sl_mod_camera, sl_mod_water)


## 6. Read parameters and make predictions -----------------------------

# coef() shows fitted coefficients on their link scales (logs here).
# predict() back-transforms them to density, encounter rate and sigma.
coef(sl_mod)
predict(sl_mod)
coef(sl_mod_camera)
# exp() turns the log encounter-rate contrast for B versus A into
# a rate ratio. A value above 1 means higher fitted rate for B.
exp(coef(sl_mod_camera)["lambda0.camera_typeB", "beta"])

# expand.grid() creates all six combinations of three TRI values and
# two camera types. newdata supplies those values to predict().
prediction_data <- expand.grid(tri = c(15, 35, 55),
                               camera_type = c("A", "B"))
predict(sl_mod_camera, newdata = prediction_data, se.fit = FALSE)

# region.N() turns fitted density into abundance. The first call
# reports abundance over the fitting mask; the second uses the
# Pamir-Alai polygon and its TRI values for regional extrapolation.
region.N(sl_mod_tri)
region.N(sl_mod_tri, region = pamir_alai_region)
# In the result, E.N is expected abundance under the fitted density
# surface. R.N estimates realised abundance during this survey.

# Check how predicted density changes with terrain ruggedness.
predict(sl_mod_tri, newdata = data.frame(tri = c(15, 35, 55)))
# quantile() finds the 5th and 95th percentiles of mask TRI values.
# seq() makes 100 points between them, staying in the data-supported
# range instead of extrapolating to very unusual terrain values.
tri_values <- seq(quantile(mask_data$tri, 0.05),
                  quantile(mask_data$tri, 0.95), length.out = 100)
tri_predictions <- predict(sl_mod_tri,
                           newdata = data.frame(tri = tri_values))
# predict() returns a list, one item per new TRI value. lapply()
# takes the D row from every item, and do.call(rbind, ...) stacks
# them into one table with estimate and confidence-limit columns.
density_est <- do.call(rbind,
                       lapply(tri_predictions, function(x) x["D", ]))
# secr reports density per hectare here. There are 10,000 hectares
# in 100 km2, so multiply by 10,000 for the slide's y-axis units.
plot(tri_values, density_est$estimate * 10000, type = "l", lwd = 2,
     xlab = "Terrain ruggedness (TRI)",
     ylab = expression("Snow leopards per 100 " * km^2),
     ylim = c(0, max(density_est$ucl * 10000)))
# polygon() shades the lower-to-upper interval. rev() reverses the
# upper boundary so it can join the lower boundary into one polygon.
polygon(c(tri_values, rev(tri_values)),
        c(density_est$lcl, rev(density_est$ucl)) * 10000,
        col = adjustcolor("steelblue", alpha.f = 0.2), border = NA)
lines(tri_values, density_est$estimate * 10000,
      lwd = 2, col = "steelblue4")


## 7. Plot fitted encounter functions -----------------------------------

# For the constant model, plot() shows how encounter rate declines as
# an animal's activity centre gets farther from a camera. limits=TRUE
# adds confidence limits; xval sets distances from 0 to 30 km.
plot(x = sl_mod, limits = TRUE,
     xval = seq(0, 30000, length.out = 60))

# The camera-type model predicts separate curves for A and B. TRI is
# held at 35; distances are evaluated every 500 m up to 30 km.
camera_types <- data.frame(tri = 35,
                           camera_type = factor(c("A", "B")))
distances <- seq(0, 30000, by = 500)
# [2, ] selects the B row and [1, ] the A row. add=TRUE overlays
# the second curve. legend() labels the colours.
plot(sl_mod_camera, newdata = camera_types[2, ],
     col = "red", xval = distances)
plot(sl_mod_camera, newdata = camera_types[1, ],
     col = "blue", xval = distances, add = TRUE)
legend("topright", c("Camera A", "Camera B"),
       col = c("blue", "red"), lty = 1, bty = "n")

# The fitted results illustrate the SCR workflow for simulated data.
# Camera placement, individual IDs and effort must be checked before
# applying these steps to a real survey.
