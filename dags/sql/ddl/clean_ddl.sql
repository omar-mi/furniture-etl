drop schema if exists "clean_data" cascade;
create schema "clean_data";

drop table if exists "clean_data"."clean_customers";
drop table if exists "clean_data"."clean_furniture";
drop table if exists "clean_data"."clean_orders";
drop table if exists "clean_data"."clean_sales";

create table "clean_data"."clean_customers" (
  "customer_id" varchar,
  "first_name" varchar,
  "last_name" varchar,
  "email" varchar,
  "country" varchar,
  "signup_date" date
);

create table "clean_data"."clean_furniture" (
  "furniture_id" varchar,
  "product_name" varchar,
  "category" varchar,
  "material" varchar,
  "base_price" decimal
);

create table "clean_data"."clean_orders" (
  "order_id" varchar,
  "customer_id" varchar,
  "order_date" date,
  "order_status" varchar
);

create table "clean_data"."clean_sales" (
  "sale_id" varchar,
  "order_id" varchar,
  "furniture_id" varchar,
  "quantity" int,
  "discount" decimal
);