library(dplyr)
library(tidyr)
library(ggplot2)

source('common.r')

#all_data <- load_data()
df_macro <- get_all_study_result( all_data, MACRO, f_value_macro, f_ri_macro)
df_micro <- get_all_study_result( all_data, MICRO, f_value_copy, f_value_copy)
df_amino <- get_all_study_result( all_data, AMINO_ACIDS, f_value_amino, f_value_copy)
df_amino_protein_corrected <- get_all_study_result( all_data, AMINO_ACIDS, f_value_amino_protein_corrected, f_value_copy)

#plot_df(df_macro %>% filter(Study == FFQ))
#plot_df(df_micro %>% filter(Study == FFQ))
#plot_df(df_amino %>% filter(Study == FFQ))
#df_micro <- get_all_study_result( all_data, MICRO, f_value_copy, f_value_copy)
