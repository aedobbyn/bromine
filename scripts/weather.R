library(tidyverse)
library(foreach)

file_name <- "data/weather/historic.csv"
file_exists <- fs::file_exists(file_name)

# Parameters for the Open Meteo API
latitude <- "40.680745"
longitude <- "-73.953425"
metrics <- c("temperature_2m", "relativehumidity_2m", "rain", "snowfall", "cloudcover", "windspeed_10m")
start_date <- "2020-01-01"
end_date <- lubridate::today()
time_zone <- "America/New_York"

# If we already have historic data, revise `start_date` so we pick up where we left off
if (file_exists) {
  existing_data <-
    read_csv(file_name)
  start_date <- 
    max(lubridate::date(test$time))
}

get_historic_weather_data <-
  function(metric) {
    httr::GET(
      "https://archive-api.open-meteo.com/v1/era5",
      query = 
        list(
          latitude = latitude,
          longitude = longitude,
          start_date = start_date,
          end_date = end_date,
          hourly = metric,
          timezone = time_zone,
          temperature_unit = "fahrenheit",
          precipitation_unit = "inch"
        )
    ) %>%
      httr::content() %>%
      .$hourly %>%
      as_tibble() %>%
      tidyr::unnest_longer(everything()) %>%
      mutate(
        time = lubridate::ymd_hm(time)
      )
  }

# Loop through each metric (the Open Meteo API allows you to call multiple metrics at the same
# time, but the `httr` URL encoder doesn't play nice with the formatting the API expects)
historic_data <-
  foreach(
    m = metrics,
    .combine = left_join 
  ) %do% {
    get_historic_weather_data(m)
  }

# Combine with existing data (if available) before overwriting the historic data
if (file_exists) {
  historic_data <-
    bind_rows(existing_data, historic_data) %>%
    distinct()
}

write_csv(historic_data, file_name)
