# Dados de exemplo

Arquivos usados pelo botão "carregar exemplo" (item 14 do roadmap) e pelos testes.
Total: cerca de 1 MB.

| Arquivo | Tipo | CRS | O que exercita |
|---|---|---|---|
| `ocorrencias.csv` | 2.033 pontos, colunas `lon`/`lat`/`pa`/`PC1..PC5` | graus decimais | Aba CSV, popups, detecção de coluna |
| `adequabilidade.tif` | raster contínuo, 461 × 537, float32, valores 0 a 1 | EPSG:4326 | Aba Raster, paletas, legenda, opacidade |
| `estados_albers.tif` | raster de códigos de UF, 525 × 626, int16, 13 classes | Albers Cônica (metros) | Reprojeção de raster para Web Mercator |
| `cerrado.gpkg` | 1 polígono do bioma Cerrado | ESRI:102033 (metros) | Aba Vetor com polígono e reprojeção |
| `rodovias_go_df.gpkg` | 477 linhas, rodovias federais de GO e DF | EPSG:4674 (SIRGAS 2000) | Despacho para `addPolylines`, popup de atributos |

## Origem e processamento

Os originais estão em `data-raw/`, fora do versionamento por serem grandes (o de
rodovias sozinho tem 93 MB). O que foi feito para chegar aos arquivos acima:

- `adequabilidade.tif` vem de `FLO_E_7275_maxent.tif`, apenas recomprimido em
  DEFLATE. Resolução e valores intactos.
- `estados_albers.tif` vem de `estados_cer.tif`, agregado por um fator de 4
  (vizinho mais próximo) e convertido de float32 para int16, já que os valores são
  códigos de UF. De 1,35 MB para 12 KB.
- `cerrado.gpkg` vem de `cerrado_s.gpkg`, com a geometria simplificada a uma
  tolerância de 1 km, preservando a topologia.
- `rodovias_go_df.gpkg` vem de `ST_DNIT_Rodovias_SNV2015_03.gpkg` (SNV 2015 do
  DNIT), recortado para Goiás e o Distrito Federal, simplificado a cerca de 200 m
  e reduzido a quatro colunas. De 6.492 feições e 93 MB para 477 feições e 212 KB.
- `ocorrencias.csv` é cópia direta de `sdmdata.csv`.

## Regras para novos exemplos

- **Abaixo de 1 MB.** Arquivo grande fica no histórico do git para sempre, e o
  `R CMD check` reclama de pacote instalado acima de 5 MB.
- **CRS sempre declarado.** Shapefile precisa do `.prj`; prefira GeoPackage, que
  é um arquivo só e sempre carrega o CRS.
- **Original em `data-raw/`**, derivado pequeno aqui, com a transformação anotada
  acima.

## Ainda falta

Um raster **categórico de verdade**, com níveis declarados. O `estados_albers.tif`
tem valores discretos, mas é um raster numérico comum: `terra::is.factor()` devolve
`FALSE`, então ele passa pelo caminho contínuo e ganha uma rampa de cor no lugar de
uma legenda de classes. Para gerar a versão categórica:

```r
r <- terra::rast("inst/extdata/estados_albers.tif")
levels(r) <- data.frame(id = terra::unique(r)[[1]], uf = c("..."))
terra::writeRaster(r, "inst/extdata/estados_categorico.tif", datatype = "INT2S")
```
