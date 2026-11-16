# Desert monitor survey: Task A — simple random sampling
# Run each section in RStudio to work through your own counts.
# Same survey-package workflow as the main plot-sampling practical:
# 02_plot_sampling/code/plot_sampling_confidence_intervals.R
# Install once if necessary: install.packages("survey")

# 1. Load the package and your CSV.
# RStudio: select your CSV in the file chooser, or replace file.choose()
# with a quoted path, e.g. "my_counts.csv".
# Terminal: Rscript task_A_srs.R my_counts.csv
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

# 3. Describe the simple random sample.
# M is the number of available plots, not the number of animals.
# A sample of 20 is drawn without replacement from all 100 plots.
srs <- counts
srs$M <- 100
srs$w <- srs$M / nrow(srs)  # Each sampled plot represents five plots.

# 4. Expand to the whole landscape, accounting for sampling design.
# fpc supplies the finite-population correction for sampling without replacement.
d_srs <- svydesign(ids = ~1,
  weights = ~w, fpc = ~M, data = srs)
fit_srs <- svytotal(~count, d_srs)
coef(fit_srs)
SE(fit_srs)
confint(fit_srs, df = degf(d_srs))

# 5. Work through the same calculation by hand.
mean_count <- mean(srs$count)
abundance <- 100 * mean_count
standard_error <- 100 * sqrt((1 - nrow(srs)/100) * var(srs$count)/nrow(srs))
degrees_freedom <- degf(d_srs)  # 20 plots - 1 = 19.
ci <- abundance + c(-1, 1) * qt(0.975, degrees_freedom) * standard_error
print(c(mean_count = mean_count, abundance = abundance,
        standard_error = standard_error, lower_95 = ci[1], upper_95 = ci[2]))
# The hand calculation and survey output should agree.
# This approximate 95% t interval describes uncertainty in the TOTAL number
# of monitors, including animals outside the surveyed plots.
# Keep full precision in calculations; report to one decimal place.
# Do not omit zero counts or replace plots after seeing their counts.
