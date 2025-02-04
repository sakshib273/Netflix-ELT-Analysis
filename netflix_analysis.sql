
--------- DATA ANALYSIS ----------

SELECT COUNT(*),rating FROM netflix
GROUP BY rating
ORDER BY COUNT(*);

SELECT COUNT(*), "type" FROM netflix
GROUP BY "type"
ORDER BY COUNT(*);

SELECT COUNT(*), release_year FROM netflix
GROUP BY release_year
ORDER BY COUNT(*);

-- For each director count the no of movies and tv shows created by them 
SELECT 
	nd.director,
	COUNT(n.type) AS total_counts,
	COUNT(CASE WHEN n.type = 'Movie' THEN n.show_id END) AS Total_movies,
	COUNT(CASE WHEN n.type = 'TV Show' THEN n.show_id END) AS Total_tv_show
FROM  netflix as n
INNER JOIN netflix_director as nd ON n.show_id = nd.show_id 
GROUP BY nd.director
HAVING COUNT(DISTINCT n.type) > 1


-- Which country has highest number of comedy movies

SELECT 
	nc.country,
	nl.listed_in,
	COUNT(CASE WHEN nl.listed_in = 'Comedies' THEN nl.show_id END) AS count_country
FROM netflix_country AS nc
INNER JOIN netflix_listed_in AS nl ON nc.show_id = nl.show_id
GROUP BY nc.country,nl.listed_in
ORDER BY count_country DESC
LIMIT 1;

-- For each year(as per date added to netflix), which director has maximum of movies released 

WITH cte AS(
SELECT 
	nd.director,
	COUNT(n.type) AS count_of_movies,
	EXTRACT(YEAR FROM n.date_added) AS "year"
FROM netflix AS n
INNER JOIN netflix_director AS nd ON n.show_id = nd.show_id
WHERE n.type = 'Movie'
GROUP BY nd.director, EXTRACT(YEAR FROM n.date_added)
ORDER BY count_of_movies DESC
),

cte2 AS(
SELECT *,
	RANK() OVER(PARTITION BY "year" ORDER BY count_of_movies DESC) AS "rank"	
FROM cte
)

SELECT * 
FROM cte2
WHERE "rank" = 1
ORDER BY "year" DESC, count_of_movies DESC;


-- What is average duration of movies in each genre

SELECT 
	nl.listed_in,
	ROUND(AVG((REPLACE(n.duration, ' min', ''))::int),2)
FROM netflix as n
INNER JOIN netflix_listed_in as nl ON n.show_id = nl.show_id
WHERE "type" = 'Movie'
GROUP BY nl.listed_in
ORDER BY nl.listed_in
;

-- Find the list of directors who have created horror and comedy movie both.
-- Display director's name along with number of horror and comedy movies directed by them

WITH cte AS(
SELECT 
	nd.director,
	n.type,
	nl.listed_in
FROM netflix AS n
INNER JOIN netflix_director AS nd ON n.show_id = nd.show_id
INNER JOIN netflix_listed_in AS nl ON nd.show_id = nl.show_id
WHERE "type" = 'Movie' AND listed_in IN ('Comedies','Horror Movies'))

SELECT 
	director,
	COUNT(CASE WHEN listed_in = 'Comedies' THEN listed_in END) AS count_of_comedy_movie,
	COUNT(CASE WHEN listed_in = 'Horror Movies' THEN listed_in END) AS count_of_horror_movie,
	COUNT(listed_in) AS total
FROM cte AS cn
GROUP BY director
HAVING COUNT(CASE WHEN listed_in = 'Comedies' THEN listed_in END) > 0 AND 
	   COUNT(CASE WHEN listed_in = 'Horror Movies' THEN listed_in END) > 0;
	 
	 
-- How many shows were added to Netflix after 2019, grouped by type (Movie or TV Show)?

SELECT 
	EXTRACT(YEAR from date_added) AS date_year,
	"type",
	COUNT(show_id)	
FROM netflix
WHERE EXTRACT(YEAR from date_added) > 2019
GROUP BY date_year,"type"
ORDER BY date_year,"type";

-- Which cast member has appeared in the most number of shows?

SELECT 
	nc."cast",
	n."type",
	COUNT(nc."cast") AS no_of_appearance 
FROM netflix_cast AS nc
INNER JOIN netflix AS n ON n.show_id = nc.show_id
WHERE n.type = 'TV Show'
GROUP BY nc."cast",n."type"
ORDER BY no_of_appearance DESC
LIMIT 1;

-- List the top 5 countries with the most Netflix shows.

SELECT
	COUNT(*) AS count_of_entries,
	nc.country
FROM netflix AS n
INNER JOIN netflix_country AS nc ON n.show_id = nc.show_id
WHERE n."type" = 'TV Show'
GROUP BY nc.country
ORDER BY count_of_entries DESC
LIMIT 5;

-- Identify the top 3 countries that produced shows directed by directors who have directed more than 10 shows.

WITH cte AS(
SELECT 
	nd.director,
	COUNT(n.show_id) AS show_counts
FROM netflix AS n 
INNER JOIN netflix_director AS nd ON n.show_id = nd.show_id
GROUP BY nd.director
HAVING COUNT(n.show_id) > 10)

SELECT
	nc.country,
	COUNT(n.show_id) AS total_shows
FROM netflix AS n
INNER JOIN netflix_country AS nc ON n.show_id = nc.show_id
INNER JOIN netflix_director AS nd ON n.show_id = nd.show_id
INNER JOIN cte AS c ON c.director = nd.director
GROUP BY nc.country
ORDER BY total_shows DESC
LIMIT 3;


-- Write a query to find all shows (title) that feature both "Robert Downey Jr." and "Scarlett Johansson" in the cast.

select 
	n.show_id,
	n.type,
	n.title,
	ncast.cast
from netflix as n
inner join netflix_cast as ncast on n.show_id = ncast.show_id
where ncast.cast in ('Robert Downey Jr.','Scarlett Johansson')
order by n.title;

-- Write a query to rank all directors based on the number of shows they’ve worked on, partitioned by type (Movie or TV Show

SELECT 
	nd.director, 
	n.type,
	COUNT(n.show_id) AS total_work,
	DENSE_RANK() OVER(PARTITION BY n.type ORDER BY COUNT(n.show_id) DESC) AS rnk
FROM netflix AS n
INNER JOIN netflix_director AS nd ON n.show_id = nd.show_id
GROUP BY n.type,nd.director
ORDER BY n.type,rnk;


-- Identify the second-highest number of shows released in a year, along with the year

SELECT release_year,MAX(show_counts) AS max_count
FROM (
	SELECT 
		release_year,
		COUNT(show_id) AS show_counts
	FROM netflix
	GROUP BY release_year
)
WHERE show_counts < (
	SELECT MAX(show_counts) 
		FROM (
		SELECT 
			release_year,
			COUNT(show_id) AS show_counts
		FROM netflix
		GROUP BY release_year)
)
GROUP BY release_year
ORDER BY max_count DESC;

-- ---------------------------------------------------------------------------------------------
-- Count the number of movies with a rating of "PG-13" added in the last 5 years.

SELECT 
	COUNT(show_id),
	rating,
	EXTRACT(YEAR FROM date_added) AS year
FROM netflix
WHERE rating = 'PG-13'
GROUP BY rating, year
ORDER BY year DESC
LIMIT 5;

-- Identify the top 3 countries that produced shows directed by directors who have directed more than 10 shows.

SELECT 
	nc.country,
	COUNT(nd.show_id) AS show_counts
FROM netflix_country AS nc
JOIN netflix_director AS nd ON nc.show_id = nd.show_id
WHERE nd.director IN 
(SELECT 
	director
FROM netflix_director
GROUP BY director
HAVING COUNT(show_id) > 10)
GROUP BY nc.country
ORDER BY show_counts DESC
LIMIT 3;

-- Write a query to find all shows (title) that feature both "Robert Downey Jr." and "Scarlett Johansson" in the cast.

SELECT 
	n.title,
	nc.cast
FROM netflix AS n
JOIN netflix_cast AS nc ON n.show_id = nc.show_id
WHERE nc.cast IN ('Robert Downey Jr.','Scarlett Johansson')
ORDER BY title;

-- How would you ensure that a show's release_year is always less than or equal to the year in date_added? Write an SQL query to identify records that violate this rule.
SELECT 
	title,
	EXTRACT(YEAR FROM date_added) AS added_year,
	release_year
FROM netflix
WHERE release_year > EXTRACT(YEAR FROM date_added);

-- Write a query to find all directors who have worked on shows in at least 3 unique countries.

SELECT
	nd.director,
	STRING_AGG(DISTINCT nc.country, ', ') AS countries
FROM netflix_director AS nd
JOIN netflix_country AS nc ON nd.show_id = nc.show_id
GROUP BY nd.director
HAVING COUNT(DISTINCT nc.country) >= 3
ORDER BY nd.director

-- Write a query to rank all directors based on the number of shows they’ve worked on, partitioned by type (Movie or TV Show).

SELECT
	nd.director,
	n.type,
	COUNT(n.type) AS show_counts,
	DENSE_RANK() OVER(PARTITION BY n.type ORDER BY COUNT(n.type) DESC) AS rnk
FROM netflix AS n
JOIN netflix_director AS nd ON n.show_id = nd.show_id 
GROUP BY nd.director,n.type
ORDER BY n.type,rnk













	  