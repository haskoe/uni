import pandas as pd
from os import path
import numpy as np
import matplotlib.pyplot as plt

script_path = path.dirname(path.abspath(__file__))

def bmr_male(weight,height,age):
    return 88.36 + 13.40 * weight + 4.799 * height - 5.677 * age

def bmr_female(weight,height,age):
    return 447.6 + 9.247 * weight + 3.098 * height - 4.330 * age

df = pd.read_csv(path.join(script_path,'ffq.tsv'),sep='\t')
ref = pd.read_csv(path.join(script_path,"nordic-nutrition-recommendations.csv"),sep=';')

# macro nutrients columns
macronutrient_columns = ['Alcohol (g)','Protein (g)','Carbs (g)','Fat (g)', 'Fiber (g)', 'Starch (g)']
ALC, PROTEIN, CARB, FAT, FIBER, STARCH = macronutrient_columns
TOTAL_ENERGY = 'Total energy'
energy_columns = [c.split()[0] for c in macronutrient_columns]
energy_percentage_columns = [c+'p' for c in energy_columns]

# energy fractions
kcal_pr_g = {
    ALC: 6.9,
    PROTEIN: 4,
    CARB: 4,
    FAT: 9,
    FIBER: 2,
    STARCH: 4
}

# Our subset of students
students = [3,4,22,34,66]

# And subset of columns
cols = [ALC, PROTEIN, CARB, FAT, FIBER, STARCH]
df = df[df['Stud_Nr'].isin(students)][cols].apply(pd.to_numeric)

# calculate energy from each column and store in new columns with ' (g)' removed
for col in cols:
    df[col.split()[0]] = df[col]*kcal_pr_g[col]
print(df)
# total energy for each student
df[TOTAL_ENERGY] = df[energy_columns].sum(axis=1)
print(df)

# energy percentage
for e,ep in zip(energy_columns,energy_percentage_columns):
    df[ep] = df[e] / df[TOTAL_ENERGY]
print(df)

df_mean_std = df[energy_percentage_columns]
result = pd.concat([df_mean_std, df_mean_std.describe().loc[['mean', 'std']]]).T
print(result)
result.plot(kind='bar',y='mean', yerr='std')
#plt.show()
# dataframe with 

 #plt.bar(np.arange(subset.shape[1]), subset.mean(), yerr=[subset.mean()-subset.min(), subset.max()-subset.mean()], capsize=6)
# plt.grid()
# plt.show()
# sem = subset.sem()
# print(sem.head())
# print(sem)
# # calculate and add mean and stddev of all columns to dataframe

#chart_subset = cols
# plot 

