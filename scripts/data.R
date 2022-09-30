library(tidyverse)
library(magrittr)

dir <- glue::glue("temp/{lubridate::now() %>% as.numeric()}")
fs::dir_create(dir)

# Filter drive to just bromine project
drive_folder <-
  googledrive::drive_find(n_max = 10) %>%
  filter(name == "Project Tech Bromine")

# Using the id of the folder, get dataframe of files in that folder
file_tbl <-
  googledrive::drive_ls(folder$id)

### Projected

path_projected <- glue::glue("{dir}/data.csv")

# Use the id of the data csv to download projected data
file_tbl %>%
  filter(name == "data.csv") %>%
  pull(id) %>%
  googledrive::drive_download(path_projected, overwrite = TRUE)

# Read in projected data
projected <-
  # Read in timestamps as characters to get correct timezone
  readr::read_csv(path_projected, col_types = "ccdc") %>%
  janitor::clean_names() %>%
  mutate(
    across(
      c(start_time, end_time),
      # Remove the weird minus 4 hours and take to datetime
      ~ . %>% str_remove("-04:00") %>% lubridate::as_datetime()
    ),
    source = "projected"
  ) %>%
  transmute(
    start_time, end_time,
    usage = value,
    source
  )

### Real

# Filter files to just real data and add columns for start and end dates
real_usage_tbl <-
  file_tbl %>%
  filter(str_detect(name, "electric_interval_data")) %>%
  mutate(
    date_start =
      name %>%
        str_extract("2022-[0-9][0-9]-[0-9][0-9]") %>%
        lubridate::as_date(),
    date_end =
      name %>%
        str_extract("to_2022-[0-9][0-9]-[0-9][0-9]") %>%
        str_remove("to_") %>%
        lubridate::as_date(),
  )

real_raw <- tibble()

# For each real usage file, download it and read it in as a csv
for (i in 1:nrow(real_usage)) {
  path_local <- glue::glue("{dir}/real_usage_{real_usage$date_start[i]}_{real_usage$date_end[i]}.csv")

  real_usage %>%
    slice(i) %>%
    pull(id) %>%
    googledrive::drive_download(path_local, overwrite = TRUE)

  this <-
    readr::read_csv(path_local, skip = 5)

  real_raw %<>%
    bind_rows(this)
}

real <-
  real_raw %>%
  # If we have overlap of the data from multiple files, only keep one row
  distinct() %>%
  janitor::clean_names() %>%
  mutate(
    start_time = glue::glue("{date} {start_time}") %>% lubridate::as_datetime(),
    end_time = glue::glue("{date} {end_time}") %>% lubridate::as_datetime(),
    source = "real"
  ) %>%
  select(
    start_time, end_time, usage, source
  )


### Combined

combined <-
  bind_rows(
    projected,
    real
  ) %>%
  arrange(
    start_time, end_time
  )

# Plot
ggplot2::ggplot(combined, aes(start_time, usage, fill = source)) +
  geom_bar(stat = "identity")

ggplot2::ggplot(
  combined %>% 
    filter(source == "projected"), 
  aes(start_time, usage, fill = source)
  ) +
  geom_bar(stat = "identity")
  # scale_x_discrete(breaks = scales::date_breaks("15 mins"))

