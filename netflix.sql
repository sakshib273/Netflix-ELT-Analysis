
----- DATA CLEANING AND TRANSFORMATION -----

SELECT * FROM netflix_extraction;

-- change 
CREATE TABLE netflix_raw(
	show_id VARCHAR(10) PRIMARY KEY,
	"type" VARCHAR(15) NULL,
	title VARCHAR(200) NULL,
	director VARCHAR(250) NULL,
	"cast" VARCHAR(1000) NULL,
	country VARCHAR(150) NULL,
	date_added VARCHAR(20) NULL,
	release_year INT NULL,
	rating VARCHAR(10) NULL,
	duration VARCHAR(15) NULL,
	listed_in VARCHAR(100) NULL,
	description VARCHAR(500) NULL
)

INSERT INTO netflix_raw
SELECT * FROM netflix_extraction;

SELECT * FROM netflix_raw;

-- remove duplicates

SELECT * FROM netflix_raw
WHERE UPPER(title) IN (
SELECT UPPER(title)
FROM netflix_raw
GROUP BY UPPER(title),TYPE
HAVING COUNT(title)>1)
ORDER BY title;

-- clean table 

WITH cte AS(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY UPPER(title), "type" ORDER BY show_id) AS rn
FROM netflix_raw
)

SELECT show_id,
	"type",
	title,
	CAST(date_added as date) AS date_added,
	release_year,
	rating,
	CASE WHEN duration IS NULL THEN rating ELSE duration END AS duration,
	description
INTO netflix
FROM cte; 

SELECT * FROM netflix;

-- new tables for listed_in, director, country, cast

CREATE TABLE netflix_director AS(
SELECT 
	show_id, 
	TRIM(UNNEST(string_to_array(director,','))) AS director 
FROM netflix_raw);

SELECT * FROM netflix_director;


CREATE TABLE netflix_cast AS(
SELECT 
	show_id,
	TRIM(UNNEST(STRING_TO_ARRAY("cast",','))) AS "cast"
FROM netflix_raw);

SELECT * FROM netflix_cast;


CREATE TABLE netflix_country AS(
SELECT 
	show_id,
	TRIM(UNNEST(STRING_TO_ARRAY(country,','))) AS country
FROM netflix_raw);

SELECT * FROM netflix_country;


	CREATE TABLE netflix_listed_in AS(
	SELECT 
		show_id,
		TRIM(UNNEST(STRING_TO_ARRAY(listed_in,','))) AS listed_in
	FROM netflix_raw);

SELECT * FROM netflix_listed_in;

-- datatype coversion

-- populate missing values in country, duration column 
--- mapping for netflix_country
INSERT INTO netflix_country
SELECT 
	show_id,
	mp.country
FROM netflix_raw AS nr
INNER JOIN (
		SELECT d.director,
		c.country
	FROM netflix_director AS d
	INNER JOIN netflix_country AS c ON d.show_id = c.show_id
	GROUP BY d.director, c.country) AS mp ON nr.director = mp.director
WHERE nr.country IS NULL;



























