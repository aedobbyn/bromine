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
projected <- readr::read_csv(path_projected)

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

real <- tibble()

# For each real usage file, download it and read it in as a csv
for (i in 1:nrow(real_usage)) {
  path_local <- glue::glue("{dir}/real_usage_{real_usage$date_start[i]}_{real_usage$date_end[i]}.csv")
  
  real_usage %>% 
    slice(i) %>% 
    pull(id) %>% 
    googledrive::drive_download(path_local, overwrite = TRUE)
  
  this <- 
    readr::read_csv(path_local, skip = 5)
  
  real %<>%
    bind_rows(this)
} 

real %<>% 
  distinct()
