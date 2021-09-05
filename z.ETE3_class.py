#! python3

import sys
import ete3
import re
import os

def judge_tree(children,num1,num2,r):

    regex1 = re.compile(r'^W')
    regex2 = re.compile(r'^E')
    
    pop1_max = num1 * r
    pop1_min = num1 * (1 - r)
    pop2_max = num2 * r
    pop2_min = num2 * (1 - r)
    num = 0;
    
    for clade in children:

        array = []
        n_t1 = 0
        n_t2 = 0
        num += 1
        
        for node in clade.traverse():        
            if node.is_leaf():
                array.append(node.name)
                
        for ele in array:
            if regex1.match(ele):
                n_t1 += 1
            elif regex2.match(ele):
                n_t2 += 1
        #print (n_t1)

        if n_t1 > pop1_max and n_t2 < pop2_min :
            return num,"\tok"
            break
        elif n_t2 > pop2_max and n_t1 < pop1_min:
            return num,"\tok"
            break
        
        if len(clade) > pop1_max or len(clade) > pop2_min:
            temp_child = clade.get_children()
            for ele in temp_child:
                children.append(ele)
                
    return num,"\twrong"
    
t = ete3.Tree(sys.argv[1])
root_point = t.get_midpoint_outgroup()
t.set_outgroup(root_point)
rate=float(sys.argv[2])

children = t.get_children()
m=judge_tree(children,num1=43,num2=18,r=rate)

path_name = (os.path.dirname(sys.argv[1]) + "/")
file_name = ("process_" + str(rate) + ".txt")
print (path_name)
with open(path_name+'process.txt','w') as f:
    f.write(str(m[0]))
    f.write(m[1] + "\n")
    f.close()
