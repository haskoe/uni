library(dplyr)

df <- read.csv('CPC.csv')
df <- df[!is.na(df$bw),]

# bw statistics grouped by male/female
df %>% group_by(sex) %>%
  summarise(
    n = n(),
    mean(bw, na.rm = T),
    sd(bw, na.rm = T),
    min(bw, na.rm = T),
    max(bw, na.rm = T),
    median(bw, na.rm = T))

# bw statistics grouped by male/female and Maternal marital status
df_sm <- df[!is.na(df$sm),]
df_sm %>% group_by(sex,sm) %>%
  summarise(
    n = n(),
    mean(bw, na.rm = T),
    sd(bw, na.rm = T),
    min(bw, na.rm = T),
    max(bw, na.rm = T),
    median(bw, na.rm = T))

# proportion of bw>4000 grouped by male/female and Maternal marital status
df_sm %>% 
  group_by(sex,sm) %>% 
  summarise(
    n = n(),
    above_4000 = 100* sum(bw >= 4000) / n(),
    below_4000 = 100 * sum(bw < 4000)/ n())

# proportion breastfed less than 8w
df_sm[!is.na(df_sm$bf),] %>% 
  group_by(sex,sm) %>% 
  summarise(
    n = n(),
    lt_8w = 100* sum(bf <= 8) / n(),
    gt_8w = 100* sum(bf > 8) / n())

# proportion complementary feeding starting less than 12w
df_sm[!is.na(df_sm$cf),] %>% 
group_by(sex,sm) %>% 
  summarise(
    n = n(),
    lt_12w = 100* sum(cf <= 12) / n(),
    gt_12w = 100* sum(cf > 12) / n())

# 2 BMI
df_bmi <- df_sm[!is.na(df_sm$wt) & !is.na(df_sm$ht),] %>% 
  mutate(BMI = wt/(ht/100)^2)

# above/below BMI 25 percentage grouped by sex and .....
df_bmi %>% 
  group_by(sex,sm) %>% 
  summarise(
    n = n(),
    above_25 = 100* sum(BMI >= 25) / n(),
    below_25 = 100* sum(BMI < 25) / n())
