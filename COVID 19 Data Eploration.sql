/*
COVID-19 Data Exploration Jan-03-2020 - JUL-05-2023

Skills Demonstrated: Joins, CTE's Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

--Select Data that I start with
SELECT
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM
	covid_deaths
ORDER BY 
	location,
	date;

--Looking at Total Cases vs Total Deaths In USA (Mortality)
SELECT
	location,
	date,
	total_cases,
	total_deaths,
	ROUND((total_deaths::decimal/total_cases)*100,3) AS mortality_percentage
FROM
	covid_deaths
WHERE
	location = 'United States'
ORDER BY location,
	date;

--Looking at how contagious COVID is in the USA
SELECT
	location,
	date,
	total_cases,
	population,
	ROUND((total_cases::decimal/population)*100,3) AS virality_percentage
FROM
	covid_deaths
WHERE
	location = 'United States'
ORDER BY 
	location,
	date;

--Looking at countries with highest virality compared to population
SELECT
	location,
	population,
	MAX(total_cases) as highest_infection_count,
	MAX(ROUND(total_cases::decimal/population,3)) AS virality_percentage
FROM
	covid_deaths
GROUP BY
	location, population
HAVING
	MAX(total_cases) IS NOT NULL
ORDER BY 
	virality_percentage DESC;	

--Looking at countries with the highest death count per population
SELECT
	location,
	MAX(total_deaths) as total_death_count
FROM
	covid_deaths
WHERE
	continent IS NOT NULL
	AND location NOT LIKE '%income%'
	AND location<>'World'
GROUP BY
	location
HAVING
	MAX(total_deaths) IS NOT NULL
ORDER BY
	total_death_count DESC;

--CONVERSELY by continent now
SELECT
	location,
	MAX(total_deaths) as total_death_count
FROM 
	covid_deaths
WHERE 
	continent IS NULL
	AND location NOT LIKE '%income%'
	AND location<>'World'
GROUP BY 
	location
HAVING 
	MAX(total_deaths) IS NOT NULL
ORDER BY 
	total_death_count DESC;
	
	
--Glance at global numbers
SELECT
	SUM(new_cases) as total_cases,
	SUM(new_deaths) as total_deaths,
	ROUND((SUM(new_deaths) * 100) / NULLIF(SUM(new_cases), 0),3) AS mortality_percentage	
FROM
	covid_deaths;	
	
-- Looking at global numbers
SELECT
	date,
	SUM(new_cases) AS total_cases,
	SUM(new_deaths) AS total_deaths,
	ROUND((SUM(new_deaths) * 100) / NULLIF(SUM(new_cases), 0),5) AS mortality_percentage
FROM
	covid_deaths
WHERE
	continent IS NOT NULL
GROUP BY
	date
HAVING
	(SUM(new_cases) <> 0 OR SUM(new_deaths) <> 0)
	AND SUM(new_deaths) <> 0::bigint
ORDER BY
	date,
	total_cases;

-- Looking at Total population vs Vaccinations using a CTE
WITH popvac (
	continent,
	location,
	date,
	population,
	new_vaccinations,
	rolling_vaccinated_sum) AS(
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(v.new_vaccinations) OVER (Partition by d.location ORDER BY d.location, d.date) AS rolling_vaccinated_sum
FROM 
	covid_deaths AS d
LEFT JOIN covid_vaccinations AS v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL
)
SELECT *,
	ROUND((rolling_vaccinated_sum::decimal/population)*100,3) AS rolling_vaccinateed_percentage
FROM popvac;


-- Looking at Total population in a temp table
DROP TABLE IF EXISTS percent_population_vaccinated;
CREATE TEMPORARY TABLE percent_population_vaccinated (
    continent TEXT,
    location TEXT,
    date DATE,
    population NUMERIC,
    new_vaccinations NUMERIC,
    rolling_vaccinated_sum NUMERIC
);

INSERT INTO percent_population_vaccinated
SELECT 
    d.continent,
    d.location,
    d.date,
    d.population,
    v.new_vaccinations,
    SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_vaccinated_sum
FROM 
    covid_deaths AS d
LEFT JOIN 
    covid_vaccinations AS v ON d.location = v.location AND d.date = v.date
WHERE 
    d.continent IS NOT NULL;

SELECT *,
    ROUND((rolling_vaccinated_sum::DECIMAL / population) * 100, 3) AS rolling_vaccinated_percentage
FROM 
    percent_population_vaccinated;


--Creating view to store for a later visualization project
CREATE VIEW percent_population_vaccinated AS
SELECT 
    d.continent,
    d.location,
    d.date,
    d.population,
    v.new_vaccinations,
    SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_vaccinated_sum
FROM 
    covid_deaths AS d
LEFT JOIN 
    covid_vaccinations AS v ON d.location = v.location AND d.date = v.date
WHERE 
    d.continent IS NOT NULL;
