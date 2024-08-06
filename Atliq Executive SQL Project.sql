/*1.  Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
business in the  APAC  region. */

select distinct market from dim_customer
where customer = "Atliq Exclusive" 
and region = "APAC"; 

select count(distinct market) from dim_customer
where customer = "Atliq Exclusive" 
and region = "APAC"; 

/*.  2) What is the percentage of unique product increase in 2021 vs. 2020? The 
final output contains these fields, 
unique_products_2020 
unique_products_2021 
percentage_chg */

create table  dim_date as (
select date, fiscal_year,product_code,customer_code
from fact_sales_monthly);

WITH product_count_2021 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2021
    FROM dim_product
    JOIN dim_date USING(product_code)
    WHERE fiscal_year = '2021'
),
product_count_2020 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2020
    FROM dim_product
    JOIN dim_date USING(product_code)
    WHERE fiscal_year = '2020'
)
SELECT 
    product_count_2020.unique_products_2020,
    product_count_2021.unique_products_2021,
    CONCAT(
        ROUND(
            ((product_count_2021.unique_products_2021 - product_count_2020.unique_products_2020)
            / product_count_2020.unique_products_2020) * 100, 2), '%') AS percentage_chg
FROM product_count_2020,product_count_2021;



/* 3)Provide a report with all the unique product counts for each  segment  and 
sort them in descending order of product counts. The final output contains 
2 fields, 
segment 
product_count */

select segment, count(distinct product_code) product_count
from dim_product
group by segment
order by product_count desc;


/*4)Follow-up: Which segment had the most increase in unique products in 
2021 vs 2020?
 The final output contains these fields, 
segment 
product_count_2020 
product_count_2021 
difference */
WITH product_count_2020 AS (
select segment, count(distinct product_code) product_count_2020
from dim_product
join dim_date
using (product_code)
WHERE fiscal_year = '2020'
group by segment
order by product_count_2020 desc
),
product_count_2021 AS (
select segment, count(distinct product_code) product_count_2021
from dim_product
join dim_date
using (product_code)
WHERE fiscal_year = '2021'
group by segment
order by product_count_2021 desc)
SELECT 
    segment,product_count_2020,
    product_count_2021 as difference,
    CONCAT(
        ROUND(
            ((product_count_2021 - product_count_2020)
            / product_count_2020) * 100, 2), '%') AS '&difference'
FROM product_count_2020
 join product_count_2021
 using(segment);
 
 
 
 
 /*5.)  Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, 
product_code 
product 
manufacturing_cost */

select product_code,product,manufacturing_cost
from dim_product
join fact_manufacturing_cost
using (product_code)
where manufacturing_cost in(
(select max(manufacturing_cost) from fact_manufacturing_cost),
(select min(manufacturing_cost) from fact_manufacturing_cost));



/*6.) Generate a report which contains the top 5 customers who received an 
average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
Indian  market. The final output contains these fields, 
customer_code 
customer 
average_discount_percentage */

select c.customer_code,customer,concat(round(avg(pre_invoice_discount_pct) * 100, 2),'&') average_discount_percentage
from dim_customer c 
join dim_date d
using (customer_code)
join fact_pre_invoice_deductions p
on p.customer_code = c.customer_code
and d.fiscal_year = p.fiscal_year
where market = "india"
and d.fiscal_year = 2021
group by c.customer_code,customer;



/*7.  Get the complete report of the Gross sales amount for the customer  “Atliq 
Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
high-performing months and take strategic decisions. 
The final report contains these columns: 
Month 
Year 
Gross sales Amount */

SELECT 
    MONTH(fsm.date) AS month, 
    fsm.fiscal_year AS year, 
    SUM(ROUND(gp.gross_price * fsm.sold_quantity, 2)) AS gross_sale_amount
FROM fact_sales_monthly fsm
JOIN fact_gross_price gp ON fsm.product_code = gp.product_code AND fsm.fiscal_year = gp.fiscal_year
JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
WHERE dc.customer = 'Atliq Exclusive'
GROUP BY MONTH(fsm.date), fsm.fiscal_year
ORDER BY year, month;


/*8.  In which quarter of 2020, got the maximum total_sold_quantity? The final 
output contains these fields sorted by the total_sold_quantity, 
Quarter 
total_sold_quantity */
select quarter(date) as Quarter, sum(sold_quantity) as total_sale_quantity
from fact_sales_monthly
where fiscal_year = 2020
group by quarter;


/*9.  Which channel helped to bring more gross sales in the fiscal year 2021 
and the percentage of contribution?  The final output  contains these fields, 
channel gross_sales_mln percentage */



WITH cte AS (SELECT channel, 
	SUM(ROUND((fsm.sold_quantity * p.gross_price) / 1000000, 2)) AS gross_sales_mln
    FROM dim_customer c
    JOIN fact_sales_monthly fsm ON c.customer_code = fsm.customer_code
    JOIN fact_gross_price p ON fsm.product_code = p.product_code AND fsm.fiscal_year = p.fiscal_year
    WHERE p.fiscal_year = 2021
    GROUP BY channel
)
SELECT channel, gross_sales_mln, 
CONCAT(ROUND(100 * (gross_sales_mln / SUM(gross_sales_mln) OVER ()), 2), '%') AS percentage
FROM cte
ORDER BY gross_sales_mln DESC;


/*10.  Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021? The final output contains these 
fields, 
division 
product_code */

with cte as(select division, product_code, sum(sold_quantity),dense_rank()over(partition by division order by sum(sold_quantity) desc)as 'rank'
from dim_product
join fact_sales_monthly
using (product_code)
group by division,product_code
)
select division,product_code
from cte 
where 'rank'< 4 




