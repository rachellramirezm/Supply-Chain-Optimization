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
), 
classification AS(
	SELECT
		p.plant_code,
		p.daily_capacity,
		o.daily_orders,
		o.daily_orders* 1.0 / p.daily_capacity AS utilization
	FROM plant_info p
	JOIN order_info o
		ON p.plant_key = o.plant_id
)

SELECT
	plant_code,
	daily_capacity,
	daily_orders,
	CASE
	    WHEN utilization > 1 THEN 'Over capacity'
	    WHEN utilization >= 0.9 THEN 'Near capacity'
	    ELSE 'Capacity larger than production'
	END AS Interpretation
FROM classification
	




