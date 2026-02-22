CREATE TABLE modeling.bridge_plant_product AS(
	SELECT DISTINCT
		pl.plant_key,
		pr.product_key
	FROM clean.products_per_plant pp
	JOIN modeling.dim_plant pl
		ON pp.plant_code = pl.plant_code	
	JOIN modeling.dim_product pr
		ON pp.product_id = pr.product_id
	ORDER BY pl.plant_key
);