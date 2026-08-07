# Dados de exemplo

Esta pasta guarda os arquivos usados pelo botão "carregar exemplo" (item 14 do
roadmap) e pelos testes. Os exemplos antigos foram removidos: eram grandes
demais para versionar, um deles não tinha `.prj` e nenhum estava documentado.

Regras para o que entra aqui:

- **Tudo abaixo de 1 MB.** Arquivo de exemplo grande polui o histórico do git
  para sempre e não ajuda a testar.
- **CRS sempre declarado.** Shapefile precisa do `.prj`.
- **Preferir GeoPackage a shapefile.** Um arquivo em vez de cinco.
- **Licença conhecida e citada** neste README, com a fonte do dado.

## O que ainda falta

| Arquivo | Tipo | Para que serve |
|---|---|---|
| (a definir) | CSV de ocorrências | Testar a aba CSV e os popups |
| (a definir) | GeoTIFF contínuo | Testar a aba Raster, paletas e legenda |
| (a definir) | GeoPackage de polígonos | Testar a aba Vetor e o popup de atributos |
| (a definir) | GeoPackage de linhas | Testar o despacho para `addPolylines` |
| (a definir) | Camada em CRS projetado | Testar a reprojeção para EPSG:4326 |
| (a definir) | GeoTIFF categórico | Fixar o comportamento do item 12 |
