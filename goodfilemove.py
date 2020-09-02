# CTA 08/25/2020
# This will read station id's from a text file (stations-QC...txt) and move files in the 
# current directory with the name sid-raw.csv (sid is the station ID) to the subdirectory
# "testdir" which is assumed to exist.
#
# The idea here is to go take a large number of files which may or may not be good
# for use in the heat index computations and move only the good files (e.g. data files
# with sufficient data, etc.) which are identified
# by the station id's in stations-QC...txt and move only those csv files to testdir.
# This does not QC check but only moves those files identified in stations-QC...txt

import os

f = open("stations-QC2020.txt", "r")

for line in f:
    lineonly = line.strip()
    fname = lineonly + "-raw.csv"
    os.rename(fname, "testdir//" + fname)

f.close()


