CREATE TABLE modeling.dim_product AS (
	SELECT
		ROW_NUMBER() OVER(ORDER BY product_id ASC) AS product_key,
		product_id
	FROM clean.products_per_plant
)