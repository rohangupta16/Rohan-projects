--COVID DEATH DATA

select *
from [Portfolio Project]..covid_deaths
where continent is not null
order by 3,4


--select *
--from [Portfolio Project]..covid_vaccination
--order by 3,4

--selct Data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from [Portfolio Project]..covid_deaths
order by 1,2

--looking at Total Cases vs Total Deaths (shows Fatality Rate)

select location, date, total_cases, total_deaths, (cast(total_deaths as float) / cast(total_cases as float)) * 100 as fatality_rate
from [Portfolio Project]..covid_deaths
where location like '%states%'
and continent is not null
order by 1,2

--looking at Total Cases vs Population (shows Infection Rate)

select location, date, total_cases, population, (cast(total_cases as float) / population) * 100 as infection_rate
from [Portfolio Project]..covid_deaths
where location like '%states%'
and continent is not null
order by 1,2

--looking at Countries with Avg Infection Rate compared to Population

select location, population, sum(cast(total_cases as float)) as total_infection_count, avg((cast(total_cases as float) / population)) * 100 as avg_infection_rate
from [Portfolio Project]..covid_deaths
where continent is not null
group by location, population
order by avg_infection_rate desc

--looking at Countries with the Highest Death Count per Population

select location, population, sum(cast(total_deaths as float)) as total_death_count
from [Portfolio Project]..covid_deaths
where continent is not null
group by location, population
order by total_death_count desc

--let's break things down by Continent

--showing Continents with the Highet Death Count per Population
select continent, sum(cast(total_deaths as float)) as total_death_count
from [Portfolio Project]..covid_deaths
where continent is not null
group by continent
order by total_death_count desc

--global numbers

select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths,
case
    when sum(new_cases) = 0 then 0
	else (sum(cast(new_deaths as float)) / sum(new_cases)) * 100
end as death_percentage
from [Portfolio Project]..covid_deaths
where continent is not null 
group by date
order by 1,2

--overall world stats on Death Percentage
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths,
case
    when sum(new_cases) = 0 then 0
	else (sum(cast(new_deaths as float)) / sum(new_cases)) * 100
end as death_percentage
from [Portfolio Project]..covid_deaths
where continent is not null 
--group by date
order by 1,2



--COVID VACCINATION DATA and DEATH DATA

--looking at Total Population vs Vaccination

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as rolling_people_vaccinated
from [Portfolio Project]..covid_deaths dea
join [Portfolio Project]..covid_vaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Using CTE to perform Calculation on Partition By in previous query

with PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as rolling_people_vaccinated
from [Portfolio Project]..covid_deaths dea
join [Portfolio Project]..covid_vaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)

select *, (rolling_people_vaccinated/population)*100 as vac_per_pop
from PopvsVac

--Temp Table

drop table if exists #PercentPopVac

create table #PercentPopVac
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

go

insert into #PercentPopVac
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as rolling_people_vaccinated
from [Portfolio Project]..covid_deaths dea
join [Portfolio Project]..covid_vaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

go

select *, (rolling_people_vaccinated/population)*100 as vac_per_pop
from #PercentPopVac

--creating View to store data for later Visualizations
use [Portfolio Project]
go
create view PercentPopVac as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date)
as rolling_people_vaccinated
from [Portfolio Project]..covid_deaths dea
join [Portfolio Project]..covid_vaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null or dea.continent is null
--order by 2,3

drop view if exists PercentPopVac

select *
from PercentPopVac