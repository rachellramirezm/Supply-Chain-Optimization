--CREATE DATABASE supply_chain

CREATE SCHEMA IF NOT EXISTS staging;

CREATE TABLE staging.plant_port (
	plant_code TEXT,
	port TEXT
);

CREATE TABLE staging.vmi_customers (
	plant_code TEXT,
	customer_id TEXT
);

CREATE TABLE staging.products_per_plant (
	plant_code TEXT,
	product_id INT
);

CREATE TABLE staging.wh_capacities (
	plant_id TEXT,
	daily_capacity INT
);

CREATE TABLE staging.wh_costs (
	plant_code TEXT,
	cost_per_unit DECIMAL
);

CREATE TABLE staging.freight_rates (
	carrier_id TEXT,
	origin_port_code TEXT,
	destination_port_code TEXT,
	min_weight_quantity DECIMAL,
	max_weight_quantity DECIMAL,
	service_code TEXT,
	minimum_cost DECIMAL,
	rate DECIMAL,
	mode_description TEXT,
	transportation_day_count INT,
	carrier_type TEXT
);

CREATE TABLE staging.order_list (
	order_id INT,
	order_date DATE,
	origin_port TEXT,
	carrier TEXT,
	transportation_day_count INT,
	service_level TEXT,
	ship_ahead_day_count INT,
	ship_late_day_count INT,
	customer TEXT,
	product_id INT,
	plant_code TEXT,
	destination_port TEXT,
	unit_quantity INT,
	weight DECIMAL
);

