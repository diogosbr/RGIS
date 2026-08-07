# Dados originais

Fonte dos arquivos de `inst/extdata/`. Não são versionados: o `.gitignore` cobre
tudo nesta pasta menos este README, porque os originais somam quase 100 MB.

Arquivos esperados aqui:

- `FLO_E_7275_maxent.tif` — saída contínua de Maxent.
- `estados_cer.tif` — códigos de UF em projeção Albers.
- `cerrado_s.gpkg` — polígono do bioma Cerrado.
- `ST_DNIT_Rodovias_SNV2015_03.gpkg` — SNV 2015 do DNIT, rodovias federais.
- `sdmdata.csv` — ocorrências com presença/ausência e componentes principais.

O que foi feito para gerar cada derivado está anotado em
`inst/extdata/README.md`. Se algum original se perder, os derivados continuam no
repositório e nada quebra.
