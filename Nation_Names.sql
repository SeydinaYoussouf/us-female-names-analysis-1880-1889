-- ======================================================================
-- PROJET 1 : ANALYSE DES PRÉNOMS FÉMININS (1880 - 1889)
-- ======================================================================

-- ÉTAPE 0 : CRÉATION DE LA TABLE
CREATE TABLE IF NOT EXISTS us_names (
    Id INT,
    Name VARCHAR(255),
    Year INT,
    Gender VARCHAR(1),
    Count INT
);

-- 1. TOP 5 DES PRÉNOMS FÉMININS LES PLUS POPULAIRES SUR LA DÉCENNIE
SELECT 
    Name, 
    SUM(Count) AS total_births
FROM 
    us_names
WHERE 
    Gender = 'F' 
    AND Year BETWEEN 1880 AND 1889
GROUP BY 
    Name
ORDER BY 
    total_births DESC
LIMIT 5;

-- 2. NOMBRE TOTAL DE NAISSANCES PAR ANNÉE POUR LE TOP 5
WITH top5_names AS (
    SELECT Name
    FROM us_names
    WHERE Gender = 'F' AND Year BETWEEN 1880 AND 1889
    GROUP BY Name
    ORDER BY SUM(Count) DESC
    LIMIT 5
)
SELECT 
    n.Year, 
    n.Name, 
    n.Count
FROM 
    us_names n
JOIN 
    top5_names t ON n.Name = t.Name
WHERE 
    n.Gender = 'F' AND n.Year BETWEEN 1880 AND 1889
ORDER BY 
    n.Year ASC, n.Count DESC;

-- 3. TAUX DE CROISSANCE ANNUEL MOYEN (TCAM) POUR LE TOP 5
WITH yearly_counts AS (
    SELECT 
        Year, 
        Name, 
        SUM(Count) AS total
    FROM us_names
    WHERE Gender = 'F' AND Year BETWEEN 1880 AND 1889
    GROUP BY Year, Name
),
top5_names AS (
    SELECT Name
    FROM yearly_counts
    GROUP BY Name
    ORDER BY SUM(total) DESC
    LIMIT 5
),
growth_calc AS (
    SELECT
        yc.Name,
        MIN(yc.Year) as start_year,
        MAX(yc.Year) as end_year,
        MIN(CASE WHEN yc.Year = 1880 THEN yc.total END) as births_1880,
        MAX(CASE WHEN yc.Year = 1889 THEN yc.total END) as births_1889
    FROM yearly_counts yc
    JOIN top5_names t ON yc.Name = t.Name
    GROUP BY yc.Name
)
SELECT
    Name,
    births_1880,
    births_1889,
    ROUND((POWER((births_1889::NUMERIC / NULLIF(births_1880, 0)::NUMERIC), 1.0/9.0) - 1) * 100, 2) AS cagr_percent
FROM growth_calc
ORDER BY cagr_percent DESC;

-- 4. VOLATILITÉ (ÉCART-TYPE) DU TOP 3
SELECT 
    Name, 
    ROUND(STDDEV(Count), 2) AS births_volatility
FROM 
    us_names
WHERE 
    Gender = 'F' 
    AND Year BETWEEN 1880 AND 1889
    AND Name IN (
        SELECT Name FROM us_names WHERE Gender = 'F' AND Year BETWEEN 1880 AND 1889 
        GROUP BY Name ORDER BY SUM(Count) DESC LIMIT 3
    )
GROUP BY 
    Name
ORDER BY 
    births_volatility DESC;

-- 5. ANALYSE DE CONCENTRATION DU MARCHÉ (INDICE DE HERFINDAHL-HIRSCHMAN - HHI)
WITH total_decade AS (
    SELECT SUM(Count) AS total_births_all
    FROM us_names
    WHERE Gender = 'F' AND Year BETWEEN 1880 AND 1889
),
name_shares AS (
    SELECT 
        Name,
        SUM(Count) AS name_births,
        (SUM(Count)::NUMERIC / MAX(t.total_births_all) * 100) AS market_share_percent
    FROM us_names, total_decade t
    WHERE Gender = 'F' AND Year BETWEEN 1880 AND 1889
    GROUP BY Name, t.total_births_all
)
SELECT 
    ROUND(SUM(POWER(market_share_percent, 2)), 2) AS hhi_index
FROM name_shares;