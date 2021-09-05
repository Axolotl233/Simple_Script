#!/usr/bin/env python

# Returns N50 (or N of your choice) and other stats of a fasta/q (can be gzipped)
# file of sequences. N50 is calculated as the sequence length above which 50%
# of the total sequence length lies when the sequences are sorted in order of
# descending length.

import getopt, sys
import copy
import gzip
import numpy as np
from itertools import groupby, imap

# Calculate the Nx where x is a number between 1 and 100.

def get_n(lengths, total_length, n):
	cumulative_length = 0
	n_value = 0
	i = 0
	while cumulative_length < total_length*(n/100.0):
		l = lengths[i]
		cumulative_length += l
		n_value = l
		i += 1
	return n_value

# Nifty little generator to efficiently process sequences.

def chunks(l, n):
	for i in xrange(0, len(l), n):
		yield l[i:i+n]

# Function to calculate all of the stats for a given fasta/q file and value of n.
# Uses itertools functions to speed things up. BioPython is slooooooow.

def get_stats(infile, n):
	total_length = 0
	num_seqs = 0
	lengths = []
	if infile.endswith('fa') or infile.endswith('fasta') or \
	infile.endswith('fn') or infile.endswith('fa.gz') or \
	infile.endswith('fn.gz') or infile.endswith('fasta.gz'):
		seq_type = 'fasta'
	elif infile.endswith('fq') or infile.endswith('fastq') or \
	infile.endswith('fq.gz') or infile.endswith('fastq.gz'):
		seq_type = 'fastq'
	if infile.endswith('gz'):
		zipped = True
	else:
		zipped = False
	if zipped:
		handle = gzip.open(infile, 'rb')
	else:
		handle = open(infile, 'r')
	if seq_type == 'fasta':
		for header, group in groupby(handle, lambda x:x.startswith('>')):  # Splits records into headers and sequences.
			if not header:  # We don't care about headers.
				num_seqs += 1  # Increments the number of reads.
				length = sum(imap(lambda x: len(x.strip()), group))  # The length of the sequence.
				lengths.append(length)
				total_length += length
	elif seq_type == 'fastq':
		lines = handle.readlines()
		for seq in chunks(lines, 4):  # Uses the chunks generator function to split sequences.
			num_seqs += 1  # Increments the number of reads.
			length = sum(imap(lambda x: len(x.strip()), seq[1]))  # The length of the sequence.
			lengths.append(length)
			total_length += length
	lengths = sorted(lengths, reverse=True)  # Need to sort the list to calculate the Nx value.
	average_length = float(total_length)/num_seqs
	max_length = max(lengths)
	min_length = min(lengths)
	med_length = np.median(lengths)
	n_value = get_n(lengths, total_length, n)
	handle.close()
	return (num_seqs, n_value, average_length, med_length, total_length, min_length, max_length)

# How to use this.

def usage():
	print """
\nfast_stats.py.\n
Returns N50 (or N of your choice) and other stats of a fasta/q file of sequences.\n
N50 is calculated as the sequence length above which 50% of the total sequence
length lies when the sequences are sorted in order of descending length.\n
Basic usage:
\tpython fast_stats.py -i <infile> -n 50\n
Arguments:
\t-h, --help\t\t\tPrint this information.
\t-i, --in <infile>\t\tfasta/q-formatted input file.
\t-n, --number <number>\t\tA number between 1 and 100."""

# Runs the main program, and parses all of the command line arguments.

def main():
	try:  ## Parses the command line arguments.
		opts, args = getopt.getopt(sys.argv[1:], 'n:i:h', ['number=', 'in=', 'help'])
	except getopt.GetoptError:
		usage()
		sys.exit(2)

	## Creates variables from the arguments.

	for opt, arg in opts:
		if opt in ('-n', '--number'):
			n = int(arg)
		elif opt in ('-i', '--in'):
			infile = arg
		elif opt in ('-h', '--help'):
			usage()
			sys.exit(0)
		else:
			usage()
			sys.exit(2)

	try:  # Tries to calculate the stats.
		num_seqs, n_value, average_length, med_length, total_length, min_length, max_length  = get_stats(infile, n)
		print '\n***Results for %s***\n' % infile
		print 'There are %i sequences' % (num_seqs)
		print 'The N%i is: %i' % (n, n_value)
		print 'The average length is: %i' % (average_length)
		print 'The median length is %f' % (med_length)
		print 'The total length is: %i' % (total_length)
		print 'The shortest length is: %i' % (min_length)
		print 'The longest length is: %i\n' % (max_length)
		print '***\n'
	except KeyboardInterrupt:
		sys.exit(1)
	except:  # Otherwise, shows usage.
		usage()
		sys.exit(1)

if __name__ == "__main__":
	main()
