#creating helper table for (sold_q + forecast_q) (for data engineers)
#did full outer join of those 2 tables

select * from fact_actual_forecast;

#setting 0 for nulls cuz why not
UPDATE fact_actual_forecast
SET forecast_quantity = 0
WHERE forecast_quantity IS NULL;

UPDATE fact_actual_forecast
SET sold_quantity = 0
WHERE sold_quantity IS NULL;

-- ================================================================================

#trigger: updating fact_actual_forecast if new records inserted into fact_sales_monthly,fact_forecast_monthly
#(for data engineers)

show triggers ;
-- ================================================================================

-- Inserting data into fact_sales_monthly for specific columns (for trigger testing)
INSERT INTO fact_sales_monthly (date, product_code, customer_code, sold_quantity)
VALUES ('2030-09-027', 123, 123, 69);

INSERT INTO fact_forecast_monthly (date, product_code, customer_code, forecast_quantity)
VALUES ('2030-09-027', 69, 69, 69);

-- ================================================================================

#TASK 11
#As a product owner, I need an aggregate forecast accuracy report for all the customers for a given fiscal year so that I can track the accuracy of the forecast we make for these customers.
#The report should have the following fields,
#1, Customer Code, Name, Market 2. Total Sold Quantity 3. Total Forecast Quantity 4. Net Error 5. Absolute Error 6. Forecast Accuracy %

#using CTE
with cte1 as (
    select customer_code,
           sum(sold_quantity) as total_sold_qty,
           sum(forecast_quantity) as total_forecast_qty,
           sum(forecast_quantity - sold_quantity) as net_error,
           round((sum(forecast_quantity - sold_quantity) * 100 / sum(forecast_quantity)),1) as net_error_pct,
           sum(abs(forecast_quantity - sold_quantity)) as abs_error,
           round((sum(abs(forecast_quantity - sold_quantity)) * 100 / sum(forecast_quantity)),1) as abs_error_pct
    from fact_actual_forecast
    where fiscal_year = 2021
    group by customer_code)

select cte1.customer_code,
       customer,
       market,
       total_sold_qty,
       total_forecast_qty,
       net_error,
       net_error_pct,
       abs_error,
       abs_error_pct,
       if(abs_error_pct>100,0,100-abs_error_pct) as forecast_accuracy

from cte1 join dim_customer c using(customer_code)
order by forecast_accuracy asc;

-- ================================================================================

#using Temporary Table
#N.B ctes can used inside temp table
create temporary table forecast_accuracy_table
    select customer_code,
           sum(sold_quantity) as total_sold_qty,
           sum(forecast_quantity) as total_forecast_qty,
           sum(forecast_quantity - sold_quantity) as net_error,
           round((sum(forecast_quantity - sold_quantity) * 100 / sum(forecast_quantity)),1) as net_error_pct,
           sum(abs(forecast_quantity - sold_quantity)) as abs_error,
           round((sum(abs(forecast_quantity - sold_quantity)) * 100 / sum(forecast_quantity)),1) as abs_error_pct
    from fact_actual_forecast
    where fiscal_year = 2021
    group by customer_code;

select fa.customer_code, customer, market, total_sold_qty, total_forecast_qty, net_error, net_error_pct, abs_error, abs_error_pct,
       if(abs_error_pct>100,0,100-abs_error_pct) as forecast_accuracy

from forecast_accuracy_table as fa join dim_customer c using(customer_code)
order by forecast_accuracy asc;

-- ================================================================================

#stored proc
set @in_fiscal_year = 2021;
call get_forecast_accuracy_by_fiscal_year(@in_fiscal_year);

-- ================================================================================

#TASK 12
#The supply chain business manager wants to see which customers’ forecast accuracy has dropped from 2020 to 2021. Provide a complete report with these columns: customer_code, customer_name, market, forecast_accuracy_2020, forecast_accuracy_2021

drop table if exists forecast_accuracy_2021;
create temporary table forecast_accuracy_2021
    select ac.customer_code,
           customer,
           round((sum(abs(forecast_quantity - sold_quantity)) * 100 / sum(forecast_quantity)),2) as abs_err_pct_2021
    from fact_actual_forecast ac join dim_customer c on ac.customer_code = c.customer_code
    where fiscal_year = 2021
    group by customer_code;

drop table if exists forecast_accuracy_2020;
create temporary table forecast_accuracy_2020
    select ac.customer_code,
           customer,
           round((sum(abs(forecast_quantity - sold_quantity)) * 100 / sum(forecast_quantity)),2) as abs_err_pct_2020
    from fact_actual_forecast ac join dim_customer c on ac.customer_code = c.customer_code
    where fiscal_year = 2020
    group by customer_code;

with cte1 as (
    select fa20.customer_code,
           fa20.customer,
           if(abs_err_pct_2020>100,0,100-fa20.abs_err_pct_2020) as forecast_accuracy_2020,
           if(abs_err_pct_2021>100,0,100-fa21.abs_err_pct_2021) as forecast_accuracy_2021
    from forecast_accuracy_2021 fa21
    join forecast_accuracy_2020 fa20 on fa21.customer_code = fa20.customer_code)

select * from cte1
where forecast_accuracy_2021<forecast_accuracy_2020 # which customers forecast accuracy has dropped from 2020 to 2021
order by forecast_accuracy_2020 desc
;






