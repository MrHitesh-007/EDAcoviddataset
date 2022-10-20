/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

select *
from dbo.covid_deaths$
order by 3,4;

select distinct location
from dbo.covid_deaths$
order by location

--select *
--from dbo.['owid-covid-data$']
--order by 3,4

select location,date,total_cases,new_cases,total_deaths,population
from dbo.covid_deaths$
order by 1,2;


--Looking at Total Cases vs Total Deaths
--Shows Likelihood of dying if you contract covid in India
select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 DeathPercentage
from dbo.covid_deaths$
where location like 'India'
order by 1,2

--Looking at Total Cases vs Population
--Shows What percentage of population got covid

select location,date,population,total_cases,(total_cases/population)*100 PercentPopulationInfected
from dbo.covid_deaths$
--where location like 'India'
where continent is not null
order by 1,2

--Looking at countries with highest infection rate compared to population

select location,population,max(total_cases) higestinfectioncount ,max((total_cases/population))*100 PercentPopulationInfected
from dbo.covid_deaths$
--where location like 'India'
where continent is not null
group by location,population
order by 4 desc


--max((total_deaths/population))*100 PercentDeathPopulation
--Shiwing the countries witn highest death count per population
select location,max(cast(total_deaths as int)) Totaldeathcount
from dbo.covid_deaths$
--where location like 'India'
where continent is not null
group by location
order by Totaldeathcount desc

--let's break things down by continent

select location,max(cast(total_deaths as int)) Totaldeathcount
from dbo.covid_deaths$
where continent is null and location not like '%income' and location not like 'World'
group by location
order by Totaldeathcount desc

--Showing the continents with Highest death count per population
select continent,max(cast(total_deaths as int)) Totaldeathcount
from dbo.covid_deaths$
where continent is not null and location not like '%income' and location not like 'World'
group by continent
order by Totaldeathcount desc


-- Global Numbers

select date,SUM(new_cases) total_cases, SUM(cast(new_deaths as int)) total_deaths,SUM(cast(new_deaths as int))/SUM(new_cases)*100 DeathPercentage
from dbo.covid_deaths$
--where location like 'India' and 
where continent is not null
group by date
order by 1,2

select SUM(new_cases) total_cases, SUM(cast(new_deaths as int)) total_deaths,SUM(cast(new_deaths as int))/SUM(new_cases)*100 DeathPercentage
from dbo.covid_deaths$ 
where continent is not null
order by 1,2;

--Looking at Total population vs Vaccination

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [dbo].[covid_deaths$] dea
Join [dbo].['owid-covid-data$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3;

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [dbo].[covid_deaths$] dea
Join [dbo].['owid-covid-data$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [dbo].[covid_deaths$] dea
Join [dbo].['owid-covid-data$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [dbo].[covid_deaths$] dea
Join [dbo].['owid-covid-data$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null ;
