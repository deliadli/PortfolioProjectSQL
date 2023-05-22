Select *
From PortfolioCovid..CovidDeaths
Where continent is not null
Order by 3,4

Select *
From PortfolioCovid..CovidVaccinations
Order by 3,4

--Select data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioCovid..CovidDeaths
Order by 1,2

--Total Cases VS Total Deaths (Alter certain column data type as it cannot be divided)

ALTER TABLE dbo.CovidDeaths ALTER COLUMN total_deaths float
ALTER TABLE dbo.CovidDeaths ALTER COLUMN total_cases float

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioCovid..CovidDeaths
Where location like '%malaysia%'
Order by 1,2

--Shows likelihood of dying if you contract covid in your country

--Looking total cases vs population

Select location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioCovid..CovidDeaths
Where location like '%malaysia%'
Order by 1,2

--Looking at Countries with highest infection rate compared to population

Select location, MAX(total_cases) as MaxInfectionCount, population, MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioCovid..CovidDeaths
--Where location like '%malaysia%'
Group by location, population
Order by PercentPopulationInfected desc

--Showing Countries with Highest Death Count per population

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioCovid..CovidDeaths
--Where location like '%malaysia%'
Where continent is not null
Group by location
Order by TotalDeathCount desc

--Showing continents with the highest death count per population

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioCovid..CovidDeaths
--Where location like '%malaysia%'
Where continent is not null
Group by continent
Order by TotalDeathCount desc

--Global number

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(NULLIF(new_cases,0))*100 as DeathPercentage
From PortfolioCovid..CovidDeaths
--Where location like '%malaysia%'
Where continent is not null
Group by date
Order by 1,2

--Overall Total cases and deaths

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(NULLIF(new_cases,0))*100 as DeathPercentage
From PortfolioCovid..CovidDeaths
--Where location like '%malaysia%'
Where continent is not null
--Group by date
Order by 1,2

--Join table Vaccination and deaths

Select *
From PortfolioCovid..CovidDeaths dea
Join PortfolioCovid..CovidVaccinations vac
	On dea.location = vac.location
	and  dea.date = vac.date

-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioCovid..CovidDeaths dea
Join PortfolioCovid..CovidVaccinations vac
	On dea.location = vac.location
	and  dea.date = vac.date
Where dea.continent is not null
Order by 2,3

--Cumulative calculation of new_vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as CumulativeVac
From PortfolioCovid..CovidDeaths dea
Join PortfolioCovid..CovidVaccinations vac
	On dea.location = vac.location
	and  dea.date = vac.date
Where dea.continent is not null
Order by 2,3

--USE CTE

With PopVsVac (Continent, location, date, population, new_vaccinations, CumulativeVac) 
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as CumulativeVac
From PortfolioCovid..CovidDeaths dea
Join PortfolioCovid..CovidVaccinations vac
	On dea.location = vac.location
	and  dea.date = vac.date
Where dea.continent is not null
--Order by 2,3
)
Select *, (CumulativeVac/population)*100
From PopVsVac

--TEMP TABLE

Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
CumulativeVac numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as CumulativeVac
From PortfolioCovid..CovidDeaths dea
Join PortfolioCovid..CovidVaccinations vac
	On dea.location = vac.location
	and  dea.date = vac.date
Where dea.continent is not null
--Order by 2,3 
Select *, (CumulativeVac/population)*100
From #PercentPopulationVaccinated


--Creating view to store data for visualizations

Use PortfolioCovid
Go
Create view PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as CumulativeVac
From PortfolioCovid..CovidDeaths dea
Join PortfolioCovid..CovidVaccinations vac
	On dea.location = vac.location
	and  dea.date = vac.date
Where dea.continent is not null
--Order by 2,3

Select *
From PercentPopulationVaccinated