CREATE TABLE modeling.dim_carrier AS(
	SELECT
		ROW_NUMBER() OVER(ORDER BY t.carrier_id) AS carrier_key,
		t.carrier_id,
		MAX(f.carrier_type) AS carrier_type,
		CASE
			WHEN MAX(f.carrier_id) IS NOT NULL THEN TRUE
			ELSE FALSE
		END AS is_active
	FROM (
		SELECT carrier_id
		FROM clean.freight_rates
		
		UNION
		
		SELECT carrier AS carrier_id
		FROM clean.order_list
	) t
	LEFT JOIN clean.freight_rates f
		ON t.carrier_id = f.carrier_id
	GROUP BY t.carrier_id
);