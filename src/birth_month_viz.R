library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)

library(Lahman)
library(baseballr)

setwd('baseball/birthdays')

playerInfo('aaron')

playerInfo('baez')

joeID <-c(subset(People, nameLast=="Jackson" & nameFirst=="Shoeless Joe")["playerID"])

subset(People, playerID == 'wisdopa01')

People %>%
  count(birthCountry) %>%
  arrange(desc(n))

by_state <- People %>%
  filter(birthCountry == 'USA') %>%
  count(birthState) %>%
  arrange(desc(n)) %>%
  as_tibble() %>%
  print(n = 51)

my_players <- People %>%
  mutate(debut = as_date(debut)) %>%
  mutate(debut_year = year(debut))

valid_countries <- my_players %>%
  count(birthCountry) %>%
  filter(n > 1) %>%
  filter(!is.na(birthCountry)) %>%
  pull(birthCountry)

by_country_year <- my_players %>%
  filter(birthCountry %in% valid_countries) %>%
  count(birthCountry, debut_year)

non_us <- by_country_year %>%
  filter(birthCountry != 'USA')

ggplot(non_us, aes(x = debut_year, y = n, group = birthCountry, color = birthCountry)) +
  geom_line() +
  theme_bw()

ggplot(non_us, aes(x = debut_year, y = birthCountry, fill = n)) +
  geom_tile(
    width = 0.5,
    height = 0.5
  ) +
  theme_bw()

mo_name <- c(
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
)

mo_name <- factor(mo_name, levels = mo_name)

by_month <- People %>%
  filter(birthCountry == 'USA') %>%
  count(birthMonth) %>%
  filter(!is.na(birthMonth)) %>%
  mutate(n_days = c(31, 28.25, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)) %>%
  mutate(mo_name = mo_name) %>%
  mutate(per_day = n / n_days)

mean_pd <- mean(by_month$per_day)
june_pd <- by_month$per_day[6]
aug_pd <- by_month$per_day[8]

june_pct <- (june_pd - mean_pd) / mean_pd
aug_pct <- (aug_pd - mean_pd) / mean_pd

by_month$pct_labels <- c(rep('',5), june_pct, '', aug_pct, rep('',4))

ggplot(by_month, aes(x = mo_name, y = per_day, label = pct_labels)) +
  geom_bar(
    stat = 'identity',
    color = 'black',
    linewidth = 0,
    fill = '#000000',
    width = 0.5,
    alpha = 0.6
  ) +
  # geom_label() +
  annotate(
    'text',
    x = 'Jun',
    y = 44,
    size = 3,
    color = '#777777',
    label = '-12%'
  ) +
  annotate(
    'text',
    x = 'Aug',
    y = 57.5,
    size = 3,
    color = '#777777',
    label = '+16%'
  ) +
  labs(
    title = 'US-born MLB players by birth month',
    subtitle = 'Per number of days in month') +
  scale_x_discrete(
    name = ''
  ) +
  scale_y_continuous(
    name = '',
    limits = c(0, 60),
    breaks = seq(0, 60, 10)
  ) +
  geom_hline(
    yintercept = mean(by_month$per_day),
    linewidth = 0.3,
    color = '#000000',
    alpha = 0.6,
    lty = 'dashed'
  ) +
  theme_bw() +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.border = element_blank(),
    axis.ticks = element_blank(),
    axis.text = element_text(size = 10, color = '#666666'),
    title = element_text(color = '#555555')
  )

People %>%
  filter(birthState == 'CA') %>%
  filter(birthCity == 'Oakland') %>%
  arrange(desc(as_date(debut))) %>%
  select(nameFirst, nameLast, debut)

People %>%
  count(bats) %>%
  arrange(desc(n)) %>%
  mutate(pct = n / sum(n))


ggplot(People, aes(x = birthMonth)) +
  geom_histogram() +
  scale_x_continuous(breaks = seq(1,12)) +
  theme_bw()

birthdays <- People %>%
  mutate(finalGame = as_date(finalGame)) %>%
  filter(finalGame >= as_date('2000-01-01'))