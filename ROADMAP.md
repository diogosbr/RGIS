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
5. **Rasters grandes não abrem.** `addRasterImage` tem `maxBytes` de 4 MB por padrão e lança erro
   acima disso, então os exemplos de 24 MB derrubavam a sessão com a tela vermelha do Shiny.
   O limite é aplicado ao raster já reprojetado para Web Mercator, que pode ser maior que o
   original, portanto elevar o teto é paliativo: a solução é agregar antes de exibir.

Bugs menores: ID `shape_path` duplicado no `ui.R`; `popup = ~shape[[input$label]]` usa índice
numérico cru; `topo.colors` chama `rev((25))` em vez de `rev(topo.colors(25))`;
`install.packages()` no `global.R`; CRS assumido como WGS84 sem verificação; erros genéricos
("Something went wrong"); PT e EN misturados.

## Lista essencial (v1.0)

A ordem importa: a fase 1 destrava todo o resto.

### Fase 1, fundação

- [x] **1. Migrar para `sf` + `terra`**, removendo `rgdal`, `raster` e `sp`.
- [x] **2. Reestruturar como pacote R**: `R/`, `DESCRIPTION`, `NAMESPACE`, função `run_app()` e
      `app.R` na raiz para as plataformas de deploy.
- [x] **3. Núcleo de camadas**: um `reactiveVal` com lista de camadas (id, nome, tipo, dado,
      estilo, visível, ordem) e `leafletProxy` para adicionar/remover sem redesenhar o mapa.
      Elimina a aba ADD inteira e resolve o problema 2.
- [x] **4. Separar por responsabilidade** para não virar um `server.R` de mil linhas:
      `camadas.R` (a pilha), `upload.R` (ingestão), `ler.R` (leitura), `estilo.R`, `mapa.R`
      (desenho e sincronização), `app_ui.R` e `app_server.R`. Não são módulos Shiny com
      namespace: uma tela só, sem componente repetido, não justifica o custo.
- [x] **5a.** `install.packages()` automático removido: as dependências agora vivem no
      `DESCRIPTION`, com versão mínima.
- [ ] **5b. `renv`** para travar as versões exatas usadas em desenvolvimento e no deploy.

### Fase 2, ingestão que não quebra

- [x] **6. Ponto de entrada único de arquivo**, com detecção de tipo por extensão: csv, tif/asc,
      shp (multi-arquivo ou `.zip`), gpkg, geojson. Copiar para tempdir preservando os nomes
      originais. Elimina o `file.choose()`.
- [x] **7a.** Reprojeção automática para EPSG:4326 e aviso na tela quando a camada não declara
      CRS, caso em que WGS84 é assumido.
- [ ] **7b.** Deixar o usuário informar o EPSG de uma camada sem CRS, em vez de só assumir.
- [x] **8. Autodetecção das colunas de coordenada** no CSV (lon, long, longitude, x,
      decimalLongitude e equivalentes de latitude), com override manual.

### Fase 3, painel de camadas

- [x] **9. Lista de camadas** com mostrar/ocultar, reordenar, renomear, zoom na camada e remover.
- [x] **10. Estilo por camada** e não global: raster (paleta, opacidade, faixa de valores);
      vetor (contorno, preenchimento, espessura, opacidade); pontos (cor, tamanho, coluna de
      popup via `selectInput` populado por `names()`, no lugar do índice numérico).
- [x] **11. Legenda por camada**, que aparece e desaparece junto com ela.
- [x] **12a.** Raster grande é agregado na leitura, e não a cada desenho, com `maxBytes` como
      rede de segurança.
- [ ] **12b.** Tratar raster categórico com legenda de classes. Hoje ele é recusado com mensagem.

### Fase 4, acabamento para iniciante

- [x] **13. Validação com mensagem específica**, do tipo "a coluna 'lon' não existe; encontradas:
      sp, longitude, latitude", no lugar de "Something went wrong".
- [x] **14. Dados de exemplo** em `inst/extdata` com botão "carregar exemplo". 1 MB cobrindo
      ponto, raster contínuo, raster projetado, polígono e linha, documentados em
      `inst/extdata/README.md`. Falta só um raster categórico de verdade, para o item 12b.
- [x] **15. Aba Ajuda de verdade**: formatos aceitos, exigências de CRS, limites de tamanho e um
      passo a passo.
- [x] **16. Indicador de progresso** ao carregar arquivo grande, para não parecer travamento.
- [x] **17. Interface toda em PT-BR.**
- [ ] **18. Exportar o mapa em PNG** (`webshot2` / `mapshot`). Sem isso o app não entrega nada
      para fora.
- [ ] **19. README com screenshot**, testes `testthat` das funções não reativas (leitura,
      reprojeção, estilo) e deploy verificado nos dois modos.
- [x] **20. Limpeza**: remover a aba FUN, corrigir o ID `shape_path` duplicado e o bug do
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

- `dev` é o branch de desenvolvimento e já contém tudo que importa de `layout`, além da migração
  para sf/terra e da reestruturação em pacote. Os branches `master` e `layout` divergiram em 2021
  e ficaram obsoletos: o único commit exclusivo do `master` (`5ce8511`) apenas adiciona
  `.gitignore` e `RGIS.Rproj`. Consolidar `dev` em um branch principal único (`main`) antes do
  v1.0 e aposentar os outros dois.
- A pasta `Exemplos/` foi removida por inteiro. Os arquivos grandes seguem no histórico do git
  (custo de ~10 MB no clone) e só sairiam de vez com reescrita de histórico, o que não vale a
  pena. Os novos exemplos vão para `inst/extdata/`, sob as regras descritas lá.
- `R CMD check` passa com 0 erros, 0 avisos e 0 notas. O `man/` é gerado por
  `devtools::document()` e está versionado.
- Os dados originais dos exemplos vivem em `data-raw/`, fora do versionamento. Se você clonar o
  repositório em outra máquina, os derivados de `inst/extdata/` vêm junto e nada quebra; só a
  regeneração a partir do original é que exige copiar os arquivos grandes de novo.
