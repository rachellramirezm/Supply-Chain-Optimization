WITH order_info AS (
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

freight_rates AS (
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

-- Generate all possible carrier options for each order
all_route_options AS (
    SELECT
        o.order_id,
        o.plant_id,
        o.origin_port_id,
        o.destination_port_id,
        o.service_level,
        o.historical_carrier,
        f.carrier_key AS alternative_carrier,
        o.total_weight,
        o.unit_quantity,
        CASE
            WHEN f.carrier_key = 1 OR f.rate IS NULL THEN 0
            ELSE GREATEST(
                o.total_weight * f.rate,
                COALESCE(f.minimum_cost,0)
            )
        END AS transport_cost
    FROM order_info o
    JOIN freight_rates f
        ON o.origin_port_id = f.origin_port_key
        AND o.destination_port_id = f.destination_port_key
        AND o.service_level = f.service_level
        AND o.total_weight BETWEEN f.min_weight AND f.max_weight
),

-- Add warehouse handling cost
total_route_costs AS (
    SELECT
        a.order_id,
        a.origin_port_id,
        a.destination_port_id,
        a.service_level,
        a.historical_carrier,
        a.alternative_carrier,
        a.transport_cost + (a.unit_quantity * w.cost_per_unit) AS total_cost
    FROM all_route_options a
    JOIN modeling.dim_plant w
        ON a.plant_id = w.plant_key
),

-- Historical route cost
historical_cost AS (
    SELECT
        order_id,
        origin_port_id,
        destination_port_id,
        service_level,
        historical_carrier,
        total_cost AS historical_total_cost
    FROM total_route_costs
    WHERE historical_carrier = alternative_carrier
),

-- Find cheapest carrier for each order
cheapest_option AS (
    SELECT
        order_id,
        origin_port_id,
        destination_port_id,
        service_level,
        alternative_carrier,
        total_cost AS cheapest_possible_cost,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY total_cost ASC
        ) AS rn
    FROM total_route_costs
)

SELECT
    h.order_id,
    h.origin_port_id,
    h.destination_port_id,
    h.service_level,
    h.historical_carrier,
    c.alternative_carrier AS cheaper_carrier,
    h.historical_total_cost,
    c.cheapest_possible_cost,
    h.historical_total_cost - c.cheapest_possible_cost AS potential_savings
FROM historical_cost h
JOIN cheapest_option c
    ON h.order_id = c.order_id
WHERE
    c.rn = 1
    AND h.historical_total_cost > c.cheapest_possible_cost
ORDER BY potential_savings DESC;