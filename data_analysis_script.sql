--0. RAW SALES DATA --data we'll be working with
select *
from sales_data_sample


--1. OVERVIEW OF DATA --inspect unique values of columns

--order specific data
select distinct STATUS
from sales_data_sample
select distinct YEAR_ID
from sales_data_sample
order by year_id desc
--product specific data
select distinct PRODUCTLINE
from sales_data_sample
select distinct DEALSIZE
from sales_data_sample
--regional data
select distinct CITY
from sales_data_sample
order by city asc
select distinct COUNTRY
from sales_data_sample
order by country asc
select distinct TERRITORY
from sales_data_sample
order by territory asc


--2. ANALYSIS OF DATA --what do we want to know

--sales performance by product line?
select PRODUCTLINE, sum(SALES) Revenue
from sales_data_sample
group by productline
order by 2 desc
--sales performance by dealsize?
select DEALSIZE, sum(SALES) Revenue
from sales_data_sample
group by dealsize
order by 2 desc
--sales performance by country?
select COUNTRY, sum(SALES) Revenue
from sales_data_sample
group by country
order by 2 desc
--sales performance by shipping status?
select STATUS, sum(SALES) Revenue
from sales_data_sample
group by status
order by 2 desc
--units by product?
select PRODUCTLINE, count(ORDERNUMBER) Units
from sales_data_sample
group by productline
order by 2 desc
--units by country?
select COUNTRY, count(ORDERNUMBER) Units
from sales_data_sample
group by country
order by 2 desc
--units by shipping status?
select STATUS, count(ORDERNUMBER) Units
from sales_data_sample
group by status
order by 2 desc

--what city has the top sales out of all countries?
select CITY, COUNTRY, sum(SALES) Revenue
from sales_data_sample
group by city, country
order by 3 desc
--what city has most units sold out of all countries?
select CITY, COUNTRY, count(ORDERNUMBER) Units
from sales_data_sample
group by city, country
order by 3 desc

--what city has the top sales in a given country?
select CITY, COUNTRY, sum(SALES) Revenue
from sales_data_sample
where country = 'USA'
group by city, country
order by 3 desc
--what product sells the most in the USA?
select COUNTRY, YEAR_ID, PRODUCTLINE, sum(SALES) Revenue
from sales_data_sample
where country = 'USA'
group by country, year_id, productline
order by 4 desc

--sales performance by year?
select YEAR_ID, sum(SALES) Revenue
from sales_data_sample
group by year_id
order by 2 desc
--units sold by year?
select YEAR_ID, count(ORDERNUMBER) Units
from sales_data_sample
group by year_id
order by 2 desc
---check revenue (2005 significantly lower)
select distinct MONTH_ID
from sales_data_sample
where year_id = '2005'
---2005 only recorded the first 5 months of the year
--top performing sales month by given year? 
select MONTH_ID, sum(SALES) Revenue
from sales_data_sample
where year_id = '2004' --change to see each year
group by month_id
order by 2 desc
---november was best performing month (holiday season?)
--what product's sales performance was highest in november?
select MONTH_ID, PRODUCTLINE, sum(SALES) Revenue, count(ORDERNUMBER) Unit_Sales
from sales_data_sample
where month_id = '11' and year_id = '2004' --change to see each year
group by month_id, productline
order by 3 desc
---classic cars exceed in both revenue and unit_sales for the month of november
--find avg month that exceeds in sales by using (!=) operator to exclude 2005
select MONTH_ID, avg(SALES) Revenue
from sales_data_sample
where year_id != '2005'
group by month_id
order by 2 desc


--3. RFM ANALYSIS --use to find who our best customer is
---RFM = marketing technique to analyze customer behavior based on 3 factors: Recency (how recent did they buy), Frequency (how frequently do they buy), Monetary value (how much did they spend))

--3a.
; with rfm as --this turns below function to CTE
(
	select
		CUSTOMERNAME
		,COUNTRY
		,CITY
		,max(ORDERNUMBER) last_order_date
		,(select max (ORDERDATE) from sales_data_sample) max_order_date
		,DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from sales_data_sample)) recency_score --date difference between max_order_date and last_order_date in dataset to determine Recency
		,count(ORDERNUMBER) frequency_score --counting frequency of orders to determine Frequency
		,avg(SALES) avg_monetary_score
		,sum(SALES) monetary_score --aggregate revenue to determine Monetary Value
	from sales_data_sample
	group by CUSTOMERNAME, COUNTRY, CITY
)

--3b. 
, rfm_scores as --this turns below function to another cte
(

	select r.*, --r is the alias for the cte: rfm
		NTILE(4) OVER (order by recency_score desc) R,
		NTILE(4) OVER (order by frequency_score asc) F,
		NTILE(4) OVER (order by monetary_score asc) M
	from rfm r
)

	select c.* --c is the alias for the cte: rfm_scores
	,R + F + M as rfm_cell
	,cast(R as varchar) + cast(F as varchar) + cast(M as varchar) rfm_cell_string
	into #rfm --#rfm is a temp table with the columns used in the rfm_scores cte
	from rfm_scores c

--3d. rfm_index uses #rfm CTE
select CUSTOMERNAME, COUNTRY, CITY, R, F, M,
	case
		when R=4 or R=3 and F=4 or F=3 and M=4 or F=3 then '1 Champions'
		when R=3 or R=2 and F=3 or F=2 and M=3 then '2 Potential Loyalist'
		when R=1 or R=2 and F=1 or F=2 and M=4 or M=3 then '3 Cannot Lose Them'
		when R=4 or R=3 and F=1 or F=2 and M=1 or M=2 then '4 New Customers'
		when R=1 or R=2 and F=4 or F=3 and M=4 or M=3 then '5 At Risk Customers'
	end rfm_index
from #rfm
order by 7 asc
