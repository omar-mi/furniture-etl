select * 
from raw_data.raw_furniture;

# Check for duplicate furniture ids
# Result:
#   No duplicates
select * 
from (
    select
        *,
        row_number() over (partition by furniture_id order by furniture_id) as row_num
    from raw_data.raw_furniture
)
where row_num > 1;

# Check for missing values
# Result:
#   The "material" and "base_price" columns have null values
# Action:
#   - Replace null material with n/a
#   - Replace null price with average base_price of items with the same material
select
    sum(case when furniture_id is null then 1 else 0 end) as nulls_num_furniture_id,
    sum(case when product_name is null then 1 else 0 end) as nulls_num_product_name,
    sum(case when category is null then 1 else 0 end) as nulls_num_category,
    sum(case when material is null then 1 else 0 end) as nulls_num_material,
    sum(case when base_price is null then 1 else 0 end) as nulls_num_base_price
from raw_data.raw_furniture;

# Check for inconsistent categorical values
# Result:
#   Inconsistent letter capitalization
# Action:
#   Standardize values
select category
from raw_data.raw_furniture
group by category
order by category;