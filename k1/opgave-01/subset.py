from os import path

data_dir = path.dirname(path.abspath(__file__))

our_group = ['"%s"' % (c,) for c in (8,19,34,35,66)]
 
def ri(line):
    print(line)
    return [(i==6) and (x!='NA') and (float(x)>3) and '1' or x for i,x in enumerate(line)] 

with open(path.join(data_dir,'pivot.csv'),'r') as f:
    lines = [l.strip().split(',') for l in f.readlines()]
    tf = [ri(l) for l in lines[1:]]
    tf = [','.join(x + [x[1] in our_group and "Our" or "Other"]) for x in tf]

first_line = ','.join(lines[0]+['"Group"']).replace('""','"Row"')
with open(path.join(data_dir,'pivot1.csv'),'w') as f:
    f.write('\n'.join([first_line]+[l.replace(',NA',',NaN') for l in tf]))
