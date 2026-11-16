# Plot sampling: code to run alongside the practical and theory slides
# Run this file from top to bottom in RStudio. You can also select and run
# one section at a time. Lines starting with # are explanations for you;
# R ignores them. Results appear in the Console and plots in the Plots pane.
#
# The practical begins with a 50 m x 50 m patch divided into 25 equal
# 10 m x 10 m plots. The counts below come directly from the slides.


# 1. Simple random sampling -----------------------------------------------

# Five of the 25 plots were surveyed. A zero means a complete search
# found no eligible juniper tree; it must stay in the data.
srs <- data.frame(
  count = c(2, 2, 1, 1, 0),
  M = 25,              # Total number of possible plots in the patch
  w = 25 / 5           # Each surveyed plot represents five plots
)

# mean() finds the average count per surveyed plot. Multiplying by 25
# expands that average to the whole patch: (6 / 5) * 25 = 30 trees.
mean(srs$count)
mean(srs$count) * 25


# 2. Stratified random sampling -------------------------------------------

# The patch is divided into woodland (W: 15 plots) and open slope
# (O: 10 plots). We sampled 6 woodland plots and 4 open-slope plots.
woodland_counts <- c(1, 2, 1, 1, 1, 1)
open_counts <- c(1, 1, 0, 5)

# Estimate each habitat separately, then add the estimated totals.
# Woodland: (7 / 6) * 15 = 17.5; open slope: (7 / 4) * 10 = 17.5.
woodland_total <- mean(woodland_counts) * 15
open_total <- mean(open_counts) * 10
woodland_total
open_total
woodland_total + open_total  # 35 trees for the whole patch


# 3. Systematic sampling ---------------------------------------------------

# These nine plots form a grid with a random start. Their observed
# counts sum to 10. The total is (10 / 9) * 25 = 27.78, or about 28.
systematic <- data.frame(
  id = c(1, 3, 5, 11, 13, 15, 21, 23, 25),
  count = c(1, 1, 1, 1, 1, 1, 0, 3, 1),
  M = 25,
  w = 25 / 9
)
sum(systematic$count)
mean(systematic$count) * 25


# 4. Approximate 95% confidence intervals --------------------------------

# The next commands are the same survey-package analyses shown on the
# practical slides. Install the package once if your computer needs it:
# install.packages("survey")
library(survey)

# ids = ~1 means there is one observation per selected plot.
# weights = ~w expands sampled plots to the full patch.
# fpc = ~M tells R how many plots were available for sampling; it
# accounts for sampling plots without replacement.
d_srs <- svydesign(ids = ~1,
                   weights = ~w, fpc = ~M, data = srs)
fit_srs <- svytotal(~count, d_srs)
coef(fit_srs)                         # Estimated total: 30
confint(fit_srs, df = degf(d_srs))   # Approximate 95% CI: 7 to 53

# Put the woodland and open-slope observations in one table. The
# habitat column tells R which stratum each count belongs to.
strat <- data.frame(
  count = c(1, 2, 1, 1, 1, 1, 1, 1, 0, 5),
  habitat = c("W", "W", "W", "W", "W", "W",
              "O", "O", "O", "O"),
  M = c(15, 15, 15, 15, 15, 15, 10, 10, 10, 10),
  Msmp = c(6, 6, 6, 6, 6, 6, 4, 4, 4, 4)
)
strat$w <- strat$M / strat$Msmp
d_strat <- svydesign(ids = ~1,
                     strata = ~habitat, weights = ~w,
                     fpc = ~M, data = strat)
fit_strat <- svytotal(~count, d_strat)
coef(fit_strat)                         # Estimated total: 35
confint(fit_strat, df = degf(d_strat)) # Approximate 95% CI: 15 to 55

# The slide uses the simple random sampling calculation as an
# approximation for the systematic grid. It does not account for
# dependence among nearby plots, so report that limitation with its CI.
d_sys <- svydesign(ids = ~1,
                   weights = ~w, fpc = ~M, data = systematic)
fit_sys <- svytotal(~count, d_sys)
coef(fit_sys)                         # Estimated total: about 28
confint(fit_sys, df = degf(d_sys))   # Approximate 95% CI: 16 to 40


# 5. Repeated surveys: the juniper coverage example -----------------------

# This follows the theory slides' single example of 500 juniper trees
# in a 20 km x 20 km region. We hold the tree locations fixed and move
# the survey grids between repeats. There are three sampling efforts:
# 9, 16 and 25 circular plots, each with radius 1 km. The result is
# three histograms, one for each effort, as in the slides.
#
# Change only this number to choose how many repeated surveys to run.
# Try 100 first, then 2000 (the number used in the slides).
n_repeats <- 2000

# A fixed seed lets everyone reproduce the same demonstration.
set.seed(2409)
N_true <- 500
region_side <- 20       # km; total area is 20 * 20 = 400 km^2
plot_radius <- 1        # km
region_area <- region_side^2

# Each row is one tree location (x and y coordinates in km).
trees <- data.frame(x = runif(N_true, 0, region_side),
                    y = runif(N_true, 0, region_side))

# expand.grid() makes all x/y combinations for a regular plot grid.
# These are the centred grids drawn on the theory slides.
plot_grids <- list(
  "9 plots" = expand.grid(x = seq(3, 17, length.out = 3),
                          y = seq(3, 17, length.out = 3)),
  "16 plots" = expand.grid(x = seq(2.5, 17.5, length.out = 4),
                           y = seq(2.5, 17.5, length.out = 4)),
  "25 plots" = expand.grid(x = seq(2, 18, length.out = 5),
                           y = seq(2, 18, length.out = 5))
)

# A tree is counted if its distance to any plot centre is at most 1 km.
# The squared distance avoids taking a square root and gives the same
# inside/outside decision. Since plots do not overlap, each tree is
# counted once.
count_trees <- function(trees, centres, radius) {
  counted <- rep(FALSE, nrow(trees))
  for (j in seq_len(nrow(centres))) {
    inside <- (trees$x - centres$x[j])^2 +
              (trees$y - centres$y[j])^2 <= radius^2
    counted <- counted | inside
  }
  sum(counted)
}

# Store one abundance estimate per repeated survey and sampling effort.
estimates <- data.frame(
  design = rep(names(plot_grids), each = n_repeats),
  estimate = NA_real_
)

for (design in names(plot_grids)) {
  centres <- plot_grids[[design]]
  number_of_plots <- nrow(centres)

  # The circular plots do not overlap. Their combined area divided by
  # the region area is the proportion covered, p_c = a / A.
  coverage <- number_of_plots * pi * plot_radius^2 / region_area
  cat(design, ": coverage =", round(coverage, 3), "\n")

  # This is the largest shift that keeps every circular plot inside
  # the 20 km x 20 km survey region.
  margin <- min(min(centres$x) - plot_radius,
                region_side - plot_radius - max(centres$x))

  for (survey_number in seq_len(n_repeats)) {
    # Choose a new random start for this survey's grid.
    shifted <- centres
    shifted$x <- shifted$x + runif(1, -margin, margin)
    shifted$y <- shifted$y + runif(1, -margin, margin)

    n_counted <- count_trees(trees, shifted, plot_radius)
    row <- which(estimates$design == design)[survey_number]
    estimates$estimate[row] <- n_counted / coverage
  }
}

# Compare the average estimate and its variance at each effort. The
# red vertical line in each histogram marks the true total, N = 500.
aggregate(estimate ~ design, estimates, mean)
aggregate(estimate ~ design, estimates, var)

# Install ggplot2 once if needed: install.packages("ggplot2")
library(ggplot2)
estimates$design <- factor(estimates$design, levels = names(plot_grids))
coverage_histograms <- ggplot(estimates, aes(x = estimate)) +
  geom_histogram(binwidth = 20, boundary = 0,
                 fill = rgb(0.16, 0.32, 0.75), colour = "white") +
  geom_vline(xintercept = N_true, colour = rgb(0.82, 0.1, 0.26)) +
  facet_wrap(~design, nrow = 1) +
  coord_cartesian(xlim = c(200, 800)) +
  labs(x = "Estimated abundance", y = "Number of surveys") +
  theme_bw()
coverage_histograms


# 6. Binomial probabilities with dbinom() ---------------------------------

# dbinom(n, N, p) gives the probability of exactly n successes in N
# independent trials, where each trial has success probability p.
# For plot sampling, a 'success' means that a tree is in the area
# covered by plots. This assumes each tree has the same chance p_c.

# Theory slide example 1: exactly 2 heads in 3 fair coin flips.
# Three arrangements (HHT, HTH, THH) each have probability 0.125.
3 * (0.5^2 * 0.5)       # 0.375
dbinom(2, 3, 0.5)       # The same answer: 0.375

# Theory slide example 2: detect exactly 2 of 3 animals if each has
# an independent 20% chance of detection.
3 * (0.2^2 * 0.8)       # 0.096
dbinom(2, 3, 0.2)       # The same answer: 0.096

# This is the dbinom calculation written on the theory slide.
n <- 10
N <- 20
p <- 0.3
dbinom(n, N, p)

# Juniper example: 20 trees were counted and 15.9% of the region was
# covered. If there were 100 trees in total, how likely is this count?
n <- 20
p <- 0.159
dbinom(n, 100, p)

# N is unknown. Try every whole number from 20 to 250. dbinom() can
# calculate all these probabilities at once: this is vectorisation.
N <- seq(20, 250)
Lik <- dbinom(n, N, p)

# The most likely N is the one with the largest likelihood. It is
# 125 trees, as shown on the slide. The direct estimate 20 / 0.159
# is about 126; the binomial likelihood gives a discrete estimate.
N[which.max(Lik)]
20 / p

# Draw the likelihood curve shown on the theory slides.
plot(N, Lik, type = "h", xlab = "Abundance (N)",
     ylab = "Likelihood (L(N))")
lines(N, Lik)
points(N[which.max(Lik)], max(Lik), pch = 19,
       col = rgb(0.82, 0.1, 0.26))

