library(dplyr)
library(tidyr)
library(ggplot2)

STUD_NR <- "Stud_Nr"
STUDY <- "Study"
SEX <- "Sex"
TOTAL_ENERGY <- "Total energy"
TOTAL_ENERGY_RI <- "Total energy RI"
RI_FRAC <- "RI"
NUTRIENT <- "Nutrient"
NUTRIENT_TYPE <- "Nutrienttype"
MACRO <- "Macro"
MICRO <- "Micro"
BMR <- "BMR kcal"
TMP_FRACTION <- "TMP"

ri_fraction_macro <- function(df,nutrient_cols,fixed_cols,energy_conv_factor) {
  # select the fixed_cols into resulting dataframe
  tmp <-df %>% select(all_of(fixed_cols))
  
  # add ri calculated for each nutrient in nutrient_cols to resulting dataframe
  for (colname in nutrient_cols) {
    tmp[colname] <- df[colname] * energy_conv_factor[colname]
  }
  tmp[TOTAL_ENERGY] <- rowSums(tmp[,nutrient_cols])
  tmp[TOTAL_ENERGY_RI] <- tmp[TOTAL_ENERGY] / tmp[BMR]
  for (colname in nutrient_cols) {
    tmp[colname] <- tmp[colname] / tmp[TOTAL_ENERGY] 
  }
  
  return (tmp)
}

ri_fraction_micro <- function(df,nutrient_cols,fixed_cols,ref_values) {
  # select the fixed_cols into resulting dataframe
  tmp <-df %>% select(all_of(fixed_cols))
  
  for (colname in nutrient_cols) {
    # filter ri to get values only for selected nutrient
    ref_nutrient <- ref_values[ref_values$Refname == colname,]
    
    tmp[colname] <- df[colname]
    joined <- dplyr::left_join(tmp, ref_nutrient, by = "Sex", keep = TRUE)
    tmp[colname] <- joined[colname] / joined$Refvalue
  }
  
  return (tmp)
}

bar_plot <- function(df, x_name, bar_cols) {
  df |>
    pivot_longer(bar_cols) |> 
    ggplot(aes(x = Sex, y = value, fill = name)) +
    # Implement a grouped bar chart
    geom_bar(position = "dodge", stat = "identity")
}
                     
fixed_cols <- c(STUD_NR, SEX, BMR)
our_group <- c(8,19,34,35,66)

ri_ref_values <- read.csv("ri-denorm.csv", sep = "\t", dec=".", strip.white=TRUE)
df_energy_conv_factor <- read.csv("kcal_pr_g.csv", sep = ";", dec=".", strip.white=TRUE)
energy_conv_factor <- setNames(as.numeric(df_energy_conv_factor$toenergyfactor),as.character(df_energy_conv_factor$macronutrient))

studies <- list("ffq", "24-hour", "4-days")
micronutrient_cols <- c("B1 Thiamine mg","B2 Riboflavin mg","B3 Niacin mg","B5 Pantothenic Acid mg","B6 Pyridoxine mg") #,"B12 Cobalamin µg") #,"Folate µg","Vitamin A µg","Vitamin C mg","Vitamin D IU","Vitamin E mg","Vitamin K µg","Calcium mg","Copper mg","Iron mg","Magnesium mg","Manganese mg","Phosphorus mg","Potassium mg","Selenium µg","Sodium mg","Zinc mg")
macronutrient_cols <- c("Alcohol g","Protein g","Carbs g","Fat g")

study <- "ffq"
df  <- read.csv(paste(study,".fixed.csv",sep=""), sep = "\t", dec=".", strip.white=TRUE, check.names=FALSE)

df_ri_macro <- ri_fraction_macro(df,macronutrient_cols,fixed_cols,energy_conv_factor)
df_ri_micro <- ri_fraction_micro(df,micronutrient_cols,fixed_cols,ri_ref_values)

pivot <- df_ri_micro |> pivot_longer(micronutrient_cols)

pivot |> 
  ggplot(aes(x = Sex, y = value, fill = name))

pivot |> 
  ggplot(aes(x = interaction(Sex, name), y = value, fill = name)) +   
  # Implement a grouped bar chart
  geom_bar(position = "dodge", stat = "identity")

# check that energy fractions sums to 1
# print(rowSums(df_ri_macro[,macronutrient_cols]))
