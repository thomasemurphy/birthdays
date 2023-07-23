library(Lahman)

setwd('baseball/birthdays')

# excel file from https://www.smartfantasybaseball.com/tag/player-id/
player_id_map <- read_csv('player_id_map.csv')

in_season_birthdays <- People %>%
  mutate(finalGame = as_date(finalGame)) %>%
  filter(finalGame >= as_date('2000-01-01')) %>%
  left_join(
    select(player_id_map, c('BREFID', 'MLBID')),
    by = c('bbrefID' = 'BREFID')
  ) %>%
  filter(birthMonth >= 4 & birthMonth <= 9) %>%
  select(playerID, nameFirst, nameLast,
         birthDate, birthYear, birthMonth, birthDay,
         debut, finalGame,
         bbrefID, MLBID) %>%
  filter(!is.na(MLBID)) %>%
  mutate(debut_year = year(debut), final_year = year(finalGame))

write_csv(in_season_birthdays, 'data/in_season_birthdays.csv')