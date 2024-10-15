library(targets)

tar_option_set()

tar_source()

list(
  tar_target(
    name = cnes_estabelecimentos,
    command = get_sus_ftp(
      link_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/ST/",
      regex = "ST..*",
      dir = "cnes_st",
    )
  ),
  tar_target(
    name = cnes_profissionais,
    command = get_sus_ftp(
      link_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/PF/",
      regex = "PF..*",
      dir = "cnes_pf"
    )
  ),
  tar_target(
    name = cnes_estab_ensino,
    command = get_sus_ftp(
      link_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/EE/",
      regex = "EE..*",
      dir = "cnes_ee"
    )
  ),
  tar_target(
    name = cnes_estab_filantropico,
    command = get_sus_ftp(
      link_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/EF/",
      regex = "EF..*",
      dir = "cnes_ef"
    )
  ),
  tar_target(
    name = cnes_equipes,
    command = get_sus_ftp(
      link_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/EP/",
      regex = "EP..*",
      dir = "cnes_ep"
    )
  ),
  tar_target(
    name = cnes_equipamentos,
    command = get_sus_ftp(
      link_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/EQ/",
      regex = "EQ..*",
      dir = "cnes_eq"
    )
  ),
  tar_target(
    name = cnes_gestao_metas,
    command = get_sus_ftp(
      link_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/GM/",
      regex = "GM..*",
      dir = "cnes_gm"
    )
  ),
  tar_target(
    name = cnes_habilitacao,
    command = get_sus_ftp(
      link_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/HB/",
      regex = "HB..*",
      dir = "cnes_hb"
    )
  ),
  tar_target(
    name = cnes_incentivos,
    command = get_sus_ftp(
      link_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/IN",
      regex = "IN..*",
      dir = "cnes_in"
    )
  ),
  tar_target(
    name = cnes_leitos,
    command = get_sus_ftp(
      link_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/LT/",
      regex = "LT..*",
      dir = "cnes_lt"
    )
  ),
  tar_target(
    name = cnes_regra_contratual,
    command = get_sus_ftp(
      link_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/RC/",
      regex = "RC..*",
      dir = "cnes_rc"
    )
  ),
  tar_target(
    name = cnes_servico_especializado,
    command = get_sus_ftp(
      link_ftp = "ftp://ftp.datasus.gov.br/dissemin/publicos/CNES/200508_/Dados/SR/",
      regex = "SR..*",
      dir = "cnes_sr"
    )
  )
)
