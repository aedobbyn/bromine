library(tidyverse)

# Grab latest data
latest <-
  tibble(
    file = fs::dir_ls(here::here("data"))
  ) %>%
  mutate(
    date =
      file %>%
        str_extract("[0-9]+") %>%
        as.integer()
  ) %>%
  arrange(desc(date)) %>%
  pull(file)

# Read it in
combined <- readr::read_csv(latest)

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
