
grab_latest <- function() {
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
  data <- readr::read_csv(latest)
}
