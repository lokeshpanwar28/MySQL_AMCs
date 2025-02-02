use AMCs;

select inception_date from funds;

UPDATE funds
SET inception_date = STR_TO_DATE(inception_date, '%Y-%m-%d');

ALTER TABLE funds 
MODIFY COLUMN inception_date DATE;

-- 1. Fund Performance Analysis
-- Q1: Retrieve the top 10 funds with the highest 5-year return.
select a.amc_name, f.fund_name, fs.`5yr_return` as returen_5year
from fund_performance fs
inner join funds f
on f.fund_id = fs.fund_id
inner join amcs a
on f.amc_id = a.amc_id
order by returen_5year DESC
limit 10;
-- Q2: Find the average NAV and expense ratio for each category of mutual funds.
select c.category_name, round(avg(fp.nav),2) as avg_nav, round(avg(fp.expense_ratio),2) as avg_exp_ratio 
from fund_performance fp
join funds f
on f.fund_id = fp.fund_id
join categories c
on f.category_id = c.category_id
group by c.category_name;
-- 2. Risk vs Return Analysis
-- Q3: Identify funds with high risk rating but low 5-year return (less than 10%).
select a.amc_name, f.fund_name,fp.`5yr_return`, rr.risk_level
from fund_performance fp
join funds f
on f.fund_id=fp.fund_id
join amcs a
on f.amc_id=a.amc_id
join risk_ratings rr
on f.risk_rating_id=rr.risk_rating_id
where fp.`5yr_return` < .1
having rr.risk_level in ('High','Very High');
-- Q4: Compare average returns for different risk categories.
select rr.risk_level, round(avg(fp.`1yr_return`),2) as returns_1yr,
 round(avg(fp.`3yr_return`),2) as returns_3yr, 
 round(avg(fp.`5yr_return`),2) as returns_5yr
from fund_performance fp
join funds f
on f.fund_id = fp.fund_id
join risk_ratings rr
on rr.risk_rating_id=f.risk_rating_id
group by rr.risk_level
order by case
when rr.risk_level='Very High' then 1
when rr.risk_level='High' then 2
when rr.risk_level='Moderate' then 3
else 4
end;
-- 3. AMC & AUM Insights
-- Q5: List AMCs managing funds with total AUM greater than ₹10,000 Cr.
select a.amc_name, round(sum(fp.aum_in_cr),2) as total_AUM
from fund_performance fp
join funds f
on f.fund_id=fp.fund_id
join amcs a
on f.amc_id = a.amc_id
group by a.amc_name
having total_AUM > 10000;
-- Q6: Identify AMCs with highest average return over 5 years.
select a.amc_name, round(avg(fp.`5yr_return`),2) as avg_5yr_return
from fund_performance fp
join funds f
on f.fund_id=fp.fund_id
join amcs a
on f.amc_id = a.amc_id
group by a.amc_name
order by avg_5yr_return desc;
-- 4. Expense Ratio & Return Correlation
-- Q7: Check if funds with higher expense ratios have better returns.
select case 
when fp.expense_ratio < 1 then 'Low'
when fp.expense_ratio between 1 and 1.5 then 'Moderate'
when fp.expense_ratio between 1.5 and 2 then 'Medium'
when fp.expense_ratio between 2 and 2.5 then 'High'
else 'Very High' 
end as exp_ratio_category, round(avg(fp.`1yr_return`),2) as returns_1year, round(avg(fp.`3yr_return`),2) as returns_3year, round(avg(fp.`5yr_return`),2) as returns_5year
from fund_performance fp
group by exp_ratio_category
order by returns_5year desc;
-- 5. Fund Inception & Longevity Analysis
-- Q8: Find the oldest 10 mutual funds still active today.funds
select fund_name, inception_date
from funds
order by inception_date asc
limit 10;
-- Q9: Count the number of mutual funds launched per year.
select year(inception_date), count(*) 
from funds
group by year(inception_date)
order by year(inception_date);

-- Count the number of mutual funds launched per year per AMCs
select a.amc_name, year(f.inception_date) as launch_year, count(f.fund_name) as num_fund
from funds f
join amcs a
on f. amc_id=a.amc_id
group by year(f.inception_date), a.amc_name
order by year(f.inception_date);
-- 6. Benchmark Performance Analysis
-- Q10: Compare mutual fund performance against their benchmarks.
select b.benchmark_name, round(avg(fp.`1yr_return`),2) as returns_1year, round(avg(fp.`3yr_return`),2) as returns_3year, round(avg(fp.`5yr_return`),2) as returns_5year
from fund_performance fp
join funds f
on fp.fund_id=f.fund_id
join benchmarks b
on f.benchmark_id=b.benchmark_id
group by b.benchmark_name;
-- 7. Outlier & Anomaly Detection
-- Q11: Identify funds with exceptionally high or low returns (possible anomalies).
select f.fund_name, fp.`1yr_return`, fp.`3yr_return`, fp.`5yr_return`
from fund_performance fp
join funds f
on fp.fund_id = f.fund_id
where fp.`1yr_return` > (select avg(`1yr_return`) + 2 * stddev(`1yr_return`) from fund_performance)
or fp.`1yr_return` < (select avg(`1yr_return`) - 2 * stddev(`1yr_return`) from fund_performance);

-- 8. Diversification Insights
-- Q12: Find the most diversified AMCs (AMCs managing funds across multiple categories).
select a.amc_name ,count(DISTINCT f.category_id) as type_fund
from funds f
join amcs a
on a.amc_id=f.amc_id
group by a.amc_name;