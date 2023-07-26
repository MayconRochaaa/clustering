
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
)

SELECT mes_pedido,
       count() AS Sellers_Venderam

FROM seller_pedido

GROUP BY mes_pedido






