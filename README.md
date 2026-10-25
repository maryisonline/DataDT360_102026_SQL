# 📊 Diagnóstico Comercial com SQL

> Atividade de meio de curso — **SQL para Análise de Dados** (DataDT360 - Mentor: Daniel Teofilo - Mentorada: Mary Castro)

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Analytics-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/status-concluído-success?style=for-the-badge)

---

## 📌 Sobre o projeto

Neste projeto atuo como analista de dados e produzo um **diagnóstico comercial** a partir de um banco relacional corporativo (PostgreSQL), com dados de vendas, clientes, produtos, localização e RH.

O objetivo é responder a 10 perguntas de negócio usando SQL e transformar os resultados em uma leitura clara para a diretoria.

## 🛠️ Conceitos praticados

- `JOIN` entre múltiplos schemas (`vendas`, `geral`)
- Agregações (`SUM`, `AVG`, `COUNT`) e `GROUP BY`
- `CASE` para categorização
- **CTEs** encadeadas
- **Window Functions**: `ROW_NUMBER`, `RANK`, `NTILE`, `LAG`, `SUM() OVER`
- Subqueries e comparação com médias por grupo
- Séries temporais com acumulado e variação mensal

## 🗂️ Modelo de dados

O banco possui três schemas principais:

| Schema   | Tabelas principais                                              | Uso na análise                              |
|----------|-----------------------------------------------------------------|---------------------------------------------|
| `vendas` | `nota_fiscal`, `item_nota_fiscal`, `produto`, `categoria`, `forma_pagamento` | Receita, quantidade, ticket médio, margem |
| `geral`  | `pessoa`, `pessoa_fisica`, `pessoa_juridica`, `endereco`, `bairro`, `cidade`, `estado` | Clientes, vendedores e análise geográfica |
| `rh`     | `funcionario`, `lotacao`, `departamento`, `cargo`, `escolaridade` | Perfil interno                              |

<!-- Adicione a imagem do diagrama em docs/modelo_relacional.png e descomente a linha abaixo -->
<!-- ![Modelo relacional](docs/modelo_relacional.png) -->

## ❓ Perguntas respondidas

| #  | Pergunta                                                              | Técnicas principais                |
|----|-----------------------------------------------------------------------|------------------------------------|
| 01 | Listagem de notas fiscais com data, valor, pagamento, cliente e vendedor | `JOIN`                          |
| 02 | Faturamento, quantidade e ticket médio por categoria                  | CTE, `SUM`,                        |
| 03 | Top 10 produtos por faturamento com ranking                           | `ROW_NUMBER`, `AVG`                |
| 04 | Margem bruta por produto                                              | Cálculo (venda − custo)            |
| 05 | Faturamento por estado e cidade do cliente                            | CTEs encadeadas, `GROUP BY`        |
| 06 | Categorização de clientes (Alto, Médio e Baixo Valor)                 | `CASE`                             |
| 07 | Participação percentual de cada categoria no faturamento              | `SUM() OVER ()`                    |
| 08 | Série temporal mensal com acumulado e variação                        | `DATE_TRUNC`, `LAG`                |
| 09 | Produtos acima da média da própria categoria                          | CTE, `AVG` por grupo               |
| 10 | Ranking de vendedores por faturamento e quantidade de NFs             | `RANK`                             |

```

## ▶️ Como executar

1. Tenha acesso a um PostgreSQL com o banco da atividade carregado.
2. Conecte usando a ferramenta de sua preferência (DBeaver, pgAdmin, `psql`).
3. Abra o arquivo `sql/atividade_sql_meio_curso.sql`.
4. Execute **uma consulta por vez** — cada pergunta está separada por um bloco de comentário.

> 🔒 As credenciais de acesso ao banco não estão neste repositório.

## 💡 Principais observações

1. A categoria que concentra mais faturamento é Informática._
2. _Fortaleza - CE é a cidade/estado que concentra maior faturamento.

## ✅ Recomendação para a diretoria

Válido analisar concentração geográfica, avaliamos que produtos da categoria de informática rende muito no faturamento, expandir vendas para regiões com menor demanda e pouca presença, com devido treinamento aos vendedores, e reforçar a venda desses produtos nas regiões fortes também.

<sub>Projeto desenvolvido para fins educacionais.</sub>
