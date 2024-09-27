#library(readr)
library(dplyr)

STUD_NR <- "Stud_Nr"
SEX <- "Sex"
TOTAL_ENERGY <- "Total energy"
RI_FRAC <- "RI fraction"
NUTRIENT <- "Nutrient"

ri <- read.csv("ri-denorm.csv", sep = "\t", dec=".", strip.white=TRUE)
df_res <- read.csv("new-empty.csv", sep = "\t", dec=".", strip.white=TRUE)

df_energy_conv_factor <- read.csv("kcal_pr_g.csv", sep = ";", dec=".", strip.white=TRUE)
energy_conv_factor <- setNames(as.numeric(df_energy_conv_factor$toenergyfactor),as.character(df_energy_conv_factor$macronutrient))

studies <- list("ffq", "24-hour", "4-days")
micronutrient_cols <- c("B1.Thiamine.mg","B2.Riboflavin.mg","B3.Niacin.mg","B5.Pantothenic.Acid.mg","B6.Pyridoxine.mg","B12.Cobalamin.µg")
macronutrient_cols <- c("Alcohol.g","Protein.g","Carbs.g","Fat.g")

for (study in studies) {
  df_csv  <- read.csv(paste(study,".csv",sep=""), sep = "\t", dec=".", strip.white=TRUE)
  
  # res: Stud_Nr, Sex, Nutrient, RI factor
  res <- df_res
  
  # ugly
  calculate_energy <- TRUE
  for (cols in list(macronutrient_cols,micronutrient_cols)) {
    output_cols <- c()
    for (colname in cols) {
      colname_frac <- paste(colname,"f",sep="")
      output_cols <- append( output_cols, colname_frac)
      colname_space <- gsub("\\.", " ", colname)
      
      col_subset <- c(STUD_NR, SEX, colname)
      tmp <-df_csv %>% select(col_subset)
      if (calculate_energy) {
        # in-place calculation of energy
        tmp[colname_frac] <- tmp[colname] * energy_conv_factor[colname_space]
      }
      else {
        # filter ri to get values only for selected nutrient
        ref <- ri[ri$Refname == colname_space,]
  
        joined <- dplyr::left_join(tmp, ref, by = "Sex", keep = TRUE)
        tmp[colname_frac] <- joined[colname] / joined$Refvalue
      }
    }
    if (calculate_energy) {
      # calculate total energy
      tmp[TOTAL_ENERGY] <- rowSums(tmp[,output_cols])
      
      # and fractions of total energy
      for (colname in output_cols) {
        tmp[colname] <- tmp[colname] / tmp[TOTAL_ENERGY] 
      }
    }

    # append rows to resulting dataframe for each nutrient
    for (colname in output_cols) {
      res <- rbind(res, cbind(tmp[c(STUD_NR,SEX)],colname,tmp[colname]))
    }
  }  
  barplot(t(as.matrix(res[output_cols])), beside=TRUE)
  calculate_energy <- FALSE
}
