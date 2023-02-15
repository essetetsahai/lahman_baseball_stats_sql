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
	--Do the same for home runs per game.


WITH decade_cte AS(
	SELECT generate_series(1920, 2020, 10) AS beginning_of_decade
)
SELECT 
	ROUND(SUM(hr)*1.0/SUM(g), 2) AS hr_pr_game,
	ROUND(SUM(so)* 1.0/SUM(g), 2) AS so_pr_game,
	
	beginning_of_decade::text || 's' AS decade
FROM teams
INNER JOIN decade_cte
ON yearid BETWEEN beginning_of_decade AND beginning_of_decade + 9
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;





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
HAVING(SUM(sb)+SUM(cs) >=20)
					   )

SELECT p.namegiven AS name,
	--p.namelast AS last, 
	s.stolen, s.caught, s.success_perct
FROM people p
INNER JOIN success_table s
USING(playerid)
ORDER BY(success_perct) DESC

--ORDER BY success_perct DESC;


-----------------------------------------------------------
--5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? 
	
SELECT yearid, teamid, SUM(w) AS wins_that_year
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'N'
GROUP BY teamid, yearid
ORDER BY wins_that_year DESC, yearid;

--The largest number of wins for a team that did not win ws is 116 by SEA in 2001.


-- What is the smallest number of wins for a team that did win the world series? 
SELECT yearid, teamid, SUM(w) AS wins_that_year
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'Y'	
GROUP BY teamid, yearid
ORDER BY wins_that_year, yearid;

--The smallest number of wins for a team that WON the ws is 63 by LAN in 1981.


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

WITH win_ranks AS (SELECT 
	yearid, 
	teamid, 
	w AS number_of_wins,
	CASE WHEN wswin='Y' THEN 1
	   		 ELSE 0 END AS world_series_won,
	RANK() OVER(PARTITION BY yearid ORDER BY w DESC) AS ranking
FROM teams

WHERE yearid BETWEEN 1970 AND 2016)

SELECT *
FROM win_ranks
WHERE ranking = 1

------------------------------------------------------

WITH win_ranks AS (SELECT 
	yearid, 
	teamid, 
	w AS number_of_wins,
	CASE WHEN wswin='Y' THEN 1
	   		 ELSE 0 END AS world_series_won,
	RANK() OVER(PARTITION BY yearid ORDER BY w DESC) AS ranking
FROM teams
WHERE yearid BETWEEN 1970 AND 2016)

SELECT ROUND(100.0*AVG(world_series_won), 1) AS percent_of_ws_winners
FROM win_ranks
WHERE ranking = 1;

--Ans: 22.6% of teams with most wins were also world series winners.

-------------------------------------------------------------------

--6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
--	 Give their full name and the teams that they were managing when they won the award.

WITH national_lg_winners AS (
SELECT aw.playerid, aw.lgid, aw.yearid, m.teamid
FROM awardsmanagers aw
INNER JOIN managers m
USING(playerid, yearid)
WHERE awardid LIKE '%TSN%' 
	AND aw.lgid = 'NL'),
	
american_lg_winners AS (
SELECT aw.playerid, aw.lgid, aw.yearid, m.teamid
FROM awardsmanagers aw
INNER JOIN managers m
USING(playerid, yearid)	
WHERE awardid LIKE '%TSN%' 
	AND aw.lgid = 'AL'
)

SELECT p.namefirst || ' ' || p.namelast AS name, n.yearid AS national_lg_won,  n.teamid AS team,  a.yearid AS american_lg_won, a.teamid AS team
FROM national_lg_winners n
INNER JOIN american_lg_winners a
USING(playerid)

INNER JOIN people p
USING(playerid)

-------------------------------------------------------------------
--7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? 
	-- Only consider pitchers who started at least 10 games (across all teams). 
	-- Note that pitchers often play for more than one team in a season, 
	-- so be sure that you are counting all stats for each player.


WITH strikeouts AS (
	SELECT  playerid  , SUM(so) AS total_strikeouts
	FROM pitching
	WHERE yearid = 2016
		AND gs >= 10
	GROUP BY playerid
)

SELECT  p.namegiven,  s.salary::numeric::money, so.total_strikeouts, (salary/total_strikeouts)::numeric::money AS salary_per_strikeout
FROM salaries s
INNER JOIN strikeouts so
USING(playerid)
INNER JOIN people p
ON so.playerid = p.playerid
WHERE yearid = 2016
ORDER BY salary_per_strikeout DESC;

-------------------------------------------------------------------
--8.Find all players who have had at least 3000 career hits. 
-- Report those players' names, total number of hits, and 
-- the year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) 
-- Note that a player being inducted into the hall of fame is indicated by a 'Y' in the inducted column of the halloffame table.

-- Hits in batting table


WITH hits AS(SELECT playerid, SUM(h) AS total_hits
			FROM batting
			GROUP BY playerid
			HAVING(SUM(h) >=3000)
			ORDER BY SUM(h) DESC),

hall_famer AS (SELECT playerid, MIN(yearid) AS year_inducted
			  FROM halloffame
			  WHERE inducted = 'Y'
			  GROUP BY playerid)

SELECT p.namefirst ||' ' ||namelast AS name,
		h.total_hits, 
		f.year_inducted
FROM people p
INNER JOIN hits h
USING(playerid)

LEFT JOIN hall_famer f
USING(playerid)

ORDER BY total_hits DESC;
-------------------------------------------------------------------

--9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.


WITH hits_by_team AS (SELECT playerid,  teamid, SUM(h) AS total_hits
					FROM batting
					GROUP BY playerid, teamid
					HAVING(SUM(h)>= 1000)
		   			ORDER BY playerid, teamid)
					

SELECT p.namefirst ||' ' ||namelast AS name, SUM(h.total_hits) AS total_hits
FROM people p

INNER JOIN hits_by_team h
USING(playerid)

GROUP BY name
HAVING(COUNT(DISTINCT h.teamid) = 2)


--10. Find all players who hit their career highest number of home runs in 2016. 
--Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
--Report the players' first and last names and the number of home runs they hit in 2016.



----------------


WITH rankings AS(
		SELECT yearid, playerid, hr, 
		RANK() OVER(PARTITION BY playerid ORDER BY hr DESC) AS ranking
		FROM batting
),

ten_yr_player AS (SELECT playerid
				 FROM batting
				 GROUP BY playerid
				 HAVING(COUNT(DISTINCT yearid) >= 10))


SELECT p.namefirst || ' ' ||p.namelast AS fullname , hr AS home_runs
FROM rankings r
INNER JOIN ten_yr_player t
USING(playerid)

INNER JOIN people p
USING(playerid)

WHERE yearid = 2016 AND ranking =1 AND hr != 0;

