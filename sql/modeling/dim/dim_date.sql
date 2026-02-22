CREATE TABLE modeling.dim_date AS(
	SELECT
		DISTINCT
		ROW_NUMBER() OVER(ORDER BY order_date) AS date_key,
		order_date AS full_date,
		EXTRACT(DAY FROM order_date) AS day,
		EXTRACT(MONTH FROM order_date) AS month,
		TO_CHAR(order_date, 'month') AS month_name,
		EXTRACT(QUARTER FROM order_date) AS quarter,
		EXTRACT(YEAR FROM order_date) AS year
	FROM(
		SELECT
			DISTINCT order_date
			FROM clean.order_list
	)d
);
