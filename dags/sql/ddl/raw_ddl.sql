drop schema if exists "raw_data" cascade;
create schema "raw_data";

drop table if exists "raw_data"."raw_customers";
drop table if exists "raw_data"."raw_furniture";
drop table if exists "raw_data"."raw_orders";
drop table if exists "raw_data"."raw_sales";

create table "raw_data"."raw_customers" (
  "customer_id" varchar,
  "first_name" varchar,
  "last_name" varchar,
  "email" varchar,
  "country" varchar,
  "signup_date" varchar
);

create table "raw_data"."raw_furniture" (
  "furniture_id" varchar,
  "product_name" varchar,
  "category" varchar,
  "material" varchar,
  "base_price" decimal
);

create table "raw_data"."raw_orders" (
  "order_id" varchar,
  "customer_id" varchar,
  "order_date" varchar,
  "order_status" varchar,
  "customer_country" varchar
);

create table "raw_data"."raw_sales" (
  "sale_id" varchar,
  "order_id" varchar,
  "furniture_id" varchar,
  "quantity" int,
  "discount" decimal,
  "total_price" decimal
);