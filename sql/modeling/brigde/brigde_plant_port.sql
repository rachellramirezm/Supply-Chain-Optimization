CREATE TABLE modeling.bridge_plant_port AS(
	SELECT DISTINCT
		pl.plant_key,
		pt.port_key
	FROM clean.plant_port pp
	JOIN modeling.dim_plant pl
		ON pp.plant_code = pl.plant_code
	JOIN modeling.dim_port pt
		ON pp.port = pt.port
	ORDER BY pl.plant_key
);