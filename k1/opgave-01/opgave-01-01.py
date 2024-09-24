import pandas as pd
import os
from os import path
import numpy as np
import matplotlib.pyplot as plt
import math

def load_dict(dict_file,sep=';'):
    with open(dict_file,'r') as f:
        return dict([(values[0],[float(v) for v in values[1:]]) for values in [l.split(';') for l in f.readlines()]])

def mean_stderr_ref_plot(mean_stderr_df,ref,column_names, mean_std_stderr_columnnames, y_max, chart_title):
    mean,std,stderr = mean_std_stderr_columnnames
    ax = mean_stderr_df.plot(ylim=(0, y_max),kind='bar',y=mean, yerr=stderr, rot=45, fill=False, title=chart_title)
    width=0.5
    x=0
    for i,c in enumerate(column_names):
        rv = np.mean(ref[c])
        ax.hlines(rv, x - width/2, x + width/2, color='red')
        x += 1

def percentage_as_str(v1,v2):
    return  f'{(100*float(v1)/float(v2)):.1f}'

def read_csv(fname,sep='\t'):
    return pd.read_csv(path.join(data_dir,fname),sep=sep)

TOTAL_ENERGY = 'Total energy'
def energy_calculation(input_df,columns):
    df = input_df.copy()
    energy_columns = [c.split()[0] for c in columns]
    energy_percentage_columns = [c+'p' for c in energy_columns]

    # calculate energy, total energy and energy percentage for each column in trial dataset and reference dataset and store in 'energy_columns'
    # energy
    for mc,ec in zip(columns,energy_columns):
        df[ec] = df[mc]*kcal_pr_g[mc]
    
    # total energy
    df[TOTAL_ENERGY] = df[energy_columns].sum(axis=1)

    # and energy percentage
    for ec,epc in zip(energy_columns,energy_percentage_columns):
        df[epc] = 100 * df[ec] / df[TOTAL_ENERGY]

    return df, [columns, energy_columns, energy_percentage_columns]

## main script starts here
try:
    data_dir = path.dirname(path.abspath(__file__))
except:
    # we are in jupyter env.
    from IPython.display import display, HTML
    display(HTML("<style>.container { width:100% !important; }</style>"))    
    data_dir = 'work'

STUDENT_NO_COLNAME='Stud_Nr'
GENDER_COLNAME='Sex'
STDDEV_COLNAME='std'
STDERR_COLNAME='stderr'
MEAN_COLNAME='mean'
MALE='male'
FEMALE='female'
BOTH='same RI'

df_ri = read_csv('ri.csv')
kcal_pr_g = load_dict(path.join(data_dir,"kcal_pr_g.csv"))

#macronutrient_columns = ['Alcohol (g)','Protein (g)','Carbs (g)','Fat (g)']
micronutrient_columns = ['B1 (Thiamine) (mg)','B2 (Riboflavin) (mg)','B3 (Niacin) (mg)','B5 (Pantothenic Acid) (mg)','B6 (Pyridoxine) (mg)','B12 (Cobalamin) (µg)']


student_subset = [str(i) for i in range(200)]
exclude = {
    'ffq': [],
    '4-days': [], #5,11,39,25],
    '24-hour': []
}

# list with lists for each nutrient for each study:
# FFQ [B1 female count below, B2 female count low_, ...]
# FFQ [B1 male count below, B2 male count low_, ...]
# 24-h [B1 female count below, B2 female count low_, ...]

df_below_data = dict([(c,[]) for c in micronutrient_columns])
studies = ('ffq','24-hour','4-days')
for study in studies:
    loaded_df = read_csv(f'{study}.csv')
    loaded_df[STUDENT_NO_COLNAME] = loaded_df[STUDENT_NO_COLNAME].astype(str)
    loaded_df[GENDER_COLNAME] = loaded_df[GENDER_COLNAME].map(lambda v: v.strip().lower())
    resulting_subset = [n for n in student_subset if not int(n) in exclude[study]]
    loaded_df = loaded_df[loaded_df[STUDENT_NO_COLNAME].isin(resulting_subset)].reset_index(drop=True) # reindex is important !!
    
    for columns,calculate_energy,mean_legend in ((micronutrient_columns,False,'Mean RI fraction'),): #(macronutrient_columns,True)):
        df = pd.concat([loaded_df[GENDER_COLNAME], loaded_df[columns].replace(',', '.',regex=True).astype(float)],axis=1) # necessary as decimal separator in CSV files is a mixture of commas and dots

        # for each input column add a new fraction column
        fraction_columns = [c+'f' for c in columns]
        gender_below_dict = { FEMALE: [], MALE:[]}
        for column, fraction_column in zip(columns,fraction_columns):
            ri = df_ri[column]
            identical_ri = len(set(ri.values[:2])) == 1
            
            # lookup ri for each student
            df_student_ri = df.merge(df_ri, on=[GENDER_COLNAME], how = 'right')[column + '_y']
            df[fraction_column] = df[column] / df_student_ri
            df_frac_notna = df[df[fraction_column].notna()==True]
            if identical_ri:
                below = len(df_frac_notna[df_frac_notna[fraction_column]<1])
                df_below_data[column].append(f'Same RI: {below}/{total}={percentage_as_str(below,total)}%')
            else:
                res =[]
                for gender in (FEMALE, MALE):
                    below = len(df_frac_notna[(df_frac_notna[GENDER_COLNAME]==gender) & (df_frac_notna[fraction_column]<1)])
                    total = len(df_frac_notna[df_frac_notna[GENDER_COLNAME]==gender])
                    res.append(f'{gender}: {below}/{total}={percentage_as_str(below,total)}%')
                df_below_data[column].append(', '.join(res))

        # calculate mean, STDDEV_COLNAME and stderr
        mean_std_df = df[fraction_columns].describe().loc[[MEAN_COLNAME,STDDEV_COLNAME]].T
        mean_std_df = mean_std_df.rename(columns={MEAN_COLNAME: mean_legend})
        mean_std_df[STDERR_COLNAME] = mean_std_df[STDDEV_COLNAME] / math.sqrt(len(mean_std_df))

        print(mean_std_df)
        ax = mean_std_df.plot(ylim = (0,10), kind ='bar', y=mean_legend, yerr=STDERR_COLNAME, rot=45, fill=False, title=f'{study} - B1-B12 mean RI fractions')
        plt.show()

# below RI dataframe
data = [[c] + df_below_data[c] for c in columns]
df_below_ri = pd.DataFrame(columns = ['Nutrient'] + list(studies), data = data)
print('DAM methods')
print(df_below_ri)
