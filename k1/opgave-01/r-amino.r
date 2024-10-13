library(dplyr)
library(tidyr)
library(ggplot2)

STUD_NR <- "Stud_Nr"
STUDY <- "Study"
SEX <- "Sex"
PROTEIN <- "Protein g"
TOTAL_ENERGY <- "Total energy"
TOTAL_ENERGY_RI <- "Total energy RI"
RI_FRAC <- "RI"
NUTRIENT <- "Nutrient"
NUTRIENT_TYPE <- "Nutrienttype"
BMR <- "BMR kcal"

MACRO <- "macro"
MICRO <- "micro"
AMINO_ACIDS <- "amino acid"

fixed_cols <- c(STUD_NR, SEX, BMR)
our_group <- c(8,19,34,35,66)

nutrient_list_by_type <- function(ref, nutrient_type) {
  return ((ref %>% filter(Nutrienttype == nutrient_type) %>% select(Refname) %>% distinct())[,1])
}

get_url <- function(filename_wo_extension){
  return (paste('https://raw.githubusercontent.com/haskoe/uni/refs/heads/main/k1/opgave-01/', filename_wo_extension, '.csv', sep=''))
}

# format. we want to end with this
# stud.nr, sex, study, nutrienttype, nutrient, calc. value, fraction of ref.
#
# calc, vlkue:
#   a) macro: 1) energy for each nutrient, 2) sum of energy and 3) fraction of total energy for each nutrient
#   b) micro: N/A
#   c) amino acids: intake / protein intake in grams (should be sufficient because it is the protein composition that is of interest)
# compare a, b and c with recommended value in ri-denorm.csv

get_study_result <- function(df, study_name, df_ref, energy_conv_factor) {
  df <- read.csv(get_url(paste(study_name,'.fixed',sep='')), sep = "\t", dec=".", strip.white=TRUE, check.names=FALSE)

  all_nutrients <- (df_ref %>% select(Refname) %>% distinct())[,1]
  
  # macro dataframe with fraction of energy intake for each nutrient
  tmp <- df %>% select(fixed_cols)
  for (colname in nutrient_list_by_type(df_ref,MACRO)) {
    tmp[colname] <- df[colname] * energy_conv_factor[colname]
  }
  tmp[TOTAL_ENERGY] <- rowSums(tmp[,nutrient_cols])
  tmp[TOTAL_ENERGY_RI] <- tmp[TOTAL_ENERGY] / tmp[BMR]
  for (colname in nutrient_list_by_type(ref,MACRO)) {
    tmp[colname] <- tmp[colname] / tmp[TOTAL_ENERGY] 
  }
  
  for (colname in nutrient_list_by_type(df_ref,MICRO)) {
    tmp[colname] <- df[colname]
  }
  
  for (colname in nutrient_list_by_type(df_ref,AMINO_ACIDS)) {
    tmp[colname] <- df[colname] / df[PROTEIN]
  }
  
  # calculate fration of reference value
  for (colname in all_nutrients) {
    df_ref_nutrient <- df_ref %>% filter(Refname == colname)
    joined <- dplyr::left_join(tmp, df_ref_nutrient, by = "Sex", keep = TRUE)
    tmp[paste(colname,"ref")] <- joined[colname] / joined$Refvalue
  }
  
  # resluting dataframe with transformed macro and amino acid values and corresponding fraction of ref. value
  return (tmp)
}

get_studies_combined_dataframe <- function() {
  df_ref <- read.csv(get_url("ri-denorm"), sep = "\t", dec=".", strip.white=TRUE, check.names=FALSE)
  
  df_energy_conv_factor <- read.csv(get_url("kcal_pr_g"), sep = ";", dec=".", strip.white=TRUE)
  energy_conv_factor <- setNames(as.numeric(df_energy_conv_factor$toenergyfactor),as.character(df_energy_conv_factor$macronutrient))
  
  res <-get_study_result(read.csv(get_url(paste("ffq",'.fixed',sep='')), sep = "\t", dec=".", strip.white=TRUE, check.names=FALSE), "ffq", df_ref, energy_conv_factor)
  for (study_name in c("24-hour","4-days")) {
    res <- rbind(res,get_study_result(read.csv(get_url(paste(study_name,'.fixed',sep='')), sep = "\t", dec=".", strip.white=TRUE, check.names=FALSE), study_name, df_ref, energy_conv_factor))
  }
  return (res)
}

df <- get_studies_combined_dataframe()
