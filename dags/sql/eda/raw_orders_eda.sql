select * 
from raw_data.raw_orders;

# Check for duplicate order ids
# Result:
#   No duplicates
select * 
from (
    select
        *,
        row_number() over (partition by order_id order by order_id) as row_num
    from raw_data.raw_orders
)
where row_num > 1;

# Check for inconsistent categorical values
# Result:
#   No inconsistencies
select order_status
from raw_data.raw_orders
group by order_status
order by order_status;

# Final notes:
#   - The order_date column has inconsistent date formats
#   - Exclude the customer_country column from clean_orders because it's repeated data
#     and can just be extracted using a join on the customer_id