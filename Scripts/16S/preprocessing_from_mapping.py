#!/usr/bin/python2.7
"""
Should be run in the folder with the mapping file. It generates the filename ${mapping_filename}_qsubs.pbs.
"""
import sys
print(sys.version)


filename = raw_input("Enter the mapping filename in .txt (without extension): ")
input_filename = filename + ".txt"

def FileCheck(fn):
    error = 0
    try:
        f=open(fn,"r")
        print("Found a file: " + input_filename)
    except IOError:
        error = 1
        print "Error: File does not appear to exist."
    return error

# [01]. Checking if file really exists
error = FileCheck(input_filename)
if error == 0:

    # [02]. Opening a file, reading column names - headers
    f = open(input_filename, 'r')
    header =  f.readline()
    header = header[1:] # avoid the '#' symbol
    header =  header.split()

    # [03]. Autodetecting sampleID column name, plus letting the user specify it.
    print "\n"
    suggested_head = ['sampleid', 'sample_id', 'id', 'idsample']
    probable = []
    for inx, head in enumerate(header):

        if head.lower() in suggested_head:
            print "[", inx, "]",head, " \t\t\t <-- Suggested"
            probable = [inx,head]
        else:
            print "[", inx, "]",head

    allowed = [i for i in range(len(header))] #allowed column numbers




    column = -1
    while (column not in allowed):
        formatedString = str( ("Please provide the column number that holds sample ids. \n (suggested column number: " + str(probable[0]) +  " - \"" + str(probable[1]) ) + ") \": ")
        column = raw_input(formatedString)
        try:
            column = int(column)
        except ValueError:
            print("Not a number!")
            column = -1

        if column != probable[0] and column in allowed:
            sure = raw_input("Are you sure? [y/n]: ")
            if sure.lower() == "n":
                column = -1

    # [04]. Reading samples ids
    sampleIds = []
    for line in f.readlines():
        sampleIds.append( line.split('\t')[column] )

    f.close()

    # [05]. Asking for preprocessing script name
    default_scriptname = "Pipeline_microbiome_preprocessing.pbs"

    default_good = raw_input('The default name for preprocessing is: \n \t\t\t\t\t' + default_scriptname + ' \n Is this correct? [y/n]: \t')
    while ( default_good.lower() not in ['y','n'] ) :
           default_good = raw_input('The default name for preprocessing is: \n \t\t\t\t\t' + default_scriptname + ' \n Is this correct? [y/n]: \t')

    if default_good == 'y':
        scriptname = default_scriptname
    else:
        scriptname = raw_input("Input name of the scriptfile (with extension):\t")


    # [08]. (a) Specify sleep time between each submit

    sleepy = raw_input('Would you like a pause between submitting each of ' + str(len(sampleIds)) + ' jobs to the cluster server? [y/n]: \t')
    while(sleepy.lower() not in ['y','n']):
        sleepy = raw_input('Would you like a pause between submitting each of ' + str(len(sampleIds)) + ' jobs to the cluster server? [y/n]: \t')

    if sleepy.lower() == 'y':
        delayTime = raw_input('Please specify time in seconds:\t')

        error=0
        try:
            delayTime = float(delayTime)
        except ValueError:
            print("Not a number!")
            error=1

        while(error == 1):
            error =0
            delayTime = raw_input('Please specify time in seconds:\t')
            try:
                delayTime = float(delayTime)
            except ValueError:
                print("Not a number!")
                error=1

    # [08]. (b) Specify to skip n-lines
    if sleepy.lower() == 'y':

        skip = raw_input('Between how many lines would you like to insert sleep command [1-' + str(len(sampleIds)-1) + "]:\t" )
        allowedSkips = [i for i in range(1, len(sampleIds) )  ]

        error = 0
        try:
            skip = int(skip)
        except ValueError:
            error =1
            print("Noty a number!")

        while(error ==1):
            error =0
            skip = raw_input('Between how many lines would you like to insert sleep command [1-' + str(len(sampleIds)-1) + "]:\t" )
            try:
                skip = int(skip)
            except ValueError:
                error =1
                print("Noty a number!")

        while(skip not in allowedSkips):
            print('Value exceeds allowed number [1-' + str(len(sampleIds)-1) + "]:\t" )
            skip = raw_input('Between how many lines would you like to insert sleep command [1-' + str(len(sampleIds)-1) + "]:\t" )

            error = 0
            try:
                skip = int(skip)
            except ValueError:
                error =1
                print("Noty a number!")

            while(error ==1):
                error =0
                skip = raw_input('Between how many lines would you like to insert sleep command [1-' + str(len(sampleIds)-1) + "]:\t" )
                try:
                    skip = int(skip)
                except ValueError:
                    error =1
                    print("Noty a number!")


    # [07]. Writing qsub commands into a filename, specifying delay time

    filenametoSave = filename+ "_qsubs.pbs"

    toSave = open(filenametoSave, 'w')


    # [07] (a) writing a header
    toSave.write("#!/bin/bash \n")
    toSave.write("#$ -V \n")
    toSave.write("#$ -cwd \n")
    toSave.write('#$ -o ' + filename + "_log.txt \n")
    toSave.write('#$ -j y \n')
    toSave.write('#$ -pe threaded 1 \n')
    toSave.write('#$ -l mem_free=10G,h_vmem=10G \n')


    # [07] (b) writing qsubs

    counter = 0
    for id in sampleIds:
        counter += 1
        if sleepy.lower() == 'n':
            cmd = "qsub -N j" + id[:9] + " " + scriptname + " " + id + " \n"
            toSave.write(cmd)
        elif sleepy.lower() == 'y':
            if counter % skip == 0:
                cmd = "qsub -N j" + id[:9] + " " + scriptname + " " + id + " \nsleep "  + str(delayTime) + "\n"
            else:
                cmd = "qsub -N j" + id[:9] + " " + scriptname + " " + id + " \n"
            toSave.write(cmd)
    toSave.close
