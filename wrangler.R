library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

library(Lahman)
library(baseballr)

setwd('baseball/birthdays')

player_id_map <- read_csv('player_id_map.csv')

birthdays <- People %>%
  mutate(finalGame = as_date(finalGame)) %>%
  filter(finalGame >= as_date('2000-01-01')) %>%
  left_join(
    select(player_id_map, c('BREFID', 'MLBID')),
    by = c('bbrefID' = 'BREFID')
  )

in_season_birthdays <- birthdays %>%
  filter(birthMonth >= 4 & birthMonth <= 9) %>%
  select(playerID, nameFirst, nameLast,
         birthDate, birthYear, birthMonth, birthDay,
         debut, finalGame,
         bbrefID, MLBID) %>%
  filter(!is.na(MLBID)) %>%
  mutate(debut_year = year(debut), final_year = year(finalGame))


for (player_count in seq(1143, 1460)) {
  
  my_player_id <- in_season_birthdays$MLBID[player_count]
  print(player_count)
  print(in_season_birthdays$playerID[player_count])
  start_year <- max(c(2000, in_season_birthdays$debut_year[player_count]))
  end_year <- in_season_birthdays$final_year[player_count]
  
  for (this_year in seq(start_year, end_year)) {
    
    game_date <- ymd(
      paste0(
        this_year,
        '-',
        in_season_birthdays$birthMonth[player_count],
        '-',
        in_season_birthdays$birthDay[player_count]
      )
    )
    
    my_mlb_pks <- mlb_game_pks(game_date)
    
    all_game_pks <- my_mlb_pks$game_pk
    
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


# javy_id <- player_id_map %>%
#   filter(PLAYERNAME == 'Javier Baez') %>%
#   pull(MLBID)

# javy_game_stats %>%
#   # filter(group == 'hitting') %>%
#   select(
#     summary,
#     play_type,
#     play_pitch_data_coordinates_x
#     )

# game_id <- my_mlb_pks %>%
#   filter(teams.home.team.name == 'Chicago Cubs') %>%
#   pull(game_pk)
# 
# javy_game_stats <- mlb_player_game_stats(
#   person_id = javy_id,
#   game_pk = game_id
# )

# baez_ids <- playerid_lookup(last_name = 'Báez', first_name = 'Javier')
# baez_mlbamid <- baez_ids['mlbam_id'][[1]]
# 
# my_mlb_pks %>%
# select(
#   game_pk,
#   gameDate,
#   teams.away.team.name,
#   teams.home.team.name
# )
  
# probably dont want retrosheet for this
# retrosheet_22 <- read_delim(
# '../../retrosheet/gamelog/GL2022.TXT',
# col_names = FALSE
# )
# gl_headers <- names(read_csv('retrosheet_gamelog_headers.csv'))
# names(retrosheet_22) <- gl_headers