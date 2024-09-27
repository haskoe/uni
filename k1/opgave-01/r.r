#library(readr)
library(dplyr)

ri <- read.csv("ri-denorm.csv", sep = "\t", dec=".", strip.white=TRUE)

studies <- list("ffq", "24-hour", "4-days")
#studies <- list("4-days")
cols <- list("B1.Thiamine.mg","B2.Riboflavin.mg","B3.Niacin.mg","B5.Pantothenic.Acid.mg","B6.Pyridoxine.mg","B12.Cobalamin.µg")
#cols <- list("B12.Cobalamin.µg")

l_df_studies <- list()
for (study in studies) {
  df_csv  <- read.csv(paste(study,".csv",sep=""), sep = "\t", dec=".", strip.white=TRUE)
  res <- df_csv["Sex"]
  for (colname in cols) {
    colname_frac <- paste(colname,"f",sep="")
    colname_space <- gsub("\\.", " ", colname)
    
    # filter ri to get values only for selected nutrient
    ref <- ri[ri$Refname == colname_space,]
                    
    col_subset <- c("Sex", colname)
    tmp <-df_csv %>% select(col_subset)
    
    joined <- dplyr::left_join(tmp, ref, by = "Sex", keep = TRUE)
    res[colname_frac] <- joined[colname] / joined$Refvalue
  }
}
