import pandas as pd
from os import path
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

script_path = path.dirname(path.abspath(__file__))

def bmr_male(weight,height,age):
    return 88.36 + 13.40 * weight + 4.799 * height - 5.677 * age

def bmr_female(weight,height,age):
    return 447.6 + 9.247 * weight + 3.098 * height - 4.330 * age

ffq = pd.read_csv(path.join(script_path,'ffq.tsv'),sep='\t')
ref = pd.read_csv(path.join(script_path,'nordic-nutrition-recommendations-transposed.csv'),sep=';').T
with open(path.join(script_path,"nordic-nutrition-recommendations-transposed.csv"),'r') as f:
    ref = dict([(l[0],float(l[1])) for l in [l.split(';') for l in f.readlines()]])
# print(ref)

# macro nutrients columns
macronutrient_columns = ['Alcohol (g)','Protein (g)','Carbs (g)','Fat (g)', 'Fiber (g)', 'Starch (g)']
ALC, PROTEIN, CARB, FAT, FIBER, STARCH = macronutrient_columns
TOTAL_ENERGY = 'Total energy'

energy_columns = [c.split()[0] for c in macronutrient_columns]
energy_percentage_columns = [c+'p' for c in energy_columns]

# for mc,ec in zip(macronutrient_columns,energy_percentage_columns):
#     ref = [ref[c]]
# print(ref.columns)
# a=bb

    # ref[ec] = ref[mc]

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
ffq = ffq[ffq['Stud_Nr'].isin(students)][macronutrient_columns].apply(pd.to_numeric)

# calculate energy, total energy and energy percentage for each column in trial dataset and reference dataset and store in 'energy_columns'
df_mean_std_all = []
for df in (ffq,):
    # energy
    for mc,ec in zip(macronutrient_columns,energy_columns):
        df[ec] = df[mc]*kcal_pr_g[mc]
        
    # total energy
    df[TOTAL_ENERGY] = df[energy_columns].sum(axis=1)

    # and energy percentage
    for ec,epc in zip(energy_columns,energy_percentage_columns):
        df[epc] = df[ec] / df[TOTAL_ENERGY]

    # mean and std dev
    df_mean_std_all.append(df[energy_percentage_columns].describe().loc[['mean', 'std']].T)
    #df = df.T
ffq_mean_std = df_mean_std_all[0]
ax = ffq_mean_std.plot(ylim=(0, 1),kind='bar',y='mean', yerr='std', rot=0, fill=False)
width=0.5
# x = np.arange(len(ffq_mean_std.columns))
x=0
for i,c in enumerate(energy_percentage_columns):
#     print(i,c,ref[c])
    ax.hlines(ref[c], x - width/2, x + width/2, color='red')
    x +=1

#     plt.axhline(ref[c], xmin=0.5, xmax=1, color='red') #i,i+0.2,color='red')    
    #break
#print(ffq)
#sns.barplot( data=ffq_mean_std, y='mean', yerr='std')
plt.show()
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

