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

# Our subset of students
students = [3,4,22,34,66]

# And subset of columns
cols = ['Alcohol (g)','Protein (g)','Carbs (g)','Fat (g)']
subset = df[df['Stud_Nr'].isin(students)][cols].apply(pd.to_numeric)
subset = pd.concat([subset, subset.describe().loc[['mean', 'std']]]).T
subset.plot(kind='bar',y='mean', yerr='std')
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

