transform_sus_parquet <- function(path = "data", dir, workers = 4) {
  
  dbc_ls <- fs::dir_info(glue::glue("{path}/{dir}/dbc")) |>
    dplyr::select(path, change_time) |>
    dplyr::mutate(file = fs::path_file(path)) |>
    dplyr::mutate(file = fs::path_ext_remove(file))

  parquet_ls <- fs::dir_info(glue::glue("{path}/{dir}/parquet")) |>
    dplyr::select(path, change_time) |>
    dplyr::mutate(file = fs::path_file(path)) |>
    dplyr::mutate(file = fs::path_ext_remove(file))

  df_queue <- dplyr::full_join(dbc_ls, parquet_ls, by = "file", suffix = c("_dbc", "_parquet")) |>
    dplyr::filter(change_time_dbc >= change_time_parquet | is.na(change_time_parquet))

  if (nrow(df_queue) > 0) {
    queue <- df_queue$path_dbc
    destfiles <- gsub("dbc", "parquet", queue)

    convert_dbc_parquet <- function(file_dbc, file_parquet) {
      base <- read.dbc::read.dbc(file_dbc)
      base[] <- lapply(base, as.character)
      #base[] <- lapply(base, stringi::stri_unescape_unicode)
      arrow::write_parquet(base, file_parquet)
    }

    library(furrr)

    plan(multisession, workers = workers)

    furrr::future_walk2(.x = queue, .y = destfiles, ~ convert_dbc_parquet(.x, .y), .progress = TRUE)
  }

  files_to_delete <- dplyr::anti_join(parquet_ls, dbc_ls, by = "file")

  if (nrow(files_to_delete) > 0) {
    log_name <- glue::glue("{path}/{dir}/logs/", janitor::make_clean_names(Sys.time()), "_rm_parquet.csv")

    data.table::fwrite(files_to_delete, log_name)

    fs::file_delete(files_to_delete$path)
  }
}
