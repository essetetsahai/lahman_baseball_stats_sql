--1.  Find all players in the database who played at Vanderbilt University. 
-- Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. 
-- Sort this list in descending order by the total salary earned. 
-- Which Vanderbilt player earned the most money in the majors?


WITH schl AS (SELECT DISTINCT c.playerid, c.schoolid, s.schoolname
		  FROM collegeplaying c
		  INNER JOIN schools s
		  USING(schoolid)
		  WHERE s.schoolname LIKE 'Vanderbilt%'),

slry AS (SELECT playerid, SUM(salary) AS total_salary
		 FROM salaries
		 GROUP BY playerid)
		 
SELECT playerID, 
		nameFirst, 
		nameLast, 
		schl.schoolname, 
		slry.total_salary
FROM people
INNER JOIN schl
USING(playerid)

LEFT JOIN slry
USING(playerid)

ORDER BY total_salary DESC;

--Ans: David Price earned the most total salary($81,851,296).

-----------------------------------------------------------


--2. Using the fielding table, group players into three groups based on their position: 
-- label players with position OF as "Outfield", 
-- those with position "SS", "1B", "2B", and "3B" as "Infield", 
-- and those with position "P" or "C" as "Battery". 
-- Determine the number of putouts made by each of these three groups in 2016.


SELECT
	CASE WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
	WHEN pos IN ('P', 'C') THEN 'Battery'
	END AS position_group,
	SUM(po) AS putouts
FROM fielding
WHERE yearid = '2016'
GROUP BY position_group;

-----------------------------------------------------------









