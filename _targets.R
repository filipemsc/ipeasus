library(targets)

tar_option_set()

tar_source()

# Replace the target list below with your own:
list(
  tar_target(
    name = cnes_estabelecimentos,
    command = get_sus_ftp(
      link_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/ST/",
      regex = "ST..*",
      dir = "cnes_st",
      path = "data"
    )
  )
)
