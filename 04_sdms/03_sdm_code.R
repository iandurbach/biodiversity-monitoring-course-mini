# Species distribution models: practical code for both simulated case studies
# Run from the course root or from 04_sdms. Work through one section at
# a time in RStudio. Lines beginning with # explain the next commands.
# All records and environmental layers in this exercise are simulated.
# Install terra once if needed: install.packages("terra")
# In R, <- stores the value on its right under the name on its left.
# A dot means the current working directory; $ selects a table column.

# library() makes the mapping functions in terra available.
library(terra)
# dir.exists() lets this script work from the course root or 04_sdms.
lecture_dir <- if (dir.exists("04_sdms")) "04_sdms" else "."
# This small function joins the lecture's data folder with file names.
# ... means it accepts one or more folder and file-name pieces.
data_path <- function(...) file.path(lecture_dir, "data", ...)

# The supplied helper gives us consistent map colours and the AUC
# calculation used on the slides. source() runs that R file here.
# It defines map_plot(), style(), auc_pb(), and the colours bl and rd.
source(file.path(lecture_dir, "code", "helpers.R"))

# Exercise exports go into a separate folder inside this lecture.
out_dir <- file.path(lecture_dir, "output", "code_walkthrough")
# recursive=TRUE also creates any missing parent folder. If the folder
# already exists, showWarnings=FALSE avoids an unnecessary message.
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)


# Case study 1: Central Asian otters --------------------------------------

# 1. Define the prediction region. This raster has values in river
# corridor cells and NA outside them. NA means "do not predict here".
# rast() opens a raster map; map_plot() draws it in the Plots pane.
preview_river <- rast(data_path("river_mask.tif"))
map_plot(preview_river, "Prediction region: simulated river corridor")


# 2. Load prepared presence records and environmental rasters ------------

# The instructor has already checked the sign records, removed
# duplicates from the same 500 m cell, and transformed coordinates.
# read.csv() loads the supplied table. Each row is a recorded presence.
records <- read.csv(data_path("otter_sdm_presences.csv"))
# table[rows, columns] selects data. Blank rows means all rows;
# c(...) combines the names of the three columns we want to see.
# head(..., 3) shows three rows; nrow() counts all records.
head(records[, c("record_id", "x", "y")], 3)
nrow(records)

# Raster names are the predictor names used later in glm(). The
# environment and mask must share cell size, extent and coordinates.
# env contains cover, elevation and temperature. river is the mask.
env <- rast(data_path("environment.tif"))
river <- rast(data_path("river_mask.tif"))
# names() lists the layer names used in model formulas. res() reports
# the width and height of each map cell in the raster's map units.
names(env)
res(env)
# compareGeom() reports whether grids align. stopifnot() stops with
# an error if they do not; extraction or prediction would be unsafe.
compareGeom(env, river)
stopifnot(compareGeom(env, river))

# x and y are UTM easting and northing in metres (EPSG:32643).
# vect() turns the table into spatial points with the raster's CRS.
# geom names the coordinate columns; crs(env) supplies the map system.
pres <- vect(records, geom = c("x", "y"), crs = crs(env))
# Draw the mask, then overlay the presence points.
map_plot(river, "Verified presence cells (simulated)", pres)


# 3. Sample background and extract environmental values -----------------

# Background points describe environments available in the corridor.
# A background label of 0 is NOT a surveyed absence of otters.
# The fixed seed reproduces the sample on the slides.
# set.seed() fixes the random-number sequence for repeatable sampling.
set.seed(410)
# spatSample() chooses 600 random points from non-missing river cells.
# as.points=TRUE returns coordinates; values=FALSE does not yet extract
# predictor values, because the next step does that for all layers.
bg <- spatSample(river, size = 600, method = "random",
                 na.rm = TRUE, as.points = TRUE, values = FALSE)
nrow(bg)

# extract() reads raster values at each point. ID=FALSE avoids adding
# an extra row-number column to the model table. pb=1 denotes a
# presence record; pb=0 denotes a background point.
# Each resulting row has cover, elevation and temperature values.
p <- extract(env, pres, ID = FALSE)
b <- extract(env, bg, ID = FALSE)
# $pb creates a new response column in each table.
p$pb <- 1
b$pb <- 0
# crds() returns point coordinates. [, 1] is easting (x), and
# [, 2] is northing (y); these will define the spatial test split.
p$x <- crds(pres)[, 1]
b$x <- crds(bg)[, 1]
p$y <- crds(pres)[, 2]
b$y <- crds(bg)[, 2]
# rbind() stacks the presence rows above the background rows.
dat <- rbind(p, b)
# complete.cases() checks every row for missing predictor values.
# stopifnot() prevents a model being fitted to incomplete inputs.
stopifnot(all(complete.cases(dat)))
# Inspect the first rows and count the two response groups.
head(dat[, c("pb", "cover", "elev_km")], 3)
table(dat$pb)


# 4. Hold out an eastern block before fitting ----------------------------

# Use records west of 329000 m to train and those east of 330000 m to
# test. The 1 km gap is an illustrative buffer. The test data are
# withheld from fitting, for a more honest evaluation of prediction.
# subset() keeps rows for which its condition is TRUE. Coordinates
# between 329000 and 330000 m go into neither table.
train <- subset(dat, x < 329000)
test <- subset(dat, x >= 330000)
# table() counts 0s and 1s; rbind() displays train and test together.
rbind(training = table(train$pb), test = table(test$pb))
# First draw the river, then add a grey buffer and coloured points.
map_plot(river, "Western training region; eastern test region")
# rect() takes left, bottom, right and top map coordinates.
rect(329000, 4370000, 330000, 4400000,
     col = adjustcolor("grey40", 0.4), border = NA)
# points() overlays locations. pch=16 means solid circles; cex sets size.
points(train$x, train$y, pch = 16, col = bl, cex = 0.4)
points(test$x, test$y, pch = 16, col = rd, cex = 0.4)
# abline(v=...) draws vertical lines at the buffer edges.
abline(v = c(329000, 330000), lty = 2)

# Temperature and elevation are nearly redundant here. As planned
# on the slides, fit with cover and elevation only.
# cor() makes a correlation matrix from the three training columns;
# round(..., 2) displays it to two decimal places.
round(cor(train[, c("cover", "elev_km", "temperature")]), 2)


# 5. Fit the presence-background GLMs -------------------------------

# A binomial GLM fits a logistic relationship. With these data its
# response is presence versus sampled background, not the probability
# that an otter occupies a cell. The theory lecture makes this
# distinction when comparing SDMs with occupancy models.
# In a formula, ~ reads "model the left side using the right side".
# family=binomial() selects logistic regression for the 0/1 pb label.
# data=train ensures the eastern test records do not help fit the model.
m_linear <- glm(pb ~ cover + elev_km,
                family = binomial(), data = train)
# I(elev_km^2) adds a squared elevation term for a curved response.
m_curve <- glm(pb ~ cover + elev_km + I(elev_km^2),
               family = binomial(), data = train)

# I(elev_km^2) lets elevation have a curved effect. AIC compares the
# models on the same training data. The slides continue with m_curve
# for the response-curve demonstration, even though m_linear has
# the lower AIC in this simulation.
# AIC() reports both scores. summary() shows the fitted coefficients.
AIC(m_linear, m_curve)
summary(m_curve)

# Predict across the observed cover range while holding elevation at
# its training median. type="link" returns logits and standard errors;
# plogis() converts them to the 0-1 score scale. The band is an
# approximate 95% confidence interval for the fitted curve.
# seq() makes 100 evenly spaced cover values from the training minimum
# to maximum. median() keeps elevation fixed at a typical value.
curve_data <- data.frame(
  cover = seq(min(train$cover), max(train$cover), length.out = 100),
  elev_km = median(train$elev_km)
)
# predict() evaluates m_curve at every row. se.fit=TRUE also asks
# for the uncertainty of the fitted curve at each row.
pr <- predict(m_curve, curve_data, type = "link", se.fit = TRUE)
# $ creates new columns. pr$fit is the logit-scale prediction.
# Subtracting or adding 1.96 standard errors gives approximate 95%
# limits; plogis() converts all three values to scores between 0 and 1.
curve_data$score <- plogis(pr$fit)
curve_data$low <- plogis(pr$fit - 1.96 * pr$se.fit)
curve_data$high <- plogis(pr$fit + 1.96 * pr$se.fit)
head(curve_data)

# Draw the two response curves shown in the practical. Red ticks mark
# training presences. One predictor varies while the other is fixed.
# style(c(1, 2)) sets a one-row, two-panel base-R plotting layout.
style(c(1, 2))
# z is only a short name for the curve table in the plotting commands.
z <- curve_data
# type="n" sets up axes without drawing a curve yet. ylim includes
# the lower and upper confidence limits, so the whole band is visible.
plot(z$cover, z$score, type = "n", ylim = range(z$low, z$high),
     xlab = "Riparian cover (%)", ylab = "Presence-background score")
# polygon() joins the lower curve to the reversed upper curve and
# shades the area between them. rev() reverses the upper values.
polygon(c(z$cover, rev(z$cover)), c(z$low, rev(z$high)),
        col = adjustcolor(bl, 0.2), border = NA)
# lines() draws the fitted score, and rug() puts small red marks on
# the axis at cover values for presence records (pb == 1).
lines(z$cover, z$score, col = bl, lwd = 3)
rug(train$cover[train$pb == 1], col = rd)
# For the elevation curve, reverse the roles: hold cover at its
# median and vary elevation across its observed training range.
e <- data.frame(cover = median(train$cover),
                elev_km = seq(min(train$elev_km), max(train$elev_km),
                              length.out = 100))
# type="response" returns the 0-1 score directly.
e$score <- predict(m_curve, e, type = "response")
plot(e$elev_km, e$score, type = "l", lwd = 3, col = bl,
     xlab = "Elevation (km)", ylab = "Presence-background score")
rug(train$elev_km[train$pb == 1], col = rd)
# Reset to one plot per page for the next figures.
style()


# 6. Evaluate on the withheld eastern block -------------------------------

# AUC is the chance that a randomly chosen withheld presence receives
# a higher score than a randomly chosen background location, counting
# ties as half. 0.5 is chance ranking; 1 is perfect ranking here.
# Add a predicted score for each test row. [condition] then selects
# scores where pb is 1 or 0; the two vectors feed auc_pb().
test$score <- predict(m_curve, test, type = "response")
p_test <- test$score[test$pb == 1]
b_test <- test$score[test$pb == 0]
auc_test <- auc_pb(p_test, b_test)
# Display AUC to three decimal places.
round(auc_test, 3)

# Overlap in these boxes shows why one score cannot be treated as a
# confirmed presence or absence at a location.
# list() provides the two labelled score groups to boxplot().
boxplot(list(Background = b_test, Presence = p_test),
        col = c("grey80", bl), ylab = "Presence-background score",
        main = paste("Withheld eastern block: AUC =", round(auc_test, 2)))


# 7. Map scores and flag extrapolation ------------------------------------

# Keep only cover and elevation, the variables used by m_curve. Apply
# the model to each river cell. Cells outside the river stay as NA.
# [[c(...)]] selects two named raster layers; mask() blanks cells
# outside the river. terra's predict() then evaluates the GLM cell by
# cell. na.rm=TRUE skips missing cells.
predictors <- mask(env[[c("cover", "elev_km")]], river)
score_map <- predict(predictors, m_curve,
                     type = "response", na.rm = TRUE)
# Name the output layer so a GIS user knows what the raster contains.
names(score_map) <- "presence_background_score"

# Mark a cell TRUE if either predictor lies outside its training
# range. This simple check cannot detect every novel COMBINATION of
# cover and elevation, but it identifies obvious extrapolation.
# The | symbol means OR. Each comparison yields a TRUE/FALSE raster;
# combining them flags cells with any out-of-range predictor.
outside <- predictors[[1]] < min(train$cover) |
           predictors[[1]] > max(train$cover) |
           predictors[[2]] < min(train$elev_km) |
           predictors[[2]] > max(train$elev_km)
# global(..., "sum") counts TRUE cells across the whole raster.
# [1, 1] takes the resulting single number from the summary table.
flagged <- global(outside, "sum", na.rm = TRUE)[1, 1]
flagged
# Draw the score and extrapolation maps beside each other.
par(mfrow = c(1, 2))
map_plot(score_map, "Otter habitat score (simulated)", pres)
map_plot(outside, "Outside training ranges", zlim = c(0, 1))
par(mfrow = c(1, 1))


# Case study 2: desert monitor lizards -----------------------------------

# This case uses a fictional polygon and two synthetic BIOCLIM layers.
# The score is again presence versus background, not occupancy.
# vect() reads the polygon boundary; rast() reads its raster mask.
mon_region <- vect(data_path("monitor_sdm", "survey_region.gpkg"))
mon_mask <- rast(data_path("monitor_sdm", "region_mask.tif"))
plot(mon_region, col = "grey92", border = bl, axes = FALSE,
     main = "Hypothetical survey region")

# These records begin as longitude/latitude (EPSG:4326). project()
# transforms them to the UTM coordinates of the climate raster.
# The CSV has point coordinates; the raster has BIO6 and BIO12 values.
mon_raw <- read.csv(data_path("monitor_sdm", "records.csv"))
mon_env <- rast(data_path("monitor_sdm", "bioclim.tif"))
# First make longitude/latitude points with their original CRS.
# project() actually transforms their coordinates to crs(mon_env).
# Assigning the wrong original CRS would put points in wrong cells.
mon_pres <- project(vect(mon_raw,
                         geom = c("longitude", "latitude"),
                         crs = "EPSG:4326"), crs(mon_env))

# Use one presence per 1 km raster cell. Check that the raster and
# region mask line up and that all retained points are in the region.
# crds() gets the projected point coordinates. cellFromXY() returns
# the climate-raster cell number underneath each point.
mon_cells <- cellFromXY(mon_env, crds(mon_pres))
# duplicated() marks later records in an already used cell; ! keeps
# only the first record from each cell.
mon_pres <- mon_pres[!duplicated(mon_cells), ]
# The first check tests grid alignment. The second extracts mask
# values at points and confirms none falls in a missing mask cell.
stopifnot(compareGeom(mon_env, mon_mask))
stopifnot(all(!is.na(extract(mon_mask, mon_pres)[, 2])))
nrow(mon_pres)
# The two BIOCLIM maps use the same points and polygon outline.
par(mfrow = c(1, 2))
map_plot(mon_env[["bio6"]], "BIO6 (degrees C)", mon_pres)
lines(mon_region, lwd = 1)
map_plot(mon_env[["bio12"]], "BIO12 (mm)", mon_pres)
lines(mon_region, lwd = 1)
par(mfrow = c(1, 1))

# Sample background inside the polygon, then extract climate values.
# BIO6 and BIO12 in these files are synthetic; no WorldClim download
# is needed. Both presences and background carry map coordinates.
# A different fixed seed reproduces the monitor background sample.
set.seed(420)
# The mask limits the 1200 random points to the chosen survey region.
mon_bg <- spatSample(mon_mask, 1200, method = "random",
                     na.rm = TRUE, as.points = TRUE, values = FALSE)
# These lines mirror the otter table: extract two predictor values,
# label background 0 and presence 1, and attach map coordinates.
mb <- extract(mon_env, mon_bg, ID = FALSE)
mb$pb <- 0
mb$x <- crds(mon_bg)[, 1]
mb$y <- crds(mon_bg)[, 2]
mp <- extract(mon_env, mon_pres, ID = FALSE)
mp$pb <- 1
mp$x <- crds(mon_pres)[, 1]
mp$y <- crds(mon_pres)[, 2]
# Combine the groups and make sure no predictor is missing.
mon_dat <- rbind(mp, mb)
stopifnot(all(complete.cases(mon_dat)))
table(mon_dat$pb)

# Hold out the eastern area with a 2 km buffer. Correlation helps
# identify predictors that carry similar information in training.
# x < 550000 is training; x >= 552000 is withheld test. Rows in
# the 2 km gap enter neither dataset.
mon_train <- subset(mon_dat, x < 550000)
mon_test <- subset(mon_dat, x >= 552000)
# Check the 0/1 counts and the correlation of the two predictors.
rbind(training = table(mon_train$pb), test = table(mon_test$pb))
round(cor(mon_train[, c("bio6", "bio12")]), 2)

# Fit the quadratic climate model shown on the slides. Squared terms
# allow a peak or trough along each climate gradient.
# The formula asks for linear and squared terms for both BIO6 and BIO12.
# Only mon_train is supplied to glm(); mon_test remains withheld.
mon_model <- glm(pb ~ bio6 + I(bio6^2) +
                      bio12 + I(bio12^2),
                 family = binomial(), data = mon_train)
summary(mon_model)

# For each curve, hold the other climate variable at its median.
# The loop repeats the same plotting steps for v="bio6" and v="bio12".
style(c(1, 2))
for (v in c("bio6", "bio12")) {
  # Start with the two training medians, then repeat that row 100 times.
  curve_mon <- data.frame(bio6 = median(mon_train$bio6),
                          bio12 = median(mon_train$bio12))
  curve_mon <- curve_mon[rep(1, 100), ]
  # [[v]] selects the column whose NAME is currently stored in v.
  # Replace that column with 100 values across its observed range.
  curve_mon[[v]] <- seq(min(mon_train[[v]]), max(mon_train[[v]]),
                        length.out = 100)
  # predict() scores those rows. if/else chooses the right axis label.
  plot(curve_mon[[v]], predict(mon_model, curve_mon, type = "response"),
       type = "l", lwd = 3, col = bl,
       ylab = "Presence-background score",
       xlab = if (v == "bio6") "BIO6 (degrees C)" else "BIO12 (mm)")
  # Mark the training-presence values along that variable's axis.
  rug(mon_train[[v]][mon_train$pb == 1], col = rd)
}
style()

# Evaluate on withheld records using the same AUC definition.
# The response-scale scores are split into presence and background
# vectors before calculating AUC and drawing their boxplots.
mon_test$score <- predict(mon_model, mon_test, type = "response")
mon_p_test <- mon_test$score[mon_test$pb == 1]
mon_b_test <- mon_test$score[mon_test$pb == 0]
mon_auc <- auc_pb(mon_p_test, mon_b_test)
round(mon_auc, 3)
boxplot(list(Background = mon_b_test, Presence = mon_p_test),
        col = c("grey80", bl), ylab = "Presence-background score",
        main = paste("Test set AUC =", round(mon_auc, 2)))

# Map the score within the polygon, then flag cells outside either
# predictor's training range. The mask excludes cells outside the
# stated prediction region.
# The inner predict() scores every climate cell; mask() then removes
# cells outside the polygon. The result is still a raster.
mon_score <- mask(predict(mon_env, mon_model,
                          type = "response", na.rm = TRUE), mon_mask)
names(mon_score) <- "presence_background_score"
# As for otters, | combines four TRUE/FALSE range checks. Each
# threshold is learned from the training data only.
mon_outside <- mon_env[["bio6"]] < min(mon_train$bio6) |
               mon_env[["bio6"]] > max(mon_train$bio6) |
               mon_env[["bio12"]] < min(mon_train$bio12) |
               mon_env[["bio12"]] > max(mon_train$bio12)
# Remove out-of-region cells from the flag layer too.
mon_outside <- mask(mon_outside, mon_mask)
par(mfrow = c(1, 2))
map_plot(mon_score, "Monitor habitat score (simulated)", mon_pres)
lines(mon_region, lwd = 1)
map_plot(mon_outside, "Training-range extrapolation", zlim = c(0, 1))
lines(mon_region, lwd = 1)
par(mfrow = c(1, 1))


# 8. Export the exercise results ------------------------------------------

# GeoTIFF maps can be opened in GIS software. Keep each score map
# together with its extrapolation map. The models and test tables
# document exactly what was fitted and evaluated.
# writeRaster() saves a raster as a GeoTIFF; overwrite=TRUE lets you
# rerun the exercise without changing file names. The four calls
# save a score and a range flag for each case study.
writeRaster(score_map, file.path(out_dir, "otter_score.tif"),
            overwrite = TRUE)
writeRaster(outside, file.path(out_dir, "otter_extrapolation.tif"),
            overwrite = TRUE)
writeRaster(mon_score, file.path(out_dir, "monitor_score.tif"),
            overwrite = TRUE)
writeRaster(mon_outside, file.path(out_dir, "monitor_extrapolation.tif"),
            overwrite = TRUE)
# saveRDS() preserves the two fitted R model objects for later work.
saveRDS(list(otter = m_curve, monitor = mon_model),
        file.path(out_dir, "glm_models.rds"))
# write.csv() saves the held-out rows and their predicted scores.
# row.names=FALSE avoids adding an extra numbered CSV column.
write.csv(test, file.path(out_dir, "otter_test.csv"), row.names = FALSE)
write.csv(mon_test, file.path(out_dir, "monitor_test.csv"), row.names = FALSE)
# sessionInfo() records R and package versions. capture.output()
# turns its display into text; writeLines() saves that text.
writeLines(capture.output(sessionInfo()),
           file.path(out_dir, "sessionInfo.txt"))


# Optional: compare the otter GLM with MaxEnt ------------------------------

# The optional slides fit MaxEnt using maxnet. Install it once if you
# want this section: install.packages("maxnet"). It uses the same
# training records and the same withheld eastern test as the GLM.
# requireNamespace() checks availability without stopping the main
# exercise if this optional package has not been installed.
if (requireNamespace("maxnet", quietly = TRUE)) {
  # xvars holds the two predictor names. The double colon asks for a
  # function from maxnet without attaching the whole package.
  xvars <- c("cover", "elev_km")
  # classes="lq" permits linear and quadratic features. regmult=1
  # sets the regularisation multiplier used on the slides.
  mx <- maxnet::maxnet(train$pb, train[, xvars],
                       f = maxnet::maxnet.formula(train$pb,
                                                 train[, xvars],
                                                 classes = "lq"),
                       regmult = 1)
  # type="link" gives MaxEnt scores suitable for ranking. clamp=FALSE
  # avoids silently replacing out-of-range predictor values at test sites.
  # as.numeric() makes a plain numeric vector for auc_pb().
  mx_test <- as.numeric(predict(mx, test[, xvars],
                                type = "link", clamp = FALSE))
  # Calculate AUC using the same held-out groups as the otter GLM.
  mx_auc <- auc_pb(mx_test[test$pb == 1], mx_test[test$pb == 0])
  round(c(GLM = auc_test, MaxEnt = mx_auc), 3)
}

# These two fitted score scales differ. AUC compares their rankings.
# The held-out test is for evaluation, not for repeatedly choosing
# features, predictors or tuning settings.
