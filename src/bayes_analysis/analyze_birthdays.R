library(tidyverse)
library(cmdstanr)
library(tidybayes)
library(shinystan)

options(mc.cores=4)


bball_data <- read_csv("../../data/birthday_vs_non_totals_by_hitter.csv")

non_bday_data <- bball_data %>% filter(game_type == "nbd")
bday_data <- bball_data %>% filter(game_type == "bd")


n_players <- nrow(non_bday_data)
y_non_birthday <- non_bday_data$tot_ob
y_birthday <- bday_data$tot_ob
n_non_birthday <- non_bday_data$pa
n_birthday <- bday_data$pa

cmdstan_model <- cmdstanr::cmdstan_model("birthday_model.stan")

stan_samples <- cmdstan_model$sample(data = list(nplayers=n_players,
                                   y_non_birthday=y_non_birthday,
                                   y_birthday=y_birthday,
                                   n_non_birthday=n_non_birthday,
                                   n_birthday=n_birthday),
                     seed = 123,
                     chains = 4,
                     iter_sampling=4000, 
                     thin=10)

stan_samples$summary()


samps <- stan_samples$draws(format="df")
samps$non_birthday_mean
mean(samps$birthday_multiplier_global > 1)

mean(samps$non_birthday_mean)


summary(samps$birthday_multiplier_global)

thetas <- samps %>% spread_draws(birthday_multiplier[K], theta_birthday[K], theta_non_birthday[K])
theta_summary <- thetas %>% mutate(theta_diff = theta_birthday - theta_non_birthday) %>% 
  group_by(K) %>% 
  summarise(pm = mean(birthday_multiplier), 
            q025=quantile(probs=c(0.025), theta_diff),
            q975=quantile(probs=c(0.975), theta_diff)) %>% 
  ungroup()

theta_summary$name <- paste(non_bday_data$nameFirst, non_bday_data$nameLast, sep=" ")
theta_summary$nbday <- bday_data$pa
theta_summary$theta_bday <- bday_data$tot_ob/bday_data$pa
theta_summary$theta_nbday <- non_bday_data$tot_ob/non_bday_data$pa


theta_summary %>% arrange(pm) %>% print(n=500)
#%>% ggplot() + geom_histogram(aes(x=pm))


shinystan::launch_shinystan(stan_samples)
