CREATE TABLE modeling.dim_port AS(
	SELECT
		ROW_NUMBER() OVER(ORDER BY port) AS port_key,
		port
	FROM (
		
		SELECT port
		FROM clean.plant_port
		
		UNION
		
		SELECT origin_port AS port
		FROM clean.order_list
		
		UNION
		
		SELECT destination_port AS port
		FROM clean.order_list
		
		UNION
		
		SELECT origin_port_code AS port
		FROM clean.freight_rates
		
		UNION
		
		SELECT destination_port_code AS port
		FROM clean.freight_rates
		
	) p
);