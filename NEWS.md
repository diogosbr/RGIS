# RGIS 0.3.0

Reestruturação em pacote R.

- O projeto deixa de ser um conjunto de scripts (`global.R`, `ui.R`, `server.R`) e
  passa a ser um pacote instalável, com ponto de entrada `run_app()`. O mesmo
  código serve para uso local e para deploy, e as dependências passam a ser
  declaradas no `DESCRIPTION` em vez de instaladas na marra pelo `global.R`.
- UI e servidor divididos em funções por responsabilidade, em `R/`.
- Abas "ADD" e "FUN" removidas. A primeira combinava camadas manualmente, com um
  botão por par de camadas, e perde sentido com a pilha de camadas do próximo
  passo; seus botões nunca tiveram observer. A segunda nunca saiu de "em
  construção".
- Aba "Ajuda" ganhou conteúdo: formatos aceitos, exigência de CRS e limites.
- Vetores de linha e de ponto passam a ser desenhados, em vez de forçados por
  `addPolygons`.
- `box(width = "100%")` corrigido para `width = 12`: o valor anterior gerava uma
  classe CSS inválida.
- Exemplos antigos removidos do repositório. O que deve entrar em
  `inst/extdata/` está documentado lá.

# RGIS 0.2.0

Migração do backend espacial.

- `rgdal` e `raster` substituídos por `sf` e `terra`. O `rgdal` saiu do CRAN em
  outubro de 2023, então a versão anterior não rodava mais.
- Faixa de valores do raster calculada com `terra::minmax(compute = TRUE)`, sem
  carregar todas as células na memória.
- Reprojeção automática para EPSG:4326, e suposição explícita de WGS84, com aviso
  na tela, quando a camada não declara CRS.
- Mensagens de erro específicas no lugar de "Something went wrong", listando as
  colunas encontradas quando as de coordenada não existem.
- Erro do leaflet (`maxBytes` estourado, falha de reprojeção) capturado, em vez de
  derrubar a sessão com a tela vermelha do Shiny.
- Coordenadas extraídas por índice em vez de renomeadas: se o CSV já tivesse uma
  coluna `lon`, a renomeação criava nomes duplicados e o app lia a coluna errada
  em silêncio.
- Corrigido `topo.colors`, que chamava `rev((25))`.
