CREATE TABLE modeling.bridge_plant_customer AS(
	SELECT DISTINCT
		pl.plant_key,
		c.customer_key
	FROM clean.vmi_customers v
	JOIN modeling.dim_plant pl
		ON v.plant_code = pl.plant_code
	JOIN modeling.dim_customer c
		ON v.customer_id = c.customer_id
	ORDER BY pl.plant_key
);