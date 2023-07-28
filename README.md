# birthdays
This repo contains code (`/src`) and data (`/data`) for exploring whether Major League Baseball players play better, worse, or the same on their birthdays.

## Methods overview

Player-game box scores were downloaded for 1,108 player-games that fell on the player's birthday between 2005 and 2022. The full-season stats were downloaded for those same players. Aggregate hitting and pitching performance was compared between birthdays and full season.

## Results

### Hitting

This dataset consisted of 1,108 player-birthday-games among 469 unique players. Players in this dataset hit worse on their birthday.

|     | Plate appearances | Batting average | On-base average | Slugging average |
| :--: | :---------: | :--: | :--: | :--: |
| **Birthdays**     |  3,991     | .249 | .308 | .410 |
| **Full season**   | 433,376    | .261 | .328 | .432 |

For on-base average, if the players on their birthdays were actually the same players they were throughout the season (.328 OBA), the probability of observing a birthday on-base average of .308 or lower in 3,991 plate appearances (p-value) is .004. Therefore, the players in this dataset had a statistically significantly lower OBA on their birthdays. The p-value for slugging average was .004 (significantly worse) and for batting average was .051 (right on the black).

## More detail on the data pipeline, which is bad

The data pipeline is very inefficient. If you can make it better, submit a pull request!

#### `get_in_season_birthdays.R`
This script loads the `People` dataframe of the `Lahman` package to get player birthdays. The `People` dataframe is filtered to only include players with a birthday between April 1 and September 30, and who played at least one game since the year 2000. The Smart Fantasy Baseball lookup table is used to match each player's baseball-reference ID to their MLBID, which will be needed for getting player-game box scores later. The resulting dataframe of players since 2000 with in-season birthdays is then saved to `data/player_lookup/in_season_birthdays.csv`

#### `get_birthday_box_scores.R`
This script contains some really bad code. For each player in `in_season_birthdays.csv`, it generates date strings for each of that player's birthdays while they were active after 2000. For each active birthday for that player, the `baseballr::mlb_game_pks()` function is used to generate `game_pk` (integer) values for all games on that date. Then, the function `baseballr::mlb_player_game_stats()` was used to loop through all games on that date until a game containing that player was found. I know, terrible. But I didn't know what team the player was playing for at the time, and it was easier to just let the API wrapper run overnight.

If a box score was found for a player on their birthday, that box score was saved to `data/birthday_box_scores/[MLBID]_[date].csv`.

#### `birthday_stats_hitting.R` and `birthday_stats_pitching.R`
These scripts clean the box scores in `data/birthday_box_scores/`. The result of `birthday_stats_hitting.R` is a dataframe with each row being a player-birthday-game, saved into `data/birthday_stats_cleaned`. Same for pitching.

#### `get_season_stats_hitting.R` and `get_season_stats_pitching.R`

These scripts get player season stats for all player-season combinations in `data/birthday_box_scores/` using the `baseballr::mlb_stats()` function.

#### `birthday_vs_non_hitting.R` and `birthday_vs_non_pitching.R`

These are sandbox scripts for comparing hitting and pitching performance on birthdays vs not.

## Thank you for these open-source packages
* The [Lahman](https://cran.r-project.org/web/packages/Lahman/index.html) package for getting player birthdays
* The [baseballr](https://billpetti.github.io/baseballr/reference/index.html) package for getting player-game box scores
* The lookup table at [Smart Fantasy Baseball](https://www.smartfantasybaseball.com/tools/) for lining up players' bbrefID with their MLBID