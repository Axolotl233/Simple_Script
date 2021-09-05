#! python3

import sys
import os
import itertools
import ete3
import re

def get_array(tree):
    array1=[]
    for node in tree.traverse():
        if node.is_leaf():
            array1.append(node.name)

    return array1
def get_C(a):
    array2=[]
    for i in itertools.combinations(a,2):
        tmp = ",".join(i)
        array2.append(tmp)
    return array2

t = ete3.Tree(sys.argv[1])
m = get_array(t)

com = get_C(m)
array3=[]
for i in com:
    array3 = i.split(',')
    d=t.get_distance(array3[0],array3[1])
    str(d)
    print (i,"\t",d)
