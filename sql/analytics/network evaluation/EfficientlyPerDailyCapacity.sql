WITH plant_info AS (
	SELECT
		plant_key,
		plant_code,
		daily_capacity
	FROM modeling.dim_plant
),

order_info AS (
	SELECT
		plant_id,
		COUNT(*) AS daily_orders
	FROM modeling.fact_orders
	GROUP BY plant_id
	ORDER BY plant_id		
)

SELECT
	p.plant_code,
	p.daily_capacity,
	o.daily_orders,
	CASE
		WHEN p.daily_capacity > o.daily_orders THEN 'Appropriate orders according to capacity'
		ELSE 'Orders not appropriate according to capacity'
	END AS efficiently
FROM plant_info p
JOIN order_info o
	ON p.plant_key = o.plant_id	

