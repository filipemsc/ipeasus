library(targets)
library(tarchetypes)

tar_option_set()

tar_source()

gen_cnes <- function(){
  tibble::tribble(
    ~ url                                                              , ~ regex, ~ dir,
    "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/ST/", "ST..*", "cnes_st",
    "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/PF/", "PF..*", "cnes_pf",
    "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/EE/", "EE..*", "cnes_ee",
    "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/EF/", "EF..*", "cnes_ef",
    "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/EP/", "EP..*", "cnes_ep",
    "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/EQ/", "EQ..*", "cnes_eq",
    "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/GM/", "GM..*", "cnes_gm",
    "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/HB/", "HB..*", "cnes_hb",
    "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/IN/", "IN..*", "cnes_in",
    "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/LT/", "LT..*", "cnes_lt",
    "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/RC/", "RC..*", "cnes_rc",
    "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/SR/", "SR..*", "cnes_sr"
  ) |>
 dplyr::mutate(desc = substring(dir, 6,7),
               empty = "")
}

cnes_df <- gen_cnes() 

list(
 tar_map(
    cnes_df,
    names = desc,
    descriptions = NULL,
    targets::tar_target(cnes, 
                        command = get_sus_ftp(url, regex, dir), 
                        cue = tar_cue(mode="always"))
  )
)
