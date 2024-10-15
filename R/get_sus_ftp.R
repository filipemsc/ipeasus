get_sus_ftp <- function(link_ftp,
                        regex,
                        dir,
                        path){
  
  download_sus_dbc(
    link_ftp = link_ftp, 
    regex = regex,
    dir = dir,
    path = path)
  
  transform_sus_parquet(
    dir = dir,
    path = path
  )
  
}

