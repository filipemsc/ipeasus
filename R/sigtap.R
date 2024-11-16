parse_table_sigtap <- function(table_zip, file_layout, file_table) {
  check_file_layout <- file_layout %in% zip::zip_list(table_zip)$filename
  check_file_table <- file_table %in% zip::zip_list(table_zip)$filename

  if (check_file_layout == FALSE | check_file_table == FALSE) {
    return(NULL)
  } else {
    suppressMessages({
      layout <- readr::read_delim(
        file = unz(table_zip, file_layout),
        locale = readr::locale(encoding = "ISO-8859-1"),
        col_names = TRUE,
        delim = ","
      )

      names <- layout |> dplyr::pull(1)
      size_cols <- layout |>
        dplyr::pull(2) |>
        as.numeric()

      table <- vroom::vroom_fwf(
        unz(table_zip, file_table),
        col_positions = vroom::fwf_widths(size_cols),
        locale = vroom::locale(encoding = "ISO-8859-1"),
        col_types = c(.default = "c")
      )

      names(table) <- names
    })

    table
  }
}

download_sigtap <- function(dir = "sigtap", path = "data") {
  dir_raw_zip <- glue::glue("{path}/{dir}/raw_zip")
  dir_logs <- glue::glue("{path}/{dir}/logs")

  fs::dir_create(dir_raw_zip)
  fs::dir_create(dir_logs)

  url_sigtap <- "ftp://ftp2.datasus.gov.br/pub/sistemas/tup/downloads/"

  link_ftp <- url_sigtap

  suppressWarnings({
    ftp_files <- RCurl::getURLContent(link_ftp) |>
      strsplit("\r*\n") |>
      unlist()

    ftp_files <- gsub(" ", "\n", ftp_files) |>
      data.frame() |>
      tidyr::separate(
        col = 1,
        into = c("linux", "file_type", "ftp1", "ftp2", "size", "month", "day", "year", "file"),
        sep = "\\\n{1,}"
      )
  })

  ftp_files_sigtap <- grep("TabelaUnificada.*zip", ftp_files$file, value = TRUE)
  path_files_sigtap <- fs::path_file(fs::dir_ls(dir_raw_zip))

  queue <- ftp_files_sigtap[!ftp_files_sigtap %in% path_files_sigtap]

  if (length(queue) > 0) {
    links_queue <- glue::glue("{url_sigtap}{queue}")
    destfiles_queue <- glue::glue("{dir_raw_zip}/{queue}")

    download <- curl::multi_download(links_queue, destfiles_queue)
    log_name <- glue::glue("{dir_logs}/", janitor::make_clean_names(Sys.time()), "_download.csv")
    data.table::fwrite(download, log_name)

    to_delete <- download |> dplyr::filter(!success | is.na(success))

    if (nrow(to_delete) > 0) {
      log_name3 <- glue::glue("{dir_logs}/", janitor::make_clean_names(Sys.time()), "_rm_zip.csv")
      data.table::fwrite(to_delete, log_name3)
      fs::file_delete(to_delete$destfile)
    }
  }
}

create_sigtap_df <- function(dir = "sigtap", path = "data") {
  
  fulldir <- glue::glue("{path}/{dir}/raw_zip")
  files <- fs::dir_ls(fulldir)

  future::plan(future::multisession(), workers = 6)

  data <- furrr::future_map(files, function(temp) {
    partial <- parse_table_sigtap(temp, "tb_procedimento_layout.txt", "tb_procedimento.txt")

    procedimento_descricao <- parse_table_sigtap(temp, "tb_descricao_layout.txt", "tb_descricao.txt")

    if (is.null(procedimento_descricao)) {
      procedimento_descricao <- data.frame(CO_PROCEDIMENTO = NA, NO_PROCEDIMENTO = NA)
    } else {
      procedimento_descricao <- procedimento_descricao |>
        dplyr::filter(nchar(CO_PROCEDIMENTO) == 10) |>
        dplyr::select(-DT_COMPETENCIA)
    }

    procedimento_cid <- parse_table_sigtap(temp, "rl_procedimento_cid_layout.txt", "rl_procedimento_cid.txt") |>
      dplyr::group_by(CO_PROCEDIMENTO, ST_PRINCIPAL) |>
      dplyr::summarize(CO_CID = paste(CO_CID, collapse = ", ")) |>
      tidyr::spread(ST_PRINCIPAL, CO_CID) |>
      dplyr::rename("CO_CID_SECUNDARIO" = N, "CO_CID_PRINCIPAL" = S) |>
      dplyr::select(CO_PROCEDIMENTO, CO_CID_PRINCIPAL, CO_CID_SECUNDARIO)

    procedimento_cbo <- parse_table_sigtap(temp, "rl_procedimento_ocupacao_layout.txt", "rl_procedimento_ocupacao.txt") |>
      dplyr::group_by(CO_PROCEDIMENTO) |>
      dplyr::summarize(CO_OCUPACAO = paste0(CO_OCUPACAO, collapse = ", "))

    procedimento_grupo <- parse_table_sigtap(temp, "tb_grupo_layout.txt", "tb_grupo.txt") |>
      dplyr::select(-DT_COMPETENCIA)

    procedimento_sub_grupo <- parse_table_sigtap(temp, "tb_sub_grupo_layout.txt", "tb_sub_grupo.txt") |>
      dplyr::select(-DT_COMPETENCIA)

    procedimento_forma_organizacao <- parse_table_sigtap(temp, "tb_forma_organizacao_layout.txt", "tb_forma_organizacao.txt") |>
      dplyr::select(-DT_COMPETENCIA)

    dic_registro <- parse_table_sigtap(temp, "tb_registro_layout.txt", "tb_registro.txt")

    procedimento_registro <- parse_table_sigtap(temp, "rl_procedimento_registro_layout.txt", "rl_procedimento_registro.txt") |>
      dplyr::select(-DT_COMPETENCIA) |>
      dplyr::left_join(dic_registro) |>
      dplyr::mutate(NO_REGISTRO = stringr::str_squish(NO_REGISTRO)) |>
      dplyr::group_by(CO_PROCEDIMENTO) |>
      dplyr::summarize(NO_REGISTRO = paste0(NO_REGISTRO, collapse = ", "))

    dic_tipo_leito <- parse_table_sigtap(temp, "tb_tipo_leito_layout.txt", "tb_tipo_leito.txt") |>
      dplyr::mutate(NO_TIPO_LEITO = stringr::str_squish(NO_TIPO_LEITO))

    procedimento_leito <- parse_table_sigtap(temp, "rl_procedimento_leito_layout.txt", "rl_procedimento_leito.txt") |>
      dplyr::group_by(CO_PROCEDIMENTO) |>
      dplyr::left_join(dic_tipo_leito) |>
      dplyr::summarize(NO_TIPO_LEITO = paste0(NO_TIPO_LEITO, collapse = ", "))

    partial <- partial |>
      dplyr::mutate(
        CO_GRUPO = substring(CO_PROCEDIMENTO, 1, 2),
        CO_SUB_GRUPO = substring(CO_PROCEDIMENTO, 3, 4),
        CO_FORMA_ORGANIZACAO = substring(CO_PROCEDIMENTO, 5, 6)
      ) |>
      dplyr::left_join(procedimento_grupo) |>
      dplyr::left_join(procedimento_sub_grupo) |>
      dplyr::left_join(procedimento_forma_organizacao) |>
      dplyr::left_join(procedimento_descricao) |>
      dplyr::left_join(procedimento_cid) |>
      dplyr::left_join(procedimento_cbo) |>
      dplyr::left_join(procedimento_registro) |>
      dplyr::left_join(procedimento_leito)

    partial
  }, .progress = TRUE)

  data <- do.call(dplyr::bind_rows, data)

  sigtap <- data |>
    dplyr::group_by(CO_PROCEDIMENTO) |>
    dplyr::arrange(DT_COMPETENCIA) |>
    dplyr::mutate(
      DT_COMPETENCIA_INICIAL = dplyr::first(DT_COMPETENCIA),
      DT_COMPETENCIA_FINAL = dplyr::last(DT_COMPETENCIA)
    ) |>
    dplyr::select(-DT_COMPETENCIA) |>
    dplyr::summarise_all(~ dplyr::last(.x))


  fs::dir_create(glue::glue("{path}/{dir}/parquet"))
  fs::dir_create(glue::glue("{path}/{dir}/xlsx"))

  arrow::write_parquet(sigtap, glue::glue("{path}/{dir}/parquet/sigtap.parquet"))
  writexl::write_xlsx(sigtap, glue::glue("{path}/{dir}/xlsx/sigtap.xlsx"))

}

get_sigtap <- function(dir = "sigtap", path = "data"){
  download_sigtap(dir, path)
  create_sigtap_df(dir, path)
}
