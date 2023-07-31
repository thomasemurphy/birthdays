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

birthday_hits <- read_csv('../data/birthday_stats_cleaned/birthday_hitter_stats.csv')

birthday_hits$game_year <- substr(birthday_hits$game_date, 1, 4)
unique_years <- unique(birthday_hits$game_year)

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
    filter(player_id %in% players_this_year)
  birthday_boys_season_stats <- rbind(
    birthday_boys_season_stats,
    birthday_boys_this_year
  )
}

birthday_boys_season_stats <- birthday_boys_season_stats %>%
  mutate(game_year = as.character(season)) %>%
  distinct(player_id, game_year, .keep_all = TRUE)

birthday_boys_season_stats %>%
  select(player_id, season, game_year, player_full_name, hits, at_bats) %>%
  print(n = 10)

birthday_boys_non_birthday <- birthday_boys_season_stats %>%
  inner_join(birthday_hits,
            by = c('player_id', 'game_year'),
            suffix = c('_fs', '_bd'),
            multiple = 'all'
            ) %>%
  group_by(player_id, game_year) %>%
  summarize(
    across(
      c(hits_bd, at_bats_bd, plate_appearances_bd, base_on_balls_bd, hit_by_pitch_bd, total_bases_bd),
      sum),
    across(
      c(hits_fs, at_bats_fs, plate_appearances_fs, base_on_balls_fs, hit_by_pitch_fs, total_bases_fs),
      max)
    ) %>%
  mutate(hits = hits_fs - hits_bd,
         at_bats = at_bats_fs - at_bats_bd,
         plate_appearances = plate_appearances_fs - plate_appearances_bd,
         base_on_balls = base_on_balls_fs - base_on_balls_bd,
         hit_by_pitch = hit_by_pitch_fs - hit_by_pitch_bd,
         total_bases = total_bases_fs - total_bases_bd
         )

birthdays_slash <- c(
  calculate_ba(birthday_hits),
  calculate_obp(birthday_hits),
  calculate_slg(birthday_hits)
)

full_season_slash <- c(
  calculate_ba(birthday_boys_season_stats),
  calculate_obp(birthday_boys_season_stats),
  calculate_slg(birthday_boys_season_stats)
)
full_season_slash

non_bd_slash <- c(
  calculate_ba(birthday_boys_non_birthday),
  calculate_obp(birthday_boys_non_birthday),
  calculate_slg(birthday_boys_non_birthday)
)
non_bd_slash

sum(birthday_boys_non_birthday$plate_appearances)
sum(birthday_boys_season_stats$plate_appearances)
sum(birthday_hits$plate_appearances)

at_bats_bd <- sum(birthday_hits$at_bats)
hits_bd <- sum(birthday_hits$hits)
pa_bd <- sum(birthday_hits$plate_appearances)
ob_bd <- sum(birthday_hits$base_on_balls) + sum(birthday_hits$hit_by_pitch) + hits_bd
tb_bd <- sum(birthday_hits$total_bases)

oba_nbd <- calculate_obp(birthday_boys_season_stats)
ba_nbd <- calculate_ba(birthday_boys_non_birthday)
slg_nbd <- calculate_slg(birthday_boys_non_birthday)

p_value_ba <- pbinom(hits_bd, at_bats_bd, ba_nbd)
p_value_oba <- pbinom(ob_bd, pa_bd, oba_nbd)
p_value_slg <- pbinom(tb_bd, at_bats_bd, slg_nbd)

# look at some players

birthday_by_player <- birthday_hits %>%
  group_by(player_id, nameFirst, nameLast, birthDate) %>%
  summarize(pa = sum(plate_appearances),
            hits = sum(hits),
            at_bats = sum(at_bats),
            base_on_balls = sum(base_on_balls),
            hit_by_pitch = sum(hit_by_pitch),
            total_bases = sum(total_bases)
            ) %>%
  mutate(tot_ob = hits + base_on_balls + hit_by_pitch) %>%
  mutate(
    obp = tot_ob / pa,
    slg = total_bases / at_bats,
    ops = obp + slg
  ) %>%
  arrange(desc(pa))

bday_player_ids <- birthday_by_player$player_id

non_birthday_by_player <- birthday_boys_non_birthday %>%
  filter(player_id %in% bday_player_ids) %>%
  group_by(player_id) %>%
  summarize(pa = sum(plate_appearances),
            at_bats = sum(at_bats),
            tot_ob = sum(hits) + sum(base_on_balls) + sum(hit_by_pitch),
            total_bases = sum(total_bases)
  ) %>%
  mutate(
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
  ) %>%
  mutate(ops_diff = ops_bd - ops_nbd) %>%
  arrange(desc(ops_diff)) %>%
  print(n = 20)

birthday_sub <- birthday_vs_non_totals %>%
  select(player_id, nameFirst, nameLast, birthDate,
         pa_bd, at_bats_bd, tot_ob_bd, total_bases_bd
         ) %>%
  mutate(game_type = 'bd') %>%
  rename(c(
    'pa' = 'pa_bd',
    'at_bats' = 'at_bats_bd',
    'tot_ob' = 'tot_ob_bd',
    'total_bases' = 'total_bases_bd'
  ))

non_birthday_sub <- birthday_vs_non_totals %>%
  select(player_id, nameFirst, nameLast, birthDate,
         pa_nbd, at_bats_nbd, tot_ob_nbd, total_bases_nbd
  ) %>%
  mutate(game_type = 'nbd') %>%
  rename(c(
    'pa' = 'pa_nbd',
    'at_bats' = 'at_bats_nbd',
    'tot_ob' = 'tot_ob_nbd',
    'total_bases' = 'total_bases_nbd'
  ))

birthday_vs_non_tidy <- rbind(non_birthday_sub, birthday_sub) %>%
  arrange(nameLast) %>%
  write.csv('../data/birthday_vs_non_totals_by_hitter.csv')

birthday_by_player %>%
  filter(pa_bd >= 15) %>%
  arrange(ops_diff) %>%
  select(nameFirst, nameLast, birthDate, pa_bd, pa_nbd, ops_bd, ops_nbd, ops_diff) %>%
  print(n = 10)

birthday_hits %>%
  filter(player_id == 455104) %>%
  select(game_date, plate_appearances, hits)
  