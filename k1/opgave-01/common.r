STUD_NR <- "Stud_Nr"
STUDY <- "Study"
SEX <- "Sex"
PROTEIN <- "Protein g"
TOTAL <- "Total energy"
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
STUDY_TYPES <- c(FFQ,H24,D4)

fixed_cols <- c(STUD_NR, SEX)
our_group <- c(8,19,34,35,66)

nutrient_list_by_class <- function(df_ref, nutrient_class) {
  return ((df_ref %>% filter(Nutrienttype == nutrient_class) %>% select(Nutrient) %>% distinct())[,1])
}

get_url <- function(filename_wo_extension){
  return (paste('https://raw.githubusercontent.com/haskoe/uni/refs/heads/main/k1/opgave-01/', filename_wo_extension, '.csv', sep=''))
}

load_data <- function() {
  df_energy_conv_factor <- read.csv(get_url("kcal_pr_g"), sep = ";", dec=".", strip.white=TRUE)
  return (list( 
    energy_conv_factor = setNames(as.numeric(df_energy_conv_factor$toenergyfactor),as.character(df_energy_conv_factor$macronutrient)),
    df_empty = read.csv(get_url("new-empty"), sep = "\t", dec=".", strip.white=TRUE, check.names=FALSE),
    df_ref = read.csv(get_url("ri-denorm"), sep = "\t", dec=".", strip.white=TRUE, check.names=FALSE),
    
    df_ffq = read.csv(get_url(paste(FFQ,'.fixed',sep='')), sep = "\t", dec=".", strip.white=TRUE, check.names=FALSE),
    df_24h = read.csv(get_url(paste(H24,'.fixed',sep='')), sep = "\t", dec=".", strip.white=TRUE, check.names=FALSE),
    df_4d = read.csv(get_url(paste(D4,'.fixed',sep='')), sep = "\t", dec=".", strip.white=TRUE, check.names=FALSE)
  ))
}  

f_value_amino <- function(df, nutrient_name) {
  return (df[nutrient_name] / df[PROTEIN])
}
f_value_amino_protein_corrected <- function(df, nutrient_name) {
  return (df[nutrient_name] / df[PROTEIN])
}
f_value_copy <- function(df, nutrient_name) {
  return (df[nutrient_name])
}
f_value_macro <- function(df, nutrient_name) {
  return (df[nutrient_name] * all_data$energy_conv_factor[nutrient_name])
}
f_total_macro <- function(df,nutrient_cols) {
  df[TOTAL_ENERGY] <- rowSums(df[,nutrient_cols])  
}
f_ri_macro <- function(df,nutrient_name) {
  return (df[nutrient_name] / df[TOTAL])
}

# format. we want to end with this
# stud.nr, sex, study, nutrienttype, nutrient, calc. value, fraction of ref.
#
# calc, vlkue:
#   a) macro: 1) energy for each nutrient, 2) sum of energy and 3) fraction of total energy for each nutrient
#   b) micro: N/A
#   c) amino acids: intake / protein intake in grams (should be sufficient because it is the protein composition that is of interest)
# compare a, b and c with recommended value in ri-denorm.csv

get_study_result <- function(all_data, df, study_name, nutrient_class, f_value, f_ri) {
  nutrient_cols <- nutrient_list_by_class(all_data$df_ref,nutrient_class)
  tmp <- df %>% select(all_of(fixed_cols))
  tmp[STUDY] = study_name
  tmp[NUTRIENT_TYPE] = nutrient_class
  
  for (nutrient_name in nutrient_cols) {
    tmp[nutrient_name] <- f_value(df, nutrient_name)
  }
  
  # total
  tmp[TOTAL] <- rowSums(tmp[,nutrient_cols])

  # RI fraction
  for (nutrient_name in nutrient_cols) {
    tmp[nutrient_name] <- f_ri(tmp, nutrient_name)
  }

  df_res <- all_data$df_empty # resulting dataframe cloned from df_empty
  df_res <- rbind(df_res,pivot_longer(tmp %>% select(!c(TOTAL)),nutrient_cols)) %>% rename_at(c("name","value"), ~c(NUTRIENT,RI))

  joined <- left_join(df_res, all_data$df_ref, by = c(SEX,NUTRIENT), keep = TRUE)
  df_res[RI_FRAC] <- joined[RI] / joined$Refvalue
  
  return (df_res)
}

get_all_study_results <- function(all_data, nutrient_class, f_value, f_ri) {
  df_res <- get_study_result( all_data, all_data$df_ffq, FFQ, nutrient_class, f_value, f_ri)
  df_res <- rbind( df_res, get_study_result( all_data, all_data$df_24h, H24, nutrient_class, f_value, f_ri))
  df_res <- rbind( df_res, get_study_result( all_data, all_data$df_4d, D4, nutrient_class, f_value, f_ri))
  return (df_res)
}

plot_df <- function(df) {
  ggplot( df
          %>% group_by(Sex, Nutrient)
          %>% summarise( 
            n = sum(!is.na(RI_ref)), 
            mean = mean(RI_ref, na.rm = TRUE), 
            min = min(RI_ref, na.rm = TRUE), 
            max = max(RI_ref, na.rm = TRUE), 
            se = sd(RI_ref, na.rm = TRUE) / sqrt(n)),
          aes(x = Nutrient, y = mean, fill = Sex)) +
    geom_bar(stat = "identity", position = position_dodge(0.9)) + 
    geom_errorbar(aes(ymin = mean-se, ymax = mean+se), 
                  position = position_dodge(.9), width = 0.3) +
    geom_errorbar(aes(ymin = min, ymax = max), 
                  position = position_dodge(.5), width = 0.3)
}