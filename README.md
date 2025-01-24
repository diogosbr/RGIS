# RGIS

RGIS é uma interface de Sistema de Informação Geográfica (SIG) desenvolvida em R, utilizando o Shiny para criar aplicações web interativas. Esta aplicação permite aos usuários visualizar e interagir com dados geoespaciais de forma intuitiva.

## Funcionalidades

- Visualização de dados geoespaciais.
- Interatividade com mapas e camadas de dados.
- Carregamento e manipulação de diferentes formatos de dados geográficos.

## Estrutura do Projeto

- **global.R**: Configurações globais e carregamento de pacotes.
- **server.R**: Lógica do servidor para processamento de dados e respostas às interações do usuário.
- **ui.R**: Definição da interface do usuário, incluindo layouts e elementos interativos.
- **Exemplos**: Exemplos de dados e scripts para demonstração das funcionalidades.

## Requisitos

- R instalado (versão 4.0 ou superior recomendada).
- Pacote Shiny instalado.

## Instalação

1. Clone este repositório:

   ```bash
   git clone https://github.com/diogosbr/RGIS.git
   ```

2. Navegue até o diretório do projeto:

   ```bash
   cd RGIS
   ```

3. Instale os pacotes necessários no R:

   ```R
   install.packages("shiny")
   # Instale outros pacotes conforme necessário
   ```

## Uso

1. Abra uma sessão R no diretório do projeto.
2. Execute a aplicação Shiny:

   ```R
   library(shiny)
   runApp()
   ```

3. A aplicação será aberta em seu navegador padrão, permitindo a interação com os dados geoespaciais.

## Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou enviar pull requests para melhorias e correções.

## Licença

Este projeto está licenciado sob a [MIT License](LICENSE).
