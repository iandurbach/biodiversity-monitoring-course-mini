# Desert monitor plot-sampling survey

The landscape contains 100 equal-area one-hectare plots. Columns A–E are open;
F–J are green. Each habitat occupies half the total area. Both tasks survey 20
plots on the same landscape, using the **same student instructions and recording
sheet**. Task A is simple random sampling; Task B is stratified random sampling
with 10 plots per habitat. Assign a task and sample-set letter before counting.

## Print

- `printable_materials.pdf`: one A3 landscape colour map per team, actual size.
- `student_instructions.pdf`: the same A4 page for every team.
- `task_cards.pdf`: A4 page with four sample lists per task; give each team its
  assigned task/set. Sample letters A–D are independent of task labels A/B.
- `recording_sheet.pdf`: the same A4 sheet for every team.
- `instructor_guide.pdf`: facilitator setup, formulas, answer table and cell key.

`04_plot_sampling_student.pdf` combines instructions, A3 map, task cards and
recording sheet. It has mixed page sizes; print its A3 page separately if your
printer cannot choose trays by page size. Component PDFs avoid that issue.
No concealed animal-count cards are needed. The printed grid cells are
rectangles representing equal-area plots; measurements on paper are unnecessary.

## Enter data and calculate

Give students `code/` and `data/student/`, alongside the student PDFs. Install
`survey` once in R with `install.packages("survey")` before class.

Copy `data/student/recording_template.csv`, enter all 20 selected plots and save
as CSV. Its exact headings match the paper sheet:

```csv
plot_id,habitat,count
```

Use two-digit row numbers (e.g. F07). Habitat must be lowercase `green` (F–J)
or `open` (A–E). Counts are whole numbers, including 0 for an empty surveyed
cell. Delete unused blank rows; never substitute missing observations with zero.
Use one row per plot, with no totals rows. The scripts check headings, IDs,
duplicates, counts and habitat labels; Task B also requires 10 per habitat.

Open the matching standalone script in RStudio and run each numbered section:

- Task A: `code/task_A_srs.R`
- Task B: `code/task_B_stratified.R`

Choose the team's CSV when prompted, or edit the `csv_file` line to a path.
From this module directory, command-line equivalents are:

```sh
Rscript code/task_A_srs.R my_counts.csv
Rscript code/task_B_stratified.R my_counts.csv
```

Each script shows abundance, standard error, approximate 95% confidence limits,
and a manual calculation to compare with the `survey` output. Calculations
match the main practical: `svydesign`, `svytotal` and
`confint(fit, df=degf(design))`, with finite-population corrections. The 95%
intervals are t-based, not prediction intervals for individual plot counts.
Both designs give weight 5 per plot here; their variance calculations differ.

## Instructor files and rebuild

Keep `data/instructor/` private until the reveal. It contains a common population
of 300 monitors (120 green, 180 open), individual positions, saved game, cell
counts, eight filled example CSVs and `task_answers.csv`. The examples have
exactly the same headings as student submissions. All answers and the map are
generated from `scripts/simulate.R`; do not hand-edit keys separately.

From the repository root:

```sh
python3 wildlife-survey-games/scripts/build.py --only plot_sampling --skip-analysis
```

This rebuilds the map, supporting PDFs, combined pack, examples and answers.
It also checks all eight example submissions against the manual calculations
and verifies that invalid student data are rejected.
It requires R (`png`, `survey`, `knitr`), Quarto/XeLaTeX and Poppler utilities.
To rebuild only the A3 map and its matching population export:

```sh
Rscript wildlife-survey-games/scripts/build_plot_landscape.R
```

Changing the population or sampling rules requires the full module rebuild.
The icon's public-domain source is documented in `assets/SOURCE.md`.
