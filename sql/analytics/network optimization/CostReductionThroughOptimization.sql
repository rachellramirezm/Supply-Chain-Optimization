WITH orderList_info AS (
	SELECT
	    order_id,
	    plant_id,
	    carrier_id AS historical_carrier,
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
		freight_rate_id,
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

-- HISTORICAL COST CALCULATION
join_result_raw AS (
    SELECT
        o.order_id,
        o.plant_id,
        o.historical_carrier AS carrier_id,
        o.unit_quantity,
        o.total_weight,
        f.rate,
        f.minimum_cost,
        ROW_NUMBER() OVER(
            PARTITION BY o.order_id
            ORDER BY f.min_weight DESC, f.freight_rate_id ASC
        ) AS rn
    FROM orderList_info o
    LEFT JOIN freightRate_info f
        ON o.origin_port_id = f.origin_port_key
        AND o.destination_port_id = f.destination_port_key
        AND o.historical_carrier = f.carrier_key
        AND o.service_level = f.service_level
        AND o.total_weight BETWEEN f.min_weight AND f.max_weight
),

join_result AS (
    SELECT
        order_id,
        plant_id,
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
        j.transport_cost,
        j.unit_quantity * w.cost_per_unit AS warehouse_cost,
        COALESCE(j.transport_cost,0) + (j.unit_quantity * w.cost_per_unit) AS total_order_cost
    FROM join_result j
    JOIN warehouse_costs w
        ON j.plant_id = w.plant_key
),

-- OPTIMIZATION (ALL CARRIER OPTIONS)
carrier_options AS (
    SELECT
        o.order_id,
        o.plant_id,
        o.historical_carrier,
        f.carrier_key AS carrier_id,
        o.unit_quantity,
        o.total_weight,
        CASE
            WHEN f.carrier_key = 1 OR f.rate IS NULL THEN 0
            ELSE GREATEST(
                o.total_weight * f.rate,
                COALESCE(f.minimum_cost,0)
            )
        END AS transport_cost
    FROM orderList_info o
    JOIN freightRate_info f
        ON o.origin_port_id = f.origin_port_key
        AND o.destination_port_id = f.destination_port_key
        AND o.service_level = f.service_level
        AND o.total_weight BETWEEN f.min_weight AND f.max_weight
),

total_costs AS (
    SELECT
        c.order_id,
        c.historical_carrier,
        c.carrier_id,
        c.transport_cost,
        c.unit_quantity * w.cost_per_unit AS warehouse_cost,
        c.transport_cost + (c.unit_quantity * w.cost_per_unit) AS total_order_cost
    FROM carrier_options c
    JOIN warehouse_costs w
        ON c.plant_id = w.plant_key
),

optimal_assignment AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY total_order_cost ASC
        ) AS rn
    FROM total_costs
),

optimal_costs AS(
	SELECT
	    order_id,
	    historical_carrier,
	    carrier_id AS optimal_carrier,
	    transport_cost,
	    warehouse_cost,
	    total_order_cost
	FROM optimal_assignment
	WHERE rn = 1
)

SELECT
    h.historical_total_cost,
    o.optimal_total_cost,
    h.historical_total_cost - o.optimal_total_cost AS potential_savings,
    ROUND(
        (h.historical_total_cost - o.optimal_total_cost) 
        / h.historical_total_cost * 100,
        2
    ) AS savings_percentage
FROM
(
    SELECT SUM(total_order_cost) AS historical_total_cost
    FROM order_costs
) h
CROSS JOIN
(
    SELECT SUM(total_order_cost) AS optimal_total_cost
    FROM optimal_costs
) o;