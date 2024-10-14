download_sus_dbc <- function(link_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/Dados/", 
                             regex = "^SP..*",
                             dir = "sih_sp"){ 

main_dir <- glue::glue("data/{dir}")
fs::dir_create(main_dir)

dbc_dir <- glue::glue("data/{dir}/dbc")
fs::dir_create(dbc_dir)

parquet_dir <- glue::glue("data/{dir}/parquet")
fs::dir_create(parquet_dir)

ftp_files <- RCurl::getURLContent(link_ftp) |>
  strsplit("\r*\n") |>
  unlist()

ftp_files <- gsub(" ", "\n", ftp_files) |>
  data.frame() |>
  tidyr::separate(col=1,
                  into=c("date","hour","size", "name"),
                  sep="\\\n{1,}") |>
  tidyr::separate(col=name, 
                  into=c("name","format"),
                  sep="\\.")

ftp_files <- ftp_files[grep(regex, ftp_files$name),]

ftp_files$size <- as.numeric(ftp_files$size)
ftp_files$date <- as.Date(ftp_files$date,format = "%m-%d-%y")

ftp_files_names <- grep(regex, ftp_files$name, value=TRUE)

path_files_names <- fs::path_ext_remove(fs::path_file(fs::dir_ls(dbc_dir)))

# Check new files
files_queue <- ftp_files_names[!ftp_files_names %in% path_files_names]

# Check if file needs update

path_files <- fs::dir_info(dbc_dir)

if(length(path_files)!=0){
  
  path_files$name <- path_files$path |> 
    fs::path_file() |>
    fs::path_ext_remove()
  
  ftp_files$updated_ftp <- paste(ftp_files$date, ftp_files$hour) |> as.POSIXct(tz = "America/Sao_Paulo")
  
  path_files <- merge(path_files, ftp_files, by ="name")
  
  path_files$need_update <- path_files$updated_ftp >= path_files$change_time
  
  need_update <- path_files[path_files$need_update == TRUE,]$name
  
  files_queue <- c(files_queue, need_update)
  
}

if(length(files_queue)!=0){
  
  links_files_queue <- glue::glue("{link_ftp}{files_queue}.dbc")
  destfiles_queue <- glue::glue("{dbc_dir}/{files_queue}.dbc")
  
  download <- curl::multi_download(urls = links_files_queue, destfiles = destfiles_queue)
  
  return(download)
  
  } else { return(NULL) }

}

download_sus_dbc()
