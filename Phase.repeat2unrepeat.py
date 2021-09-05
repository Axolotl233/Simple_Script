#! python

import os
import sys

bed_file = (sys.argv[1])
len_file = (sys.argv[2])

len_dict ={}
bed_dict ={}
with open(len_file,"r") as len_object:
    for line in len_object:
        line=line.strip('\n')
        array = []
        array = line.split("\t")
        len_dict[array[0]] = array[1]

last ="NA";
array2 =[]
with open(bed_file,"r") as bed_object:
    for line in bed_object:
        line=line.strip('\n')
        array = []
                   
        array = line.split("\t")
        if array[0] != last:
            if last != "NA":
                bed_dict[last]=array2
            last = array[0]
            array2 = [array[1],array[2]]
            
        else:
            array2.append(array[1])
            array2.append(array[2])
            last = array[0]
bed_dict[last]=array2

for name in (bed_dict.keys()):
    array3 = bed_dict[name]
    array3.append(len_dict[name])
    array3.insert(0,0)
    for i in range(0,len(array3),2):
        print("%s\t%d\t%d" %(name,(int(array3[i])),(int(array3[i+1]))))
