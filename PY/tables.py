import pandas as pd


df_matches = pd.read_csv('match_scrapp.csv')
df_players = pd.read_csv('premier-player-23-24.csv')


# Create DimDate
dim_date = df_matches[['Date', 'Week', 'Day']].drop_duplicates().reset_index(drop=True)

# Create DimStadium
dim_stadium = df_matches[['Stadium']].drop_duplicates().reset_index(drop=True)
dim_stadium['StadiumID'] = dim_stadium.index + 1

# Create DimTeam
teams = pd.concat([df_matches['HomeTeam'], df_matches['AwayTeam'], df_players['Team']])
dim_team = teams.drop_duplicates().reset_index(drop=True).to_frame(name='Team')
dim_team['TeamID'] = dim_team.index + 1

# Create DimPlayer
dim_player = df_players[['Player', 'Nation', 'Pos', 'Age']].drop_duplicates().reset_index(drop=True)
dim_player['PlayerID'] = dim_player.index + 1

# Create FactMatch
fact_match = df_matches.copy()
fact_match = fact_match.merge(dim_team, left_on='HomeTeam', right_on='Team', how='left')
fact_match = fact_match.rename(columns={'TeamID': 'HomeTeamID'}).drop(columns='Team')
fact_match = fact_match.merge(dim_team, left_on='AwayTeam', right_on='Team', how='left')
fact_match = fact_match.rename(columns={'TeamID': 'AwayTeamID'}).drop(columns='Team')
fact_match = fact_match.merge(dim_stadium, on='Stadium', how='left')
fact_match = fact_match[['Date', 'HomeTeamID', 'AwayTeamID', 'StadiumID', 'HXG', 'AXG', 'Result', 'Attendance']]


# Create FactPlayer
fact_player = df_players.copy()
fact_player = fact_player.merge(dim_player, on=['Player', 'Nation', 'Pos', 'Age'], how='left')
fact_player = fact_player.merge(dim_team, on='Team', how='left')
fact_player = fact_player[['PlayerID', 'TeamID', 'MP', 'Starts', 'Min','Gls', 'Ast', 'xG', 'xAG', 'npxG','CrdY', 'CrdR','PrgC', 'PrgP', 'PrgR']]



# Save Dim Tables
dim_date.to_csv('DimDate.csv', index=False)
dim_team.to_csv('DimTeam.csv', index=False)
dim_player.to_csv('DimPlayer.csv', index=False)
dim_stadium.to_csv('DimStadium.csv', index=False)


# Save Fact Tables
fact_match.to_csv('FactMatch.csv', index=False)
fact_player.to_csv('FactPlayerPerformance.csv', index=False)
