library(tidyverse)

source(here::here("scripts/helpers.R"))

data <- grab_latest()

# Plot
ggplot2::ggplot(data, aes(start_time, usage, fill = source)) +
  geom_bar(stat = "identity")

ggplot2::ggplot(
  data %>%
    filter(source == "projected"),
  aes(start_time, usage, fill = source)
) +
  geom_bar(stat = "identity")
# scale_x_discrete(breaks = scales::date_breaks("15 mins"))
