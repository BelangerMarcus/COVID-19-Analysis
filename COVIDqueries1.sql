SELECT * From CovidDeaths
WHERE continent is not null
ORDER BY 3, 4;


--Select * From CovidVaccinations
--Order By 3, 4;


--1
-- Select Data we will be using 
SELECT location, date, total_cases,new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2;


--2
-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in X country
SELECT location, date, total_cases, total_deaths, Round((total_deaths/total_cases)*100,3) AS death_percentage
FROM CovidDeaths
WHERE continent is not null
--Where location like '%states%' AND continent is not null
ORDER BY 1,2;


--3
-- Looking at total cases vs Population
SELECT location, date, population, total_cases,  Round((total_cases/population)*100,3) AS percent_population_infected
FROM CovidDeaths
WHERE continent is not null
--Where location like '%states%'
ORDER BY 1,2;


--4
-- Looking at countries with Highest Infection Rate compare to Population
SELECT location, population, MAX(total_cases) AS highest_infection_count,  MAX(Round((total_cases/population)*100,3)) AS percent_population_infected
FROM CovidDeaths
--WHERE continent is not null
WHERE population > 30000000 AND continent is not null
GROUP BY location, population
ORDER BY percent_population_infected DESC;


--4.5
--ranking countries based on total deaths
SELECT location, population, MAX(cast(total_deaths as int)) as total_DEATHS
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY total_DEATHS DESC;


--5
-- Looking at countries with Highest death rate compared to population
SELECT location, population, MAX(cast(total_deaths as int)) AS total_death_count,  
MAX(Round((cast(total_deaths as int)/population)*100,3)) AS percent_population_died
FROM CovidDeaths
--WHERE continent is not null
WHERE population > 30000000 AND continent is not null
GROUP BY location, population
ORDER BY percent_population_died DESC;


----6
-- Looking at connection between death rate and population density
SELECT location, population, round(population_density,0) as population_density, MAX(Round((cast(total_deaths as int)/population)*100,3)) AS percent_population_died
FROM CovidDeaths
--WHERE continent is not null
WHERE population > 30000000 AND continent is not null
GROUP BY location, population, population_density
ORDER BY population_density DESC
--ORDER BY percent_population_died DESC;


--7
-- Showing Countries with Highest Death Count 
SELECT location, MAX(cast(total_deaths as int)) AS total_death_count 
FROM CovidDeaths
WHERE continent is not null
--WHERE population > 30000000 AND continent is not null
GROUP BY location
ORDER BY total_death_count DESC;



--8
-- CONTINENT TOTAL DEATH COUNT                                         DRILL DOWN ISSUES?
SELECT location, MAX(cast(total_deaths as int)) AS total_death_count 
FROM CovidDeaths
WHERE continent is null AND location not LIKE '%income%'  
GROUP BY location
ORDER BY total_death_count DESC;

SELECT continent, MAX(cast(total_deaths as int)) AS total_death_count 
FROM CovidDeaths
WHERE continent is not null AND location not LIKE '%income%'  
GROUP BY continent
ORDER BY total_death_count DESC;  

--Select location, continent, MAX(cast(total_deaths as int)) AS total_death_count 
--FROM CovidDeaths
--WHERE continent is not null AND location not LIKE '%income%'  
--GROUP BY location, continent
--ORDER BY total_death_count DESC;  

--10
-- GLOBAL NUMBERS / compared with specific Countries 
SELECT location, MAX(population) AS population, MAX(population_density) AS population_density, MAX(total_cases) AS total_cases, 
MAX(cast(total_deaths as int)) AS total_deaths, MAX(Round((total_cases/population)*100,2)) as infection_rate, 
MAX(ROUND((cast(total_deaths as int)/population)*100,4)) as death_rate,
ROUND((MAX(cast(total_deaths as int))/MAX(total_cases))*100,4) as death_rate_for_infected
FROM CovidDeaths
WHERE location like '%World%' 
OR location like '%france%'
--WHERE continent is null AND location not LIKE '%income%'  
GROUP BY location
ORDER BY total_deaths DESC; 

--11
--global numbers
--Select date, MAX(total_cases) as world_cases, MAX(total_deaths) as world_deaths, MAX(cast(total_deaths as int)) AS total_death_count,
--MAX(ROUND((cast(total_deaths as int)/total_cases)*100,4)) as death_rate_for_infected
--FROM CovidDeaths
--WHERE continent is not null
--GROUP BY 
--order by 1,2; 


--12
--global numbers by day
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
ROUND((SUM(cast(new_deaths as int))/SUM(new_cases)*100),4) as daily_death_rate_for_infected 
FROM CovidDeaths
WHERE continent is not null 
--AND WHERE 
GROUP BY date
ORDER BY 1,2;


--12.5
--GLOBAL worst days of pandemic
SELECT location, date, population as world_population, total_cases, new_cases, 
total_deaths, new_deaths, ROUND(new_cases/population*100, 4) as daily_infection_rate,
ROUND(cast(new_deaths as int)/NULLIF(new_cases,0)*100,2) as daily_death_rate_for_infected,
ROUND(cast(new_deaths as int)/population*100,6) as daily_death_rate
FROM CovidDeaths
--WHERE continent is not null
WHERE location = 'World'
--ORDER BY 1, 2
ORDER by daily_death_rate DESC;




--13 
-- looking at total Population vs Vaccinations

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) 
OVER (Partition by cd.location ORDER BY cd.location, CONVERT(date, cd.date)) AS cumulative_vaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent is not null 
--AND cd.location like '%states%'
ORDER BY 2,3



-- 14
-- USE CTE
-- ratio of vaccines given vs population
with POPvsVAC (continent, location, date, population, new_vaccinations, cumulative_vaccinations) AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) 
OVER (Partition by cd.location ORDER BY cd.location, CONVERT(date, cd.date)) AS cumulative_vaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent is not null 
AND cd.location like '%states%'
)
SELECT *, (cumulative_vaccinations/population)*100 as ratio_of_vaccines_given_to_pop
FROM POPvsVAC


--15
-- percent of one-dose, and fully-vaccinated individuals
SELECT cd.continent, cd.location, cd.date, cd.population, cv.people_vaccinated, cv.people_fully_vaccinated,
ROUND(((cast(cv.people_vaccinated as bigint))/cd.population*100),5) as percent_of_pop_min_one_vax,
ROUND(((cast(cv.people_fully_vaccinated as bigint))/cd.population*100),5) as percent_of_pop_fully_vaxxed
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent is not null 
--AND cd.location like '%canada%'
ORDER BY 2,3

--16
-- Ranking countries by vaccination rates
SELECT cd.continent, cd.location, MAX(cd.population) as population, MAX(cast(cv.people_vaccinated as bigint)) as people_vaxxed, 
MAX(cast(cv.people_fully_vaccinated as bigint)) as people_fully_vaxxed,
ROUND(((MAX(cast(cv.people_vaccinated as bigint)))/MAX(cd.population)*100),5) as percent_of_pop_min_one_vax,
ROUND(((MAX(cast(cv.people_fully_vaccinated as bigint)))/MAX(cd.population)*100),5) as percent_of_pop_fully_vaxxed
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
WHERE cd.continent is not null 
--AND cd.population > 30000000
--AND cd.location like '%canada%'
GROUP BY cd.continent, cd.location
ORDER BY percent_of_pop_fully_vaxxed DESC


--17
-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date date,
population numeric,
new_vaccinations numeric,
cumulative_vaccinations numeric
)
INSERT into #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) 
OVER (Partition by cd.location ORDER BY cd.location, CONVERT(date, cd.date)) AS cumulative_vaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
--WHERE cd.continent is not null 
--AND cd.location like '%states%'

SELECT *, (cumulative_vaccinations/population)*100 as ratio_of_vaccines_given_to_pop
FROM #PercentPopulationVaccinated



--18
-- Creating VIEW to store data for late visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(bigint, cv.new_vaccinations)) 
OVER (Partition by cd.location ORDER BY cd.location, CONVERT(date, cd.date)) AS cumulative_vaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent is not null 
--AND cd.location like '%states%'
--ORDER BY 2,3 

--Select from view
SELECT * 
FROM PercentPopulationVaccinated