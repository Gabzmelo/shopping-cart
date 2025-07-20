
# Desafio técnico e-commerce - Carrinho de Compras

  

Este projeto implementa uma API RESTful para gerenciamento de carrinho de compras, conforme o Desafio Técnico proposto pela RD Station para vagas de Pessoa Desenvolvedora Júnior/Pleno - Engenharia 2025.

  

## Princípios de Design e Escolhas Técnicas

  

A equipe de engenharia da RD Station valoriza um código que seja **fácil de entender, não apenas fácil de escrever**. Seguindo esse princípio, as seguintes escolhas de design foram feitas:

  

*  **Clean Code e Legibilidade**: Priorizei a clareza e a legibilidade do código. Métodos e classes foram nomeados de forma a expressar sua intenção. Lógicas complexas foram segmentadas em métodos menores ou encapsuladas em modelos quando apropriado.

*  **Performance (Complexidade de Algoritmo)**: Operações de busca e atualização em coleções grandes (como itens em um carrinho, embora no escopo do desafio não seja tão grande) foram consideradas para evitar iterações desnecessárias. O uso adequado de índices de banco de dados (`foreign_key: true` em migrações) fundamental para a performance em operações de lookup.

*  **Modelagem de Dados**:

* Criação do modelo `CartItem`: Em vez de armazenar produtos diretamente no `Cart` (e.g., via um array JSON), optei por uma tabela `cart_items` para modelar a relação N:N entre `Cart` e `Product`. Esta é uma abordagem padrão em Rails (`has_many through`) que oferece maior flexibilidade, integridade de dados e capacidade de expansão. Permite adicionar metadados específicos do item no carrinho (como `quantity` e `unit_price`).

* Armazenamento de `unit_price` no `CartItem`: O preço unitário de um produto no carrinho é salvo no `CartItem` no momento da adição/atualização. Isso garante que, se o preço do `Product` mudar no futuro, o valor no carrinho não seja alterado retroativamente, preservando a consistência da transação.

* Campos `abandoned_at` e `last_interaction_at` no `Cart`: Essenciais para o gerenciamento de carrinhos abandonados, permitindo um controle claro do status e tempo de inatividade.

*  **Gerenciamento de Sessão**: O `cart_id` é armazenado na sessão do usuário (`session[:cart_id]`). Esta é uma maneira simples e eficaz de associar um carrinho a uma sessão HTTP sem a necessidade de autenticação de usuário completa, atendendo ao requisito de "se não existir um carrinho para a sessão, criar o carrinho e salvar o ID do carrinho na sessão".

*  **Tratamento de Erros**: Foram adicionados validações e tratamentos de erro no controller e nos modelos (e.g., quantidade negativa, produto não encontrado). As respostas da API retornam status HTTP apropriados (`404 Not Found`, `422 Unprocessable Entity`) e mensagens claras para o consumidor da API.

*  **Background Jobs (Sidekiq)**: O gerenciamento de carrinhos abandonados é feito através de um Sidekiq Job (`MarkCartAsAbandonedJob`). Esta é a abordagem padrão para tarefas de tempo prolongado ou agendadas no Rails, evitando bloquear o thread principal da aplicação web e garantindo escalabilidade. O agendamento é feito via `sidekiq-scheduler`, um recurso robusto para agendar jobs de forma declarativa.

*  **Testes (RSpec e FactoryBot)**:

*  **Cobertura**: Testes foram implementados para os novos endpoints do `CartsController`, bem como para a lógica de negócio dos modelos `Cart` e `CartItem` e o `MarkCartAsAbandonedJob`.

*  **Factories**: Utilização de `FactoryBot` para criar objetos de teste de forma flexível e legível, reduzindo a duplicação e facilitando a manutenção dos testes.

*  **Dockerização**: Um arquivo `docker-compose.yml` foi criado para orquestrar os serviços da aplicação (Rails, PostgreSQL, Redis e Sidekiq). Isso facilita o setup do ambiente de desenvolvimento/produção, garantindo consistência e isolamento.

  

## Dependências

  

*  **Ruby**: 3.3.1

*  **Rails**: 7.1.3.2

*  **PostgreSQL**: 16

*  **Redis**: 7.0.15

*  **Sidekiq**: ~> 7.2.4

*  **Sidekiq-Scheduler**: ~> 5.0.3

  

As dependências são gerenciadas pelo `Bundler`.

  

## Como Executar o Projeto

  

### Pré-requisitos

  

Certifique-se de ter o `Docker` e o `Docker Compose` instalados em sua máquina.

  

### Executando com Docker Compose (Recomendado)

  

1.  **Construir as imagens Docker**:

```bash

docker-compose build

```

2.  **Configurar o Banco de Dados**:

Este comando cria o banco de dados, executa as migrações e popula com os dados iniciais (`db/seeds.rb`).

```bash

docker-compose run web bundle exec rails db:create db:migrate db:seed

```

(Você pode omitir `db:seed` se não quiser dados iniciais).

3.  **Iniciar os serviços**:

```bash

docker-compose up

```

Isso iniciará o servidor Rails (`web`), o banco de dados (`db`), o Redis (`redis`) e o Sidekiq (`sidekiq`).

  

A API estará disponível em `http://localhost:3000`. O painel do Sidekiq estará em `http://localhost:3000/sidekiq`.

  

### Executando sem Docker (Ambiente local)

  

Dado que todas as ferramentas (Ruby, Rails, PostgreSQL, Redis) estão instaladas e configuradas em seu ambiente:

  

1.  **Instalar dependências Ruby**:

```bash

bundle install

```

2.  **Configurar o Banco de Dados**:

```bash

rails db:create db:migrate db:seed

```

3.  **Executar o Sidekiq**:

```bash

bundle exec sidekiq

```

4.  **Executar o Projeto (Servidor Rails)**:

```bash

bundle exec rails server

```

A API estará disponível em `http://localhost:3000`.

  

## Endpoints da API

  

Todos os payloads de resposta seguiram o formato do desafio.

  

### 1. Registrar um produto no carrinho (`POST /cart`)

  

*  **Descrição**: Adiciona um produto ao carrinho ou, se já existir, **define** a quantidade do produto no carrinho para o valor fornecido.

*  **Rota**: `POST /cart`

*  **Payload de Requisição**:

```json

{

	"product_id": 345,
	"quantity": 2

}

```

*  **Respostas**:

*  `200 OK`: Produto adicionado/quantidade atualizada com sucesso. Retorna o carrinho atualizado.

*  `404 Not Found`: `{"error": "Produto não existe"}` se o `product_id` não existir.

*  `422 Unprocessable Entity`: `{"error": "Quantity must be greater than zero"}` se a quantidade for inválida.

  

### 2. Listar itens do carrinho atual (`GET /cart`)

  

*  **Descrição**: Lista todos os produtos no carrinho atual do usuário.

*  **Rota**: `GET /cart`

*  **Respostas**:

*  `200 OK`: Retorna o carrinho atualizado, incluindo a lista de produtos e o total.

  

### 3. Alterar (Incrementar) a quantidade de produtos no carrinho (`POST /cart/add_item`)

  

*  **Descrição**: **Incrementa** a quantidade de um produto existente no carrinho pelo valor fornecido. Se o produto não estiver no carrinho, ele é adicionado com a quantidade especificada.

*  **Rota**: `POST /cart/add_item`

*  **Payload de Requisição**:

```json

{

	"product_id": 1230,
	"quantity": 1

}

```

*  **Respostas**:

*  `200 OK`: Quantidade do produto incrementada/adicionada com sucesso. Retorna o carrinho atualizado.

*  `404 Not Found`: `{"error": "Product not found"}` se o `product_id` não existir.

*  `422 Unprocessable Entity`: `{"error": "Quantity to add must be greater than zero"}` se a quantidade a ser adicionada for inválida.

  

### 4. Remover um produto do carrinho (`DELETE /cart/:product_id`)

  

*  **Descrição**: Remove um produto específico do carrinho.

*  **Rota**: `DELETE /cart/:product_id` (onde `:product_id` é o ID do produto a ser removido)

*  **Respostas**:

*  `200 OK`: Produto removido com sucesso. Retorna o carrinho atualizado.

*  `404 Not Found`: `{"error": "Product not found in cart"}` se o produto não estiver no carrinho.

  

## Testes

  

Para executar os testes:

  

```bash
bundle  exec  rspec
```

Se  estiver  usando  Docker:

````Bash
docker-compose  run  test  bundle  exec  rspec
````

Os  testes  abrangem:

spec/models/product_spec.rb:  Validações  básicas  do  modelo  Product.

spec/models/cart_spec.rb:  Validações,  lógica  de  mark_as_abandoned,  remove_old_abandoned_carts  e  calculate_total_price  do  modelo  Cart.

spec/requests/products_spec.rb:  Testes  para  os  endpoints  CRUD  de  produtos.

spec/requests/carts_spec.rb:  Testes  completos  para  os  endpoints  POST  /cart,  GET  /cart,  POST  /cart/add_item  e  DELETE  /cart/:product_id,  incluindo  cenários  de  sucesso,  falha  e  validação  de  payloads.

spec/sidekiq/mark_cart_as_abandoned_job_spec.rb:  Testa  a  execução  e  o  comportamento  do  job  de  carrinhos  abandonados.