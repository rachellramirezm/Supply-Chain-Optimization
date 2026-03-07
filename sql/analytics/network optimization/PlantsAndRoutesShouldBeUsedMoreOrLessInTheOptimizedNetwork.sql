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

warehouse_costs AS (
    SELECT
        plant_key,
        cost_per_unit
    FROM modeling.dim_plant
),

-- All carrier options per order
carrier_options AS (
    SELECT
        o.order_id,
        o.plant_id,
        o.origin_port_id,
        o.destination_port_id,
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

-- Total logistics cost
total_costs AS (
    SELECT
        c.order_id,
        c.plant_id,
        c.origin_port_id,
        c.destination_port_id,
        c.historical_carrier,
        c.carrier_id,
        c.transport_cost,
        c.unit_quantity * w.cost_per_unit AS warehouse_cost,
        c.transport_cost + (c.unit_quantity * w.cost_per_unit) AS total_order_cost
    FROM carrier_options c
    JOIN warehouse_costs w
        ON c.plant_id = w.plant_key
),

-- Optimal carrier selection
optimal_assignment AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY total_order_cost ASC
        ) AS rn
    FROM total_costs
),

optimal_orders AS (
    SELECT
        order_id,
        plant_id,
        origin_port_id,
        destination_port_id
    FROM optimal_assignment
    WHERE rn = 1
),

-- Historical shipment distribution
historical_routes AS (
    SELECT
        plant_id,
        origin_port_id,
        destination_port_id,
        COUNT(*) AS historical_orders
    FROM orderList_info
    GROUP BY
        plant_id,
        origin_port_id,
        destination_port_id
),

-- Optimized shipment distribution
optimized_routes AS (
    SELECT
        plant_id,
        origin_port_id,
        destination_port_id,
        COUNT(*) AS optimal_orders
    FROM optimal_orders
    GROUP BY
        plant_id,
        origin_port_id,
        destination_port_id
)

SELECT
    COALESCE(h.plant_id, o.plant_id) AS plant_id,
    COALESCE(h.origin_port_id, o.origin_port_id) AS origin_port_id,
    COALESCE(h.destination_port_id, o.destination_port_id) AS destination_port_id,
    COALESCE(h.historical_orders,0) AS historical_orders,
    COALESCE(o.optimal_orders,0) AS optimal_orders,
    COALESCE(o.optimal_orders,0) - COALESCE(h.historical_orders,0) AS change_in_orders
FROM historical_routes h
FULL JOIN optimized_routes o
    ON h.plant_id = o.plant_id
    AND h.origin_port_id = o.origin_port_id
    AND h.destination_port_id = o.destination_port_id
ORDER BY change_in_orders DESC;