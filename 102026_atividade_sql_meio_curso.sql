/* =====================================================================
   DATADT | SQL para Análise de Dados
   Atividade de Meio de Curso - Diagnóstico comercial
   Banco: datadt_digital_corporativo (PostgreSQL)
   Schemas utilizados: vendas, geral
   ===================================================================== */


/* ---------------------------------------------------------------------
   QUESTÃO 01
   --------------------------------------------------------------------- */

-- Liste as notas fiscais com data da venda, número da NF, valor total, forma de pagamento, cliente e vendedor.

WITH relacao_nf AS ( 
	SELECT
		nf.id
		,inf.id_nota_fiscal
		,CAST(nf.data_venda AS DATE) AS data_venda -- ajustado para o formato de data
		,nf.numero_nf
		,SUM(inf.valor_venda_real) AS vtotal
		,nf.id_cliente
		,nf.id_vendedor
	FROM vendas.item_nota_fiscal inf
	INNER JOIN vendas.nota_fiscal nf 
	ON inf.id_nota_fiscal = nf.id
	GROUP BY (nf.id, inf.id_nota_fiscal, data_venda, nf.numero_nf, nf.id_cliente, nf.id_vendedor)
) -- CTE feita para relacionar dados das tabelas de forma_pagamento e item_nota_fiscal, visto que a principio ambas não possuem nenhuma coluna em comum

SELECT 
	rnf.id_nota_fiscal 		AS "idNotaFiscal"
	,rnf.data_venda 		AS "DataVenda"
	,rnf.numero_nf 			AS "NumeroNF"
	,rnf.vtotal 			AS "ValorTotal"
	,fp.descricao			AS "FormaPagto"
	,rnf.id_cliente			AS "Cliente"
	,rnf.id_vendedor		AS "Vendedor"
FROM relacao_nf rnf
INNER JOIN vendas.forma_pagamento fp
ON rnf.id = fp.id;


/* ---------------------------------------------------------------------
   QUESTÃO 02
   --------------------------------------------------------------------- */

-- Calcule o faturamento total, a quantidade vendida e o ticket médio por categoria de produto. 

WITH rel_categoriaproduto AS (

	SELECT 
		ct.id 															AS "id_categoria" -- definido um alias pois nas duas tabelas possuem colunas com o mesmo nome
		,ct.descricao
		,pr.id_categoria
		,pr.id 															AS "id_produto" -- """"
	FROM vendas.categoria ct
	INNER JOIN vendas.produto pr
	ON ct.id = pr.id_categoria
) -- CTE feita para relacionar dados das tabelas de categoria e item_nota_fiscal, visto que a principio ambas não possuem nenhuma coluna em comum

SELECT 
	ctpr.descricao														AS "Categoria"
	,SUM(inf.quantidade)												AS "Qtde"
	,ROUND((SUM(inf.valor_venda_real)) / SUM(inf.quantidade)) 			AS "TicketMedio"
	,SUM(inf.valor_venda_real) 											AS "Faturamento"
FROM rel_categoriaproduto ctpr
INNER JOIN vendas.item_nota_fiscal inf
ON inf.id_produto = ctpr.id_produto
GROUP BY ("Categoria")
ORDER BY "Faturamento" DESC


/* ---------------------------------------------------------------------
   QUESTÃO 03
   --------------------------------------------------------------------- */

-- Identifique os 10 produtos com maior faturamento, incluindo quantidade vendida, valor medio unitario e ranking. 

SELECT 
	ROW_NUMBER() OVER (
			ORDER BY SUM(inf.valor_venda_real)
											DESC)		AS "Ranking" -- feito uma WF para retornar o ranking, sem partição (PARTITION BY)
	,pr.nome											AS "Produto"
	,SUM(inf.valor_venda_real)							AS "Faturamento"
	,SUM(inf.quantidade)								AS "Qtde"
	,ROUND(AVG(inf.valor_unitario), 2)					AS "MediaValorUnitario"
	FROM vendas.produto pr
	INNER JOIN vendas.item_nota_fiscal inf
	ON pr.id = inf.id_produto

	GROUP BY ("Produto")
	
LIMIT 10;


/* ---------------------------------------------------------------------
   QUESTÃO 04
   --------------------------------------------------------------------- */

-- Calcule a margem bruta por produto usando valor de venda e valor de custo quando disponível no modelo

SELECT 
	nome												AS "Produto"
	,(SUM(valor_venda)) - (SUM(valor_custo))			AS "MargemBruta" 
		
FROM vendas.produto

GROUP BY ("Produto");


/* ---------------------------------------------------------------------
   QUESTÃO 05
   --------------------------------------------------------------------- */

-- Analise o faturamento por estado e cidade do cliente, ordenando do maior para o menor

WITH cid_uf AS (
	SELECT 
		uf.id								AS "idEstado"
		,uf.descricao						AS "Estado"
		,cid.id								AS "idCidade"
		,cid.descricao						AS "Cidade"
	FROM geral.estado uf
	INNER JOIN geral.cidade cid
	ON uf.id = cid.id_estado
) -- conectando cidade e estado

,bairro AS (
	SELECT 
		b.id								AS "idBairro"
		,b.id_cidade						AS "idCidade"
		,cu."Cidade"						AS "Cidade"
		,cu."Estado"						AS "Estado"
	FROM geral.bairro b
	INNER JOIN cid_uf cu
	ON cu."idCidade" = b.id_cidade
) -- conectando cidade, estado e bairro

,endereco AS (
	SELECT
		e.id_pessoa							AS "idPessoa"
		,b."Estado"
		,b."Cidade"
	FROM geral.endereco e
	INNER JOIN bairro b
	ON e.id_bairro = b."idBairro"
) -- trazendo cidade, estado e o id_pessoa pq vai precisar dele pra trazer o cliente

,pessoa AS (
	SELECT
		p.id								AS "idPessoa"
		,e."Estado"
		,e."Cidade"
	FROM geral.pessoa p
	INNER JOIN endereco e
	ON p.id = e."idPessoa"
)

,nf AS (
	SELECT
		p."idPessoa"
		,p."Estado"
		,p."Cidade"
		,nf.id								AS "idNF"
	FROM vendas.nota_fiscal nf
	INNER JOIN pessoa p
	ON nf.id_cliente = p."idPessoa"
)

,inf AS (
	SELECT
		nf."idPessoa"
		,nf."Estado"
		,nf."Cidade"
		,inf.valor_venda_real				AS "Faturamento"
	FROM vendas.item_nota_fiscal inf
	INNER JOIN nf
	ON nf."idNF" = inf.id_nota_fiscal
)

SELECT 
	"Estado"
	,"Cidade"
	,SUM("Faturamento")						AS "FaturamentoTotal"
FROM inf
GROUP BY ("Estado", "Cidade")
ORDER BY "FaturamentoTotal" DESC;


/* ---------------------------------------------------------------------
   QUESTÃO 06
   --------------------------------------------------------------------- */

-- Crie uma categorização de clientes em Alto Valor, Médio Valor e Baixo Valor com base no total comprado.

WITH total_cliente AS (
	SELECT
		id_cliente
		,SUM(valor)							AS total_comprado
	FROM vendas.nota_fiscal
	GROUP BY id_cliente
)

,limites AS (
	SELECT
		PERCENTILE_CONT(1.0/3) WITHIN GROUP (ORDER BY total_comprado)	AS corte_baixo
		,PERCENTILE_CONT(2.0/3) WITHIN GROUP (ORDER BY total_comprado)	AS corte_alto
	FROM total_cliente
) -- valores que separam os 3 grupos (1/3 e 2/3 dos clientes)

SELECT
	tc.id_cliente							AS "Cliente"
	,tc.total_comprado						AS "TotalComprado"
	,CASE
		WHEN tc.total_comprado >= l.corte_alto THEN 'Alto Valor'
		WHEN tc.total_comprado >= l.corte_baixo THEN 'Médio Valor'
		ELSE 'Baixo Valor'
	END										AS "Categoria"
FROM total_cliente tc
CROSS JOIN limites l
ORDER BY tc.total_comprado DESC;


/* ---------------------------------------------------------------------
   QUESTÃO 07
   --------------------------------------------------------------------- */

-- Calcule a participação percentual de cada categoria no faturamento total.

WITH total_cliente AS (
	SELECT
		id_cliente
		,SUM(valor)							AS total_comprado
	FROM vendas.nota_fiscal
	GROUP BY id_cliente
)

,limites AS (
	SELECT
		PERCENTILE_CONT(1.0/3) WITHIN GROUP (ORDER BY total_comprado)	AS corte_baixo
		,PERCENTILE_CONT(2.0/3) WITHIN GROUP (ORDER BY total_comprado)	AS corte_alto
	FROM total_cliente
)

,categorizado AS (
	SELECT
		tc.total_comprado
		,CASE
			WHEN tc.total_comprado >= l.corte_alto THEN 'Alto Valor'
			WHEN tc.total_comprado >= l.corte_baixo THEN 'Médio Valor'
			ELSE 'Baixo Valor'
		END									AS categoria
	FROM total_cliente tc
	CROSS JOIN limites l
)

SELECT
	categoria								AS "Categoria"
	,SUM(total_comprado)					AS "Faturamento"
	,ROUND(100.0 * SUM(total_comprado) / SUM(SUM(total_comprado)) OVER (), 2)
											AS "ParticipacaoPct"
FROM categorizado
GROUP BY categoria
ORDER BY "Faturamento" DESC;


/* ---------------------------------------------------------------------
   QUESTÃO 08
   --------------------------------------------------------------------- */

-- Gera uma série temporal de vendas por mês com faturamento mensal, soma acumulada e variação em relação ao mês anterior.

WITH mensal AS (
	SELECT
		DATE_TRUNC('month', data_venda)::date	AS mes
		,SUM(valor)								AS faturamento
	FROM vendas.nota_fiscal
	GROUP BY 1
)

,comparativo AS (
	SELECT
		mes
		,faturamento
		,SUM(faturamento) OVER (ORDER BY mes)	AS acumulado
		,LAG(faturamento) OVER (ORDER BY mes)	AS fat_anterior
	FROM mensal
) -- fat_anterior fica nulo no primeiro mês, pois não existe mês anterior

SELECT
	mes											AS "Mes"
	,faturamento								AS "Faturamento"
	,acumulado									AS "FaturamentoAcumulado"
	,CASE
		WHEN fat_anterior IS NULL THEN 0
		ELSE faturamento - fat_anterior
	END											AS "VariacaoValor"
	,CASE
		WHEN fat_anterior IS NULL OR fat_anterior = 0 THEN 0
		ELSE ROUND(100.0 * (faturamento - fat_anterior) / fat_anterior, 2)
	END											AS "VariacaoPct"
FROM comparativo
ORDER BY "Mes";


/* ---------------------------------------------------------------------
   QUESTÃO 09
   --------------------------------------------------------------------- */

-- Use uma subquery ou CTE para encontrar produtos com faturamento acima da media da propria categoria.

WITH fat_produto AS (
	SELECT
		p.id
		,p.nome
		,p.id_categoria
		,SUM(inf.valor_venda_real)				AS faturamento
	FROM vendas.produto p
	INNER JOIN vendas.item_nota_fiscal inf
		ON inf.id_produto = p.id
	GROUP BY p.id, p.nome, p.id_categoria
) -- faturamento por produto

,media_categoria AS (
	SELECT
		id_categoria
		,AVG(faturamento)						AS media_categoria
	FROM fat_produto
	GROUP BY id_categoria
) -- média de faturamento dos produtos de cada categoria

SELECT
	c.descricao									AS "Categoria"
	,fp.nome									AS "Produto"
	,fp.faturamento								AS "Faturamento"
	,ROUND(mc.media_categoria, 2)				AS "MediaCategoria"
FROM fat_produto fp
INNER JOIN media_categoria mc
	ON mc.id_categoria = fp.id_categoria
INNER JOIN vendas.categoria c
	ON c.id = fp.id_categoria
WHERE fp.faturamento > mc.media_categoria
ORDER BY c.descricao, fp.faturamento DESC;


/* ---------------------------------------------------------------------
   QUESTÃO 10
   --------------------------------------------------------------------- */

-- Use função window para ranquear vendedores por faturamento total e por quantidade de notas fiscais emitidas.

-- RANK() para que empates compartilhem a posição
-- vendedor considerado pessoa física (nome vem de geral.pessoa_fisica)
WITH vendedor AS (
	SELECT
		id_vendedor
		,SUM(valor)								AS faturamento_total
		,COUNT(*)								AS qtd_nf
	FROM vendas.nota_fiscal
	GROUP BY id_vendedor
)

SELECT
	pf.nome										AS "Vendedor"
	,v.faturamento_total						AS "FaturamentoTotal"
	,v.qtd_nf									AS "QtdNF"
	,RANK() OVER (ORDER BY v.faturamento_total DESC)	AS "RankFaturamento"
	,RANK() OVER (ORDER BY v.qtd_nf DESC)				AS "RankQtdNF"
FROM vendedor v
INNER JOIN geral.pessoa_fisica pf
	ON pf.id = v.id_vendedor
ORDER BY "RankFaturamento";
