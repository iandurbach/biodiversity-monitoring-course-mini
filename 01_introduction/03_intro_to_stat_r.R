# Introduction to statistical modelling in R ------------------------------
# Companion to 02_intro_to_stat_r.qmd, starting at "R as a calculator".
# Run the sections in order: later examples use objects created earlier.
# In RStudio, select a line or block and press Ctrl+Enter (Windows/Linux)
# or Cmd+Enter (Mac). Results appear in the Console; graphs in Plots.
# Lines beginning with # are comments for you to read; R ignores them.
# This script creates its own objects; no lecture code needs to run first.


# 1. R as a calculator ----------------------------------------------------

# Use + for addition, * for multiplication and / for division.
34.56 + 150.34
630.80 * 0.25
630.80 / 4

# Try changing the numbers, then run the line again.


# 2. Store values as named objects ----------------------------------------

# <- means "store the value on the right in the object on the left".
# Assignment saves a result; typing the name displays the saved value.
mymain <- 150.34
mydrink <- 34.56
mybill <- mymain + mydrink
mybill

# Names are case-sensitive: mybill and Mybill would be different objects.
# Changing mymain later does not automatically recalculate mybill:
# you would also need to run mybill <- mymain + mydrink again.

# A function performs a task. Its inputs go inside parentheses, ().
class(mybill)                  # The kind of object: numeric
typeof(mybill)                 # Its internal storage type: double
ls()                           # Names of objects currently in the workspace

# To open documentation, run the next line without the leading #:
# ?mean


# 3. Data types -----------------------------------------------------------

a <- 10                        # Numeric: a number used in calculations
b <- "elephant"                # Character: text is enclosed in quotes
c <- TRUE                      # Logical: TRUE or FALSE, without quotes
d <- factor(c("foraging", "travel", "foraging"))
# A factor represents categories; its possible categories are "levels".
# Here c() combines values. Despite the object named c above, R can still
# find the c() function when it is called with parentheses.

class(a)
class(b)
class(c)
class(d)
levels(d)


# 4. Vectors, indexing and missing values ---------------------------------

# A vector is an ordered collection of values of the same type.
x1 <- c(10, 20, 30, 40)
x1
length(x1)                     # How many values are in the vector? Four.
x1[1]                          # Square brackets select a value: 10
x1[3]                          # R counts positions starting at 1: 30

x1[12]                         # No twelfth value exists, so R returns NA
# NA means "Not Available". It is not zero and is not text in quotes.
mean(c(1, 2, 3, NA))            # The missing value makes this mean NA
mean(c(1, 2, 3, NA), na.rm = TRUE)  # Omit NA values: the mean is 2

# is.na() returns TRUE for missing values and FALSE for other values.
# sum() counts TRUE as 1 and FALSE as 0, so this counts missing values.
sum(is.na(c(1, 2, 3, NA)))
# Always investigate why data are missing before deciding to omit them.


# 5. Data frames and lists ------------------------------------------------

# A data frame is a table: each column is a variable, each row an observation.
# 1:4 is shorthand for the sequence 1, 2, 3, 4.
df1 <- data.frame(
  id = 1:4,
  value = c(10, 20, 30, 40),
  group = c("A", "A", "B", "B")
)
df1

names(df1)                     # Column names
dim(df1)                       # Dimensions: number of rows, then columns
str(df1)                       # Structure: column types and example values
head(df1)                      # First six rows, or all rows if fewer than six
tail(df1)                      # Last six rows

# A list can hold several different kinds of object together.
lst <- list(
  numbers = x1,
  table = df1,
  summary = mean(x1)
)
names(lst)
lst$numbers                    # $ selects a named component
lst$summary                    # The stored mean of x1: 25


# 6. Functions and their arguments ----------------------------------------

# Arguments are the inputs or options supplied to a function.
log(10)                        # Natural logarithm (base e)
sqrt(16)                       # Square root: 4
mean(x = c(1, 2, 3, 4, 5))     # x names the input argument; mean is 3
sum(c(1, 2, 3, 4, 5))          # Sum: 15
sd(x = c(1, 2, 3, 4, 5))       # Sample standard deviation
mean(x = c(1, 2, 3, NA), na.rm = TRUE)

# Many arguments have defaults. mean() uses na.rm = FALSE unless told
# otherwise. Run ?mean in the Console to read its arguments and examples.

# Define a function of our own. The code inside braces runs when called.
my_fun <- function(x) {
  res <- x + x
  return(res)                  # Send the result back to the caller
}
my_fun(3)                      # Expect 6
my_fun(2)                      # Expect 4

# Comments can explain a whole line or follow code on the same line.
counts <- c(12, 8, 15, 10)     # Animal counts at four survey sites
mean(counts)                   # Average count per surveyed site

# Your turn: write celsius_to_fahrenheit() using F = C * 9/5 + 32.
# Try it yourself before running the worked answer below.
celsius_to_fahrenheit <- function(celsius) {
  fahrenheit <- celsius * 9 / 5 + 32
  return(fahrenheit)
}
celsius_to_fahrenheit(0)        # Expect 32
celsius_to_fahrenheit(20)       # Expect 68
# If either answer differs, inspect the calculation before continuing.


# 7. Packages and the pipe ------------------------------------------------

# Packages add functions to R. This lesson uses dplyr; the other examples
# use functions supplied with R. Installing downloads a package once;
# library() makes its functions available in each new session.
# If needed, remove # from the next line and run it (requires internet):
# install.packages("dplyr", repos = "https://cloud.r-project.org")
library(dplyr)

x3 <- 1:5
y3 <- x3^2                     # ^ means "raise to a power": square x3
df3 <- data.frame(x = x3, y = y3)

# The pipe |> passes the object on its left into the function on its right.
# It requires R 4.1 or later. mutate() adds or changes a column.
df3a <- df3 |>
  mutate(y2 = y^2)
df3
df3a
# Saving under a new name leaves df3 available for comparison.
# Without the pipe, the same command is: mutate(df3, y2 = y^2).


# 8. Read and inspect the penguin data ------------------------------------

# These measurements are from penguins near Palmer Station, Antarctica,
# derived from the palmerpenguins data. The CSV is supplied with this module.
# Use the module folder if running from the repository root; otherwise
# use the current folder (as when Introduction.Rproj is open).
module_dir <- if (file.exists("01_introduction/data/penguin_dat.csv")) {
  "01_introduction"
} else {
  "."
}
data_file <- file.path(module_dir, "data", "penguin_dat.csv")
if (!file.exists(data_file)) {
  stop("Cannot find penguin_dat.csv. Run from the course root or 01_introduction folder.")
}

# read.csv() reads a comma-separated table. The quoted path names a file;
# penguin_dat is the name we give to the resulting data frame in R.
penguin_dat <- read.csv(data_file)
dim(penguin_dat)
names(penguin_dat)
head(penguin_dat)
str(penguin_dat)


# 9. Select rows and columns; summarise a measurement ----------------------

# For a data frame, use [row, column]. Leaving one side empty selects
# every row or every column on that side.
penguin_dat[1, 1]               # First row, first column
head(penguin_dat[, 1])          # First few entries of the first column
penguin_dat[1, ]                # All measurements for the first penguin

# $ selects a column by name, which is usually easier to read than a number.
mean(penguin_dat$bill_length_mm)  # Returns NA because some lengths are missing
sum(is.na(penguin_dat$bill_length_mm))
mean(penguin_dat$bill_length_mm, na.rm = TRUE)
# The last mean uses only penguins with a recorded bill length, in mm.


# 10. Create a column and save the data -----------------------------------

# Work on a copy so that the original imported table remains available.
penguin_dat2 <- penguin_dat
penguin_dat2$body_mass_kg <- penguin_dat2$body_mass_g / 1000
head(penguin_dat2)

# Create output folders inside this module. recursive = TRUE also creates
# missing parent folders; showWarnings = FALSE avoids a warning if a folder
# already exists. file.path() builds paths appropriate for your computer.
data_output_dir <- file.path(module_dir, "output", "data")
dir.create(data_output_dir, recursive = TRUE, showWarnings = FALSE)
write.csv(penguin_dat2,
          file.path(data_output_dir, "penguin_dat2.csv"),
          row.names = FALSE)
# row.names = FALSE prevents an extra column of row numbers in the CSV.
# Rerunning this command replaces this derived CSV; the source is preserved.


# 11. Draw and save plots -------------------------------------------------

x4 <- 1:10
y4 <- x4^2
plot(x4, y4, pch = 19, col = "blue")
lines(x4, y4)                  # Add connecting lines to the current plot
# pch selects the point symbol (19 = filled circle); col sets its colour.

penguin_plot_data <- penguin_dat2
boxplot(body_mass_kg ~ species, data = penguin_plot_data,
        main = "Penguin body mass by species",
        xlab = "Species", ylab = "Body mass (kg)")
# Here ~ means "group body mass by species". Each box shows the middle
# half of the recorded masses, with a line at the median. Points beyond
# the whiskers mark unusually low or high values, not necessarily errors.
# Missing masses are omitted from the plot.

# To save a graph, open a file graphics device, draw, then close the device.
figure_output_dir <- file.path(module_dir, "output", "figures")
dir.create(figure_output_dir, recursive = TRUE, showWarnings = FALSE)
pdf(file.path(figure_output_dir, "penguin_body_mass_boxplot.pdf"),
    width = 7, height = 5)      # PDF dimensions are in inches
boxplot(body_mass_kg ~ species, data = penguin_plot_data,
        main = "Penguin body mass by species",
        xlab = "Species", ylab = "Body mass (kg)")
dev.off()                      # Finish writing the PDF; do not skip this!
# Rerunning this section replaces the saved PDF with the new version.


# 12. Inspect a relationship and fit a linear regression ------------------

# Question: is body mass associated with flipper length?
# Look first: does mass tend to increase or decrease with flipper length?
# Is a straight line a reasonable description of the overall pattern?
plot(body_mass_g ~ flipper_length_mm, data = penguin_dat,
     pch = 19, col = "blue",
     xlab = "Flipper length (mm)", ylab = "Body mass (g)",
     main = "Penguin Body Mass and Flipper Length")

# A model formula has the response on the left and predictor on the right:
# body_mass_g ~ flipper_length_mm
# We model mass = intercept + slope * flipper length + residual error.
# lm() fits a linear model; data tells it where to find the named columns.
model <- lm(
  body_mass_g ~ flipper_length_mm,
  data = penguin_dat,
  na.action = na.omit           # Omit rows missing either model variable
)
summary(model)
nobs(model)                    # Number of complete observations used


# 13. Interpret the coefficients and fitted line --------------------------

coef(model)
# (Intercept): predicted average mass at zero flipper length. Zero is far
# outside the observed lengths, so this intercept has little biological use.
# flipper_length_mm: predicted change in mass (g) per extra millimetre of
# flipper length. A positive slope means longer flippers predict higher mass.

plot(body_mass_g ~ flipper_length_mm, data = penguin_dat,
     pch = 19, col = "blue",
     xlab = "Flipper length (mm)", ylab = "Body mass (g)")
abline(model, col = "red", lwd = 2)
# abline() adds the fitted straight line; lwd controls its thickness.
# This line estimates average mass. Individual penguins differ from it.

summary(model)$r.squared
# This is also printed as "Multiple R-squared" in summary(model).
# It is the proportion of variation in observed mass explained by this
# model: 0 means none, 1 means all; 0.75 would mean 75% explained.
# A large R-squared alone does not establish that assumptions are met or
# that flipper length causes mass. This example pools several species.


# 14. Predict for new flipper lengths -------------------------------------

# newdata must have a column with exactly the predictor name in the model.
newdata <- data.frame(flipper_length_mm = c(180, 200, 220))
predict(model, newdata = newdata)
# The three answers are estimated average masses, in grams, in row order.
# They are not the exact masses of individual penguins.

range(penguin_dat$flipper_length_mm, na.rm = TRUE)
# Observed lengths range from 172 to 231 mm. Our new lengths lie within
# this range. Predicting at 250 mm would extrapolate beyond the data and
# needs extra caution because the observed relationship may not continue.

# Practice: change one prediction length to another value within the range.
# Before running predict() again, decide whether its mass should rise or fall.
# Then revisit the script: can you explain each important step, its inputs
# and its output? Inspect data, summarise and plot before fitting models;
# check assumptions and whether the results make sense before using them.
