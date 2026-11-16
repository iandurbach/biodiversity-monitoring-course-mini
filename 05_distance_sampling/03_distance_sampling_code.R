# Distance sampling: code for the practical and relevant theory examples
# Run from the course root or from 05_distance_sampling. Work through
# one section at a time in RStudio. All data are simulated teaching data.
# Install the package once if needed: install.packages("Distance")
# In R, <- stores a result under a name. A $ selects a table column.

# library() makes the Distance package functions available.
library(Distance)
# Choose the path to this lecture's data from either working directory.
lecture_dir <- if (dir.exists("05_distance_sampling")) {
  "05_distance_sampling"
} else {
  "."
}


## Case study 1: desert monitors on line transects -----------------------

### 1. Read and check the flat-file data

# read.csv() loads a table. file.path() joins folder and file names.
monitors <- read.csv(file.path(lecture_dir, "data",
                               "monitor_line_transects.csv"))
# habitat is a category; factor() tells R to treat it as such when
# we fit the later detection model. Open is the reference category.
monitors$habitat <- factor(monitors$habitat,
                           levels = c("Open", "Shrubby"))
# table[rows, columns] selects part of a table. Blank rows keeps all;
# c(...) combines the column names. head(..., 4) displays four rows.
head(monitors[, c("Sample.Label", "Effort", "distance")], 4)

# Usually one row is one animal sighting. A completed line with no
# sighting has one row with missing object and distance values (NA).
# A distance of 0 means an animal was seen on the line, not no animals.
# unique() keeps each line once, so its length is not counted again
# for every animal seen on that line.
lines <- unique(monitors[, c("Sample.Label", "Effort")])
# stopifnot() stops the exercise if any condition is false. These
# checks catch duplicate line IDs, non-positive effort, and negative
# recorded distances before model fitting.
stopifnot(!anyDuplicated(lines$Sample.Label))
stopifnot(all(lines$Effort > 0))
stopifnot(all(monitors$distance >= 0, na.rm = TRUE))
# sum() totals lengths once per line; is.na() identifies completed
# lines with no detections. na.rm=TRUE means ignore missing values.
sum(lines$Effort)
sum(is.na(monitors$distance))
sum(!is.na(monitors$distance))  # Number of detected animals


### 2. Inspect distances and choose the analysis limit

# hist() bins observed perpendicular distances (metres). The line
# at 30 m marks the truncation distance used on the slides.
w_monitor <- 30
hist(monitors$distance, breaks = seq(0, 40, 5),
     xlab = "Perpendicular distance (m)", main = "Simulated monitors",
     col = "lightblue")
abline(v = w_monitor, col = "red", lty = 2)
# These detections lie beyond 30 m and will be excluded by ds().
# The survey effort for their lines still contributes to the model.
sum(monitors$distance > w_monitor, na.rm = TRUE)


### 3. Match the units and fit a half-normal curve

# Distances and truncation are in metres; Effort is line length in
# kilometres; Area is in square kilometres. convert_units() tells
# ds() how to reconcile them so density is per square kilometre.
line_units <- convert_units("meter", "kilometer", "square kilometer")

# ds() fits a detection function and estimates density and abundance.
# transect="line" uses perpendicular distances from line transects.
# key="hn" chooses a half-normal curve; adjustment=NULL means no
# added curve terms. optimizer="R" uses the R fitting engine.
# The flat file includes the region area and the zero-count lines.
# The usual model assumes detection is certain on the line (g(0)=1)
# for animals available to be seen. Burrowed animals can still be missed.
monitor_hn <- ds(monitors,
                 transect = "line", truncation = w_monitor,
                 key = "hn", adjustment = NULL,
                 convert_units = line_units, optimizer = "R")
# summary() shows detection and abundance results. The average.p
# entry is mean detection probability within the 30 m strip for
# animals available to be seen; it does not measure availability.
monitor_summary <- summary(monitor_hn)
monitor_summary$ds$average.p
# plot() overlays the fitted detection curve on distance frequencies.
plot(monitor_hn, showpoints = FALSE, nc = 6,
     xlab = "Perpendicular distance (m)")

# The theory lecture separates two corrections with round numbers.
# If 60 animals are detected and average detection within the strip
# is 0.6, an estimated 100 were available inside that strip.
detected_example <- 60
average_detection_example <- 0.6
corrected_in_strip <- detected_example / average_detection_example
corrected_in_strip
# If the strip covers 10% of the whole region, scale that 100 up to
# 1000 animals for the region. This illustration is not a monitor fit.
region_coverage_example <- 0.1
corrected_in_strip / region_coverage_example


### 4. Compare an alternative and check model fit

# "hr" fits the hazard-rate detection curve to the same observations,
# truncation distance, line effort and area. That makes AIC comparable.
monitor_hr <- ds(monitors,
                 transect = "line", truncation = w_monitor,
                 key = "hr", adjustment = NULL,
                 convert_units = line_units, optimizer = "R")
# par(mfrow=c(1,2)) puts two plots on one row. The two calls differ
# only in which fitted model supplies the curve.
par(mfrow = c(1, 2))
plot(monitor_hn, showpoints = FALSE, nc = 6,
     main = "Half-normal", xlab = "Distance (m)")
plot(monitor_hr, showpoints = FALSE, nc = 6,
     main = "Hazard-rate", xlab = "Distance (m)")
par(mfrow = c(1, 1))
# AIC() ranks these candidates; lower is better among the two.
# It does not tell us whether either fits well in absolute terms.
AIC(monitor_hn, monitor_hr)
# gof_ds() makes a Q-Q plot and reports a goodness-of-fit test.
# Look for systematic departure from the diagonal.
monitor_gof <- gof_ds(monitor_hn)
monitor_gof$dsgof$CvM$p


### 5. Read density, abundance and uncertainty

# The $ signs step through named parts of the fitted result.
# D is available-animal density per km2; N is available-animal
# abundance for the 100 km2 region in the data file.
monitor_D <- monitor_hn$dht$individuals$D
monitor_N <- monitor_hn$dht$individuals$N
monitor_D
monitor_N
# Estimate is the point estimate. lcl and ucl are the lower and upper
# 95% confidence limits. cv is uncertainty relative to the estimate.
monitor_N[, c("Estimate", "lcl", "ucl", "cv")]

# Draw the abundance estimate as a dot, with its interval as a line.
# segments() draws from the lower to upper confidence limit.
plot(monitor_N$Estimate, 1,
     xlim = c(0, monitor_N$ucl * 1.1), ylim = c(0.7, 1.3),
     pch = 16, col = "#2952BF", yaxt = "n",
     xlab = "Simulated available-animal abundance", ylab = "")
segments(monitor_N$lcl, 1, monitor_N$ucl, 1,
         col = "#2952BF", lwd = 3)
points(monitor_N$Estimate, 1, pch = 16, col = "#2952BF", cex = 1.3)


### 6. Compare raw strip density with detection-corrected density

# Count detections at or inside 30 m. For a line transect the sampled
# strip extends 30 m on each side, hence the factor of 2 below.
n_retained <- sum(monitors$distance <= w_monitor, na.rm = TRUE)
# Divide metres by 1000 to turn width into kilometres. Multiplying
# by total line length gives the physical strip area in km2.
strip_km2 <- 2 * w_monitor / 1000 * sum(lines$Effort)
raw_density <- n_retained / strip_km2
raw_density
monitor_D$Estimate
# barplot() compares the naive count/area result with the fitted
# correction for available animals missed away from the line.
barplot(c(raw_density, monitor_D$Estimate),
        names.arg = c("Count / strip area", "Detection corrected"),
        col = c("grey65", "#2952BF"), border = NA,
        ylab = "Available animals per km2", main = "Simulated monitors")


### 7. Let detection vary with habitat

# formula=~habitat allows a different detection scale in open and
# shrubby habitat. It describes detection, not monitor density by
# habitat. The other settings match the first half-normal model.
monitor_cov <- ds(monitors,
                  transect = "line", truncation = w_monitor,
                  key = "hn", adjustment = NULL, formula = ~habitat,
                  convert_units = line_units, optimizer = "R")
AIC(monitor_hn, monitor_cov)
# Check this model's detection curve and goodness of fit as well.
plot(monitor_cov)
gof_ds(monitor_cov)


## Case study 2: golden eagles at point transects ------------------------

### 1. Read and inspect the point-count data

eagles <- read.csv(file.path(lecture_dir, "data",
                             "golden_eagle_point_transects.csv"))
# Effort is one completed snapshot per point. Keep the NA-distance
# placeholder for each completed point with no eagle sighting.
points <- unique(eagles[, c("Sample.Label", "Effort")])
stopifnot(nrow(points) == 100, all(points$Effort == 1))
sum(is.na(eagles$distance))
# A point histogram can rise at first because rings farther from
# the point cover more area. It is not a plot of detection probability.
hist(eagles$distance, breaks = seq(0, 1200, 150),
     xlab = "Radial distance (m)", main = "Simulated eagles",
     col = "lightblue")


### 2. Fit the point model and compare two views

# Point distances and the 1000 m truncation radius are in metres.
# Effort is a count of completed snapshots, so the middle argument
# to convert_units() is NULL. Area is in square kilometres.
point_units <- convert_units("meter", NULL, "square kilometer")
w_eagle <- 1000
# transect="point" accounts for increasing ring area away from a
# point. The half-normal model is the one used in the practical slides.
eagle_hn <- ds(eagles, transect = "point",
               truncation = w_eagle, key = "hn", adjustment = NULL,
               convert_units = point_units, optimizer = "R")
# The first plot shows detection probability against distance. In
# the second, pdf=TRUE shows the expected distribution of observed
# distances, which also reflects ring area.
par(mfrow = c(1, 2))
plot(eagle_hn, showpoints = FALSE, main = "Detection probability")
plot(eagle_hn, pdf = TRUE, showpoints = FALSE, ylab = "",
     main = "Observed distance distribution")
mtext("Probability density", side = 2, line = 4.3, las = 0)
par(mfrow = c(1, 1))


### 3. Check the fit and interpret estimates

# The goodness-of-fit result checks whether the fitted distance
# pattern matches the observed distances. plot=FALSE returns its
# numerical result without drawing another figure.
eagle_gof <- gof_ds(eagle_hn, plot = FALSE)
eagle_gof$dsgof$CvM$p
# Extract density and abundance in the same way as for monitors.
eagle_D <- eagle_hn$dht$individuals$D
eagle_N <- eagle_hn$dht$individuals$N
eagle_D
eagle_N
# The estimates concern birds available during the snapshot survey.
# They are not nesting-territory or total population estimates.
