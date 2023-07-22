library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

library(Lahman)
library(baseballr)

setwd('baseball/birthdays')

# excel file from https://www.smartfantasybaseball.com/tag/player-id/
player_id_map <- read_csv('player_id_map.csv')

# use the Lahman data set to get everyone's birthday
birthdays <- People %>%
  mutate(finalGame = as_date(finalGame)) %>%
  filter(finalGame >= as_date('2000-01-01')) %>%
  left_join(
    select(player_id_map, c('BREFID', 'MLBID')),
    by = c('bbrefID' = 'BREFID')
  )

# only get april-september birthdays
in_season_birthdays <- birthdays %>%
  filter(birthMonth >= 4 & birthMonth <= 9) %>%
  select(playerID, nameFirst, nameLast,
         birthDate, birthYear, birthMonth, birthDay,
         debut, finalGame,
         bbrefID, MLBID) %>%
  filter(!is.na(MLBID)) %>%
  mutate(debut_year = year(debut), final_year = year(finalGame))

# super inefficient loop for downloading each player's birthday box scores
# loop over players
for (player_count in seq(1143, 1460)) {
  
  # try every year since 2000 for this player
  my_player_id <- in_season_birthdays$MLBID[player_count]
  print(player_count)
  print(in_season_birthdays$playerID[player_count])
  start_year <- max(c(2000, in_season_birthdays$debut_year[player_count]))
  end_year <- in_season_birthdays$final_year[player_count]
  
  for (this_year in seq(start_year, end_year)) {
    
    # construct the game date
    game_date <- ymd(
      paste0(
        this_year,
        '-',
        in_season_birthdays$birthMonth[player_count],
        '-',
        in_season_birthdays$birthDay[player_count]
      )
    )
    
    # use the baseballr function mlb_game_pks to get all games for this date
    my_mlb_pks <- mlb_game_pks(game_date)
    all_game_pks <- my_mlb_pks$game_pk
    
    # this is so bad...loop through all games until the one the player played in is found
    game_pk_count <- 1
    found_game <- FALSE
    player_game_df <- NULL
    while (
      (game_pk_count <= length(all_game_pks)) &
      found_game == FALSE
    ) {
      test_df <- mlb_player_game_stats(
        person_id = my_player_id,
        game_pk = all_game_pks[game_pk_count]
      )
      if (ncol(test_df) > 100) {
        found_game <- TRUE
        player_game_df <- test_df
      }
      game_pk_count <- game_pk_count + 1
    }
    
    # save the box score to csv
    if (!is.null(player_game_df)) {
      filename <- paste0(
        'data/',
        my_player_id,
        '_',
        game_date,
        '.csv'
      )
      write.csv(player_game_df, filename)
      print(filename)
    }
    
  }
}
