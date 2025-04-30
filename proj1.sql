-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
    FROM people
    WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
FROM people
where namefirst
LIKE '% %'
ORDER BY namefirst ASC, namelast ASC
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height) AS avgheight, COUNT(*) AS count
FROM people
-- we need query the birthyear that are bull
GROUP BY birthyear
ORDER BY birthyear ASC
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, avgheight, count
FROM q1iii
WHERE avgheight > 70
ORDER BY birthyear ASC
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
    SELECT p.namefirst, p.namelast, p.playerid, h.yearid
FROM people p
LEFT JOIN halloffame h
    ON p.playerid = h.playerid
    WHERE h.inducted = 'Y'
ORDER BY h.yearid DESC , p.playerid ASC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
    SELECT namefirst, namelast, q2i.playerid, s.schoolid, yearid
FROM q2i, collegeplaying c, schools s
WHERE q2i.playerid = c.playerid AND c.schoolID = s.schoolID AND schoolstate LIKE 'CA'
ORDER BY yearid DESC, s.schoolid, q2i.playerid
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT q2i.playerid, namefirst, namelast, schoolid
FROM q2i
    LEFT JOIN collegeplaying c ON q2i.playerid = c.playerid
ORDER BY q2i.playerid DESC, schoolid ASC
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid, namefirst, namelast, yearid,
         -- 计算公式
         ROUND((CAST(h AS FLOAT) + 1.0 * CAST(h2b AS FLOAT) + 2.0 * CAST(h3b AS FLOAT) + 3.0 * CAST(hr AS FLOAT)) / CAST(ab AS FLOAT),4) AS slg
FROM people p
INNER JOIN batting b
    ON p.playerid = b.playerid
WHERE b.AB > 50
ORDER BY slg DESC, yearid ASC, p.playerid ASC
LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT p.playerid, namefirst, namelast,
         ROUND((CAST(SUM(h) AS FLOAT) + 1.0 * CAST(SUM(h2b) AS FLOAT) + 2.0 * CAST(SUM(h3b) AS FLOAT) + 3.0 * CAST(SUM(hr) AS FLOAT)) / CAST(SUM(ab) AS FLOAT),4) AS lslg
FROM people p
INNER JOIN batting b ON p.playerid = b.playerid
GROUP BY p.playerid
HAVING SUM(ab) > 50
ORDER BY lslg DESC, p.playerid ASC
LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
WITH mayslslg(lslg) AS (
    SELECT ROUND((CAST(SUM(h) AS FLOAT) + 1.0 * CAST(SUM(h2b) AS FLOAT) + 2.0 * CAST(SUM(h3b) AS FLOAT) + 3.0 * CAST(SUM(hr) AS FLOAT)) / CAST(SUM(ab) AS FLOAT),4)
    FROM people p
    INNER JOIN batting b ON p.playerid = b.playerid
    WHERE p.playerid LIKE 'mayswi01'
    GROUP BY p.playerid)

SELECT namefirst, namelast, ROUND((CAST(SUM(h) AS FLOAT) + 1.0 * CAST(SUM(h2b) AS FLOAT) + 2.0 * CAST(SUM(h3b) AS FLOAT) + 3.0 * CAST(SUM(hr) AS FLOAT)) / CAST(SUM(ab) AS FLOAT),4) AS lslgn
FROM people p
INNER JOIN batting b ON p.playerid = b.playerid
GROUP BY p.playerid
HAVING SUM(ab) > 50 AND lslgn > (SELECT lslg FROM mayslslg)
ORDER BY lslgn DESC, p.playerid ASC
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary) AS min, MAX(salary) AS max, AVG(salary) AS avg
    FROM salaries
    GROUP BY yearid
    ORDER BY yearid ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
WITH bin(binid, low, high) AS (
    SELECT num AS binid, (min + num * (max - min) / 10) AS low, (min + (num + 1) * (max - min) / 10) AS high
    FROM
        (SELECT 0 AS num UNION ALL -- 内部建表
        SELECT 1 AS num UNION ALL
        SELECT 2 AS num UNION ALL
        SELECT 3 AS num UNION ALL
        SELECT 4 AS num UNION ALL
        SELECT 5 AS num UNION ALL
        SELECT 6 AS num UNION ALL
        SELECT 7 AS num UNION ALL
        SELECT 8 AS num UNION ALL
        SELECT 9 AS num),
    (SELECT MAX(salary) AS max, MIN(salary) AS min
    FROM salaries
    WHERE yearid = 2016
    GROUP BY yearid) AS y2016 -- 建立表
group by binid)

SELECT binid, low, high, COUNT(salary)
FROM salaries, bin
WHERE yearid = 2016 AND ((binid < 9 AND salary >= low AND salary < high) OR (binid = 9 AND salary >= low AND salary <= high))
GROUP BY binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  SELECT curr.yearid,
         curr.min - prev.min AS mindiff,
         curr.max - prev.max AS maxdiff,
         curr.avg - prev.avg AS avgdiff
    FROM q4i curr
    JOIN q4i prev
        ON curr.yearid = prev.yearid + 1
    WHERE curr.yearid > 1985
ORDER BY curr.yearid ASC
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
    SELECT s.playerid, p.namefirst, p.namelast, s.salary, s.yearid
FROM salaries s
JOIN people p ON s.playerid = p.playerid
WHERE s.yearid IN (2000, 2001)
AND s.salary = (SELECT MAX(s2.salary) FROM salaries s2 WHERE s2.yearid = s.yearid)
;

-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT a.teamid,
         MAX(s.salary) - MIN(s.salary) AS diffAvg -- 计算全明星球员薪水最高的队伍与最低的队伍之间的差值
FROM allstarfull a
JOIN salaries s ON a.playerid = s.playerid AND a.yearid = s.yearid -- 连接条件
WHERE s.yearid = 2016
GROUP BY a.teamid
;

