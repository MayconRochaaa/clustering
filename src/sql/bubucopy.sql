
WITH seller_pedido AS (

SELECT t1.seller_id,
       strftime( '%Y-%m',t3.order_approved_at) AS mes_pedido
       --count()

FROM tb_sellers AS t1

LEFT JOIN tb_order_items AS t2
ON t1.seller_id = t2. seller_id

LEFT JOIN tb_orders AS t3
ON t2.order_id = t3.order_id

WHERE t3.order_status = 'delivered'
AND mes_pedido IS NOT NULL

GROUP BY mes_pedido, t1.seller_id
),
 
seller_venderam AS(

SELECT  seller_id,
         CASE WHEN mes_pedido = '2016-09' THEN 1 ELSE 0 END AS qnt_2016_09,
         CASE WHEN mes_pedido = '2016-10' THEN 1 ELSE 0 END AS qnt_2016_10,
         CASE WHEN mes_pedido = '2016-12' THEN 1 ELSE 0 END AS qnt_2016_12,
         CASE WHEN mes_pedido = '2017-01' THEN 1 ELSE 0 END AS qnt_2017_01,
         CASE WHEN mes_pedido = '2017-02' THEN 1 ELSE 0 END AS qnt_2017_02,
         CASE WHEN mes_pedido = '2017-03' THEN 1 ELSE 0 END AS qnt_2017_03,
         CASE WHEN mes_pedido = '2017-04' THEN 1 ELSE 0 END AS qnt_2017_04,
         CASE WHEN mes_pedido = '2017-05' THEN 1 ELSE 0 END AS qnt_2017_05,
         CASE WHEN mes_pedido = '2017-06' THEN 1 ELSE 0 END AS qnt_2017_06,
         CASE WHEN mes_pedido = '2017-07' THEN 1 ELSE 0 END AS qnt_2017_07,
         CASE WHEN mes_pedido = '2017-08' THEN 1 ELSE 0 END AS qnt_2017_08,
         CASE WHEN mes_pedido = '2017-09' THEN 1 ELSE 0 END AS qnt_2017_09,
         CASE WHEN mes_pedido = '2017-10' THEN 1 ELSE 0 END AS qnt_2017_10,
         CASE WHEN mes_pedido = '2017-11' THEN 1 ELSE 0 END AS qnt_2017_11,
         CASE WHEN mes_pedido = '2017-12' THEN 1 ELSE 0 END AS qnt_2017_12,
         CASE WHEN mes_pedido = '2018-01' THEN 1 ELSE 0 END AS qnt_2018_01,
         CASE WHEN mes_pedido = '2018-02' THEN 1 ELSE 0 END AS qnt_2018_02,
         CASE WHEN mes_pedido = '2018-03' THEN 1 ELSE 0 END AS qnt_2018_03,
         CASE WHEN mes_pedido = '2018-04' THEN 1 ELSE 0 END AS qnt_2018_04,
         CASE WHEN mes_pedido = '2018-05' THEN 1 ELSE 0 END AS qnt_2018_05,
         CASE WHEN mes_pedido = '2018-06' THEN 1 ELSE 0 END AS qnt_2018_06,
         CASE WHEN mes_pedido = '2018-07' THEN 1 ELSE 0 END AS qnt_2018_07,
         CASE WHEN mes_pedido = '2018-08' THEN 1 ELSE 0 END AS qnt_2018_08  

FROM seller_pedido

GROUP BY seller_id
)

SELECT  *--sum(qnt_2016_10)

FROM seller_venderam



       


