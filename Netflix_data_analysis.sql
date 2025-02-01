DROP TABLE IF EXISTS netflix;

CREATE TABLE netflix
(
show_id VARCHAR(6),
type VARCHAR(10),
title VARCHAR(150),
director VARCHAR(210),
casts VARCHAR(1000),
country VARCHAR(150),
date_added VARCHAR(50),
release_year INT,
rating VARCHAR(10),
duration VARCHAR(15),
listed_in VARCHAR(100),
description VARCHAR(250)
);

SELECT * FROM netflix;

SELECT COUNT(*) AS total_content
FROM netflix;

SELECT DISTINCT type
FROM netflix;

-- 15 Business Problems & Solutions

-- 1. Count the number of Movies vs TV Shows
SELECT type, count(*)
FROM netflix
GROUP BY type;

-- 2. Find the most common rating for movies and TV shows
SELECT type, rating
FROM (SELECT type,rating, count(rating) as cnt, RANK() OVER(PARTITION BY type ORDER BY count(rating) DESC) AS rnk
FROM netflix
GROUP BY type,rating) AS t1
WHERE rnk = 1;

--3. List all movies released in a specific year (e.g., 2020)
SELECT *
FROM netflix
WHERE (type='Movie') AND (release_year=2020);

--4. Find the top 5 countries with the most content on Netflix
SELECT TRIM(UNNEST(STRING_TO_ARRAY(country,','))) AS new_country, count(show_id) as total_content
FROM netflix
GROUP BY new_country
ORDER BY total_content DESC
LIMIT 5;

--5. Identify the longest movie
SELECT title, replace(TRIM(duration), ' min','')::INT AS duration_min
FROM netflix
WHERE type='Movie' AND duration IS NOT NULL
ORDER BY duration_min DESC
LIMIT 1;

 --6. Find content added in the last 5 years
SELECT *
FROM netflix
WHERE TO_DATE(date_added, 'Month DD, YYYY') >= (CURRENT_DATE - INTERVAL '5 years');

--7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
SELECT *
FROM netflix
WHERE director ILIKE '%Rajiv Chilaka%';

--8. List all TV shows with more than 5 seasons
SELECT *
FROM netflix
WHERE type = 'TV Show' AND (TRIM(LEFT(duration,2))::INT>5);

--9. Count the number of content items in each genre
SELECT A.genre, count(*) as total_content
FROM (SELECT TRIM(UNNEST(STRING_TO_ARRAY(listed_in,','))) as genre
FROM netflix) AS A
GROUP BY A.genre
ORDER BY total_content DESC;

-- 10.Find each year and the average numbers of content release in India on netflix. 
-- return top 5 year with highest avg content release!
WITH a as
(SELECT 
	EXTRACT(year FROM TO_DATE(date_added, 'Month DD, YYYY')) as year,
	show_id,
	TRIM(UNNEST(STRING_TO_ARRAY(country,','))) as new_country
FROM netflix) ,

b as (SELECT 
	 year,
	count(distinct show_id)::NUMERIC as total_content
FROM a
GROUP BY year),

c as (SELECT 
	 year,
	count(distinct show_id)::NUMERIC as total_content
FROM a
where new_country = 'India'
group by year)

select b.year, ROUND(c.total_content/b.total_content,2) as avg
from c left join b
on c.year = b.year
order by avg desc
limit 5;

--11. List all movies that are documentaries
SELECT *
FROM netflix
WHERE listed_in ILIKE '%Documentaries%'

--12. Find all content without a director
SELECT *
FROM netflix
WHERE director IS NULL

--13. Find how many movies actor 'Salman Khan' appeared in last 10 years!
SELECT *
FROM netflix
WHERE casts ILIKE '%Salman Khan%' AND release_year >=2015

--14. Find the top 10 actors who have appeared in the highest number of movies produced in India.
SELECT 
	TRIM(UNNEST(STRING_TO_ARRAY(casts,','))) AS actors,
	COUNT(DISTINCT show_id) AS no_of_movies
FROM netflix
WHERE country ILIKE '%India%'
GROUP BY TRIM(UNNEST(STRING_TO_ARRAY(casts,',')))
ORDER BY no_of_movies DESC
LIMIT 10;

--Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
--the description field. Label content containing these keywords as 'Bad' and all other 
--content as 'Good'. Count how many items fall into each category.

With categories as
(SELECT *, CASE 
WHEN (description ILIKE '%kill%') OR (description ILIKE '%violence%') THEN 'Bad'
ELSE 'Good'
END AS category
FROM netflix)

SELECT category, count(*) as total_content
FROM categories
GROUP BY category
