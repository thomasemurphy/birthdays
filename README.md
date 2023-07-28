# birthdays
This repo contains code (`/src`) and data (`/data`) for exploring whether baseball players play better, worse, or the same on their birthdays.

## Thank you for these open-source packages
* The [Lahman](https://cran.r-project.org/web/packages/Lahman/index.html) package for getting player birthdays
* The [baseballr](https://billpetti.github.io/baseballr/reference/index.html) package for getting player-game box scores
* The lookup table at [Smart Fantasy Baseball](https://www.smartfantasybaseball.com/tools/) for lining up players' bbrefID with their MLBID

## Data pipeline

The data pipeline is very inefficient. If you can make it better, submit a pull request!

### `get_in_season_birthdays.R`
This script loads the `People` dataframe of the `Lahman` package to get player birthdays. The `People` dataframe is filtered to only include players with a birthday between April 1 and September 30, and who played at least one game since the year 2000. The Smart Fantasy Baseball lookup table is used to match each player's baseball-reference ID to their MLBID, which will be needed for getting player-game box scores later. The resulting dataframe of players since 2000 with in-season birthdays is then saved to `data/player_lookup/in_season_birthdays.csv`

### `get_birthday_box_scores.R`
This script contains some really bad code. For each player in `in_season_birthdays.csv`, it generates date strings for each of that player's birthdays while they were active after 2000. For each active birthday for that player, the `baseballr::mlb_game_pks()` function is used to generate `game_pk` (integer) values for all games on that date. Then, the function `baseballr::mlb_player_game_stats()` was used to loop through all games on that date until a game containing that player was found. I know, terrible. But I didn't know what team the player was playing for at the time, and it was easier to just let the API wrapper run overnight.

If a box score was found for a player on their birthday, that box score was saved to `data/birthday_box_scores/[MLBID]_[date].csv`.

### `birthday_stats_hitting.R` and `birthday_stats_pitching.R`
