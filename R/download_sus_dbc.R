download_sus_dbc <- function(link_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/Dados/", 
                             regex = "^SP..*",
                             dir = "sih_sp",
                             path = "data"){ 

    dbc_dir <- glue::glue("{path}/{dir}/dbc")
    fs::dir_create(dbc_dir)
    
    log_dir <- glue::glue("{path}/{dir}/logs")
    fs::dir_create(log_dir)
    
    parquet_dir <- glue::glue("{path}/{dir}/parquet")
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
      
      ftp_files$size <- fs::as_fs_bytes(ftp_files$size)
      
      ftp_files$updated_ftp <- paste(ftp_files$date, ftp_files$hour) |> lubridate::parse_date_time("Ymd I:Mp") 
      
      path_files <- merge(path_files, ftp_files, by ="name",suffixes = c("dir","ftp"))
        
      path_files$need_update <- (path_files$updated_ftp >= path_files$birth_time | path_files$sizedir != path_files$sizeftp)
      
      need_update <- path_files[path_files$need_update == TRUE,]$name
      
      files_queue <- c(files_queue, need_update)
      
    }
    
    if(length(files_queue)!=0){
      
      links_files_queue <- glue::glue("{link_ftp}{files_queue}.dbc")
      destfiles_queue <- glue::glue("{dbc_dir}/{files_queue}.dbc")
      
      download <- curl::multi_download(urls = links_files_queue, destfiles = destfiles_queue)
      
      log_name <- glue::glue("{path}/{dir}/logs/", janitor::make_clean_names(Sys.time()),"_download.csv")
      
      data.table::fwrite(download, log_name)
      
      failed_downloads <- download |> dplyr::filter(isFALSE(success)|is.na(success))
      
      if(nrow(failed_downloads)>0){
        
        failed_queue <- failed_downloads$url
        failed_desfiles <- failed_downloads$destfile
        
        download2 <- curl::multi_download(failed_queue, failed_desfiles)
        
        log_name2 <- glue::glue("{path}/{dir}/logs/", janitor::make_clean_names(Sys.time()),"_retry.csv")
       
        data.table::fwrite(download2, log_name2)
        
        to_delete <- download2 |> dplyr::filter(isFALSE(success)|is.na(success))
        
        if(nrow(to_delete)>0){
          
          log_name3 <- glue::glue("{path}/{dir}/logs/", janitor::make_clean_names(Sys.time()),"_rm_dbc.csv")
          
          data.table::fwrite(to_delete, log_name3)
          
          fs::file_delete(to_delete$destfile)
          
        }
        
        return(list("Tentativa 1" = download, "Tentativa 2" = download2, "Arquivos com erro" = to_delete$destfile))
      } 
      
      if(nrow(failed_downloads) == 0){ return(list("Tentativa 1" = download, "Arquivos com erro" = NULL)) }
      
      } else { return(NULL) }

}