library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

library(Lahman)
library(baseballr)
library(plotly)

#setwd('baseball/birthdays/src')
setwd('C:/repos/birthdays/src')

# Consider this alternate data source if you don't have statistical or theoretical reasons to include 2000-2105 and 2022 data.
# i.e. should we expect the birthday boy effect to be consistent across years?
# this script maps players in the player_id_map csv against mlb-game-data hittersByGame.csv and games.csv
# (from https://www.kaggle.com/datasets/josephvm/mlb-game-data/)
# who played on their birthday between 2016 and 2021

# see get_in_season_birthdays.R
in_season_birthdays <- read_csv('../data/player_lookup/in_season_birthdays.csv')

# read in games data
mlb_game_data_games <- read_csv('../data/kaggle_mlb_game_data/games.csv')

# read in hittersByGame data
mlb_game_data_hittersByGame <- read_csv('../data/kaggle_mlb_game_data/hittersByGame.csv')

# crosswalk between mlb id and espn id from
# https://www.smartfantasybaseball.com/2020/12/everything-you-need-to-know-about-the-player-id-map/
# post is from 2020 and says it is kept current, assume it is?
# check for and remove duplicates before joining with in_season_birthdays
sfbb_player_id_map <- read_csv('../data/sfbb_player_id/SFBB Player ID Map - PLAYERIDMAP.csv')

sfbb_player_id_map_dups <- sfbb_player_id_map %>% 
  group_by(MLBID) %>% 
  filter(n() > 1) %>% 
  arrange(MLBID)
sfbb_player_id_map_dups

# Othani's in there twice which kind of makes sense.
# Not sure about the rest. I guess Richard Palacios changed his name to "Richie?"
# Let's just drop the ones missing ESPNID and take one of the Othanis
sfbb_player_id_map_dedup <- sfbb_player_id_map %>% 
  filter(!is.na(ESPNID)) %>% 
  distinct(MLBID, ESPNID)

# add espn id to in_season_birthdays
# and convert date to MM-DD
# and again, get rid of the double Othanis
in_season_birthdays_plus_espn <- in_season_birthdays %>% 
  left_join(select(sfbb_player_id_map_dedup, ESPNID, MLBID), by = c("MLBID")) %>% 
  mutate(birthDateMMDD = format(as.Date(birthDate), "%m-%d")) %>%
  distinct()

# add dates to hittersByGame but first
# look at the game dates and times, something seems goofy with the timestamps
mlb_game_data_games_hour <- mlb_game_data_games %>% 
  mutate(Hour = format(as.POSIXct(Date), "%H"))

mlb_game_data_games_hour_sum <- mlb_game_data_games_hour %>% 
  group_by(Hour) %>% 
  summarize(n())
mlb_game_data_games_hour_sum
# so, yeah, looks like the time is when it was posted, not the time of game
# so adjust dates back one if posted between midnight and noon
mlb_game_data_games_date_adj <- mlb_game_data_games_hour %>% 
  mutate(Date = if_else(Hour < 12, Date - days(1), Date))

# check for dups in mlb_game_data_games to see what's up with that
mlb_game_data_games_dups <- mlb_game_data_games_date_adj %>% 
  group_by(Game) %>% 
  filter(n() > 1) %>% 
  arrange(Game)
mlb_game_data_games_dups

# dups seem dumb and no weirdness with Game and Date, so just keep distinct
mlb_game_data_games_dedup <- mlb_game_data_games_date_adj %>% 
  distinct(Game, Date)

# convert `Hitter Id` in hittersByGame to ESPNID and make it numeric
# and get rid of anyting missing `Hitter Id` / ESPNID (the TEAM rows)
mlb_game_data_hittersByGame_plus_date <- mlb_game_data_hittersByGame %>%
  filter(!is.na(`Hitter Id`) & `Hitter Id` != "-" & Position != "TEAM") %>% 
  inner_join(select(mlb_game_data_games_dedup, Game, Date), by = "Game") %>% 
  mutate(DateMMDD = format(as.Date(Date), "%m-%d"),
         ESPNID = as.numeric(`Hitter Id`)) %>% 
  select(-`Hitter Id`)

# assign birthday boys
# and convert date to MM-DD
mlb_game_data_hittersByGame_bbs <- mlb_game_data_hittersByGame_plus_date %>% 
  right_join(select(in_season_birthdays_plus_espn, -birthDate, -birthDateMMDD), by = "ESPNID") %>% 
  left_join(select(in_season_birthdays_plus_espn, ESPNID, birthDate, birthDateMMDD), by = (c("ESPNID", c("DateMMDD" = "birthDateMMDD")))) %>% 
  mutate(birthday_boy = if_else(is.na(birthDate), 0, 1),
         PA = AB + BB) %>% 
  group_by(birthday_boy)

bb_yes <- mlb_game_data_hittersByGame_bbs %>% 
  filter(!is.na(PA) & PA > 0 & birthday_boy == 1) %>% 
  ungroup()

bb_no <- mlb_game_data_hittersByGame_bbs %>% 
  filter(!is.na(PA) & PA > 0 & birthday_boy == 0) %>%
  right_join(distinct(select(bb_yes, ESPNID)), by = "ESPNID")

bbs_obp_compare <- bb_yes %>% 
  bind_rows(bb_no) %>% 
  group_by(birthday_boy) %>% 
  summarize(sum_H = sum(H), sum_BB = sum(BB), sum_PA = sum(PA)) %>% 
  mutate(obp = (sum_H + sum_BB) / sum_PA)
bbs_obp_compare
# not much difference, but non birthday boys a little better on obp?
# given sample size, probably statistically significant, if not practically

# look for good birthday boys and bad birthday boys
bbs_obp_player <- bb_yes %>%
  bind_rows(bb_no) %>% 
  group_by(ESPNID, nameFirst, nameLast, birthday_boy) %>% 
  summarize(sum_H = sum(H), sum_BB = sum(BB), sum_PA = sum(PA)) %>% 
  mutate(obp = (sum_H + sum_BB) / sum_PA) %>% 
  ungroup()

# Let's just look at those with 10+ PA on their BD
bbs_obp_player_compare <- bbs_obp_player %>% 
  filter(birthday_boy == 1) %>% 
  transmute(ESPNID, nameFirst, nameLast, PA_yes = sum_PA, obp_yes = obp) %>% 
  left_join(filter(bbs_obp_player, birthday_boy == 0) %>% transmute(ESPNID, PA_no = sum_PA, obp_no = obp), by = "ESPNID") %>% 
  filter(PA_yes >= 10)

# Create a custom color scale from light to dark blue for ratio of BD obp to not BD obp (darker = bigger BD bump)
color_scale <- colorRamp(c("lightblue", "darkblue"))

bb_plot <- plot_ly(bbs_obp_player_compare, x = ~obp_no, y = ~obp_yes, color = ~obp_yes / obp_no,
                       colors = color_scale,
                       text = ~paste(nameFirst, nameLast, "PA on not BD:", PA_no, "PA on BD:", PA_yes),
                       type = "scatter",
                       mode = "markers",
                       marker = list(size = 8, opacity = 0.8),
                       showlegend = FALSE) %>%
    layout(
      title = list(
        text = "OBP Not on Birthday vs. on Birthday",
        font = list(size = 16)
      ),
      xaxis = list(
        title = "OBP Not on Birthday",
        titlefont = list(size = 14)
      ),
      yaxis = list(
        title = "OBP on Birthday",
        titlefont = list(size = 14)
      ),
      hovermode = "closest",
      height = 600, width = 700, margin = list(l = 50, r = 50, b = 50, t = 50)
    ) %>%
    add_lines(data = bbs_obp_player_compare, x = ~obp_no, y = ~lm(obp_yes ~ obp_no)$fitted.values, line = list(shape = "linear"), inherit = F)

bb_plot
# some similarities with Tom's best birthday boys (which looks at ops)
# Conculsions:
# Austin Hedges and Joc Pederson rule on their birthdays
# Justin Upton and Carlos Corea suck on their birthdays
# Othani is actually two guys
