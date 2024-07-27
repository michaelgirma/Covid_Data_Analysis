USE Portfolio_Project;

-- Select Data that we are going to be starting with
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM covid_deaths
WHERE location LIKE '%states%'
AND continent IS NOT NULL 
ORDER BY 1, 2;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT Location, date, Population, total_cases, (total_cases / population) * 100 AS PercentPopulationInfected
FROM covid_deaths
WHERE location LIKE '%states%'
ORDER BY 1, 2;

-- Countries with Highest Infection Rate compared to Population
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM covid_deaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count per Population
SELECT Location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM covid_deaths
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM covid_deaths
WHERE continent IS NOT NULL AND continent <> ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, 
		SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths, 
        (SUM(CAST(new_deaths AS UNSIGNED)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM covid_deaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;


-- looking at total population vs vaccination
SELECT d.continent, 
		d.location, 
        d.date, 
        d.population, 
        v.new_vaccinations,
        SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS growth_rate_of_people_vaccinated
FROM covid_deaths d
JOIN covid_vaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL 
ORDER BY 2,3;


-- USE CTE
WITH population_vs_vaccination (continent, location, date, population, new_vaccinations, growth_rate_of_people_vaccinated)
AS
(
SELECT d.continent, 
		d.location, 
        d.date, 
        d.population, 
        v.new_vaccinations,
        SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS growth_rate_of_people_vaccinated
FROM covid_deaths d
JOIN covid_vaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL 
)

SELECT *, (growth_rate_of_people_vaccinated/population)*100 
FROM population_vs_vaccination
WHERE new_vaccinations <> ''
ORDER BY 2,3;

-- Countries With more than 10,000 vaccinations
WITH max_amount_vaccinations_by_location (location, new_vaccinations)
AS
(
SELECT location,
		MAX(new_vaccinations)
FROM covid_vaccinations
GROUP BY location
)

SELECT *
FROM max_amount_vaccinations_by_location
WHERE new_vaccinations > 10000
ORDER BY 1,2;

-- TEMP TABLE
DROP TEMPORARY TABLE IF EXISTS percent_population_vaccinated;

CREATE TEMPORARY TABLE percent_population_vaccinated (
	continent varchar(255),
    location varchar(255),
    date varchar(255),
    population numeric,
    new_vaccinations varchar(255),
    growth_rate_of_people_vaccinated numeric
);

INSERT INTO percent_population_vaccinated
SELECT d.continent, 
		d.location, 
        d.date, 
        d.population, 
        v.new_vaccinations,
        SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS growth_rate_of_people_vaccinated
FROM covid_deaths d
JOIN covid_vaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL; 

SELECT *, (growth_rate_of_people_vaccinated/population)*100
FROM percent_population_vaccinated;

-- VIEW 
CREATE VIEW percent_population_vaccinated_view AS
SELECT d.continent, 
		d.location, 
        d.date, 
        d.population, 
        v.new_vaccinations,
        SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS growth_rate_of_people_vaccinated
FROM covid_deaths d
JOIN covid_vaccinations v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL;

CREATE VIEW percent_population_infected AS
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM covid_deaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

CREATE VIEW chance_of_death_by_date_us AS
SELECT Location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM covid_deaths
WHERE location LIKE '%states%'
AND continent IS NOT NULL 
ORDER BY 1, 2;

 



