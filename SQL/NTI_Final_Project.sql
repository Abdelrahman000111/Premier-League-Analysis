CREATE DATABASE PL_NTI;
GO
USE PL_NTI;
GO

ALTER TABLE FactMatch
ADD CONSTRAINT FK_FactMatch_HomeTeam FOREIGN KEY (HomeTeamID) REFERENCES DimTeam(TeamID);

ALTER TABLE FactMatch
ADD CONSTRAINT FK_FactMatch_AwayTeam FOREIGN KEY (AwayTeamID) REFERENCES DimTeam(TeamID);

ALTER TABLE FactMatch
ADD CONSTRAINT FK_FactMatch_Stadium FOREIGN KEY (StadiumID) REFERENCES DimStadium(StadiumID);

ALTER TABLE DimDate
ADD CONSTRAINT PK_DimDate_Date PRIMARY KEY (Date);

ALTER TABLE FactMatch
ADD CONSTRAINT FK_FactMatch_Date FOREIGN KEY (Date) REFERENCES DimDate(Date);

ALTER TABLE FactPlayerPerformance
ADD CONSTRAINT FK_FactPlayerPerformance_Player FOREIGN KEY (PlayerID) REFERENCES DimPlayer(PlayerID);

ALTER TABLE FactPlayerPerformance
ADD CONSTRAINT FK_FactPlayerPerformance_Team FOREIGN KEY (TeamID) REFERENCES DimTeam(TeamID);

EXEC sp_fkeys @fktable_name = 'FactMatch';


-- Amr Wahdan
-- overview
-- Top 10 Scorers
SELECT TOP 10
	Player , SUM(Gls) AS TotalGoals
FROM 
	DimPlayer AS DP
JOIN
	FactPlayerPerformance AS FPP ON FPP.PlayerID = DP.PlayerID
GROUP BY
	Player
ORDER BY
	TotalGoals DESC;


-- Top 10 Stadiums by Attendance
SELECT TOP 10
	Stadium , SUM(Attendance) AS TotalAttendance
FROM 
	DimStadium AS DS
JOIN
	FactMatch AS FM ON FM.StadiumID = DS.StadiumID
GROUP BY
	Stadium
ORDER BY
	TotalAttendance DESC;


-- Total Goals By Weeks
SELECT 
	[Week] , SUM(HTG + ATG) AS TotalGoals
FROM 
	DimDate AS Dd
JOIN
	FactMatch AS FM ON FM.Date = DD.Date
GROUP BY
	[Week]
ORDER BY
	TotalGoals DESC;



-- Top 10 Assisters
SELECT TOP 10
	Player , SUM(Ast) AS TotalAssists
FROM 
	DimPlayer AS DP
JOIN
	FactPlayerPerformance AS FPP ON FPP.PlayerID = DP.PlayerID
GROUP BY
	Player
ORDER BY
	TotalAssists DESC;


-- Total Goals
SELECT SUM(Gls) AS TotalGoals FROM FactPlayerPerformance;


-- Total Assists
SELECT SUM(Ast) AS TotalAssists FROM FactPlayerPerformance;


-- Total Attendance
SELECT SUM(Attendance) AS TotalAttendance FROM FactMatch;


-- non-penalties XG
SELECT ROUND(SUM(npxG) , 1) AS np_penalties_xg FROM FactPlayerPerformance;



-- Abdelrahman Ayman
-- Team Analysis
-- Top Teams Scored Goals?
SELECT 
    t.Team,
    SUM(CASE WHEN t.TeamID = m.HomeTeamID THEN m.HTG ELSE 0 END +
        CASE WHEN t.TeamID = m.AwayTeamID THEN m.ATG ELSE 0 END) AS TotalGoals
FROM 
    DimTeam t
JOIN FactMatch m
    ON t.TeamID = m.HomeTeamID OR t.TeamID = m.AwayTeamID
GROUP BY 
    t.Team
ORDER BY 
    TotalGoals DESC;


-- Top Teams Have AVG Expected Goals?
SELECT 
    t.Team,
    AVG(CASE WHEN t.TeamID = m.HomeTeamID THEN m.HXG ELSE 0 END +
        CASE WHEN t.TeamID = m.AwayTeamID THEN m.AXG ELSE 0 END) AS AvgExpectedGoals
FROM 
    DimTeam t
JOIN FactMatch m
    ON t.TeamID = m.HomeTeamID OR t.TeamID = m.AwayTeamID
GROUP BY 
    t.Team
ORDER BY 
    AvgExpectedGoals DESC;


-- Red / Yellow Cards by Each Team?
SELECT 
    t.Team,
    SUM(p.CrdY) AS TotalYellowCards,
    SUM(p.CrdR) AS TotalRedCards
FROM 
    FactPlayerPerformance p
JOIN 
    DimTeam t ON p.TeamID = t.TeamID
GROUP BY 
    t.Team
ORDER BY 
    TotalRedCards DESC, TotalYellowCards DESC;


-- Which teams have the best goal difference?
SELECT 
    t.Team,
    SUM(CASE WHEN t.TeamID = m.HomeTeamID THEN m.HTG ELSE 0 END +
        CASE WHEN t.TeamID = m.AwayTeamID THEN m.ATG ELSE 0 END) AS GoalsFor,
    SUM(CASE WHEN t.TeamID = m.HomeTeamID THEN m.ATG ELSE 0 END +
        CASE WHEN t.TeamID = m.AwayTeamID THEN m.HTG ELSE 0 END) AS GoalsAgainst,
    SUM(
        (CASE WHEN t.TeamID = m.HomeTeamID THEN m.HTG ELSE 0 END +
         CASE WHEN t.TeamID = m.AwayTeamID THEN m.ATG ELSE 0 END) 
        -
        (CASE WHEN t.TeamID = m.HomeTeamID THEN m.ATG ELSE 0 END +
         CASE WHEN t.TeamID = m.AwayTeamID THEN m.HTG ELSE 0 END)
    ) AS GoalDifference
FROM 
    DimTeam t
JOIN 
    FactMatch m ON t.TeamID = m.HomeTeamID OR t.TeamID = m.AwayTeamID
GROUP BY 
    t.Team
ORDER BY 
    GoalDifference DESC;


-- Goals And XG Per Each Team?
SELECT 
    t.Team,
    SUM(CASE WHEN t.TeamID = m.HomeTeamID THEN m.HTG ELSE 0 END +
        CASE WHEN t.TeamID = m.AwayTeamID THEN m.ATG ELSE 0 END) AS TotalGoals,
    SUM(CASE WHEN t.TeamID = m.HomeTeamID THEN m.HXG ELSE 0 END +
        CASE WHEN t.TeamID = m.AwayTeamID THEN m.AXG ELSE 0 END) AS TotalxG,
    SUM(
        (CASE WHEN t.TeamID = m.HomeTeamID THEN m.HTG ELSE 0 END +
         CASE WHEN t.TeamID = m.AwayTeamID THEN m.ATG ELSE 0 END)
        -
        (CASE WHEN t.TeamID = m.HomeTeamID THEN m.HXG ELSE 0 END +
         CASE WHEN t.TeamID = m.AwayTeamID THEN m.AXG ELSE 0 END)
    ) AS Goal_xG_Diff
FROM 
    DimTeam t
JOIN 
    FactMatch m ON t.TeamID = m.HomeTeamID OR t.TeamID = m.AwayTeamID
GROUP BY 
    t.Team
ORDER BY 
    TotalGoals DESC;

-- AVG XG
SELECT 
    t.Team,
    COUNT(*) AS MatchesPlayed,
    SUM(CASE WHEN t.TeamID = m.HomeTeamID THEN m.HXG ELSE 0 END +
        CASE WHEN t.TeamID = m.AwayTeamID THEN m.AXG ELSE 0 END) AS TotalxG,
    ROUND(
        1.0 * SUM(CASE WHEN t.TeamID = m.HomeTeamID THEN m.HXG ELSE 0 END +
                      CASE WHEN t.TeamID = m.AwayTeamID THEN m.AXG ELSE 0 END)
        / COUNT(*), 2) AS AvgxG_PerMatch
FROM 
    DimTeam t
JOIN 
    FactMatch m ON t.TeamID = m.HomeTeamID OR t.TeamID = m.AwayTeamID
GROUP BY 
    t.Team
ORDER BY 
    AvgxG_PerMatch DESC;


-- Total Red Cards
SELECT 
    SUM(CrdR) AS TotalRedCards
FROM 
    FactPlayerPerformance;


-- Total Yellow Cards
SELECT 
    SUM(CrdY) AS TotalYellowCards
FROM 
    FactPlayerPerformance;


-- Top 10 Teams Waste Goals??
SELECT TOP 10
    t.Team,
    SUM(CASE WHEN t.TeamID = m.HomeTeamID THEN m.HXG ELSE 0 END +
        CASE WHEN t.TeamID = m.AwayTeamID THEN m.AXG ELSE 0 END) AS TotalxG,
    SUM(CASE WHEN t.TeamID = m.HomeTeamID THEN m.HTG ELSE 0 END +
        CASE WHEN t.TeamID = m.AwayTeamID THEN m.ATG ELSE 0 END) AS TotalGoals,
    SUM(
        (CASE WHEN t.TeamID = m.HomeTeamID THEN m.HXG ELSE 0 END +
         CASE WHEN t.TeamID = m.AwayTeamID THEN m.AXG ELSE 0 END)
        -
        (CASE WHEN t.TeamID = m.HomeTeamID THEN m.HTG ELSE 0 END +
         CASE WHEN t.TeamID = m.AwayTeamID THEN m.ATG ELSE 0 END)
    ) AS WastedGoals
FROM 
    DimTeam t
JOIN 
    FactMatch m ON t.TeamID = m.HomeTeamID OR t.TeamID = m.AwayTeamID
GROUP BY 
    t.Team
HAVING 
    SUM(
        (CASE WHEN t.TeamID = m.HomeTeamID THEN m.HXG ELSE 0 END +
         CASE WHEN t.TeamID = m.AwayTeamID THEN m.AXG ELSE 0 END)
        -
        (CASE WHEN t.TeamID = m.HomeTeamID THEN m.HTG ELSE 0 END +
         CASE WHEN t.TeamID = m.AwayTeamID THEN m.ATG ELSE 0 END)
    ) > 0
ORDER BY 
    WastedGoals DESC;


-- Abdelrahman Reda
-- Top Stadiums Have XG
SELECT
	Stadium , ROUND(SUM(HXG + AXG) , 1) AS total_xg
FROM
	DimStadium AS DS
JOIN
	FactMatch AS FM ON FM.StadiumID = DS.StadiumID
GROUP BY
	Stadium
ORDER BY
	total_xg DESC;


-- Top Stadiums Have AVG Attendance
SELECT
	Stadium , SUM(Attendance) AS total_attendance
FROM
	DimStadium AS DS
JOIN
	FactMatch AS FM ON FM.StadiumID = DS.StadiumID
GROUP BY
	Stadium
ORDER BY
	total_attendance DESC;


-- Top Teams Have AVG HTG
SELECT
	Team , SUM(HTG) AS home_team_goals
FROM
	DimTeam AS DT
JOIN
	FactMatch AS FM ON FM.HomeTeamID = DT.TeamID
GROUP BY
	Team
ORDER BY
	home_team_goals DESC;




-- Weeks by Total Attendance
SELECT
	[Week] , SUM(Attendance) AS total_attendance
FROM
	DimDate AS DD
JOIN
	FactMatch AS FM ON FM.Date = DD.Date
GROUP BY
	[Week]
ORDER BY
	total_attendance DESC;


-- Total HTG
SELECT SUM(HTG) AS home_team_goals FROM FactMatch;

-- Total ATG
SELECT SUM(ATG) AS away_team_goals FROM FactMatch;

-- Total Attendance
SELECT SUM(Attendance) AS total_attendance FROM FactMatch;

-- Total HTG
SELECT ROUND(SUM(HXG + AXG) , 1) AS total_xg FROM FactMatch;



-- Top Players Have Contributions
SELECT
	Player , 
	SUM(Ast + Gls) AS total_contributions 
FROM 
	FactPlayerPerformance AS FPP
JOIN
	DimPlayer AS DP ON DP.PlayerID = FPP.PlayerID
GROUP BY
	DP.Player
ORDER BY
	total_contributions DESC;


-- Top Players Have Progressive Carries
SELECT
	Player , SUM(PrgC) AS total_progressive_carries
FROM 
	DimPlayer AS DP
JOIN
	FactPlayerPerformance AS FPP ON DP.PlayerID = FPP.PlayerID
GROUP BY
	DP.Player
ORDER BY
	total_progressive_carries DESC;


-- Top Players Have Progressive Passes
SELECT 
	Player , SUM(Prgp) AS total_progressive_passes
FROM 
	DimPlayer AS DP
JOIN
	FactPlayerPerformance AS FPP ON DP.PlayerID = FPP.PlayerID
GROUP BY
	DP.Player
ORDER BY
	total_progressive_passes DESC;


-- Top Players Have Non-Penalty xG
SELECT
	Player , ROUND(SUM(npxG) , 1) AS non_penalties_xg
FROM 
	DimPlayer AS DP
JOIN
	FactPlayerPerformance AS FPP ON DP.PlayerID = FPP.PlayerID
GROUP BY
	Player
ORDER BY
	non_penalties_xg DESC;


-- Top Players Waste Goals
SELECT
    DP.Player,
    ROUND(SUM(FPP.xG) , 1) AS Total_xG,
    SUM(FPP.Gls) AS Total_Goals,
    ROUND(SUM(FPP.xG) ,	1) - SUM(FPP.Gls) AS Missed_Chances
FROM 
    DimPlayer AS DP
JOIN 
    FactPlayerPerformance AS FPP ON DP.PlayerID = FPP.PlayerID
GROUP BY 
    DP.Player
ORDER BY 
    Missed_Chances DESC;


-- Top Players Exploited Chances
SELECT
    DP.Player,
    SUM(FPP.Gls) AS Total_Goals,
    ROUND(SUM(FPP.xG) , 1) AS Total_xG,
    SUM(FPP.Gls) - ROUND(SUM(FPP.xG) , 1) AS Exploited_Chances
FROM 
    DimPlayer AS DP
JOIN 
    FactPlayerPerformance AS FPP ON DP.PlayerID = FPP.PlayerID
GROUP BY 
    DP.Player
ORDER BY 
    Exploited_Chances DESC;



-- Total Foreign Players
SELECT COUNT(*) AS total_foreign_players FROM DimPlayer
WHERE Nation <> 'ENG';


-- Total Players Under 20
SELECT COUNT(*) AS total_players_under20 FROM DimPlayer
WHERE Age < 20;


-- Total Players Above 30
SELECT COUNT(*) AS total_players_above30 FROM DimPlayer
WHERE Age > 30;


-- Total Progressive Runs by Players
SELECT SUM(PrgR) AS total_progressive_runs FROM FactPlayerPerformance;