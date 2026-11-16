# Desert monitor survey: Task B — stratified random sampling with equal effort
# Run each section in RStudio to work through your own counts.
# Same survey-package workflow as the main plot-sampling practical:
# 02_plot_sampling/code/plot_sampling_confidence_intervals.R
# Install once if necessary: install.packages("survey")

# 1. Load the package and your CSV.
# RStudio: select your CSV in the file chooser, or replace file.choose()
# with a quoted path, e.g. "my_counts.csv".
# Terminal: Rscript task_B_stratified.R my_counts.csv
library(survey)
args <- commandArgs(trailingOnly = TRUE)
csv_file <- if (length(args)) args[1] else file.choose()
counts <- read.csv(csv_file, stringsAsFactors = FALSE, check.names = FALSE)

# 2. Check the data before estimating anything.
# Use exactly the same headings as the shared paper recording sheet.
if (!identical(names(counts), c("plot_id", "habitat", "count")))
  stop("CSV headings must be exactly: plot_id,habitat,count")
if (nrow(counts) != 20L)
  stop("Enter all 20 selected plots, one row per plot, without blank rows.")
if (anyNA(counts) || !is.numeric(counts$count) ||
    any(!is.finite(counts$count)) || any(counts$count < 0) ||
    any(counts$count != floor(counts$count)))
  stop("Every count must be a non-negative whole number; record empty plots as 0.")
if (any(!grepl("^[A-J](0[1-9]|10)$", counts$plot_id)) ||
    anyDuplicated(counts$plot_id))
  stop("Use 20 distinct plot IDs, A01 through J10, with two-digit row numbers.")
expected_habitat <- ifelse(substr(counts$plot_id, 1, 1) %in% LETTERS[6:10],
                           "green", "open")
if (any(counts$habitat != expected_habitat))
  stop("Habitat must be green for F-J and open for A-E (lowercase).")
print(counts)
print(table(counts$habitat))
# Confirm these IDs are the list assigned to your team. Valid IDs alone
# cannot establish that a random sampling procedure was followed.

# 3. Describe the stratified random sample with equal effort.
# There are 50 available plots in each habitat. Sample 10 in each,
# without replacement. Both habitats together represent the whole landscape.
if (sum(counts$habitat == "green") != 10L ||
    sum(counts$habitat == "open") != 10L)
  stop("Task B requires exactly 10 green plots and 10 open plots.")
strat <- counts
strat$M <- 50
strat$Msmp <- ave(strat$count, strat$habitat, FUN = length)
strat$w <- strat$M / strat$Msmp

# 4. Estimate habitat totals and combine them using the sampling design.
# This is the practical's stratified svydesign/svytotal/confint workflow.
d_strat <- svydesign(ids = ~1,
  strata = ~habitat, weights = ~w,
  fpc = ~M, data = strat)
fit_strat <- svytotal(~count, d_strat)
coef(fit_strat)
SE(fit_strat)
confint(fit_strat, df = degf(d_strat))
# Optional: see the two estimated habitat totals separately.
svyby(~count, ~habitat, d_strat, svytotal)

# 5. Work through the habitat calculations by hand.
habitat_counts <- split(strat$count, strat$habitat)
n_h <- lengths(habitat_counts)
mean_h <- vapply(habitat_counts, mean, numeric(1))
s2_h <- vapply(habitat_counts, var, numeric(1))
total_h <- 50 * mean_h
variance_h <- 50^2 * (1 - n_h/50) * s2_h/n_h
print(data.frame(habitat = names(mean_h), sampled_plots = n_h,
                 mean_count = mean_h, estimated_total = total_h))
abundance <- sum(total_h)
standard_error <- sqrt(sum(variance_h))
degrees_freedom <- degf(d_strat)  # 20 plots - 2 strata = 18.
ci <- abundance + c(-1, 1) * qt(0.975, degrees_freedom) * standard_error
print(c(abundance = abundance, standard_error = standard_error,
        lower_95 = ci[1], upper_95 = ci[2]))
# The hand calculation and survey output should agree.
# With 50 plots and 10 sampled in EACH habitat, the point estimate also
# equals 100 * mean(strat$count). The stratified SE uses within-habitat
# variation, not the pooled variance used for simple random sampling.
# These are approximate 95% t intervals; keep the calculated limits intact.
# Keep full precision in calculations; report to one decimal place.
