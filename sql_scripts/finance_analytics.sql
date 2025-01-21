-- ================================================================================

#TASK-1
#as a product owner, I want to generate a report of individual product sales (aggregated on a monthly as a basis at the product code level) for Croma India customer for FY=2021 so that I can track individual product sales and run further product analytics on it in excel. report should have following fields
-- Month (date represents month, its already aggregated)
-- Product Name
-- Variant
-- Sold Quantity
-- Gross Price per Item
-- Gross Price Total

select sm.date,sm.product_code,p.product,p.variant,sm.sold_quantity, round(gross_price,2) as gross_price,
       round(sm.sold_quantity * gross_price,2) as gross_sales
from fact_sales_monthly sm
join dim_product p on sm.product_code = p.product_code
join fact_gross_price gp on sm.product_code = gp.product_code
                        and gp.fiscal_year=get_fiscal_year(sm.date) # fiscsl year also need to be linked
where customer_code= 90002002 and
      get_fiscal_year(date)=2021
order by date asc;

-- ================================================================================

#TASK-2
#as product owner, I need an aggregate monthly gross sales report for Croma India customer so that I can track how much sales this particular customer is generating for AtliQ and manage our relationships accordingly.
#The report should have the following fields,
#1. Month
#2. Total gross sales amount to Croma India in this month

select sm.date,sum(sm.sold_quantity) as quantity, round(sum(gross_price),2) as gross_price,
       round(sum(sm.sold_quantity * gross_price),2) as gross_price_total
from fact_sales_monthly sm
join dim_product p on sm.product_code = p.product_code
join fact_gross_price gp on sm.product_code = gp.product_code
                        and gp.fiscal_year=get_fiscal_year(sm.date) # fiscsl year also need to be linked
where customer_code= 90002002
group by sm.date
order by date asc;

-- ================================================================================

#TASK-3
#Generate a yearly report for Croma India where there are two columns
# 1. Fiscal Year
# 2. Total Gross Sales amount In that year from Croma

select get_fiscal_year(date) as fiscal_year,
       sum(fsm.sold_quantity) as quantity,
       round(sum(gp.gross_price),2) as gross_price,
       round(sum(fsm.sold_quantity*gp.gross_price),2) as total_gross_sales

from fact_sales_monthly fsm
join fact_gross_price gp on fsm.product_code = gp.product_code and
                            get_fiscal_year(fsm.date) = gp.fiscal_year
where customer_code = 90002002
group by get_fiscal_year(date);

-- ================================================================================

#TASK-4
#As a data analyst, I want to create a stored proc for monthly gross sales report so that I don't have to manually modify the query every time. Stored proc can be run by other users to (who have limited access to database) and they can generate this report without having to involve data analytics team.
#The report should have the following columns,
# 1. Month
# 2. Total gross sales in that month from a given customer

set @in_customer_code ='90002008,90002016'; #croma = 90002002, amazon_india = 90002008,90002016
call get_monthly_gross_sales_for_customer(@in_customer_code);

-- ================================================================================


#TASK-5
#Create a stored proc that can determine the market badge based on the following logic,
# If total sold quantity > 5 million that market is considered Gold else it is Silver
# My input will be (market, fiscal)
# Output (market badge)

set @in_market = 'india';
set @in_fiscal_year = 2021;
call get_market_badge(
        @in_market,
        @in_fiscal_year,
        @out_badge
     );
select @out_badge;

-- ================================================================================








