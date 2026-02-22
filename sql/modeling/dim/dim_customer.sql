CREATE TABLE modeling.dim_customer AS(
	SELECT
		ROW_NUMBER() OVER(ORDER BY customer_id) AS customer_key,
		customer_id,
		CASE
			WHEN customer_id IN (
				SELECT customer_id
				FROM clean.vmi_customers
			)
			THEN TRUE
			ELSE FALSE
		END AS is_vmi_customer
	FROM (
		SELECT customer_id
		FROM clean.vmi_customers
		
		UNION
		
		SELECT customer AS customer_id
		FROM clean.order_list
	) t
);