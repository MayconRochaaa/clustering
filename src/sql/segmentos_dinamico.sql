
--WITH foi usado para evitar subquerys

WITH IDADE AS (

/*Retorna uma tabela contendo o seller_id e a diferença entre a data em que a compra foi aprovada e a data de entrega*/

SELECT T2.seller_id, --Seleciona a culuna de seller id
    MAX(julianday('{date}')-julianday(T1.order_approved_at)) AS idade_base --Cria e seleciona a culuna da diferença entre a data de entrega e a data em que a entrega foi aprovada

FROM tb_orders AS T1

LEFT JOIN tb_order_items as T2 --Cruza as informações da tabela de pedidos com a tabela dos itens dos pedidos para obter informações das datas
ON T1.order_id = T2.order_id

WHERE T1.order_approved_At < '{date}' --Pega apenas datas anteriores à informada
AND T1.order_status = 'delivered' --Pega apenas os pedidos que de fato foram entreges

GROUP BY T2.seller_id --Agrupa a tabela pelos vendedores
),   

VARIAVEIS AS (
/*Retorna uma tabela contendo o seller_id e todas variavéis úteis para o modelo de ML*/
SELECT  T2.seller_id,
        AVG(T5.review_score) AS avg_review, --Média da avaliação do vendedor
        T3.idade_base AS idade_dias, --Tempo que o vendedor está na base, em dias
        1+CAST(T3.idade_base/30 AS INT) AS idade_mes, --Tempo que o vendedor está na base, em meses
        CAST(-julianday(max(T1.order_approved_at))+julianday('{date}') AS INT) AS qtd_dias_UltmVenda, --Tempo que o vendedor está sem vender
        COUNT(DISTINCT STRFTIME('%m', T1.order_approved_at)) AS qtd_mes_ativacao, --Quantidade de meses em que o vendedor vendeu pelo menos uma vez
        CAST(COUNT(DISTINCT STRFTIME('%m', T1.order_approved_at)) AS FLOAT)/min(1+CAST (T3.idade_base/30 AS INT),6 ) AS proporcao_ativacao,--Proporção de vendas nos ultimos 6 meses
        SUM(CASE WHEN julianday(T1.order_estimated_delivery_date)<julianday(T1.order_delivered_customer_date) THEN 1 ELSE 0 END)/COUNT(DISTINCT T2.product_id) AS prop_atraso,--Proporção de atrasos
        CAST(AVG(julianday(T1.order_estimated_delivery_date)-julianday(T1.order_purchase_timestamp)) AS INT) AS avg_tempo_entrega, --Tempo médio de entrega dos pedidos
        SUM(T2.price) AS receita_total,--Receita total
        COUNT(DISTINCT T2.order_id) AS quantidade_vendas,--Quantidade de vendas
        SUM(T2.price)/COUNT(DISTINCT T2.order_id) AS avg_vl_venda,--Valor médio das vendas

        SUM(T2.price)/min(1+CAST (T3.idade_base/30 AS INT),6 ) AS avg_vl_venda_mes,--Valor médio das vendas por mês na base
        SUM(T2.price)/COUNT(DISTINCT STRFTIME('%m', T1.order_approved_at)) AS avg_vl_venda_mes_ativado,--Valor médio das vendas por mês ativo na base
        COUNT(T2.product_id) AS quantidade_produto,--Quantidade de produtos vendidos por cada vendendor
        COUNT(DISTINCT T2.product_id) AS quantidade_produto_dst,--Quantidade de produtos distintos vendidos por cada vendendor
        SUM(T2.price)/ COUNT(T2.product_id) AS avg_vl_produto,--Valor médio dos produtos de cada vendendor
        COUNT(T2.product_id)/COUNT(DISTINCT T2.order_id) AS avg_quantidade_produto_venda,--Valor médio da quantidade de produto por venda

        --Quantidade de produtos vendidos em cada categoria por cada vendedor        
        SUM( CASE WHEN  T4.product_category_name = 'cama_mesa_banho' THEN 1 ELSE 0 END) AS qtde_cama_mesa_banho,
        SUM( CASE WHEN  T4.product_category_name = 'beleza_saude' THEN 1 ELSE 0 END) AS qtde_beleza_saude,
        SUM( CASE WHEN  T4.product_category_name = 'esporte_lazer' THEN 1 ELSE 0 END) AS qtde_esporte_lazer,
        SUM( CASE WHEN  T4.product_category_name = 'moveis_decoracao' THEN 1 ELSE 0 END) AS qtde_moveis_decoracao,
        SUM( CASE WHEN  T4.product_category_name = 'informatica_acessorios' THEN 1 ELSE 0 END) AS qtde_informatica_acessorios,
        SUM( CASE WHEN  T4.product_category_name = 'utilidades_domesticas' THEN 1 ELSE 0 END) AS qtde_utilidades_domesticas,
        SUM( CASE WHEN  T4.product_category_name = 'relogios_presentes' THEN 1 ELSE 0 END) AS qtde_relogios_presentes,
        SUM( CASE WHEN  T4.product_category_name = 'telefonia' THEN 1 ELSE 0 END) AS qtde_telefonia,
        SUM( CASE WHEN  T4.product_category_name = 'ferramentas_jardim' THEN 1 ELSE 0 END) AS qtde_ferramentas_jardim,
        SUM( CASE WHEN  T4.product_category_name = 'automotivo' THEN 1 ELSE 0 END) AS qtde_automotivo,
        SUM( CASE WHEN  T4.product_category_name = 'brinquedos' THEN 1 ELSE 0 END) AS qtde_brinquedos,
        SUM( CASE WHEN  T4.product_category_name = 'cool_stuff' THEN 1 ELSE 0 END) AS qtde_cool_stuff,
        SUM( CASE WHEN  T4.product_category_name = 'perfumaria' THEN 1 ELSE 0 END) AS qtde_perfumaria,
        SUM( CASE WHEN  T4.product_category_name = 'bebes' THEN 1 ELSE 0 END) AS qtde_bebes,
        SUM( CASE WHEN  T4.product_category_name = 'eletronicos' THEN 1 ELSE 0 END) AS qtde_eletronicos,
        SUM( CASE WHEN  T4.product_category_name = 'papelaria' THEN 1 ELSE 0 END) AS qtde_papelaria,
        SUM( CASE WHEN  T4.product_category_name = 'fashion_bolsas_e_acessorios' THEN 1 ELSE 0 END) AS qtde_fashion_bolsas_e_acessorios,
        SUM( CASE WHEN  T4.product_category_name = 'pet_shop' THEN 1 ELSE 0 END) AS qtde_pet_shop,
        SUM( CASE WHEN  T4.product_category_name = 'moveis_escritorio' THEN 1 ELSE 0 END) AS qtde_moveis_escritorio,
        SUM( CASE WHEN  T4.product_category_name = 'consoles_games' THEN 1 ELSE 0 END) AS qtde_consoles_games,
        SUM( CASE WHEN  T4.product_category_name = 'malas_acessorios' THEN 1 ELSE 0 END) AS qtde_malas_acessorios,
        SUM( CASE WHEN  T4.product_category_name = 'construcao_ferramentas_construcao' THEN 1 ELSE 0 END) AS qtde_construcao_ferramentas_construcao,
        SUM( CASE WHEN  T4.product_category_name = 'eletrodomesticos' THEN 1 ELSE 0 END) AS qtde_eletrodomesticos,
        SUM( CASE WHEN  T4.product_category_name = 'instrumentos_musicais' THEN 1 ELSE 0 END) AS qtde_instrumentos_musicais,
        SUM( CASE WHEN  T4.product_category_name = 'eletroportateis' THEN 1 ELSE 0 END) AS qtde_eletroportateis,
        SUM( CASE WHEN  T4.product_category_name = 'casa_construcao' THEN 1 ELSE 0 END) AS qtde_casa_construcao,
        SUM( CASE WHEN  T4.product_category_name = 'livros_interesse_geral' THEN 1 ELSE 0 END) AS qtde_livros_interesse_geral,
        SUM( CASE WHEN  T4.product_category_name = 'alimentos' THEN 1 ELSE 0 END) AS qtde_alimentos,
        SUM( CASE WHEN  T4.product_category_name = 'moveis_sala' THEN 1 ELSE 0 END) AS qtde_moveis_sala,
        SUM( CASE WHEN  T4.product_category_name = 'casa_conforto' THEN 1 ELSE 0 END) AS qtde_casa_conforto,
        SUM( CASE WHEN  T4.product_category_name = 'bebidas' THEN 1 ELSE 0 END) AS qtde_bebidas,
        SUM( CASE WHEN  T4.product_category_name = 'audio' THEN 1 ELSE 0 END) AS qtde_audio,
        SUM( CASE WHEN  T4.product_category_name = 'market_place' THEN 1 ELSE 0 END) AS qtde_market_place,
        SUM( CASE WHEN  T4.product_category_name = 'construcao_ferramentas_iluminacao' THEN 1 ELSE 0 END) AS qtde_construcao_ferramentas_iluminacao,
        SUM( CASE WHEN  T4.product_category_name = 'climatizacao' THEN 1 ELSE 0 END) AS qtde_climatizacao,
        SUM( CASE WHEN  T4.product_category_name = 'moveis_cozinha_area_de_servico_jantar_e_jardim' THEN 1 ELSE 0 END) AS qtde_moveis_cozinha_area_de_servico_jantar_e_jardim,
        SUM( CASE WHEN  T4.product_category_name = 'alimentos_bebidas' THEN 1 ELSE 0 END) AS qtde_alimentos_bebidas,
        SUM( CASE WHEN  T4.product_category_name = 'industria_comercio_e_negocios' THEN 1 ELSE 0 END) AS qtde_industria_comercio_e_negocios,
        SUM( CASE WHEN  T4.product_category_name = 'livros_tecnicos' THEN 1 ELSE 0 END) AS qtde_livros_tecnicos,
        SUM( CASE WHEN  T4.product_category_name = 'telefonia_fixa' THEN 1 ELSE 0 END) AS qtde_telefonia_fixa,
        SUM( CASE WHEN  T4.product_category_name = 'fashion_calcados' THEN 1 ELSE 0 END) AS qtde_fashion_calcados,
        SUM( CASE WHEN  T4.product_category_name = 'eletrodomesticos_2' THEN 1 ELSE 0 END) AS qtde_eletrodomesticos_2,
        SUM( CASE WHEN  T4.product_category_name = 'construcao_ferramentas_jardim' THEN 1 ELSE 0 END) AS qtde_construcao_ferramentas_jardim,
        SUM( CASE WHEN  T4.product_category_name = 'agro_industria_e_comercio' THEN 1 ELSE 0 END) AS qtde_agro_industria_e_comercio,
        SUM( CASE WHEN  T4.product_category_name = 'artes' THEN 1 ELSE 0 END) AS qtde_artes,
        SUM( CASE WHEN  T4.product_category_name = 'pcs' THEN 1 ELSE 0 END) AS qtde_pcs,
        SUM( CASE WHEN  T4.product_category_name = 'sinalizacao_e_seguranca' THEN 1 ELSE 0 END) AS qtde_sinalizacao_e_seguranca,
        SUM( CASE WHEN  T4.product_category_name = 'construcao_ferramentas_seguranca' THEN 1 ELSE 0 END) AS qtde_construcao_ferramentas_seguranca,
        SUM( CASE WHEN  T4.product_category_name = 'artigos_de_natal' THEN 1 ELSE 0 END) AS qtde_artigos_de_natal


FROM tb_orders as T1

--Cruzamentos necessários
LEFT JOIN tb_order_items as T2
ON T1.order_id = T2.order_id

LEFT JOIN IDADE AS T3
ON T2.seller_id = T3.seller_id

LEFT JOIN tb_products AS T4
ON T2.product_id = T4.product_id

LEFT JOIN tb_order_reviews AS T5
ON T1.order_id = T5.order_id 

--Condições 
WHERE T1.order_approved_at >= date('{date}','-6 months') --Será considerado apenas os seis meses anteriores à data informada
AND T1.order_approved_at < '{date}' --Pega apenas datas anteriores à informada
AND T1.order_status = 'delivered' --Pega apenas os pedidos que de fato foram entreges
AND T5.review_score IS NOT NULL -- Ignora vendedores sem avaliação 

GROUP BY T2.seller_id --Agrupa pelos vendedores

)

--Tabela final
SELECT '{date}' AS dt_ref,
       T2.seller_city,
       T2.seller_state,
       T1.*

FROM(VARIAVEIS) AS T1

LEFT JOIN tb_sellers AS T2
ON T1.seller_id = T2.seller_id 
;