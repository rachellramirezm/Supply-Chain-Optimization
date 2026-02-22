CREATE TABLE modeling.fact_orders AS (
	SELECT
		ROW_NUMBER() OVER(ORDER BY o.order_id) AS order_key,
		o.order_id, 
		d.date_key AS date_id,
		pl.plant_key AS plant_id,
		p.product_key AS product_id,
		c.customer_key AS customer_id,
		cr.carrier_key AS carrier_id,
		
		pto.port_key AS origin_port_id,
		ptd.port_key AS destination_port_id,
		
		o.transportation_day_count AS transport_mode,
		o.service_level,
		o.unit_quantity,
		o.weight,
		o.ship_ahead_day_count AS ship_ahead_days,
		o.ship_late_day_count AS ship_late_days
		
	FROM clean.order_list o
	
	JOIN modeling.dim_date d
		ON o.order_date = d.full_date
		
	JOIN modeling.dim_plant pl
		ON o.plant_code = pl.plant_code
		
	JOIN modeling.dim_product p
		ON o.product_id = p.product_id	
		
	JOIN modeling.dim_customer c
		ON o.customer = c.customer_id
		
	JOIN modeling.dim_carrier cr
		ON o.carrier = cr.carrier_id
		
	JOIN modeling.dim_port pto
		ON o.origin_port = pto.port
		
	JOIN modeling.dim_port ptd
		ON o.destination_port = ptd.port
);