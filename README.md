# birthdays
This repo contains code (`/src`) and data (`/data`) for exploring whether Major League Baseball players play better, worse, or the same on their birthdays.

## Methods overview

Player-game box scores were downloaded for 1,108 player-games that fell on the player's birthday between 2005 and 2022. The full-season stats were downloaded for those same players. Aggregate hitting and pitching performance was compared between birthdays and non-birthdays. Non-birthday stats were calculated by subtracting birthday totals from full-season totals.

## Results

### Hitting

This dataset consisted of 1,108 player-birthday-games among 469 unique players.

|     | Plate appearances | Batting average | On-base average | Slugging average |
| :--: | :---------: | :--: | :--: | :--: |
| **Non-birthdays**   | 429,385    | .261 | .328 | .432 |
| **Birthdays**     |  3,991     | .249 | .308 | .410 |
| **p-value**   |    | .049 | .0045 | .0039 |

Hitters in this dataset performed statistically significantly worse on their birthdays than on their non-birthdays.

#### Calculating the p-values

Taking for example on-base average, if the players on their birthdays were actually the same players they were on their non-birthdays (.328 OBA), the probability of observing a birthday on-base average of .308 or lower in 3,991 plate appearances (p-value) is .0045. To calculate this in R,

`p_value = pbinom(.308 * 3991, 3991, .328)`

### Pitching

This dataset consisted of 90 pitcher-birthday-games among 71 unique pitchers. Pitchers were compared on the basis of run average (runs allowed per 9 innings) and strikeout rate (strikeouts per 9 innings).

|     | Innings pitched | Runs per 9 | Strikeouts per 9 |
| :--: | :---------: | :--: | :--: |
| **Non-birthdays**   | 12,293    | 4.37 | 7.85 |
| **Birthdays**     |  487.2     | 4.08 | 8.05 |
| **p-value**   |    | .161 | .313 |

Pitchers in this dataset had a lower run allowance rate and a higher strikeout rate on their birthday. However, due to the smaller sample size of pitcher birthday games, the pitcher birthday performance boost is not statistically significant.

#### Calculating the p-values

The Poisson test (`poisson.test` in R) was used to calculate the p-values for run rate being lower on birthdays than non, and strikeout rate being higher on birthdays than non.

### Best birthday boys

Players were filtered by having at least 16 birthday plate appearances, resulting in 82 players. Birthday boost was calculated as the difference between birthday OPS and non-birthday OPS. Below are the top 10 birthday boys.

|player            |birthday | birthday PA|birthday OPS |non-birthday OPS |birthday boost |
|:-----------------|:--------:|:-----------:|:------------:|:----------------:|:--------------:|
|Mike Trout        |Aug  7   |          18|1.567        |0.988            |0.579          |
|Andrew Benintendi |Jul  6   |          24|1.351        |0.780            |0.572          |
|Joc Pederson      |Apr 21   |          26|1.375        |0.821            |0.554          |
|Adam Duvall       |Sep  4   |          16|1.286        |0.785            |0.501          |
|Yonder Alonso     |Apr  8   |          17|1.221        |0.737            |0.484          |
|Austin Hedges     |Aug 18   |          16|1.080        |0.612            |0.468          |
|José Ramírez      |Sep 17   |          27|1.167        |0.819            |0.349          |
|Trea Turner       |Jun 30   |          17|1.162        |0.827            |0.335          |
|Miguel Cabrera    |Apr 18   |          21|1.159        |0.834            |0.325          |
|Jason Heyward     |Aug  9   |          16|1.038        |0.741            |0.298          |

### Birthday losers

Below are the top 10 birthday losers, ranked in order of birthday boost.

|player          |birthday | birthday PA|birthday OPS |non-birthday OPS |birthday boost |
|:-----------------|:--------:|:-----------:|:------------:|:----------------:|:--------------:|
|Justin Upton    |Aug 25   |          20|0.050        |0.810            |-0.760         |
|Chris Iannetta  |Apr  8   |          22|0.045        |0.712            |-0.666         |
|Carlos Correa   |Sep 22   |          23|0.317        |0.830            |-0.513         |
|Ian Desmond     |Sep 20   |          17|0.248        |0.740            |-0.492         |
|Brandon Belt    |Apr 20   |          22|0.336        |0.823            |-0.486         |
|Hunter Pence    |Apr 13   |          17|0.301        |0.761            |-0.459         |
|Zack Cozart     |Aug 12   |          21|0.295        |0.711            |-0.416         |
|George Springer |Sep 19   |          25|0.467        |0.843            |-0.376         |
|Maikel Franco   |Aug 26   |          17|0.368        |0.739            |-0.372         |
|Josh Bell       |Aug 14   |          21|0.458        |0.817            |-0.358         |

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
* The [baseballr](https://billpetti.github.io/baseballr/reference/index.html) package for getting player-game box scores and player-season totals
* The lookup table at [Smart Fantasy Baseball](https://www.smartfantasybaseball.com/tools/) for lining up players' bbrefID with their MLBID