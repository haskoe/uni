#library(readr)
library(dplyr)

ri <- read.csv("ri-denorm.csv", sep = "\t", dec=".", strip.white=TRUE)

studies <- list("ffq", "24-hour", "4-days")
cols <- list("B1.Thiamine.mg") #,"B2.Riboflavin.mg","B3.Niacin.mg","B5.Pantothenic.Acid.mg","B6.Pyridoxine.mg","B12.Cobalamin.µg")

l_df_studies <- list()
for (study in studies) {
  df  <- read.csv(paste(study,".csv",sep=""), sep = "\t", dec=".", strip.white=TRUE)

  for (colname in cols) {
    colname_space <- gsub("\\.", " ", colname)
    
    # filter ri to get values only for selected nutrient
    ref <- ri[ri$Refname == colname_space,]
                    
    col_subset <- c("Sex", v=colname)
    df <- X4_days %>% select(col_subset)
    
    joined <- dplyr::left_join(df, ref, by = "Sex", keep = TRUE)
    joined$frac <- joined$ * joined$Refvalue
    View(joined)
  }
}
