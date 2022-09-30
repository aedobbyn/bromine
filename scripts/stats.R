library(tidyverse)

source(here::here("scripts/helpers.R"))

data <- grab_latest()

pre_hot_tub_average_usage <- 
  data %>% 
  filter(
    start_time < lubridate::as_datetime("2022-09-27 20:00:00")
  ) %>% 
  summarise(
    avg = mean(usage)
  ) %>% 
  pull(avg)

maintenance_window_99 <- 
  data %>% 
  filter(
    start_time > lubridate::as_datetime("2022-09-28 23:00:00") &
      start_time < lubridate::as_datetime("2022-09-29 10:00:00")
  ) %>% 
  summarise(
    avg = mean(usage)
  ) %>% 
  pull(avg)

diff <- maintenance_window_99 - pre_hot_tub_average_usage