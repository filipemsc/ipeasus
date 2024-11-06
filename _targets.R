library(targets)
library(tarchetypes)

tar_option_set()

tar_source()

cnes_df <- tibble::tribble(
  ~url, ~regex, ~dir,
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
)

sinan_prelim_df <- tibble::tribble(
  ~url, ~regex, ~dir,
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/PRELIM/", "HIVA..*", "sinan_prelim_hiv_a",
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/PRELIM/", "HIVC..*", "sinan_prelim_hiv_c",
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/PRELIM/", "HIVE..*", "sinan_prelim_hiv_e",
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/PRELIM/", "HIVG..*", "sinan_prelim_hiv_g",
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/PRELIM/", "HEPA..*", "sinan_prelim_hepa",
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/PRELIM/", "SIFA..*", "sinan_prelim_sif_a",
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/PRELIM/", "SIFC..*", "sinan_prelim_sif_c",
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/PRELIM/", "SIFG..*", "sinan_prelim_sif_g",
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/PRELIM/", "VIOL..*", "sinan_prelim_viol",
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/PRELIM/", "ZIKA..*", "sinan_prelim_zika",
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/PRELIM/", "DENG..*", "sinan_prelim_deng",
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/PRELIM/", "AIDA..*", "sinan_prelim_aids_a",
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SINAN/DADOS/PRELIM/", "AIDC..*", "sinan_prelim_aids_c",
)

sih_df <- tibble::tribble(
  ~url, ~regex, ~dir,
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/Dados/", "^SP..*", "sih_sp",
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/Dados/", "^RD..*", "sih_rd",
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/Dados/", "^RJ..*", "sih_rj",
  "ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/Dados/", "^ER..*", "sih_er"
)

datasus_df <- rbind(cnes_df, sih_df, sinan_prelim_df)

list(
  tar_map(
    datasus_df,
    names = dir,
    descriptions = NULL,
    targets::tar_target(datasus,
      command = get_sus_ftp(url, regex, dir),
      cue = tar_cue(mode = "always")
    )
  )
)
