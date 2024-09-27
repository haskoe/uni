library(pivottabler)
library(dplyr)
library(ggplot2)

STUD_NR <- "Stud_Nr"
STUDY <- "Study"
SEX <- "Sex"
TOTAL_ENERGY <- "Total energy"
RI_FRAC <- "RI fraction"
NUTRIENT <- "Nutrient"
NUTRIENT_TYPE <- "Nutrienttype"
MACRO <- "Macro"
MICRO <- "Micro"

ri <- read.csv("ri-denorm.csv", sep = "\t", dec=".", strip.white=TRUE)
df_empty <- read.csv("new-empty.csv", sep = "\t", dec=".", strip.white=TRUE)

df_energy_conv_factor <- read.csv("kcal_pr_g.csv", sep = ";", dec=".", strip.white=TRUE)
energy_conv_factor <- setNames(as.numeric(df_energy_conv_factor$toenergyfactor),as.character(df_energy_conv_factor$macronutrient))

studies <- list("ffq", "24-hour", "4-days")
micronutrient_cols <- c("B1.Thiamine.mg","B2.Riboflavin.mg","B3.Niacin.mg","B5.Pantothenic.Acid.mg","B6.Pyridoxine.mg","B12.Cobalamin.µg","Folate.µg","Vitamin.A.µg","Vitamin.C.mg","Vitamin.D.IU","Vitamin.E.mg","Vitamin.K.µg","Calcium.mg","Copper.mg","Iron.mg","Magnesium.mg","Manganese.mg","Phosphorus.mg","Potassium.mg","Selenium.µg","Sodium.mg","Zinc.mg")
macronutrient_cols <- c("Alcohol.g","Protein.g","Carbs.g","Fat.g")

col_subset <- c(STUD_NR, SEX)
res <- df_empty
for (study in studies) {
  df_csv  <- read.csv(paste(study,".csv",sep=""), sep = "\t", dec=".", strip.white=TRUE)
  
  # res: Stud_Nr, Sex, Nutrient, RI factor
  
  # ugly
  nutrient_type <- MACRO
  for (cols in list(macronutrient_cols,micronutrient_cols)) {
    output_cols <- c()
    tmp <-df_csv %>% select(col_subset)
    for (colname in cols) {
      colname_frac <- paste(colname,"f",sep="")
      output_cols <- append( output_cols, colname_frac)
      colname_space <- gsub("\\.", " ", colname)
      
      if (nutrient_type == MACRO) {
        # in-place calculation of energy
        tmp[colname_frac] <- df_csv[colname] * energy_conv_factor[colname_space]
      }
      else {
        tmp[colname_frac] <- df_csv[colname]
        
        # filter ri to get values only for selected nutrient
        ref <- ri[ri$Refname == colname_space,]
  
        joined <- dplyr::left_join(tmp, ref, by = "Sex", keep = TRUE)
        tmp[colname_frac] <- joined[colname_frac] / joined$Refvalue
      }
    }
    if (nutrient_type == MACRO) {
      # calculate total energy
      tmp[TOTAL_ENERGY] <- rowSums(tmp[,output_cols])
    
      # and fractions of total energy
      for (colname in output_cols) {
        tmp[colname] <- tmp[colname] / tmp[TOTAL_ENERGY] 
      }
    }
    
    # append rows to resulting dataframe for each nutrient
    # could have used pivot_longer !!
    for (colname in output_cols) {
      res <- rbind(res, setNames( cbind(tmp[c(STUD_NR,SEX)],study,colname,nutrient_type, tmp[colname]), names(res)))
    }
    
    nutrient_type <- MICRO
  }

  write.csv( res, "pivot.csv")
  #grouped <- res %>% group_by_at(c(STUDY,SEX,NUTRIENT))
#  friendly_plot <- grouped %>%  ggplot()
  
  
#  barplot(t(as.matrix(res[output_cols])), beside=TRUE)
}
