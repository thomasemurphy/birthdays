library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

library(Lahman)
library(baseballr)

setwd('baseball/birthdays/src')

calculate_obp <- function(hitter_df) {
  tot_ob <- sum(hitter_df$hits) +
    sum(hitter_df$base_on_balls) +
    sum(hitter_df$hit_by_pitch)
  tot_pa <- sum(hitter_df$plate_appearances)
  obp <- tot_ob / tot_pa
  obp
}

calculate_ba <- function(hitter_df) {
  ba <- sum(hitter_df$hits) / sum(hitter_df$at_bats)
  ba
}

calculate_slg <- function(hitter_df) {
  slg <- sum(hitter_df$total_bases) / sum(hitter_df$at_bats)
  slg
}

# load birthday hitter box scores
birthday_hits <- read_csv('../data/birthday_stats_cleaned/birthday_hitter_stats.csv') %>%
  mutate(game_year = substr(game_date, 1, 4))

unique_years <- unique(birthday_hits$game_year)

# load full-season stats for all player-years in birthday_hits
birthday_boys_season_stats <- data.frame()
for (year_str in unique_years) {
  print(year_str)
  season_stats_fname <- paste0('../data/player_season_stats/hitting_stats_',
                               year_str,
                               '.csv')
  season_stats_df <- read_csv(season_stats_fname)
  players_this_year <- birthday_hits %>%
    filter(game_year == year_str) %>%
    pull(player_id)
  birthday_boys_this_year <- season_stats_df %>%
    filter(player_id %in% players_this_year) %>%
    mutate(game_year = year_str)
  birthday_boys_season_stats <- rbind(
    birthday_boys_season_stats,
    birthday_boys_this_year
  )
}

# take a look
birthday_boys_season_stats %>%
  select(player_id, season, game_year, player_full_name, hits, at_bats) %>%
  print(n = 10)

# subtract birthday stats from full-season stats to get non-birthday stats
birthday_boys_non_birthday <- birthday_boys_season_stats %>%
  inner_join(birthday_hits,
            by = c('player_id', 'game_year'),
            suffix = c('_fs', '_bd'),
            multiple = 'all'
            ) %>%
  
  # take care of double-headers
  group_by(player_id, game_year) %>%
  summarize(
    across(
      c(hits_bd, at_bats_bd, plate_appearances_bd, base_on_balls_bd, hit_by_pitch_bd, total_bases_bd, strike_outs_bd, home_runs_bd),
      sum),
    across(
      c(hits_fs, at_bats_fs, plate_appearances_fs, base_on_balls_fs, hit_by_pitch_fs, total_bases_fs, strike_outs_fs, home_runs_fs),
      max)
    ) %>%
  
  mutate(hits = hits_fs - hits_bd,
         at_bats = at_bats_fs - at_bats_bd,
         plate_appearances = plate_appearances_fs - plate_appearances_bd,
         base_on_balls = base_on_balls_fs - base_on_balls_bd,
         hit_by_pitch = hit_by_pitch_fs - hit_by_pitch_bd,
         total_bases = total_bases_fs - total_bases_bd,
         strike_outs = strike_outs_fs - strike_outs_bd,
         home_runs = home_runs_fs - home_runs_bd
         )

# birthday vs non slash lines
birthdays_slash <- c(
  calculate_ba(birthday_hits),
  calculate_obp(birthday_hits),
  calculate_slg(birthday_hits)
)
birthdays_slash

non_bd_slash <- c(
  calculate_ba(birthday_boys_non_birthday),
  calculate_obp(birthday_boys_non_birthday),
  calculate_slg(birthday_boys_non_birthday)
)
non_bd_slash

# birthday totals
at_bats_bd <- sum(birthday_hits$at_bats)
hits_bd <- sum(birthday_hits$hits)
pa_bd <- sum(birthday_hits$plate_appearances)
ob_bd <- sum(birthday_hits$base_on_balls) + sum(birthday_hits$hit_by_pitch) + hits_bd
tb_bd <- sum(birthday_hits$total_bases)
home_runs_bd <- sum(birthday_hits$home_runs)
walks_bd <- sum(birthday_hits$base_on_balls)
strikeouts_bd <- sum(birthday_hits$strike_outs)

# non-birthday totals
walks_nbd <- sum(birthday_boys_non_birthday$base_on_balls)
strikeouts_nbd <- sum(birthday_boys_non_birthday$strike_outs)
home_runs_nbd <- sum(birthday_boys_non_birthday$home_runs)
pa_nbd <- sum(birthday_boys_non_birthday$plate_appearances)
oba_nbd <- calculate_obp(birthday_boys_season_stats)
ba_nbd <- calculate_ba(birthday_boys_non_birthday)
slg_nbd <- calculate_slg(birthday_boys_non_birthday)
walk_rate_nbd <- walks_nbd / pa_nbd
k_rate_nbd <- strikeouts_nbd / pa_nbd
hr_rate_nbd <- home_runs_nbd / pa_nbd

# frequentist aggregate p-values
p_value_ba <- pbinom(hits_bd, at_bats_bd, ba_nbd)
p_value_oba <- pbinom(ob_bd, pa_bd, oba_nbd)
p_value_slg <- pbinom(tb_bd, at_bats_bd, slg_nbd)
p_value_walks <- pbinom(walks_bd, pa_bd, walk_rate_nbd)
p_value_strikeouts <- pbinom(strikeouts_bd, pa_bd, k_rate_nbd, lower.tail = FALSE)
p_value_hr <- pbinom(home_runs_bd, pa_bd, hr_rate_nbd)

# by-player birthday performance
birthday_by_player <- birthday_hits %>%
  group_by(player_id, nameFirst, nameLast, birthDate) %>%
  summarize(pa = sum(plate_appearances),
            hits = sum(hits),
            at_bats = sum(at_bats),
            base_on_balls = sum(base_on_balls),
            hit_by_pitch = sum(hit_by_pitch),
            total_bases = sum(total_bases),
            strike_outs = sum(strike_outs),
            home_runs = sum(home_runs)
            ) %>%
  mutate(
    tot_ob = hits + base_on_balls + hit_by_pitch,
    obp = tot_ob / pa,
    slg = total_bases / at_bats,
    ops = obp + slg
  ) %>%
  arrange(desc(pa))

# by-player non-birthday performance
bday_player_ids <- birthday_by_player$player_id
non_birthday_by_player <- birthday_boys_non_birthday %>%
  filter(player_id %in% bday_player_ids) %>%
  group_by(player_id) %>%
  summarize(pa = sum(plate_appearances),
            hits = sum(hits),
            at_bats = sum(at_bats),
            base_on_balls = sum(base_on_balls),
            hit_by_pitch = sum(hit_by_pitch),
            total_bases = sum(total_bases),
            strike_outs = sum(strike_outs),
            home_runs = sum(home_runs)
  ) %>%
  mutate(
    tot_ob = hits + base_on_balls + hit_by_pitch,
    obp = tot_ob / pa,
    slg = total_bases / at_bats,
    ops = obp + slg
  ) %>%
  arrange(desc(ops)) %>%
  print(n = 20)

birthday_vs_non_totals <- birthday_by_player %>%
  left_join(
    non_birthday_by_player,
    by = 'player_id',
    suffix = c('_bd', '_nbd')
  )

birthday_sub <- birthday_vs_non_totals %>%
  select(player_id, nameFirst, nameLast, birthDate,
         pa_bd, at_bats_bd, tot_ob_bd, total_bases_bd,
         strike_outs_bd, base_on_balls_bd, home_runs_bd
         ) %>%
  mutate(game_type = 'bd') %>%
  rename(c(
    'pa' = 'pa_bd',
    'at_bats' = 'at_bats_bd',
    'tot_ob' = 'tot_ob_bd',
    'total_bases' = 'total_bases_bd',
    'strike_outs' = 'strike_outs_bd',
    'walks' = 'base_on_balls_bd',
    'hr' = 'home_runs_bd'
  ))

non_birthday_sub <- birthday_vs_non_totals %>%
  select(player_id, nameFirst, nameLast, birthDate,
         pa_nbd, at_bats_nbd, tot_ob_nbd, total_bases_nbd,
         strike_outs_nbd, base_on_balls_nbd, home_runs_nbd
  ) %>%
  mutate(game_type = 'nbd') %>%
  rename(c(
    'pa' = 'pa_nbd',
    'at_bats' = 'at_bats_nbd',
    'tot_ob' = 'tot_ob_nbd',
    'total_bases' = 'total_bases_nbd',
    'strike_outs' = 'strike_outs_nbd',
    'walks' = 'base_on_balls_nbd',
    'hr' = 'home_runs_nbd'
  ))

# save results for
birthday_vs_non_tidy <- rbind(non_birthday_sub, birthday_sub) %>%
  arrange(nameLast, nameFirst)

write.csv(birthday_vs_non_tidy, '../data/birthday_vs_non_totals_by_hitter.csv')

birthday_by_player %>%
  filter(pa_bd >= 15) %>%
  arrange(ops_diff) %>%
  select(nameFirst, nameLast, birthDate, pa_bd, pa_nbd, ops_bd, ops_nbd, ops_diff) %>%
  print(n = 10)

# look for a player by ID
birthday_hits %>%
  filter(player_id == 455104) %>%
  select(game_date, plate_appearances, hits)
  