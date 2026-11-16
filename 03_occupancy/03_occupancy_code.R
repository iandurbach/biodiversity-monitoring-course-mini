# Occupancy: code for the practical, with useful examples from the theory
# Run from the course root or from 03_occupancy. Work through one section
# at a time in RStudio. Lines beginning with # explain the next commands.
# All otter data are simulated; they are not estimates for Kyrgyzstan.
# Install unmarked and ggplot2 once if needed:
# install.packages(c("unmarked", "ggplot2"))
# In R, <- stores the value on its right under the name on its left.
# c(...) combines values; $ selects a named column from a table.

# library() makes a package's functions available in this session.
library(unmarked)
library(ggplot2)

# dir.exists() checks whether a folder is present. The if/else chooses
# a path that works when your working directory is the course root or
# the lecture folder. A dot means the current working directory.
lecture_dir <- if (dir.exists("03_occupancy")) "03_occupancy" else "."


# 1. Look at the repeat-visit data ----------------------------------------

# One row is one fixed 600 m shoreline transect. y.1 to y.3 are three
# visits within one short season. A 1 means fresh otter signs were found;
# a 0 means a completed search found none. A missed visit would be NA.
# file.path() joins folder and file names; read.csv() reads a CSV table.
surveys <- read.csv(file.path(lecture_dir, "data/otter_surveys_simulated.csv"))
# This second table contains 200 hypothetical river segments for mapping.
network <- read.csv(file.path(lecture_dir, "data/otter_network_simulated.csv"))
# table[rows, columns] selects part of a table. Leaving rows blank
# keeps every site; c(...) names the seven season-one columns to keep.
occdata <- surveys[, c("y.1", "y.2", "y.3", "cover",
                       "highFlow.1", "highFlow.2", "highFlow.3")]
# head() displays the first few rows; dim() gives rows and columns.
head(occdata)
dim(occdata)  # 100 sites; three visits, cover and three flow values

# This matrix contains only the detection histories. Each row belongs
# to a site, and each column to a visit. highFlow has the same layout.
# A matrix is a rectangular set of values of one kind. Here we need
# a 100-row by 3-column matrix of zeros and ones for unmarked.
y <- as.matrix(occdata[, 1:3])
# $cover extracts the single cover column as a vector of 100 numbers.
cover <- occdata$cover
# Columns 5 to 7 contain the flow values for visits 1 to 3.
highFlow <- as.matrix(occdata[, 5:7])

# The theory slides distinguish observed signs from true occupancy.
# A site with only zeros may still have been used by otters if signs
# were missed on all three visits. This is the naive detected fraction.
# rowSums() adds the three visit results at each site. > 0 turns each
# sum into TRUE (at least one detection) or FALSE (none recorded).
# na.rm=TRUE would ignore a missed visit coded NA.
detected <- rowSums(y, na.rm = TRUE) > 0
# For TRUE/FALSE values, sum() counts TRUEs and mean() gives their share.
sum(detected)
mean(detected)


# 2. Tell unmarked which variables describe sites and visits --------------

# y: detection matrix; siteCovs: one cover value per site;
# obsCovs: one high-flow value per visit at each site.
# data.frame() makes a site table; list() supplies a named set of
# visit-level tables or matrices to obsCovs. The names must match the
# names later used in the model formulas.
umf <- unmarkedFrameOccu(
  y = occdata[, 1:3],
  siteCovs = data.frame(cover = occdata$cover),
  obsCovs = list(highFlow = occdata[, 5:7])
)
# summary() checks that unmarked received 100 sites, 3 visits and
# the expected covariates before fitting any model.
summary(umf)


# 3. Fit and compare the four models on the practical slides --------------

# In occu(), the FIRST formula describes detection probability p;
# the SECOND describes occupancy probability psi. ~1 means a constant
# probability. cover is a site variable; highFlow changes by visit.
# Each <- stores a fitted model. Models m1 to m4 test the four
# combinations of constant or covariate-dependent p and psi.
m1 <- occu(formula = ~1        ~1,     data = umf)
m2 <- occu(formula = ~highFlow ~1,     data = umf)
m3 <- occu(formula = ~1        ~cover, data = umf)
m4 <- occu(formula = ~highFlow ~cover, data = umf)

# AIC compares how well the models fit while accounting for the number
# of parameters. Smaller AIC is preferred among these four candidates.
# fitList() gives descriptive names to the fitted models. The labels
# p(.) and psi(.) mean that no covariate appears in that part.
fl <- fitList(
  "p(.)    psi(.)" = m1,
  "p(flow) psi(.)" = m2,
  "p(.)    psi(cover)" = m3,
  "p(flow) psi(cover)" = m4
)
# modSel() calculates and ranks AIC for the four models.
ms <- modSel(fl)
# A name by itself displays the object in the Console.
ms

# m4 has the lowest AIC for these simulated data, as on the slides.
# Its occupancy part estimates an effect of riparian cover; its
# detection part estimates an effect of recent high-flow days.
topmod <- m4
# summary() includes estimates and their standard errors on the logit
# scale. coef() extracts just the fitted coefficients.
summary(topmod)
coef(topmod)

# The simulation used these values to generate the data. They are
# shown on the practical slides for comparison with fitted values;
# real survey data would not reveal the true coefficients.
beta0 <- -3       # Occupancy intercept, on the logit scale
beta1 <- 0.06     # Effect of one percentage point of cover
alpha0 <- 1.5     # Detection intercept, on the logit scale
alpha1 <- -0.86   # Effect of one high-flow day


# 4. Predict occupancy and detection -------------------------------------

# plogis() converts a logit-scale value into a probability. For
# example, compare the simulation's true occupancy and detection
# probabilities at a chosen cover and number of high-flow days.
plogis(beta0 + beta1 * 50)  # True psi at 50% cover
plogis(alpha0 + alpha1 * 2) # True p after two high-flow days

# Predict occupancy throughout the range of cover observed at the sites.
# type="state" selects occupancy; append=TRUE keeps cover in the result.
# min() and max() find the observed endpoints; seq() makes 30 evenly
# spaced cover values between them. We predict only within this range.
pred.psi.df <- data.frame(cover = seq(from = min(occdata$cover),
                                     to = max(occdata$cover),
                                     length.out = 30))
# newdata supplies the cover values; predict() returns a probability,
# standard error and confidence limits for each row.
pred.psi <- predict(object = topmod, type = "state",
                    newdata = pred.psi.df, append = TRUE)
head(pred.psi)

# Predict detection throughout the observed range of high-flow days.
# type="det" selects the detection part of the same fitted model.
# min() and max() also work on the highFlow matrix of all visits.
pred.p.df <- data.frame(highFlow = seq(from = min(highFlow),
                                      to = max(highFlow),
                                      length.out = 30))
pred.p <- predict(object = topmod, type = "det",
                  newdata = pred.p.df, append = TRUE)
head(pred.p)

# Predicted is the fitted probability. lower and upper give its 95%
# confidence interval. The two panels match the slide relationships.
# ggplot() starts a plot from pred.psi; aes() maps table columns to
# the horizontal and vertical axes. The + signs add layers.
occupancy_plot <- ggplot(pred.psi, aes(x = cover, y = Predicted)) +
  # geom_ribbon() shades the interval between lower and upper.
  geom_ribbon(aes(ymin = lower, ymax = upper),
              fill = "#5B84B1", alpha = 0.25) +
  # geom_line() draws the fitted probability curve.
  geom_line(colour = "#5B84B1", linewidth = 1) +
  # labs() labels the axes; coord_cartesian() displays probabilities 0-1.
  labs(x = "Riparian cover (%)", y = "Pr(occupancy)") +
  coord_cartesian(ylim = c(0, 1)) + theme_bw()
# Evaluating the plot's name displays it in RStudio's Plots pane.
occupancy_plot

# The detection plot repeats those layers, now using highFlow on the
# horizontal axis and the predictions from type="det".
detection_plot <- ggplot(pred.p, aes(x = highFlow, y = Predicted)) +
  geom_ribbon(aes(ymin = lower, ymax = upper),
              fill = "#5B84B1", alpha = 0.25) +
  geom_line(colour = "#5B84B1", linewidth = 1) +
  labs(x = "High-flow days in preceding week", y = "Pr(detection)") +
  coord_cartesian(ylim = c(0, 1)) + theme_bw()
detection_plot


# 5. Predict across the hypothetical river network -----------------------

# The network table has riparian cover for 200 river segments. Only
# 100 segments were surveyed, but we can predict at all 200 because
# cover is available for every segment. The predictions are habitat-
# based seasonal site-use probabilities, not confirmed presence.
# append=TRUE retains the network coordinates needed to draw the map.
network.pred <- predict(topmod, type = "state",
                        newdata = network, append = TRUE)
# Select the columns relevant to interpretation before inspecting rows.
head(network.pred[, c("cover", "Predicted", "lower", "upper")])

# geom_segment() draws each river segment from (x, yy) to (xend, yend).
# Mapping colour to Predicted colours segments by fitted site use.
ggplot(network.pred) +
  geom_segment(aes(x = x, y = yy, xend = xend, yend = yend,
                   colour = Predicted), linewidth = 2) +
  scale_colour_viridis_c(limits = c(0, 1), name = "Pr(site use)") +
  coord_equal() + theme_void()

# A second map shows the width of each 95% interval. Wide intervals
# mean less precise predictions; they do not mean higher occupancy.
# Subtract the lower confidence limit from the upper one at each site.
network.pred$CIwidth <- network.pred$upper - network.pred$lower
# The map construction is the same; only the colour variable changes.
ggplot(network.pred) +
  geom_segment(aes(x = x, y = yy, xend = xend, yend = yend,
                   colour = CIwidth), linewidth = 2) +
  scale_colour_viridis_c(name = "95% CI width") +
  coord_equal() + theme_void()


# 6. Optional: the multi-season extension -------------------------------

# The optional practical slides use the same 100 sites in three
# seasons, with three visits per season. Columns must be ordered by
# season and then visit. Seasons can gain or lose use; a site's state
# is assumed stable during the three visits within each season.
# Store the number of seasons and repeat visits so the column-name
# construction below is easier to read.
nseasons <- 3
J <- 3
# paste0() joins text and numbers into column names. 1:J makes 1,2,3;
# rep() repeats season and visit numbers in the order used in the CSV.
y.columns <- c(paste0("y.", 1:J),
               paste0("y.S", rep(2:nseasons, each = J), "V",
                      rep(1:J, nseasons - 1)))
flow.columns <- c(paste0("highFlow.", 1:J),
                  paste0("highFlow.S", rep(2:nseasons, each = J), "V",
                         rep(1:J, nseasons - 1)))
# Keep exactly the named columns, in season-then-visit order.
y.ms <- as.matrix(surveys[, y.columns])
flow.ms <- as.matrix(surveys[, flow.columns])
# Give corresponding detection and flow columns the same short labels.
season.visit <- paste0("S", rep(1:nseasons, each = J), "V",
                       rep(1:J, nseasons))
colnames(y.ms) <- colnames(flow.ms) <- season.visit
# data.frame() places the nine detections, one cover value and nine
# flow values for each site in the layout shown on the slides.
msdata <- data.frame(y = y.ms, cover = cover, highFlow = flow.ms)
head(msdata, 2)

# numPrimary=3 tells unmarked there are three seasons. The nine
# detection columns and nine flow columns must be in the same order.
# Columns 1:9 are detections; 10 is cover; 11:19 are flow values.
umf.ms <- unmarkedMultFrame(y = msdata[, 1:9],
                           siteCovs = data.frame(cover = msdata$cover),
                           obsCovs = list(highFlow = msdata[, 11:19]),
                           numPrimary = 3)

# colext() uses four separate formulas: initial use, gain of use,
# loss of use, and detection. A ~1 transition formula gives one
# constant probability between seasons.
# The four formula names are specific to this multi-season model.
mod.ms <- colext(psiformula = ~cover,
                 gammaformula = ~1,
                 epsilonformula = ~1,
                 pformula = ~highFlow,
                 data = umf.ms)
summary(mod.ms)

# backTransform() converts logit-scale estimates to probabilities.
# For initial use, c(1, 50) means intercept + 50 * cover slope.
# linearComb() first combines those two fitted coefficients. type="psi"
# selects initial occupancy; "col" and "ext" select transition terms.
initial.use <- backTransform(linearComb(mod.ms, c(1, 50), type = "psi"))
gain.use <- backTransform(mod.ms, type = "col")
loss.use <- backTransform(mod.ms, type = "ext")
# A list can hold the three different unmarked estimate objects.
ms.estimates <- list(initial.use, gain.use, loss.use)
# vapply() runs the small function on each list item and collects one
# number per item. coef() obtains the estimate; confint() its limits.
# numeric(1) says each function call must return one number.
ms.results <- data.frame(
  Process = c("Initial use at 50% cover", "Gain of use (colonisation)",
              "Loss of use (local extinction)"),
  Estimate = vapply(ms.estimates, function(x) unname(coef(x)), numeric(1)),
  Lower = vapply(ms.estimates, function(x) confint(x)[1], numeric(1)),
  Upper = vapply(ms.estimates, function(x) confint(x)[2], numeric(1))
)
# Round only the numeric columns for an easy first look; the full
# table that follows retains the unrounded values and process names.
round(ms.results[, 2:4], 2)
ms.results

# Gain and loss refer to site use, not births or deaths of animals.
# Fewer detections in a later season alone do not establish loss.

