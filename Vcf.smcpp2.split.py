#! python

# -*- coding: utf-8 -*-
'''
<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>
for one or two pop
SMC++
by zhangjin 2021 23/5
<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>
'''
import os, sys, re
import argparse
import gzip
from pathlib import Path
from multiprocessing import Pool
class SMCPP():
    smcpp = 'smc++'
    def __init__(self):
        self.smc_dir='data'
    def vcf2smc(self,chr_name):
        process = '%s vcf2smc %s %s/%s.%s.smc.gz %s %s:%s'%(self.smcpp,self.vcf,self.smc_dir,self.popname,chr_name,chr_name,self.popname,self.samples)
        os.system(process)
    def estimate(self):
        process='%s estimate %s -o %s/ %s %s/%s.*.smc.gz'%(self.smcpp,self.spline,self.popname,self.mutation,self.smc_dir,self.popname)
        os.system(process)
    def plot1(self,json):
        process='%s plot %s plot.pdf %s'%(self.smcpp,self.year,json)
        os.system(process)
    def vcf2smc2(self,chr_name):
        process1='%s vcf2smc %s %s/pop12.%s.smc.gz %s pop1:%s pop2:%s'%(self.smcpp,self.vcf,self.smc_dir,chr_name,chr_name,self.pop1_sample,self.pop2_sample)
        process2='%s vcf2smc %s %s/pop21.%s.smc.gz %s pop2:%s pop1:%s'%(self.smcpp,self.vcf,self.smc_dir,chr_name,chr_name,self.pop2_sample,self.pop1_sample)
        os.system(process1)
        os.system(process2)
    def split2(self):
        process='%s split -o split/ pop1/model.final.json pop2/model.final.json %s/*.smc.gz'%(self.smcpp,self.smc_dir)
        os.system(process)
    def plot2(self):
        process='%s plot %s joint.pdf split/model.final.json'%(self.smcpp,self.year)
        os.system(process)

def read_pop(pop_file):
    with open(pop_file) as pops:
        pop_dict = {}
        for pop in pops:
            pop = pop.strip().split(':')
            pop_dict[pop[0]]=pop[1]
    return pop_dict
def read_chr(chr_list):
    with open(chr_list) as lines:
        chrs = []
        for line in lines:
            line = line.strip()
            chrs.append(line)
    return chrs

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='SMC++ PROCESS',formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('--version', action='version', version='%(prog)s 1.0')
    parser.add_argument('-p', '--pop', dest='pop_num', type=int, required=True, help='the pop number must be 1 or 2\nif 1 you can give any pop,but2,you must give only 2 pop ,and the pop_name should better be pop1 and pop2')
    parser.add_argument('-pf', '--pop_file', dest='pop_file', required=True, help='the every pop inclold sample example:\npop1:HH1,HH2,HH3\npop2:HY2,HY3,HY4')
    parser.add_argument('-cl', '--chr_list', dest='chr_list', required=True, help='the all chr of the vcf for example:\nchr1\nchr2\nchr3')
    parser.add_argument('-v', '--vcf', dest='vcf_file', required=True, help='the vcf file you must be give,it should be end with .gz')
    parser.add_argument('-mu', '--mutation', dest='mutation', required=True, help=' the per-generation mutation rate such as 1.25e-8')
    parser.add_argument('-g', '--year', dest='year', nargs='?',default='', const='', help='-g sets the generation time (in years) used to scale the x-axis. If not given, the plot will be in coalescent units.')
    parser.add_argument('-sp', '--spline', dest='spline', nargs='?', default='', const='', help='[cubic,pchip,piecewise],type of model representation (smooth spline orpiecewise constant) to use')
    parser.add_argument('-o', '--out_dir', dest='out_dir', nargs='?', default='.', const='.', help='the ou_dir ,default=.')
    parser.add_argument('-j', '--theards', dest='theards', type=int, nargs='?', default=1, const=1, help='Please give the number of threads')
    args = parser.parse_args()

    year=args.year
    SMCPP.year='-g '+year if year else year
    spline=args.spline
    SMCPP.spline='--spline '+spline if spline else spline
    pop_num = args.pop_num
    pop_file = args.pop_file
    chr_list = args.chr_list
    vcf_file = os.path.abspath(args.vcf_file)
    mutation = args.mutation
    out_dir = args.out_dir
    theards = args.theards
    if not Path('%s.tbi'%(vcf_file)).is_file():
        print('there must be index of vcf')
        sys.exit()
    if pop_num not in [1,2]:
        print('the pop_num only be 1 or 2')
        sys.exit()

    pop_dict = read_pop(pop_file)
    chrs = read_chr(chr_list)
    os.chdir(out_dir)
    SMCPP.vcf = vcf_file
    SMCPP.mutation = mutation
    smc_p = SMCPP()
    if pop_num ==2:
        if len(pop_dict) !=2:
            print('the pop_file is not 2 pop')
            sys.exit()
        if 'pop1' not in pop_dict or 'pop2' not in pop_dict:
            print('the 2 you should give the popname are pop1 and pop2')

    pop_keys = sorted(pop_dict.keys())
    if not Path('data').is_dir():
        os.mkdir('data')
    for pop_key in pop_keys:
        if not Path(pop_key).is_dir():
            os.mkdir(pop_key)
        SMCPP.est_dir=pop_key
        SMCPP.popname=pop_key
        SMCPP.samples=pop_dict[pop_key]
        po1 = Pool(theards)
        po1.map(smc_p.vcf2smc,chrs)
        po1.close()
        smc_p.estimate()
    if pop_num == 1:
        all_json=' '.join([x+"/model.final.json" for x in pop_keys])
        smc_p.plot1(all_json)
    else:
        SMCPP.pop1_sample=pop_dict['pop1']
        SMCPP.pop2_sample=pop_dict['pop2']
        po2 = Pool(theards)
        po2.map(smc_p.vcf2smc2,chrs)
        po2.close()
        if not Path('split').is_dir():
            os.mkdir('split')
        smc_p.split2()
        smc_p.plot2()
