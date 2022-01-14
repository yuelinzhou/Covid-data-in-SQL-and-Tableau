/*
Covid Data Exploration project 
Time range is between 1/22/2020 to 1/11/2022 
Skills used: Joins, CTE, subqueries, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- First, I'm interested in the Covid cases situation
select * 
from covid_data_cases
Where continent is not null 
order by location,date


-- Death rates in the US 
-- shows the likelihood of dying if you got covid in the US 
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
From covid_data_cases
Where location  = 'United States'
order by location, date

-- Average death rates in the US by year 
select year, avg(Death_Percentage) as Average_Death_Rates 
from
(Select DATEPART(year, date) as year , total_cases,total_deaths,  (total_deaths/total_cases)*100 as Death_Percentage
From covid_data_cases
Where location  = 'United States') as subquery
group by year
order by year

-- Total Cases within the US Population
-- Shows what percentage of population infected with Covid
Select Location, date, Population, total_cases,  (total_cases/population)*100 as Percent_Population_Infected
From covid_data_cases
Where location  = 'United States'
order by location, date

-- Compare Countries with Highest infection rates in population
Select Location, population, max(total_cases) as higest_cases, max((total_cases/population))*100 as Percent_Population_Infected       
From covid_data_cases
Where continent is not null 
group by location, Population
order by Percent_Population_Infected  desc

-- Global situation
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as Death_Percentage
From covid_data_cases
where continent is not null 
Group By date
order by date

-- Next, I'm interested in the vaccinations situation
select * 
from covid_data_vaccination
Where continent is not null 
order by location,date

-- Vaccinations situation in the US
select location, date, total_vaccinations,people_vaccinated,people_fully_vaccinated,total_boosters, population
from covid_data_vaccination
Where location  = 'United States' and total_vaccinations is not null
order by date

-- Shows Percentage of Population that has fully vaccinated (2 shots) or has recieved the booster (3 shots) in th US
select location, date, people_fully_vaccinated,
COALESCE(total_boosters, 0) as total_boosters, population, 
((people_fully_vaccinated + COALESCE(total_boosters, 0))/population )*100 as Percentage_of_2or3_shots
from covid_data_vaccination
Where location  = 'United States' and people_fully_vaccinated is not null
order by date

-- Shows Percentage of Population that has recieved the booster (3 shots) in all countries on 1/12/2022
select location,COALESCE(total_boosters, 0) as total_boosters, population, 
(COALESCE(total_boosters, 0)/population )*100 as Percentage_of_3_shots
from covid_data_vaccination
Where continent is not null and date = '01/12/2022'
order by location, date

-- Show number of new vaccinations per day in all countries
-- Show percentage of populaion people vaccinations per day in all countries
-- Use CTE
with vacc_per_day (continent, location, date,year,population ,new_vaccinations, total_People_Vaccinated ) as
(Select continent, location, date, DATEPART(year, date) as year, population, new_vaccinations,
sum(cast(new_vaccinations as bigint)) over (partition by location order by location, date) as total_People_Vaccinated 
From covid_data_vaccination
Where continent is not null )

select *, (new_vaccinations/ population)*100 as percentage_populaion_vaccinations_per_day
from vacc_per_day
-- where location in('China', 'United States',....so on)
order by location,date;

-- Show the average new vaccinations per day in each country by year
-- Use CTE
with vacc_per_day2 as (
Select location, date, DATEPART(year, date) as year,COALESCE(new_vaccinations, 0) as new_vaccinations
From covid_data_vaccination
Where continent is not null )

select location,year, avg(cast(new_vaccinations as bigint)) as average_new_vacconations_per_day
from vacc_per_day2
-- where location in('China', 'United States',....so on)
group by location, year
order by location,year

-- Relationship between new cases per day and new vaccinations per day
-- will use this dataset for scatter plot and find out their correlations

select cases.location,cases.date, cases.population, cast(new_cases as int) as new_cases_per_day, 
COALESCE(new_vaccinations, 0) as new_vaccinations_per_day
from covid_data_cases as cases
join covid_data_vaccination as vacc
on cases.location = vacc.location 
and cases.date = vacc.date

-- Using Temp Table 
DROP Table if exists average_newvaccinations_by_year
Create Table average_newvaccinations_by_year
(
location nvarchar(255),
year int,
average_new_vacconations_per_day numeric
)

Insert into  average_newvaccinations_by_year
select location,year, avg(cast(new_vaccinations as bigint)) as average_new_vacconations_per_day
from 
(Select location, date, DATEPART(year, date) as year,COALESCE(new_vaccinations, 0) as new_vaccinations
From covid_data_vaccination
Where continent is not null) as sub
group by location, year


select * from average_newvaccinations_by_year

-- Creating View to store data for visualizations in Tableau/Power BI
Create View average_new_vaccinations_by_year as 
select location,year, avg(cast(new_vaccinations as bigint)) as average_new_vacconations_per_day
from 
(Select location, date, DATEPART(year, date) as year,COALESCE(new_vaccinations, 0) as new_vaccinations
From covid_data_vaccination
Where continent is not null) as sub
group by location, year