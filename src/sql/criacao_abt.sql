DROP TABLE IF EXISTS tb_abt_churn;
CREATE TABLE tb_abt_churn AS  -- Cria a abt para churn. Caso já exista a linha acima deleta a tabela já existente e cria uma nova.

--WITH para evitar subquerys
WITH VENDEDORES AS(

-- Retorna uma tabela com quem vendeu na data dada e os define com a flag 0 (vendeu)
SELECT T2.seller_id,
       strftime( '%Y-%m',T1.order_approved_at) || "-01" AS dt_venda,
       0 AS venda

--Para isso utiliza-se dados da tabela tb_orders cruzados com a tb_order_items
FROM tb_orders AS T1 

LEFT JOIN tb_order_items AS T2
ON T1.order_id = T2.order_id


--Com as condições abaixo, onde:
WHERE order_approved_at IS NOT NULL --Considera-se apenas pedidos aprovados
AND seller_id IS NOT NULL --Considera-se apenas vendedores existentes
AND T1.order_status = 'delivered' --Considera-se apenas pedidos que de fato foram entregues

-- A tabela é agrupada pelas datas e depois pelos vendedores e ordenadas pela ordem contraria.
GROUP BY strftime('%Y-%m',T1.order_approved_at) || "-01",
        T2.seller_id
ORDER BY T2.seller_id,
        strftime('%Y-%m',T1.order_approved_at) || "-01"
),


CHURN AS (

-- Retorna uma tabela na qual os vendedores da tabela "VENDEDORES", que não venderam pelos próximos 3 meses são definidos com uma flag de churn, 1.
SELECT  T1.dt_ref, 
        T1.seller_id,
        coalesce(T2.venda,1) AS flag_churn

FROM tb_book_sellers AS T1

--Cruza a tabela tb_book_sellers (criada com o código "exec_safra.py") com a de "VENDEDORES".
LEFT JOIN VENDEDORES AS T2
ON T1.seller_id = T2.seller_id --O cruzamento é feito com base nos sellers id e aqueles que venderam entre a data de referencia (fornecida em "exec_safra.py") e 3 meses após ela
AND T2.dt_venda BETWEEN T1.dt_ref AND date(T1.dt_ref, '+2 months')

GROUP BY T1.dt_ref, T1.seller_id
ORDER BY dt_ref 
)


--Cria a ABT completa
SELECT  T2.*,
        T1.flag_churn
       

FROM CHURN AS T1

LEFT JOIN   tb_book_sellers AS T2
ON   T1.seller_id = T2.seller_id
AND T1.dt_ref = T2.dt_ref
;