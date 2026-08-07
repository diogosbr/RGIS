# Roadmap do RGIS

## Decisões de escopo

Definidas em agosto de 2026, ao retomar o projeto após a pausa de 2021.

| Dimensão | Decisão |
|---|---|
| Produto | Visualizador de camadas geoespaciais. Carregar N camadas, ver juntas, estilizar, inspecionar, exportar. Sem geoprocessamento no v1.0. |
| Distribuição | Pacote R com `run_app()` e também publicável na web (shinyapps.io). O mesmo código nos dois modos. |
| Público | Alunos e iniciantes em R/GIS. Exige mensagens de erro claras, dados de exemplo e ajuda de verdade. |
| Estratégia | Refatorar a base. A arquitetura reativa atual não tem remendo possível. |
| Idioma | Interface em PT-BR no v1.0. Bilíngue fica como desejo. |

A ambição original de "clone do QGIS em R" foi deliberadamente abandonada: é escopo infinito
e foi o que travou o projeto em 2021. O alvo é um visualizador de camadas redondo e acabado.

## Diagnóstico do estado herdado (tag `v0.2.0`)

Cinco problemas travam o produto:

1. **O app não roda.** `rgdal` foi retirado do CRAN em outubro de 2023 e `readOGR` não existe
   mais. `raster` é legado.
2. **Camadas não coexistem.** Cada botão reconstrói `m_base` do zero e chama `renderLeaflet`
   de novo, então plotar um raster apaga os pontos. A aba ADD, com um botão por combinação de
   camadas (`plot_csv_raster`, `plot_csv_shape`, `plot_shape_raster`, `plot_all`), é o sintoma:
   3 camadas exigiriam 7 botões, 4 exigiriam 15. Este é o defeito central.
3. **Não existe o conceito de camada.** É 1 CSV + 1 raster + 1 shape presos a `input$file1/2/3`,
   sem nome, visibilidade, ordem ou remoção.
4. **Carregamento quebrado por design.** `file.choose()` no server abre o diálogo na máquina do
   servidor: funciona local, quebra na web. A saída foi essa porque `fileInput` não lida com
   shapefile multi-arquivo.
5. **Rasters grandes falham em silêncio.** `addRasterImage` tem `maxBytes` de 4 MB por padrão;
   os exemplos de 24 MB simplesmente não aparecem.

Bugs menores: ID `shape_path` duplicado no `ui.R`; `popup = ~shape[[input$label]]` usa índice
numérico cru; `topo.colors` chama `rev((25))` em vez de `rev(topo.colors(25))`;
`install.packages()` no `global.R`; CRS assumido como WGS84 sem verificação; erros genéricos
("Something went wrong"); PT e EN misturados.

## Lista essencial (v1.0)

A ordem importa: a fase 1 destrava todo o resto.

### Fase 1, fundação

- [ ] **1. Migrar para `sf` + `terra`**, removendo `rgdal`, `raster` e `sp`. Sem isso o app não roda.
- [ ] **2. Reestruturar como pacote R**: `R/`, `DESCRIPTION`, `inst/app/`, função `run_app()`.
      Habilita uso local e deploy web com o mesmo código.
- [ ] **3. Núcleo de camadas**: um `reactiveVal` com lista de camadas (id, nome, tipo, dado,
      estilo, visível, ordem) e `leafletProxy` para adicionar/remover sem redesenhar o mapa.
      Elimina a aba ADD inteira e resolve o problema 2.
- [ ] **4. Modularizar em módulos Shiny** (`mod_upload`, `mod_layers`, `mod_style`, `mod_map`)
      para não virar um `server.R` de mil linhas.
- [ ] **5. `renv`** para travar versões, e remover o `install.packages()` do `global.R`.

### Fase 2, ingestão que não quebra

- [ ] **6. Ponto de entrada único de arquivo**, com detecção de tipo por extensão: csv, tif/asc,
      shp (multi-arquivo ou `.zip`), gpkg, geojson. Copiar para tempdir preservando os nomes
      originais. Elimina o `file.choose()`.
- [ ] **7. Detecção e reprojeção de CRS**: avisar quando ausente, permitir escolher o EPSG,
      reprojetar tudo para EPSG:4326 na exibição.
- [ ] **8. Autodetecção das colunas de coordenada** no CSV (lon, long, longitude, x,
      decimalLongitude e equivalentes de latitude), com override manual.

### Fase 3, painel de camadas

- [ ] **9. Lista de camadas** com mostrar/ocultar, reordenar, renomear, zoom na camada e remover.
- [ ] **10. Estilo por camada** e não global: raster (paleta, opacidade, faixa de valores);
      vetor (contorno, preenchimento, espessura, opacidade); pontos (cor, tamanho, coluna de
      popup via `selectInput` populado por `names()`, no lugar do índice numérico).
- [ ] **11. Legenda por camada**, que aparece e desaparece junto com ela.
- [ ] **12. Raster grande**: agregação automática antes de exibir e `maxBytes` ajustado.
      Tratar categórico e contínuo de formas diferentes.

### Fase 4, acabamento para iniciante

- [ ] **13. Validação com mensagem específica**, do tipo "a coluna 'lon' não existe; encontradas:
      sp, longitude, latitude", no lugar de "Something went wrong".
- [ ] **14. Dados de exemplo** em `inst/extdata` com botão "carregar exemplo".
- [ ] **15. Aba Ajuda de verdade**: formatos aceitos, exigências de CRS, limites de tamanho e um
      passo a passo.
- [ ] **16. Indicador de progresso** ao carregar arquivo grande, para não parecer travamento.
- [ ] **17. Interface toda em PT-BR.**
- [ ] **18. Exportar o mapa em PNG** (`webshot2` / `mapshot`). Sem isso o app não entrega nada
      para fora.
- [ ] **19. README com screenshot**, testes `testthat` das funções não reativas (leitura,
      reprojeção, estilo) e deploy verificado nos dois modos.
- [ ] **20. Limpeza**: remover a aba FUN, corrigir o ID `shape_path` duplicado e o bug do
      `topo.colors`.

## Lista de desejos (v1.x+)

Em ordem de valor por esforço.

- [ ] **Identify por clique**: clicar no mapa e ver o valor do raster e os atributos do polígono
      naquele ponto. O mais próximo de essencial desta lista.
- [ ] **Tabela de atributos** navegável com seleção sincronizada com o mapa. A intenção já estava
      no código: `DT` e `crosstalk` são importados sem uso.
- [ ] **Extract de raster nos pontos** com download em CSV. Ponte natural para o trabalho de SDM.
- [ ] **Estilo graduado / categorizado por coluna** (choropleth com quebras por quantil ou
      natural breaks).
- [ ] **Filtro de feições por atributo.**
- [ ] **Salvar e carregar projeto** (JSON com camadas e estilos), para retomar o trabalho.
- [ ] **Recorte por polígono desenhado** e download do resultado. O draw toolbar já está no mapa.
- [ ] Exportar camada em outro formato (gpkg, geojson).
- [ ] Basemap WMS / XYZ customizado.
- [ ] Histograma e estatísticas da camada.
- [ ] Composição RGB multi-banda.
- [ ] Interface bilíngue PT/EN.
- [ ] Docker para deploy reprodutível.
- [ ] `bookmarking` de URL do Shiny.
- [ ] Submissão ao CRAN.

## Dívida de repositório

- Os branches `master` e `layout` divergiram. `layout` é a ponta real do trabalho (9 commits à
  frente); o único commit exclusivo do `master` (`5ce8511`, "creating project") apenas adiciona
  `.gitignore` e `RGIS.Rproj`, que o `layout` já tem. Vale consolidar em um branch principal
  único antes do v1.0.
- Rasters grandes (`.tif` de 24 MB e 4,9 MB) ficaram fora do versionamento via `.gitignore`.
  Os exemplos que ficarem no repo devem ser pequenos e ir para `inst/extdata`.
