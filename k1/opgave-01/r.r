#library(readr)
library(dplyr)

SEX <- "Sex"
TOTAL_ENERGY <- "Total energy"

ri <- read.csv("ri-denorm.csv", sep = "\t", dec=".", strip.white=TRUE)
df_energy_conv_factor <- read.csv("kcal_pr_g.csv", sep = ";", dec=".", strip.white=TRUE)
energy_conv_factor <- setNames(as.numeric(df_energy_conv_factor$toenergyfactor),as.character(df_energy_conv_factor$macronutrient))

studies <- list("ffq", "24-hour", "4-days")
micronutrient_cols <- c("B1.Thiamine.mg","B2.Riboflavin.mg","B3.Niacin.mg","B5.Pantothenic.Acid.mg","B6.Pyridoxine.mg","B12.Cobalamin.µg")
macronutrient_cols <- c("Alcohol.g","Protein.g","Carbs.g","Fat.g")

l_df_studies <- list()
for (study in studies) {
  df_csv  <- read.csv(paste(study,".csv",sep=""), sep = "\t", dec=".", strip.white=TRUE)
  res <- df_csv["Sex"]
  
  # ugly
  calculate_energy <- TRUE
  for (cols in list(macronutrient_cols,micronutrient_cols)) {
    output_cols <- c()
    for (colname in cols) {
      colname_frac <- paste(colname,"f",sep="")
      output_cols <- append( output_cols, colname_frac)
      colname_space <- gsub("\\.", " ", colname)
      
      col_subset <- c("Sex", colname)
      tmp <-df_csv %>% select(col_subset)
      if (calculate_energy) {
        # in-place calculation of energy
        res[colname_frac] <- tmp[colname] * energy_conv_factor[colname_space]
      }
      else {
        # filter ri to get values only for selected nutrient
        ref <- ri[ri$Refname == colname_space,]
  
        joined <- dplyr::left_join(tmp, ref, by = "Sex", keep = TRUE)
        res[colname_frac] <- joined[colname] / joined$Refvalue
      }
    }
    if (calculate_energy) {
      # calculate total energy
      res[TOTAL_ENERGY] <- sum(select(res,output_cols))
      
      # and fractions of total energy
      for (colname in cols) {
        colname_frac <- paste(colname,"f",sep="")
        res[colname_frac] <- res[colname_frac] / res[TOTAL_ENERGY] 
      }
    }
    calculate_energy <- FALSE
  }
}
