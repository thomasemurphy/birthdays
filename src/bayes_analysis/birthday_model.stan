data {
  int<lower=0> nplayers;
  int y_non_birthday[nplayers]; // binomial outcome for non birthdays
  int y_birthday[nplayers]; // binomial outcome for birthdays
  int n_non_birthday[nplayers]; // attempts, non birthdays
  int n_birthday[nplayers]; // attempts birthdays
}

parameters {
  real<lower=0, upper=1> non_birthday_mean; // league average success probability, non bdays
  real<lower=0> birthday_multiplier_global; // multipler for the odds of success on birthdays (avg)
  vector<lower=0>[nplayers] birthday_multiplier; // multipler for the odds, per player
  vector<lower=0, upper=1>[nplayers] theta_non_birthday; // success probability, per player
  real<lower=0> sigma_non_bday; // variation in theta_non_bday across players
  
} transformed parameters {

  vector<lower=0>[nplayers] birthday_odds; // odds of sucess on birthdays
  vector<lower=0, upper=1>[nplayers] theta_birthday; // probability scale
  
  // birthday odds is non birthday odds times multiplier
  birthday_odds = theta_non_birthday ./ (1.0 - theta_non_birthday) .* birthday_multiplier;
  // convert to probability scale
  theta_birthday = birthday_odds ./ (1.0 + birthday_odds);
  
}

model {
  
  sigma_non_bday ~ normal(0, 1);
  
  // non birthday success is normal about league average
  theta_non_birthday ~ normal(non_birthday_mean, sigma_non_bday);
  
  // birthday multiplier is normal about league average multiplier
  birthday_multiplier ~ normal(birthday_multiplier_global, 0.05);
  
  // binomial likelihood
  y_non_birthday ~ binomial(n_non_birthday, theta_non_birthday);
  y_birthday ~ binomial(n_birthday, theta_birthday);
}

