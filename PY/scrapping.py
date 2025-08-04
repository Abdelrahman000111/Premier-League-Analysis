from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from bs4 import BeautifulSoup
import pandas as pd
import time


options = webdriver.ChromeOptions()
options.add_argument("--headless")
driver = webdriver.Chrome(service=Service(), options=options)


url = 'https://fbref.com/en/comps/9/2023-2024/schedule/2023-2024-Premier-League-Scores-and-Fixtures'
driver.get(url)


time.sleep(5) 

html = driver.page_source
soup = BeautifulSoup(html, 'html.parser')


table = soup.find('table', {'id': 'sched_2023-2024_9_1'})


matches = []
for row in table.tbody.find_all('tr'):
    cols = row.find_all(['th', 'td'])
    if len(cols) > 8:
        date = cols[0].text.strip()
        time_ = cols[1].text.strip()
        home_team = cols[2].text.strip()
        score = cols[3].text.strip()
        away_team = cols[4].text.strip()
        attendance = cols[5].text.strip()
        xg = cols[6].text.strip()
        wk = cols[7].text.strip()

        matches.append({
            'Date': date,
            'Time': time_,
            'HomeTeam': home_team,
            'AwayTeam': away_team,
            'Score': score,
            'Attendance': attendance,
            'xG': xg,
            'Wk': wk
        })


df = pd.DataFrame(matches)

stadiums = {
    'Arsenal': 'Emirates Stadium',
    'Aston Villa': 'Villa Park',
    'Bournemouth': 'Vitality Stadium',
    'Brentford': 'Gtech Community Stadium',
    'Brighton': 'Amex Stadium',
    'Burnley': 'Turf Moor',
    'Chelsea': 'Stamford Bridge',
    'Crystal Palace': 'Selhurst Park',
    'Everton': 'Goodison Park',
    'Fulham': 'Craven Cottage',
    'Liverpool': 'Anfield',
    'Luton Town': 'Kenilworth Road',
    'Manchester City': 'Etihad Stadium',
    'Manchester Utd': 'Old Trafford',
    'Newcastle Utd': "St James' Park",
    "Nott'ham Forest": 'City Ground',
    'Sheffield Utd': 'Bramall Lane',
    'Tottenham': 'Tottenham Hotspur Stadium',
    'West Ham': 'London Stadium',
    'Wolves': 'Molineux Stadium'
}



df = df[~df['AwayTeam'].isin(['', 'Home'])]

df['Stadium'] = df['AwayTeam'].map(stadiums)




df.to_csv('match_scrapp.csv', index=False)
print(df.head())


driver.quit()