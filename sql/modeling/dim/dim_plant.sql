CREATE TABLE modeling.dim_plant AS(
	SELECT
		ROW_NUMBER() OVER(ORDER BY c.plant_id) AS plant_key,
		c.plant_id AS plant_code,
		c.daily_capacity,
		w.cost_per_unit
	FROM clean.wh_capacities c
	JOIN clean.wh_costs w
		ON c.plant_id = w.plant_code
);