--COUNTRY TOTALS--

--QUERY 1
-- ranks countries by total cases
SELECT location, population, MAX(total_cases) AS total_cases
FROM CovidDeaths
WHERE population > 30000000 AND continent IS NOT NULL
GROUP BY location, population
ORDER BY total_cases DESC;

--QUERY 2
-- ranks countries by total infection rate
SELECT  location, population, MAX(total_cases) AS total_cases, 
		MAX(ROUND((total_cases/population)*100,3)) AS percent_population_infected
FROM CovidDeaths
WHERE population > 30000000 AND continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected DESC;

--QUERY 3
-- ranks countries by total number of deaths
SELECT location, population, MAX(CAST(total_deaths AS INT)) AS total_deaths
FROM CovidDeaths
WHERE population > 30000000 AND continent IS NOT NULL
GROUP BY location, population
ORDER BY total_deaths DESC;

--QUERY 4
-- ranks countries by their total death rate 
SELECT	location, population, MAX(CAST(total_deaths AS INT)) AS total_deaths,  
		MAX(ROUND((CAST(total_deaths AS INT)/population)*100,3)) AS percent_population_died
FROM CovidDeaths
WHERE population > 30000000 AND continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_died DESC;

--QUERY 5
-- ranks countries by death rate for those infected with covid
SELECT  location, population, MAX(total_cases) AS total_cases, MAX(CAST(total_deaths AS INT)) AS total_deaths,
		(ROUND((MAX(CAST(total_deaths AS INT))/MAX(total_cases))*100,3)) AS death_rate_for_infected
FROM CovidDeaths
WHERE population > 30000000 AND continent IS NOT NULL
GROUP BY location, population
ORDER BY death_rate_for_infected DESC;

--QUERY 6
-- shows relationship between population density and total infection rate
SELECT	location, population, ROUND(population_density,0) AS population_density, 
		MAX(ROUND((total_cases/population)*100,3)) AS percent_population_infected
FROM CovidDeaths
WHERE population > 30000000 AND continent IS NOT NULL
GROUP BY location, population, population_density
ORDER BY population_density DESC;

--QUERY 7
-- shows relationship between population density and total death rate
SELECT	location, population, ROUND(population_density,0) AS population_density, 
		MAX(ROUND((CAST(total_deaths AS INT)/population)*100,3)) AS percent_population_died
FROM CovidDeaths
WHERE population > 30000000 AND continent IS NOT NULL
GROUP BY location, population, population_density
ORDER BY population_density DESC;

--QUERY 8
-- first day of new vaccines for all countries
SELECT continent, location, date, new_vaccinations
FROM (
  SELECT continent, location, date, CAST(new_vaccinations AS BIGINT) AS new_vaccinations,
         ROW_NUMBER() OVER (PARTITION BY location ORDER BY date) AS rn
  FROM CovidVaccinations
  WHERE continent IS NOT NULL
  AND CAST(new_vaccinations AS BIGINT) > 0
) table_t
WHERE rn = 1
ORDER BY date;

--VIEW--
-- reduces need to constantly join and allows me to create a table that is extremely easy to work 
-- with in Tableau (fixes drill down issues).
CREATE OR ALTER VIEW vwDailyCountryStats AS 
SELECT	cd.continent, cd.location, cd.date, cd.population, cd.population_density, cv.gdp_per_capita, 
		CAST(cv.new_tests AS BIGINT) AS new_tests, CAST(cv.total_tests AS BIGINT) AS total_tests, 
		CONVERT(FLOAT, cv.positive_rate)*100 AS positive_rate,
		CAST(cv.new_vaccinations AS BIGINT) AS new_vaccinations, 
		CAST(cv.new_people_vaccinated_smoothed AS BIGINT) AS new_people_vaccinated,
		CAST(cv.total_vaccinations AS BIGINT) AS total_vaccinations,
		CAST(cv.people_vaccinated AS BIGINT) AS people_vaccinated, 
		CAST(cv.people_fully_vaccinated AS BIGINT) AS people_fully_vaccinated, 
		cd.new_cases, cd.total_cases, CAST(cd.new_deaths AS BIGINT) AS new_deaths, 
		CAST(cd.total_deaths AS BIGINT) AS total_deaths
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;

--QUERY 9 
-- ranks countries by total number of fully vaccinated 
SELECT	location, MAX(population) AS population, 
		MAX(people_vaccinated) AS people_vaccinated,
		MAX(people_fully_vaccinated) AS people_fully_vaccinated
FROM vwDailyCountryStats
WHERE population > 30000000
GROUP BY continent, location
ORDER BY people_fully_vaccinated DESC;

--QUERY 10
-- ranks countries by vaccination percentage
SELECT	location, MAX(population) AS population, 
		MAX(people_fully_vaccinated) AS people_fully_vaccinated, 
		ROUND(((MAX(people_fully_vaccinated)/MAX(population))*100),5) AS percent_fully_vaccinated
FROM vwDailyCountryStats
WHERE population > 30000000
GROUP BY continent, location
ORDER BY percent_fully_vaccinated DESC;

--QUERY 11
-- compares vaccination percentage to total death rate 
SELECT	location, MAX(population) AS population, 
		ROUND(((MAX(people_fully_vaccinated)/MAX(population))*100),5) AS percent_fully_vaccinated,
		ROUND((MAX(total_deaths)/MAX(population))*100,3) AS percent_population_died
FROM vwDailyCountryStats
WHERE population > 30000000
GROUP BY continent, location
ORDER BY percent_fully_vaccinated DESC;

--QUERY 12
-- compares vaccination percentage to death rate for infected 
SELECT	location, MAX(population) AS population, 
		ROUND(((MAX(people_fully_vaccinated)/MAX(population))*100),5) AS percent_fully_vaccinated,
		ROUND((MAX(total_deaths)/MAX(total_cases))*100,3) AS death_rate_for_infected
FROM vwDailyCountryStats
WHERE population > 30000000
GROUP BY continent, location
ORDER BY percent_fully_vaccinated DESC;

--QUERY 13
-- compares death rates for infected to GDP per cap
SELECT	location, MAX(population) AS population, MAX(gdp_per_capita) AS gdp_per_capita,
		MAX(ROUND((total_cases/population)*100,3)) AS percent_population_infected,
		ROUND((MAX(total_deaths)/MAX(total_cases))*100,3) AS death_rate_for_infected
FROM vwDailyCountryStats
GROUP BY location
ORDER BY gdp_per_capita DESC;
----------------------------------------------------------------------------------------------------------

--COUNTRY DAILY cumulative--

--QUERY 14
-- shows daily cumulative stats for all countries with populations above 30,000,000
SELECT	location, date, population, total_cases, total_deaths,
		ROUND(total_cases/population*100,3) AS percent_population_infected,
		ROUND(total_deaths/total_cases*100,3) AS death_rate_for_infected,
		ROUND(total_deaths/population*100,3) AS percent_population_died,
		total_tests, total_vaccinations, people_vaccinated, people_fully_vaccinated, 
		ROUND(people_vaccinated/population*100,3) AS percent_one_dose,
		ROUND(people_fully_vaccinated/population*100,3) AS percent_fully_vaccinated		
FROM vwDailyCountryStats
WHERE population > 30000000 AND continent IS NOT NULL
ORDER BY location, date;

--QUERY 15
-- same as QUERY 14, but just for USA
SELECT	location, date, population, total_cases, total_deaths,
		ROUND(total_cases/population*100,3) AS percent_population_infected,
		ROUND(total_deaths/total_cases*100,3) AS death_rate_for_infected,
		ROUND(total_deaths/population*100,3) AS percent_population_died,
		total_tests, total_vaccinations, people_vaccinated, people_fully_vaccinated, 
		ROUND(people_vaccinated/population*100,3) AS percent_one_dose,
		ROUND(people_fully_vaccinated/population*100,3) AS percent_fully_vaccinated		
FROM vwDailyCountryStats
WHERE population > 30000000 AND continent IS NOT NULL
AND location like '%states%'
ORDER BY location, date;

--COUNTRY DAILY daily (non-cumulative)--

--QUERY 16
-- shows daily new stats for countries with populations above 30,000,000
SELECT	location, date, population, new_cases, new_deaths,
		ROUND(new_cases/population*100,6) AS daily_percent_population_infected,
		ROUND(new_deaths/NULLIF(new_cases,0)*100,3) AS daily_death_rate_for_infected,
		ROUND(new_deaths/population*100,6) AS daily_percent_population_died,
		new_tests, new_people_vaccinated
FROM vwDailyCountryStats
WHERE population > 30000000 AND continent IS NOT NULL
ORDER BY location, date;

--QUERY 17
-- same as QUERY 16, but just for USA
SELECT	location, date, population, new_cases, new_deaths,
		ROUND(new_cases/population*100,6) AS daily_percent_population_infected,
		ROUND(new_deaths/NULLIF(new_cases,0)*100,3) AS daily_death_rate_for_infected,
		ROUND(new_deaths/population*100,6) AS daily_percent_population_died,
		new_tests, new_people_vaccinated
FROM vwDailyCountryStats
WHERE population > 30000000 AND continent IS NOT NULL
AND location like '%states%'
ORDER BY location, date;

--QUERY 18 
-- using PARTITION BY to see cumulative vaccinations by country
SELECT	cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	SUM(CONVERT(BIGINT, cv.new_vaccinations)) 
	OVER (PARTITION BY cd.location ORDER BY cd.location, 
	CONVERT(DATE, cd.date)) AS cumulative_vaccinations
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.population > 30000000 AND cd.continent IS NOT NULL 
ORDER BY cd.location, cd.date;
----------------------------------------------------------------------------------------------------------

--GLOBAL TOTALS--

--QUERY 19
-- shows global totals
SELECT	cd.location, MAX(cd.population) AS population, MAX(cd.population_density) AS population_density, 
		MAX(cd.total_cases) AS total_cases, MAX(CAST(cd.total_deaths AS INT)) AS total_deaths, 
		MAX(ROUND((cd.total_cases/cd.population)*100,2)) AS percent_population_infected,
		ROUND((MAX(CAST(cd.total_deaths AS INT))/MAX(cd.total_cases))*100,4) AS death_rate_for_infected, 
		MAX(ROUND((CAST(cd.total_deaths AS INT)/cd.population)*100,4)) AS percent_population_died,
		MAX(CAST(cv.people_vaccinated AS BIGINT)) AS people_vaccinated, 
		MAX(CAST(cv.people_fully_vaccinated AS BIGINT)) AS people_fully_vaccinated,
		ROUND(MAX(CAST(cv.people_vaccinated AS BIGINT))/MAX(cd.population)*100,3) AS percent_one_dose,
		ROUND(MAX(CAST(cv.people_fully_vaccinated AS BIGINT))/MAX(cd.population)*100,3) AS percent_fully_vaccinated	
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.location like '%World%' 
GROUP BY cd.location
ORDER BY total_deaths DESC; 

--QUERY 20
-- shows global totals compared with specific Countries 
SELECT	cd.location, MAX(cd.population) AS population, MAX(cd.population_density) AS population_density, 
		MAX(cd.total_cases) AS total_cases, MAX(CAST(cd.total_deaths AS INT)) AS total_deaths, 
		MAX(ROUND((cd.total_cases/cd.population)*100,2)) AS percent_population_infected,
		ROUND((MAX(CAST(cd.total_deaths AS INT))/MAX(cd.total_cases))*100,4) AS death_rate_for_infected, 
		MAX(ROUND((CAST(cd.total_deaths AS INT)/cd.population)*100,4)) AS percent_population_died,
		MAX(CAST(cv.people_vaccinated AS BIGINT)) AS people_vaccinated, 
		MAX(CAST(cv.people_fully_vaccinated AS BIGINT)) AS people_fully_vaccinated,
		ROUND(MAX(CAST(cv.people_vaccinated AS BIGINT))/MAX(cd.population)*100,3) AS percent_one_dose,
		ROUND(MAX(CAST(cv.people_fully_vaccinated AS BIGINT))/MAX(cd.population)*100,3) AS percent_fully_vaccinated	
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.location like '%World%' 
OR cd.location like '%States%' --change this to whatever country(ies) you wish to compare
GROUP BY cd.location
ORDER BY total_deaths DESC; 

--GLOBAL DAILY cumulative--

--QUERY 21
-- shows daily cumulative stats for world
SELECT	cd.location, cd.date, cd.population, cd.total_cases, cd.total_deaths,
		ROUND((cd.total_cases/cd.population)*100,2) AS percent_population_infected,
		ROUND((CAST(cd.total_deaths AS INT)/cd.total_cases)*100,4) AS death_rate_for_infected, 
		ROUND((CAST(cd.total_deaths AS INT)/cd.population)*100,4) AS percent_population_died,
		cv.total_vaccinations, CAST(cv.people_vaccinated AS BIGINT) AS people_vaccinated, 
		CAST(cv.people_fully_vaccinated AS BIGINT) AS people_fully_vaccinated,
		ROUND(CAST(cv.people_vaccinated AS BIGINT)/cd.population*100,3) AS percent_one_dose,
		ROUND(CAST(cv.people_fully_vaccinated AS BIGINT)/cd.population*100,3) AS percent_fully_vaccinated
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.location like '%World%' 
ORDER BY cd.location, cd.date; 

--GLOBAL DAILY daily (non-cumulative)

--QUERY 22
--shows daily new stats for world
SELECT	cd.location, cd.date, cd.population, cd.new_cases, cd.new_deaths,
		ROUND((cd.new_cases/cd.population)*100,4) AS daily_percent_population_infected,
		ROUND((CAST(cd.new_deaths AS BIGINT)/NULLIF(cd.new_cases,0))*100,4) AS daily_death_rate_for_infected, 
		ROUND((CAST(cd.new_deaths AS BIGINT)/cd.population)*100,6) AS daily_percent_population_died,
		CAST(cv.new_people_vaccinated_smoothed AS BIGINT) AS new_people_vaccinated
FROM CovidDeaths cd
JOIN CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.location like '%World%' 
ORDER BY cd.location, cd.date; 


SELECT	location, date, population, new_cases, new_deaths,
		ROUND(new_cases/population*100,6) AS daily_percent_population_infected,
		ROUND(new_deaths/NULLIF(new_cases,0)*100,3) AS daily_death_rate_for_infected,
		ROUND(new_deaths/population*100,6) AS daily_percent_population_died,
		new_tests, new_people_vaccinated
FROM vwDailyCountryStats
WHERE population > 30000000 AND continent IS NOT NULL
ORDER BY location, date;

--QUERY 23
-- worst ten days of pandemic by total deaths 
SELECT	TOP 10 location, date, population, new_cases, 
		CAST(new_deaths AS BIGINT) AS new_deaths, 
		ROUND(new_cases/population*100, 4) AS daily_infection_rate,
		ROUND(CAST(new_deaths AS BIGINT)/NULLIF(new_cases,0)*100,2) AS daily_death_rate_for_infected,
		ROUND(CAST(new_deaths AS BIGINT)/population*100,6) AS daily_percent_population_died
FROM CovidDeaths
WHERE location = 'World'
ORDER by new_deaths DESC;

--QUERY 24 
-- Ranks continents by total number of deaths                               
SELECT continent, MAX(CAST(total_deaths AS INT)) AS total_deaths 
FROM CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE '%income%'  
GROUP BY continent
ORDER BY total_deaths DESC; 
------------------------------------------------------------------------------------------
--USING CTE
-- shows ratio of vaccines given to population
WITH POPvsVAC (continent, location, date, population, new_vaccinations, cumulative_vaccinations) AS
(
SELECT	cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	SUM(CONVERT(bigint, cv.new_vaccinations)) 
	OVER (Partition by cd.location ORDER BY cd.location, 
	CONVERT(date, cd.date)) AS cumulative_vaccinations
FROM CovidProject.dbo.CovidDeaths cd
JOIN CovidProject.dbo.CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.population >30000000 AND cd.continent IS NOT NULL 
)
SELECT *, (cumulative_vaccinations/population) AS ratio_of_vaccines_given_to_pop
FROM POPvsVAC

--USING TEMP TABLE
-- Shows ratio of vaccines given to population
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
SELECT	cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	SUM(CONVERT(bigint, cv.new_vaccinations)) 
	OVER (Partition by cd.location ORDER BY cd.location, 
	CONVERT(date, cd.date)) AS cumulative_vaccinations
FROM CovidProject.dbo.CovidDeaths cd
JOIN CovidProject.dbo.CovidVaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date

SELECT *, (cumulative_vaccinations/population)*100 AS ratio_of_vaccines_given_to_pop
FROM #PercentPopulationVaccinated
