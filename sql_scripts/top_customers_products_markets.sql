# As a product owner, I want a report for top (markets, products, customers) by [net sales] for a given [financial year] so that I can have a holistic view of our financial performance and can take appropriate actions to address any potential issues.
#TASK-6


#created pre_discounts view
select * from sales_pre_discount;

-- ================================================================================

#created post_discounts view
select * from sales_post_discount;

-- ================================================================================

#created net_sales view
select * from net_sales;

-- ================================================================================

#created gross_sales view
select * from gross_sales;

-- ================================================================================

#top n market by net sales
set @fiscal_year = 2021;
set @top_n = 5;
call get_top_n_markets_by_net_sales(
        @fiscal_year,
        @top_n
     );

#top n customer by net sales
set @market = 'bangladesh';
set @fiscal_year = 2021;
set @top_n = 3;
call get_top_n_customers_by_net_sales(
        @market,
        @fiscal_year,
        @top_n
     );

#top n products by net sales
set @fiscal_year = 2021;
set @top_n = 5;
call get_top_n_products_by_net_sales(
        @fiscal_year,
        @top_n
     );

-- ================================================================================

#TASK 7
#As a product owner, I want to see a bar chart report for FY=2021 for top 10 markets by % net sales. It should look something like this,

with cte1 as(
select customer,
       round(sum(ns.net_sales)/1000000,2) as net_sales_mln # sum of all net_sales_mln 823.90
from net_sales ns
join dim_customer c on ns.customer_code = c.customer_code
where fiscal_year = 2021
group by customer
)
select customer,
       net_sales_mln,
       round(net_sales_mln * 100 / sum(net_sales_mln) over (), 2) as market_share_pct
from cte1
order by market_share_pct desc
limit 10; #market e ase sob player, dekhacchi 10 tar
#check 'top_10_customer_by_market_share%' csv in dumps

-- ================================================================================

#TASK 8
# As a product owner, I want to see region wise (APAC, EU, L TAM etc) % net sales breakdown by customers in a respective region so that I can perform my regional analysis on financial performance of the company.
# The end result should be bar charts in the following format for FY-2021. Build a reusable asset that we can use to conduct this analysis for any financial year.

with cte2 as(
select region,
       customer,
       round(sum(ns.net_sales)/1000000,2) as net_sales_mln # sum of all net_sales_mln 823.90
from net_sales ns
join dim_customer c on ns.customer_code = c.customer_code
where fiscal_year = 2021 and region = 'EU'
group by region,customer
order by net_sales_mln desc
limit 10 #market e asei 10 player, if used in next part, market_share_pct total wont be 100
)
select concat(customer,' - ',region) as customer_region,
       net_sales_mln,
       round(net_sales_mln * 100 / sum(net_sales_mln) over ()) as market_share_pct
from cte2
order by market_share_pct desc
;

#all in one
with cte2 as(
select region,
       customer,
       round(sum(ns.net_sales)/1000000,2) as net_sales_mln # sum of all net_sales_mln 823.90
from net_sales ns
join dim_customer c on ns.customer_code = c.customer_code
where fiscal_year = 2021
group by region,customer
order by net_sales_mln desc
)
select region,
       customer,
       net_sales_mln,
       round(net_sales_mln * 100 / sum(net_sales_mln) over (partition by region),2) as market_share_pct
from cte2
order by region,market_share_pct desc;
#check 'market_share%_by_region_customer' csv in dumps

-- ================================================================================
#TASK 9
#Write a stored proc for getting TOP n products in each division by their quantity sold in a given financial year. For example below would be the result for FY=2021,

set @fiscal_year = 2021;
set @top_n = 3;
call get_top_n_products_per_division_by_qty_sold(
        @fiscal_year,
        @top_n
     );

-- ================================================================================
#TASK 10
#Retrieve the top 2 markets in every region by their gross sales amount in FY=2021

DELIMITER $$

CREATE PROCEDURE get_top_n_market_per_region_by_gross_sales(
    IN fiscal_year INT,
    IN top_n INT
)
BEGIN
    WITH cte1 AS (SELECT g.market,
                         region,
                         ROUND(SUM(gross_price_total / 1000000), 2) AS gross_sales_mln
                  FROM gross_sales g
                           JOIN dim_customer c ON g.customer_code = c.customer_code
                  WHERE g.fiscal_year = fiscal_year #is fiscal_year = fiscal_year used, will give wrong value cuz wont recognize colmn
                  GROUP BY region, g.market),
         cte2 AS (SELECT *,
                         DENSE_RANK() OVER (PARTITION BY region ORDER BY gross_sales_mln DESC) AS ranking
                  FROM cte1)
    SELECT *
    FROM cte2
    WHERE ranking <= top_n;
END$$

DELIMITER ;

-- ================================================================================

set @fiscal_year = 2021;
set @top_n = 2;
call get_top_n_market_per_region_by_gross_sales(
        @fiscal_year,
        @top_n
     );


