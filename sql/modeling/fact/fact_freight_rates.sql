CREATE TABLE modeling.fact_freight_rates AS(
	SELECT
		ROW_NUMBER() OVER() AS freight_rate_id,
		
		c.carrier_key,
		
		op.port_key AS origin_port_key,
		dp.port_key AS destination_port_key,
		
		f.service_code AS service_level,
		f.mode_description AS transport_mode,
		
		f.min_weight_quantity AS min_weight,
		f.max_weight_quantity AS max_weight,
		
		f.rate,
		f.minimum_cost,
		f.transportation_day_count AS transport_days,
		
		f.carrier_type
		
	FROM clean.freight_rates f
	
	JOIN modeling.dim_carrier c
		ON f.carrier_id = c.carrier_id
		
	JOIN modeling.dim_port op
		ON f.origin_port_code = op.port
		
	JOIN modeling.dim_port dp
		ON f.destination_port_code = dp.port
);