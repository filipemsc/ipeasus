# Tempo atual: 5067.38 sec elapsed
tictoc::tic()

library(dplyr)
library(tidyr)

parse_table_sigtap <- function(table_zip, file_layout, file_table){
  
  test_dir <- fs::dir_exists("tmp/")
  
  if(test_dir == FALSE) fs::dir_create("tmp/")
  
  check_file_layout <- file_layout %in% unzip(table_zip,exdir="tmp/", list=TRUE)[,1] 
  check_file_table <- file_table %in% unzip(table_zip,exdir="tmp/", list=TRUE)[,1]

  if(check_file_layout == FALSE | check_file_table == FALSE ){
    
    return(NULL)
  
  } else{
    
  layout <- readr::read_delim(
     file = unzip(table_zip,file_layout, exdir="tmp/"),
     locale = readr::locale(encoding = "ISO-8859-1"),
     col_names = TRUE,
     delim = ",")
  
  names <- layout |> pull(1)
  n <- length(names)
  
  size_cols <- layout |> pull(2)
  
  table_vec <- readr::read_delim(unzip(table_zip,file_table, exdir = "tmp/"),
                    locale = readr::locale(encoding = "ISO-8859-1"),
                    col_names = FALSE,
                    delim = "\n") |> pull()
  
  table_df <- tempfile()
  
  cat(file = table_df, table_vec, sep = "\n")
  
  table <- read.fwf(
    file = table_df,
    widths = size_cols,
    colClasses = rep("character",n),
    fill=TRUE
  )
  
  names(table) <- names
  
  tibble::tibble(table)
  
  }
}

link <- "ftp://ftp2.datasus.gov.br/pub/sistemas/tup/downloads/"

arqs <- RCurl::getURLContent(link)

temp_names <- stringr::str_extract_all(arqs,"TabelaUnificada.*zip")[[1]]

links <- paste0(link,temp_names)

data <- NULL

for(i in 1:length(links)){
  
  link <- links[i]
  
  temp <- tempfile()
  
  utils::download.file(link, temp, mode = "wb")
  
  partial <- parse_table_sigtap(temp, "tb_procedimento_layout.txt", "tb_procedimento.txt")
  
  procedimento_descricao <- parse_table_sigtap(temp, "tb_descricao_layout.txt", "tb_descricao.txt") 
  
  if(is.null(procedimento_descricao)){
    procedimento_descricao <- data.frame(CO_PROCEDIMENTO =NA, NO_PROCEDIMENTO = NA)
  } else {
    procedimento_descricao <- procedimento_descricao |>
      filter(nchar(CO_PROCEDIMENTO)==10) |>
      select(-DT_COMPETENCIA)
  } 
  
  procedimento_cid <- parse_table_sigtap(temp, "rl_procedimento_cid_layout.txt","rl_procedimento_cid.txt" ) |>
    group_by(CO_PROCEDIMENTO, ST_PRINCIPAL) |>
    summarize(CO_CID = paste(CO_CID, collapse=", ")) |>
    spread(ST_PRINCIPAL, CO_CID) |>
    rename("CO_CID_SECUNDARIO"=N, "CO_CID_PRINCIPAL"=S) |>
    select(CO_PROCEDIMENTO, CO_CID_PRINCIPAL, CO_CID_SECUNDARIO)
  
  procedimento_cbo <- parse_table_sigtap(temp, "rl_procedimento_ocupacao_layout.txt", "rl_procedimento_ocupacao.txt") |> 
    group_by(CO_PROCEDIMENTO) |>
    summarize(CO_OCUPACAO = paste0(CO_OCUPACAO, collapse=", "))
  
  procedimento_grupo <- parse_table_sigtap(temp, "tb_grupo_layout.txt", "tb_grupo.txt") |> 
    select(-DT_COMPETENCIA)
  
  procedimento_sub_grupo <- parse_table_sigtap(temp, "tb_sub_grupo_layout.txt", "tb_sub_grupo.txt") |>
    select(- DT_COMPETENCIA)
  
  procedimento_forma_organizacao <- parse_table_sigtap(temp, "tb_forma_organizacao_layout.txt", "tb_forma_organizacao.txt") |>
    select(- DT_COMPETENCIA)
  
  dic_registro <- parse_table_sigtap(temp, "tb_registro_layout.txt", "tb_registro.txt")
  
  procedimento_registro <- parse_table_sigtap(temp, "rl_procedimento_registro_layout.txt", "rl_procedimento_registro.txt") |>
    select(- DT_COMPETENCIA) |> 
    left_join(dic_registro) |>
    mutate(NO_REGISTRO = stringr::str_squish(NO_REGISTRO)) |>
    group_by(CO_PROCEDIMENTO) |>
    summarize(NO_REGISTRO = paste0(NO_REGISTRO, collapse = ", "))
  
  dic_tipo_leito <- parse_table_sigtap(temp, "tb_tipo_leito_layout.txt", "tb_tipo_leito.txt") |>
    mutate(NO_TIPO_LEITO = stringr::str_squish(NO_TIPO_LEITO))
  
  procedimento_leito <- parse_table_sigtap(temp, "rl_procedimento_leito_layout.txt", "rl_procedimento_leito.txt") |>
    group_by(CO_PROCEDIMENTO) |>
    left_join(dic_tipo_leito) |>
    summarize(NO_TIPO_LEITO = paste0(NO_TIPO_LEITO, collapse=", "))
  
  partial <- partial |>
    mutate(CO_GRUPO = substring(CO_PROCEDIMENTO,1,2),
           CO_SUB_GRUPO = substring(CO_PROCEDIMENTO,3,4),
           CO_FORMA_ORGANIZACAO = substring(CO_PROCEDIMENTO, 5,6)) |>
    left_join(procedimento_grupo) |>
    left_join(procedimento_sub_grupo) |>
    left_join(procedimento_forma_organizacao) |> 
    left_join(procedimento_descricao) |>
    left_join(procedimento_cid) |>
    left_join(procedimento_cbo) |>
    left_join(procedimento_registro) |>
    left_join(procedimento_leito)
  
  data <- dplyr::bind_rows(data, partial)
  
  unlink(temp)
  
}

tictoc::toc()