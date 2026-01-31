insert into clean_data.clean_customers (
  customer_id,
  first_name,
  last_name,
  email,
  country,
  signup_date
)
select
  customer_id,
  first_name,
  last_name,
  coalesce(email, 'n/a'),
  initcap(lower(trim(country))),
  case
    when signup_date like '__/__/____' then to_date(signup_date, 'MM/DD/YYYY')
    when signup_date like '__-__-____' then to_date(signup_date, 'DD-MM-YYYY')
    when signup_date like '____-__-__' then to_date(signup_date, 'YYYY-MM-DD')
    else null
  end case
from (
    select
        *,
        row_number() over (partition by customer_id order by customer_id) as row_num
    from raw_data.raw_customers
)
where row_num = 1;

insert into clean_data.clean_furniture (
  furniture_id,
  product_name,
  category,
  material,
  base_price
)
select
  furniture_id,
  product_name,
  category,
  coalesce(material, 'n/a'),
  coalesce(
    base_price,
    (
        select round(avg(sf.base_price), 2)
        from raw_data.raw_furniture sf
        where sf.material = f.material
    ),
    (
        select round(avg(sf.base_price), 2)
        from raw_data.raw_furniture sf
        where sf.category = f.category
    )
  )
from raw_data.raw_furniture f;

insert into clean_data.clean_orders (
  order_id,
  customer_id,
  order_date,
  order_status
)
select
  order_id,
  customer_id,
  case
    when order_date like '__/__/____' then to_date(order_date, 'MM/DD/YYYY')
    when order_date like '__-__-____' then to_date(order_date, 'DD-MM-YYYY')
    when order_date like '____-__-__' then to_date(order_date, 'YYYY-MM-DD')
    else null
  end case,
  order_status
from raw_data.raw_orders;

insert into clean_data.clean_sales (
  sale_id,
  order_id,
  furniture_id,
  quantity,
  discount
)
select
  s.sale_id,
  s.order_id,
  s.furniture_id,
  abs(s.quantity),
  s.discount
from (
    select
        *,
        row_number() over (partition by sale_id order by sale_id) as row_num
    from raw_data.raw_sales
) s
join clean_data.clean_orders o
    on s.order_id = o.order_id
where row_num = 1 and s.quantity <> 0 and o.order_status <> 'CANCELLED';