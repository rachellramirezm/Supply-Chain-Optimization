--Which routes generate the highest logistics costs?
WITH orderList_info AS (
	SELECT
	    order_id,
	    plant_id,
	    carrier_id,
	    origin_port_id,
	    destination_port_id,
	    service_level,
	    SUM(unit_quantity) AS unit_quantity,
	    SUM(unit_quantity * weight) AS total_weight
	FROM modeling.fact_orders
	GROUP BY
	    order_id,
	    plant_id,
	    carrier_id,
	    origin_port_id,
	    destination_port_id,
	    service_level
),

freightRate_info AS (
    SELECT
        carrier_key,
        origin_port_key,
        destination_port_key,
        service_level,
        min_weight,
        max_weight,
        rate,
        minimum_cost
    FROM modeling.fact_freight_rates
),

join_result_raw AS (
    SELECT
        o.order_id,
        o.plant_id,
		o.origin_port_id,
		o.destination_port_id,
        o.carrier_id,
        o.unit_quantity,
        o.total_weight,
        f.rate,
        f.minimum_cost,
        ROW_NUMBER() OVER(
            PARTITION BY o.order_id
            ORDER BY f.min_weight DESC
        ) AS rn
    FROM orderList_info o
    LEFT JOIN freightRate_info f
        ON o.origin_port_id = f.origin_port_key
        AND o.destination_port_id = f.destination_port_key
        AND o.carrier_id = f.carrier_key
        AND o.service_level = f.service_level
        AND o.total_weight BETWEEN f.min_weight AND f.max_weight
),

join_result AS (
    SELECT
        order_id,
        plant_id,
		origin_port_id,
		destination_port_id,
        carrier_id,
        unit_quantity,
        total_weight,
        rate,
        minimum_cost,
        CASE
            WHEN carrier_id = 1 OR rate IS NULL THEN 0
            ELSE GREATEST(
                total_weight * rate,
                COALESCE(minimum_cost,0)
            )
        END AS transport_cost
    FROM join_result_raw
    WHERE rn = 1 OR rn IS NULL
),

warehouse_costs AS (
    SELECT
        plant_key,
        cost_per_unit
    FROM modeling.dim_plant
),

order_costs AS (
    SELECT
        j.order_id,
		j.plant_id,
		j.origin_port_id,
		j.destination_port_id,
        j.transport_cost,
        j.unit_quantity * w.cost_per_unit AS warehouse_cost,
        COALESCE(j.transport_cost,0) + (j.unit_quantity * w.cost_per_unit) AS total_order_cost
    FROM join_result j
    JOIN warehouse_costs w
        ON j.plant_id = w.plant_key
)

SELECT
	origin_port_id,
	destination_port_id,
    SUM(transport_cost) AS total_transport_cost,
    SUM(warehouse_cost) AS total_warehouse_cost,
    SUM(total_order_cost) AS total_logistics_cost
FROM order_costs
GROUP BY plant_id, origin_port_id, destination_port_id
ORDER BY total_logistics_cost DESC


