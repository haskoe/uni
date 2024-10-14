library(dplyr)
library(tidyr)
library(ggplot2)

STUD_NR <- "Stud_Nr"
STUDY <- "Study"
SEX <- "Sex"
PROTEIN <- "Protein g"
TOTAL_ENERGY <- "Total energy"
TOTAL_ENERGY_RI <- "Total energy RI"
TOTAL_ENERGY_RI_REF <- "Total energy RI	RI ref"
RI <- "RI"
RI_FRAC <- "RI_ref"
NUTRIENT <- "Nutrient"
NUTRIENT_TYPE <- "Nutrienttype"
BMR <- "BMR kcal"

MACRO <- "macro"
MICRO <- "micro"
AMINO_ACIDS <- "amino acid"

FFQ <- "ffq"
H24 <- "24-hour"
D4 <- "4-days"

fixed_cols <- c(STUD_NR, SEX)
our_group <- c(8,19,34,35,66)

nutrient_list_by_type <- function(ref, nutrient_type) {
  return ((ref %>% filter(Nutrienttype == nutrient_type) %>% select(Nutrient) %>% distinct())[,1])
}

get_url <- function(filename_wo_extension){
  #return (paste('https://raw.githubusercontent.com/haskoe/uni/refs/heads/main/k1/opgave-01/', filename_wo_extension, '.csv', sep=''))
  return (paste(filename_wo_extension, '.csv', sep=''))
}

# format. we want to end with this
# stud.nr, sex, study, nutrienttype, nutrient, calc. value, fraction of ref.
#
# calc, vlkue:
#   a) macro: 1) energy for each nutrient, 2) sum of energy and 3) fraction of total energy for each nutrient
#   b) micro: N/A
#   c) amino acids: intake / protein intake in grams (should be sufficient because it is the protein composition that is of interest)
# compare a, b and c with recommended value in ri-denorm.csv

get_study_result <- function(df, study_name, df_ref, df_empty, energy_conv_factor) {
  df_res <- df_empty

  all_nutrients <- (df_ref %>% select(Nutrient) %>% distinct())[,1]

  # macro calculation
  nutrient_cols <- nutrient_list_by_type(df_ref,MACRO)
  tmp <- df %>% select(all_of(fixed_cols))
  tmp[STUDY] = study_name
  tmp[NUTRIENT_TYPE] = MACRO
  
  # calculate energy from each macro nutrient
  for (nutrient_name in nutrient_cols) {
    tmp[nutrient_name] <- df[nutrient_name] * energy_conv_factor[nutrient_name]
  }
  
  # total energy
  tmp[TOTAL_ENERGY] <- rowSums(tmp[,nutrient_cols])
  
  # fraction of total energy for each macro nutrient
  for (nutrient_name in nutrient_cols) {
   tmp[nutrient_name] <- tmp[nutrient_name] / tmp[TOTAL_ENERGY] 
  }
  
  # fraction of total energy needed for each subject
  #tmp[TOTAL_ENERGY_RI] <- tmp[TOTAL_ENERGY] / df[BMR] 

  # add pivoted macro dataframe to resulting
  df_res <- rbind(df_res,pivot_longer(tmp %>% select(!c(TOTAL_ENERGY)),nutrient_cols))

  # micro nutrients are appended w/o modification
  # we are repeating code here !!
  nutrient_cols <- nutrient_list_by_type(df_ref,MICRO)
  tmp <- df %>% select(all_of(fixed_cols))
  tmp[STUDY] = study_name
  tmp[NUTRIENT_TYPE] = MICRO
  for (nutrient_name in nutrient_cols) {
    tmp[nutrient_name] <- df[nutrient_name]
  }
  df_res <- rbind(df_res,pivot_longer(tmp, nutrient_cols))

    # amino acids
  # we are repeating code here !!
  nutrient_cols <- nutrient_list_by_type(df_ref,AMINO_ACIDS)
  tmp <- df %>% select(all_of(fixed_cols))
  tmp[STUDY] = study_name
  tmp[NUTRIENT_TYPE] = AMINO_ACIDS
  for (nutrient_name in nutrient_cols) {
    tmp[nutrient_name] <- df[nutrient_name] / df[PROTEIN]
  }
  df_res <- rbind(df_res,pivot_longer(tmp, nutrient_cols))
  df_res <- df_res %>% rename_at(c("name","value"), ~c(NUTRIENT,RI))

  # we can now calculate fraction of ref. value with join on gender and nutrient
  joined <- left_join(df_res, df_ref, by = c(SEX,NUTRIENT), keep = TRUE)
  df_res[RI_FRAC] <- joined[RI] / joined$Refvalue

  return (df_res)
}

get_studies_combined_dataframe <- function() {
  df_energy_conv_factor <- read.csv(get_url("kcal_pr_g"), sep = ";", dec=".", strip.white=TRUE)
  energy_conv_factor <- setNames(as.numeric(df_energy_conv_factor$toenergyfactor),as.character(df_energy_conv_factor$macronutrient))

    df_empty <- read.csv(get_url("new-empty"), sep = "\t", dec=".", strip.white=TRUE, check.names=FALSE)
  df_ref <- read.csv(get_url("ri-denorm"), sep = "\t", dec=".", strip.white=TRUE, check.names=FALSE)
  
  df_ffq <- read.csv(get_url(paste(FFQ,'.fixed',sep='')), sep = "\t", dec=".", strip.white=TRUE, check.names=FALSE)
  df_24h <- read.csv(get_url(paste(H24,'.fixed',sep='')), sep = "\t", dec=".", strip.white=TRUE, check.names=FALSE)
  df_4d <- read.csv(get_url(paste(D4,'.fixed',sep='')), sep = "\t", dec=".", strip.white=TRUE, check.names=FALSE)
  
  res <- df_empty
  res <- rbind( res, get_study_result( df_ffq , FFQ, df_ref, df_empty, energy_conv_factor))
  #res <- rbind( res, get_study_result( df_24h , H24, df_ref, df_empty, energy_conv_factor))
  #res <- rbind( res, get_study_result( df_4d , D4, df_ref, df_empty, energy_conv_factor))

  return (res)
}

df <- get_studies_combined_dataframe()

df_ffq <- df %>% filter(Study == FFQ)

# bar plot of protein RI_ref by student
ggplot( df_ffq %>% filter(Nutrient == PROTEIN),
        aes(x = Stud_Nr, y = RI_ref)) +
  geom_bar(stat = "identity", position = position_dodge(0.9))


# bar plot mean amino acid RI for groups female and male in study FFW
df_amino_ffq <- df %>% filter(Nutrienttype == AMINO_ACIDS) 
ggplot( df_amino_ffq
        %>% group_by(Sex, Nutrient)
        %>% summarise( 
          n = sum(!is.na(RI_ref)), 
          mean = mean(RI_ref, na.rm = TRUE), 
          se = sd(RI_ref, na.rm = TRUE) / sqrt(n)),
        aes(x = Nutrient, y = mean, fill = Sex)) +
  geom_bar(stat = "identity", position = position_dodge(0.9)) + 
  geom_errorbar(aes(ymin = mean-se, ymax = mean+se), 
                position = position_dodge(.9), width = 0.3)
