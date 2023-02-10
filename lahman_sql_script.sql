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

INNER JOIN slry
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

--3. Find the average number of strikeouts per game by decade since 1920. 

--so in pitching
--so in batting

SELECT trunc(b.yearid, -1) AS decade, ROUND(AVG(b.so), 2) AS average_batting_so,  ROUND(AVG(p.so), 2) AS average_pitching_so
FROM batting b
INNER JOIN pitching p
USING(yearid)
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade


--Do the same for home runs per game.

--hr in pitching
--hr in batting

SELECT trunc(b.yearid, -1) AS decade, ROUND(AVG(b.hr), 2) AS average_batting_hr,  ROUND(AVG(p.hr), 2) AS average_pitching_hr
FROM batting b
INNER JOIN pitching p
USING(yearid)
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade

-----------------------------------------------------------
--4. Find the player who had the most success stealing bases in 2016, where 
	-- success is measured as the percentage of stolen base attempts which are successful. 
	-- (A stolen base attempt results either in a stolen base or being caught stealing.) 
	-- Consider only players who attempted at least 20 stolen bases. 
	-- Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.
	
--SB stolen bases in batting table
--CS caught stealing in batting table

--success = SB/(SB+CS)

WITH success_table AS (SELECT 
	playerid,
	SUM(sb) AS stolen, 
	SUM(cs) AS caught, 
	ROUND(100.0 * SUM(sb)/(SUM(sb) + SUM(cs)), 1) AS success_perct
FROM batting 
WHERE yearid ='2016'
GROUP BY playerid
HAVING (SUM(sb) + SUM(cs) >=20))

SELECT p.namefirst AS first, p.namelast AS last, s.stolen, s.caught, s.success_perct
FROM people p
INNER JOIN success_table s
USING(playerid);


-----------------------------------------------------------
--5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? 
	
SELECT yearid, teamid, SUM(w) AS wins_that_year
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'N'
GROUP BY teamid, yearid
ORDER BY wins_that_year DESC, yearid;

--The largest number of wins is 116 by SEA in 2001.


-- What is the smallest number of wins for a team that did win the world series? 
SELECT yearid, teamid, SUM(w) AS wins_that_year
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'Y'	
GROUP BY teamid, yearid
ORDER BY wins_that_year, yearid;

--The smallest number of wins is 63 by LAN in 1981.


-- Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. 
-- Then redo your query, excluding the problem year. 

--"The 1981 MLB season was shortened due to a midyear players’ strike that wiped out games from June 12 through July 31."

SELECT yearid, teamid, SUM(w) AS wins_that_year
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'Y'
	AND yearid != '1981'
GROUP BY teamid, yearid
ORDER BY wins_that_year, yearid


-- How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
SELECT yearid, teamid, SUM(w) AS wins_that_year, 
	SUM(CASE WHEN wswin='Y' THEN 1
	   		 ELSE 0 END)
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND yearid != '1981'
	
GROUP BY teamid, yearid

