-- STEP 1: Database schema setup

CREATE DATABASE IF NOT EXISTS health_economics_portfolio;
USE health_economics_portfolio;

CREATE TABLE life_expectancy (
	country_name VARCHAR(100),
    country_code VARCHAR(10),
    year INT,
    life_expectancy DECIMAL(6,2),
    PRIMARY KEY (country_code, year)
);

CREATE TABLE health_spending (
	country_name VARCHAR(100),
    country_code VARCHAR(10),
    year INT,
    health_spend_pc DECIMAL(10,2),
    PRIMARY KEY (country_code, year)
);

CREATE TABLE out_of_pocket (
	country_name VARCHAR(100),
    country_code VARCHAR(10),
    year INT,
    oop_pct DECIMAL(6,2),
    PRIMARY KEY (country_code, year)
);

-- STEP 2: Row-count verification
SELECT 'life_expectancy' AS table_name,
COUNT(*) AS row_name
FROM life_expectancy
UNION ALL
SELECT 'health_spending',
COUNT(*)
FROM health_spending
UNION ALL
SELECT 'out_of_pocket',
COUNT(*)
FROM out_of_pocket;

-- STEP 3: Creating a virtual table 
-- Joins all three normalized tables and computes life-years achieved per $100 spent

CREATE OR REPLACE VIEW vw_health_economics_master AS
SELECT
	le.country_name,
    le.country_code,
    le.year,
    hs.health_spend_pc,
    oop.oop_pct,
    le.life_expectancy,
    ROUND((le.life_expectancy/NULLIF(hs.health_spend_pc, 0)) * 100, 2) AS life_years_per_100_usd
FROM life_expectancy le
INNER JOIN health_spending hs
	ON le.country_code = hs.country_code
    AND le.year = hs.year
INNER JOIN out_of_pocket oop
	ON le.country_code = oop.country_code
    AND le.year = oop.year
WHERE le.life_expectancy IS NOT NULL
AND hs.health_spend_pc IS NOT NULL
AND oop.oop_pct IS NOT NULL;

-- STEP 4: REGIONAL BENCHMARKING (EAST AFRICA VS. CANADA & GLOBAL AVERAGE)
-- Compares health spending, out-of-pocket burden, life expectancy, and cost-efficiency
SELECT 
	country_name,
    year,
    health_spend_pc AS spend_per_person_usd,
    oop_pct AS out_of_pocket_pct,
    life_expectancy,
    life_years_per_100_usd
FROM vw_health_economics_master
WHERE country_code IN ('KEN', 'UGA', 'TZA', 'RWA', 'ZAF', 'CAD', 'WLD')
	AND year IN (2000, 2010, 2015, 2020, 2021)
ORDER BY country_name, year;

    
