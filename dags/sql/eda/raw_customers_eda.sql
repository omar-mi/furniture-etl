-- Select all customers
select * 
from raw_data.raw_customers;

-- Check for duplicate customer ids
-- Result:
--   Some customers had their details stored more than once
-- Action:
--   We can safely remove duplicates based on customer_id
with dups as (
    select * 
    from (
        select
            *,
            row_number() over (partition by customer_id order by customer_id) as row_num
        from raw_data.raw_customers
    )
    where row_num > 1
)
select * 
from raw_data.raw_customers
where customer_id in (select customer_id from dups)
order by customer_id;

-- Check for missing values
-- Result:
--   The "email" column has a bunch of null values
-- Action:
--   Replace nulls with n/a
select
    sum(case when customer_id is null then 1 else 0 end) as nulls_num_customer_id,
    sum(case when first_name is null then 1 else 0 end) as nulls_num_first_name,
    sum(case when last_name is null then 1 else 0 end) as nulls_num_last_name,
    sum(case when email is null then 1 else 0 end) as nulls_num_email,
    sum(case when country is null then 1 else 0 end) as nulls_num_country,
    sum(case when signup_date is null then 1 else 0 end) as nulls_num_signup_date
from raw_data.raw_customers;

-- Check for inconsistent categorical values
-- Result:
--   Same value is represented differently for some entries:
--      - Leading & trailing space
--      - Inconsistent letter capitalization
-- Action:
--   Standardize values
select country
from raw_data.raw_customers
group by country
order by country;

-- Final notes:
--   The signup_date column has inconsistent date formats