"""
Reference assemblyID lists can be downloaded from phylophlan server:
http://cmprod1.cibio.unitn.it/databases/PhyloPhlAn/taxa2genomes.txt
Script will do it automatically with -r flag

This script requires biopython (v1.78 works)
CHANGE E-MAIL IN CONFIG SECTION BEFORE RUNNING!

EXAMPLE Basic usage (if never used before):
    python cart.py -r -i request.txt -o refgenomes
    -r will download reference lists
    -i request.txt is an input tab-separated file following the (example) structure:
    Taxon   n_genomes
    p__Proteobacteria	6
    g__Pelagibacter 2
    ...
    -o refgenomes is the output folder
    
Repeated use (same work dir):
    python cart.py -i request.txt -o refgenomes
    (skip the reference list download, should work with -r but sometimes doesn't) 

Issue 1) Too many genome requests make NCBI angry. Loop over a more modest request file instead.
Issue 2) The summary file is provisional. Not all species have standard taxonomy structure so header might not always be correct. 

cart.py [-h] [-a [get .faa instead of .fna]]-i INPUT [-r [Null->auto-download reflist, else->give path]] [-o [output folder]]
[--inheader [header lines in input (default = 1)]] [--no-inheader]
[--refheader [header lines in reference (default = 3]] [--no-refheader] [--pool (-> pool genomes for every species)]
"""
## Required libraries

import random
import ftplib
import os
import subprocess
import sys
import argparse
from datetime import datetime
from Bio import Entrez

## Config - EDIT THIS
# Required
email ="brownie.chocolate@hotmail.com"
Entrez.email = email
# Can be changed via command line arguments
home = '/home/alexab/plankton2022' #only used here
outfolder = home+'/data/refgenomes' #where to save (change via '-o' argument)
ref = 'taxa2genomes_cpa201901_up201901.txt' #where to find ref (change via '-r' argument)

## FUNCTIONS
## Get readable file size
## Source: https://www.thepythoncode.com/article/list-files-and-directories-in-ftp-server-in-python
def get_size_format(n, suffix="B"):
    # converts bytes to scaled format (e.g KB, MB, etc.)
    for unit in ["", "K", "M", "G", "T", "P"]:
        if n < 1024:
            return f"{n:.2f}{unit}{suffix}"
        n /= 1024

## Flatten 2-level list
## Source: https://stackoverflow.com/questions/952914/how-to-make-a-flat-list-out-of-a-list-of-lists
def flatten(t):
    return [item for sublist in t for item in sublist]

## Refill random selection of assemblies if one in the original selection fails
def refill(main, backup):
    i = random.randrange(0, len(backup))
    alt = backup.pop(i)
    main.append(alt)
    return None

## Collect command line arguments
parser = argparse.ArgumentParser()
# Input/Output
requiredNamed = parser.add_argument_group('required named arguments')
requiredNamed.add_argument('-i', '--input', required=True,
                           help='.tsv with requested taxa and number of genomes. \n ALSO: CHECK #config section of script to change email')
parser.add_argument('-r', '--get_reference', default=ref, nargs='?', const=True, type=str,
                    help='Custom reference list. No argument supplied will download phylophlan ref list.'
                         'Default personalized in source code')
parser.add_argument('-o', '--output', nargs='?', const='.', default=outfolder,
                    help='Output directory')
parser.add_argument('-a', '--aminoacid', action='store_true', default=False,
                    help='Get amino acid sequence')

# Input header settings
parser.add_argument('--inheader', default='1', nargs='?', const='1', type=int,
                    help='number of header lines in input .tsv')
parser.add_argument('--no-inheader', dest='inheader', action='store_false',
                    help="no header in input file requesting taxa")
parser.add_argument('--refheader', default='3', nargs='?', const='3', type=int,
                    help='number of header lines in assembly list')
parser.add_argument('--no-refheader', dest='refheader', action='store_false',
                    help='no header in reference assembly list')


# Take all assemblies for a species instead of taking random
parser.add_argument('--pool', action='store_true', help='pool assemblies for a taxon match (decreases variety)')

args = parser.parse_args()

# Aminoacids or genomes
getaa = args.aminoacid

## Inputs
if args.get_reference == True:
    linkfileurl = "http://cmprod1.cibio.unitn.it/databases/PhyloPhlAn/taxa2genomes.txt"
    getlinks = subprocess.run(['wget', '-c', linkfileurl])
    if not os.path.exists('taxa2genomes.txt'):
        print('Could not get reference link list! Check phylophlan github for taxa2genome.txt')
        exit()
    with open('taxa2genomes.txt', 'r') as linkfile:
        rows = linkfile.readlines()
        for row in [row for row in rows if row[0][0] != '#']:
            link = row.split()[1]
            getref = subprocess.run(['wget', '-c', link])
            if not any(fname.startswith('taxa2genomes_') for fname in os.listdir('.')):
                if row==rows[-1]:
                    print('Downloading any reflist file failed, see phylophlan on github')
                    exit()
                else:
                    continue
            else:
                break
    files = os.listdir('.')
    for file in files:
        if (file.startswith('taxa2genomes_') and file.endswith('.txt.bz2')):
            unzip = subprocess.run(['bzip2', '-d', file])
            reffile = file[:-4]
            break
else:
    reffile = args.get_reference

infile = str(args.input)

if args.inheader == False:
    inpHead = 0
else:
    inpHead = args.inheader

if args.refheader == False:
    refHead = 0
else:
    refHead = args.refheader

# Define output folder
outfolder = args.output

# Translate request file into dictionary
cart = {}
with open(infile, 'r') as inp:
    taxa = inp.readlines()[inpHead:]
    tottaxa = len(taxa)
    for entry in taxa:
        entrydata = entry.split('\t')
        taxon = entrydata[0]
        ngen = int(entrydata[1])
        cart[taxon] = ngen
        # if duplicate entries, only last one is valid

# Total requested sequences
totgen = sum(cart.values())

print(f'{totgen} genomes from {len(cart)} taxa requested \n')
print('Collecting data from reference file...')


options={} # collect alternatives for a requested taxon
taxids={} # save NCBI taxID for each alternative

with open(reffile, 'r') as f:
    Lines = f.readlines()[refHead:]
    totlines = len(Lines)
    for line in Lines:
        linedata = line.split("\t")
        taxid = linedata[0]
        taxonomy = linedata[1].split("|")
        for tax in taxonomy[::-1]: # Check backwards to prioritize low-level taxa
            if tax in cart:
                acc_nums = linedata[2].split(';')
                # Take all assemblies available if --pool enables
                if args.pool:
                    assemblies = [acc.split('.')[0] for acc in acc_nums]
                    if tax in options:
                        options[tax] += assemblies
                    else:
                        options[tax] = assemblies
                    for acc_num in assemblies:
                        taxids[acc_num] = taxid
                else:
                    choose_one = random.choice(linedata[2].split(';'))
                    assembly = choose_one.split('.')[0]
                    if tax in options:
                        options[tax].append(assembly)
                    else:
                        options[tax] = [assembly]
                    taxids[assembly] = taxid

notfound = [taxa for taxa in list(cart.keys()) if taxa not in list(options.keys())]
if notfound != []:
    print('Taxa not found: ', notfound)


## Present user with expected download
n_download = 0
for taxon in options:
    found = len(options[taxon])
    if found < cart[taxon]:
        n_download += found
    else:
        n_download += cart[taxon]

print(f'{len(flatten(options.values()))} entries from {len(options)}/{len(cart)} taxa matching request located in reference file')
print(f'{n_download} random assemblies from matching entries taxa will be queried for download')
print('Generating download URLs...')

base = 'ftp.ncbi.nih.gov'
#winhome = 'C:/Users/brown/Documents/MobaXterm/home'
#wincmd = 'C:/WINDOWS/system32/cmd.exe' #for windows experimentation

## Create output folder
if not os.path.exists(outfolder):
    subprocess.run(['mkdir', outfolder])

commands = []
p = 0
size = 0

## Start building links for ftp
ftp = ftplib.FTP(base, "anonymous", email)
ftp.encoding = "utf-8"

for taxon in options:
    # Subsample from options
    randlist = random.sample(options[taxon], k=min(cart[taxon], len(options[taxon])))
    backup = [alt for alt in options[taxon] if alt not in randlist] # other options to try if needed
    for assembly in randlist:
        # Build path in NCBI database
        refacc = assembly.replace('_', '')
        for c in range(3, 16, 4):
            refacc = refacc[:c] + '/' + refacc[c:]

        path = 'genomes/all/'+refacc

        # Try to access path, else, refill sampled assemblies and try again
        try:
            ftp.cwd(path)
        except ftplib.error_perm:
            if len(backup) > 0:
                refill(randlist, backup)
                print(f'\n {taxon} | {assembly}: Folder error, trying alternative...')
            else:
                print(f'\n {taxon} | {assembly}: Folder options exhausted! Skipping to next...')
            continue

        # Move to file records directory
        enddir = ftp.nlst()[0]
        ftp.cwd(enddir)

        # Find genome.fasta file
        filelist = ftp.nlst()
        if getaa:
            onefile = [file for file in filelist if 'protein.faa.gz' in file]
        else:
            onefile = [file for file in filelist if 'genomic.fna.gz' in file
                   and 'rna' not in file and 'cds' not in file]

        # Case: file found -> construct command, add to list, go back to home NCBI directory
        if len(onefile) > 0:
            fna = f'{base}/{path}{enddir}/{onefile[0]}'
            cmd = f'rsync://{fna}'
            ftp.sendcmd("TYPE i") # Switch to binary to get file size
            size += ftp.size(onefile[0])
            print(f'{taxon} | {assembly} located, size: {get_size_format(ftp.size(onefile[0]))} ', end=' ')
            ftp.sendcmd("TYPE A") # Switch back to ASCII
            commands.append(cmd)
            ftp.cwd('/')
            p += 1
            print(f'{p}/{n_download}')
        # Case: no file found but there are alternatives left in backup
        elif len(backup) > 0:
            refill(randlist, backup)
            print(f'{taxon} | {assembly} Fasta file error, trying alternative...')
        # Case: no file and no alternatives
        else:
            print(f'\n {taxon} | {assembly}: Folder options exhausted (file error)! Skipping to next...')


print(f'{p} of {n_download} assemblies found online')
# Close connection
ftp.quit()

tot = len(commands)
print(f'\n{tot} assembly URLs generated for {p} assemblies found in NCBI catalogue')
print(f'\nExecuting bash commands for download {get_size_format(size)} total...')

dlfails = 0
dlskips = 0

# Download fastas via bash
for comd in commands:
    bname = os.path.basename(comd)
    if not os.path.exists(f'{outfolder}/{bname}'):
        subprocess.run(['rsync', '-t', comd, outfolder], capture_output=True)
        if os.path.exists(f'{outfolder}/{bname}'):
            print(f'{bname} downloaded successfully')
        else:
            print(f'{bname} could not be downloaded')
            dlfails+=1
    else:
        print(f'{bname} is already present on the system! Skipping download')
        dlskips += 1
        
print(f'Successfully downloaded {tot-dlfails-dlskips} files ({dlskips} skipped, {dlfails} failed). Exiting program..')

# Make summary file
print('Writing summary...')
now = datetime.now()
timestamp = now.strftime("%Y-%m-%d__%H:%M:%S")
summary = f'{outfolder}/summary{timestamp}.log'
with open(summary, 'w') as s:
    # Write headings
    s.write('NCBI Assembly ID\tTaxonomyID\tKingdom\tPhylum\tClass\tOrder\tFamily\tGenus\tSpecies\n')
    for comd in commands:
        #Get assemblyID and taxonomyID
        assembly = os.path.basename(comd).split('.')[0]
        taxid = str(taxids[assembly])
        s.write(f'{assembly}\t{taxid}\t')
        #Get data from NCBI taxonomy via Entrez
        handle = Entrez.efetch(db='taxonomy', id=taxid, retmode="xml")
        data = Entrez.read(handle)[0]
        #Extract lineage data
        lineage = data['LineageEx']
        for lev in range(1, len(lineage)):
            div = lineage[lev]['ScientificName']
            s.write(f'{div}\t')
        #Extract species name
        species = data['ScientificName']
        s.write(f'{species}\n')
