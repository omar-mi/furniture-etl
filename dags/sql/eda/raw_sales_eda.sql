select * 
from raw_data.raw_sales;

# Check for duplicate sale ids
# Result:
#   Multiple sales had the same id with same details
# Action:
#   We can safely remove duplicates based on sale_id
with dups as (
    select * 
    from (
        select
            *,
            row_number() over (partition by sale_id order by sale_id) as row_num
        from raw_data.raw_sales
    )
    where row_num > 1
)
select * 
from raw_data.raw_sales
where sale_id in (select sale_id from dups)
order by sale_id;

# Check for missing values
# Result:
#   The entire total_price column is null which means it still needs to be calculated
# Action:
#   Exclude this column for now and calculate it later
select
    sum(case when sale_id is null then 1 else 0 end) as nulls_num_sale_id,
    sum(case when order_id is null then 1 else 0 end) as nulls_num_order_id,
    sum(case when furniture_id is null then 1 else 0 end) as nulls_num_furniture_id,
    sum(case when quantity is null then 1 else 0 end) as nulls_num_quantity,
    sum(case when discount is null then 1 else 0 end) as nulls_num_discount,
    sum(case when total_price is null then 1 else 0 end) as nulls_num_total_price
from raw_data.raw_sales;

# Check for invalid values
# Result:
#   Some sales had quantities equal to or less than 0
# Action:
#   - Sales with zero quantities are considered invalid orders and are removed
#   - Sales with negative quantities are converted into positive ones
select *
from raw_data.raw_sales
where quantity <= 0;

select *
from raw_data.raw_sales
where discount < 0;

# Check if some sales belong to cancelled orders
# Result:
#   There is
# Action:
#   Remove them
select
    s.sale_id,
    o.order_id,
    o.order_status
from raw_data.raw_sales as s
join raw_data.raw_orders as o
    on s.order_id = o.order_id
where o.order_status = 'CANCELLED';