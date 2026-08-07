# RGIS

Visualizador de camadas geoespaciais em R, feito com Shiny e leaflet.

Carrega ocorrências em CSV, rasters contínuos e camadas vetoriais, reprojeta tudo
para WGS84 e desenha sobre basemaps, com estilo ajustável e ferramentas de medição
e desenho. Feito para quem trabalha com dados de biodiversidade e modelagem de
distribuição de espécies e não quer abrir um SIG de desktop só para olhar um
resultado.

> **Status**: em reconstrução. O plano, o que já está pronto e o que falta estão
> em [ROADMAP.md](ROADMAP.md). A versão publicada em 2021 não roda mais, porque o
> `rgdal` saiu do CRAN.

## Instalação

```r
# install.packages("remotes")
remotes::install_github("diogosbr/RGIS", ref = "dev")
```

O `ref = "dev"` é necessário enquanto o branch padrão do repositório ainda aponta
para a versão de 2021, que não roda.

## Uso

```r
RGIS::run_app()
```

O app abre no navegador. Cada aba trata um tipo de dado:

- **CSV**: tabela de pontos com uma coluna de longitude e uma de latitude, em
  graus decimais.
- **Raster**: GeoTIFF contínuo de uma banda, com CRS definido.
- **Vetor**: shapefile, GeoPackage, GeoJSON ou KML, com CRS definido. Polígonos,
  linhas e pontos.

Para aumentar o limite de upload:

```r
RGIS::run_app(max_upload_mb = 100)
```

## Requisitos

R 4.1 ou superior. As dependências espaciais são `sf` e `terra`, que precisam de
GDAL, GEOS e PROJ instalados no sistema. Em Ubuntu e Debian:

```sh
sudo apt install libgdal-dev libgeos-dev libproj-dev libudunits2-dev
```

## Deploy

O `app.R` na raiz existe para as plataformas de deploy, que procuram esse arquivo.
O `rsconnect` precisa saber de onde vem o próprio RGIS, então instale a partir do
GitHub antes de publicar. Se o pacote estiver instalado do fonte local, o deploy
falha com "Unable to determine the source of package RGIS":

```r
remotes::install_github("diogosbr/RGIS")
rsconnect::deployApp()
```

## Contribuindo

O [ROADMAP.md](ROADMAP.md) traz a lista essencial do v1.0 e a lista de desejos, em
ordem de prioridade. O desenvolvimento acontece no branch `dev`.

## Licença

GPL-3.
