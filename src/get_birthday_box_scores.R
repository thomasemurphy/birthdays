library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

library(Lahman)
library(baseballr)

setwd('baseball/birthdays/src')

# this script downloads player-game box scores for all players in the player_id_map csv
# who played on their birthday between 2000 and 2022
# do not run this script unless you really need to
# it is very slow and inefficient

# see get_in_season_birthdays.R
in_season_birthdays <- read_csv('../data/player_lookup/in_season_birthdays.csv')

# super inefficient loop for downloading each player's birthday box scores
# loop over players
for (player_count in seq(1, 10)) {
  
  # try every year since 2000 for this player
  my_player_id <- in_season_birthdays$MLBID[player_count]
  print(player_count)
  print(in_season_birthdays$playerID[player_count])
  print(in_season_birthdays$nameLast[player_count])
  print(in_season_birthdays$nameFirst[player_count])
  start_year <- max(c(2000, in_season_birthdays$debut_year[player_count]))
  end_year <- in_season_birthdays$final_year[player_count]
  
  for (this_year in seq(start_year, end_year)) {
    
    print(this_year)
    
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
      print(ncol(test_df))
      if (ncol(test_df) > 100) {
        found_game <- TRUE
        player_game_df <- test_df
      }
      game_pk_count <- game_pk_count + 1
    }
    
    # save the box score to csv
    if (!is.null(player_game_df)) {
      filename <- paste0(
        '../data/birthday_box_scores/',
        my_player_id,
        '_',
        game_date,
        '.csv'
      )
      # write.csv(player_game_df, filename)
      print(filename)
    }
    
  }
}
