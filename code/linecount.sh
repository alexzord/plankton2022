#!/bin/bash -l

#Help
Help()
{
	echo "############################################################################################################################"
	echo "################################################# LINE COUNTER HELP TEXT ###################################################"
        echo "Usage: linecount.sh <options>"
        echo "Default mode: count lines in all files in current directory"
        echo "Output is saved in linecounts.out in current directory"
        echo "Options [ h | e | c | s | n | i | x ]:"
        echo " -h	print help text"
        echo " -e	space-separated string of file names to exclude from current directory | Example [ -e 'depth.txt coverage.txt' ]"
	echo " -c	space-separated string of file names (either relative or full paths) | Example [ -c 'file1 file2 file3' ]"
	echo " -s	no summary in bottom of output file"
	echo " -n	no header"	
	echo -n " -i 	formats (extensions) to include from working directory or custom list (-c), space-separated string | Example [ -i "
	echo '"txt out bin" ]'
	echo -n " -x	formats (extensions) to exclude from working directory or custom list (-c), space-separated string | Example [ -x "
	echo '"txt out bin" ]' 
	echo "Good strings with filenames can be generated using:"
	echo 'p=$(echo $(find . -name "<pattern>*")); t=$(echo ${p##*/});  s=$(echo ${t//[$'\t\r\n']} | echo $(sed "s,./, ./,g")); echo ${s[@]}'
	echo "###################################################### HELP TEXT END #######################################################"
	echo "############################################################################################################################"
}

#Extension filter

FindExtensions()
{
        local track="${1}"
        if [[ ${track} =~ "c" ]]; then local filecoll="${3}"; local search=${filecoll}; else local search="./"; fi
        local EXSTR="${2}"
        set -f
        local EXTARR=(${EXSTR})
        local liststr=""
        for ext in ${EXTARR[@]}; do
                local  exclstr=$(find $search -name "*.${ext}")
                for filename in ${exclstr[@]}; do liststr+="${filename//[$'\n\r]'}"; done
        done
	FILEARRAY=($(echo "${liststr}" | sed "s,./, ./,g"))
}


#Standard
ERRORMSG() { local msg="$1"; echo "ERROR: Please submit a $msg, see [-h] for help"; return 1; }
FILES=($(ls))
IFS=' '
head=TRUE
sum=TRUE
track=s
EXARR=()

while getopts ":e:c:hsnri:x:" option; do
	case "${option}" in

	":") #silent errorr
		if [ ${OPTARG} =~  "c" ]; then err="string-list of files for a custom collection [-c]";
		elif [ ${OPTARG} =~ "e" ]; then err="string-list of files to exclude [-e]";
		elif [ ${OPTARG} =~ "i" ]; then err="string-list of extensions to include [-i]";
		elif [ ${OPTARG} =~ "x" ]; then err="string-list of extensions to exclude [-x]"; 
		else echo "Unknown crash. Abort mission"; exit 0; fi
                ERRORMSG "${err}"
		Help
                if [ ${?} -eq 1 ]; then
		exit 1; fi
		;;
        c) #custom list
		track=c
                STR="${OPTARG}"
		echo ${OPTARG}
                set -f
                CUSTOM=(${STR})
                FILES=(${CUSTOM[@]})
                ;;
		
	e) #exclude files
		if [ $track = "c" ]; then track=ce; else track=e; fi
                EXSTR=${OPTARG}
                set -f
                EXARR=(${OPTARG})
                ;;
       	h) #help section
		Help
		exit
		;;
	s) #no summary
		sum=FALSE;;
	n) #no header file
		head=FALSE;;
	i) #include extension
		INCSTR=${OPTARG}
		INCARR=()
		FindExtensions ${track} ${INCSTR} "${FILES[*]}"
		INCARR=(${FILEARRAY[@]})
		unset $FILEARRAY
		if ! [ track = "c" ]; then FILES=(); fi
		FILES=(${FILES[@]} ${INCARR[@]})
		;;
	 x) #exclude extensions
                if [ $track = s ]; then track=e; else track=ce; fi
		EXTSTR=${OPTARG}
		EXFARR=()
		FindExtensions ${track} ${EXTSTR} "${FILES[*]}"
		EXFARR=(${FILEARRAY[@]})
		unset $FILERARRAY
                EXARR=(${EXARR[@]} ${EXFARR[@]})
		;;
	\?) #inexisting option
		echo "Option not available"
		echo -n "Run "; echo -n "'linecount.sh -h'"; echo " for available options"
		exit
		;;
	esac  
done


if [[ -f "$PWD/linecounts.out" ]]; then
rm linecounts.out
fi

touch linecounts.out

if [ $head ]; then
	HEADER=$(printf "Filename\tLines\n")
	echo -e $HEADER >> linecounts.out
fi


files=0
lines=0

for file in ${FILES[@]}
do
if [[ ${track} =~ "e" ]] && [[ "${EXARR[*]}" =~ "${file}" ]]; then
	continue
else
	LC=$(wc -l $file)
	COUNT=${LC%% *}
	OUT=$(printf ${file##*/}" \t "$COUNT "\n")
	echo $OUT >> linecounts.out
	files+=1
	lines+=$COUNT
fi
done

if [ $sum ]; then
	case "${track}" in
		s)
		source=$(printf "working directory ($(echo $PWD))");;
		c)
		source="custom list: $(echo ${CUSTOM[@]})";;
		e)
		source="working directory ($(echo $PWD)) with excluded files: $(echo ${EXARR[@]})";;
		ce)
		source="custom list: $(echo ${CUSTOM[@]}) with excluded files: $(echo ${EXARR[@]})";;
	esac
	SUMMARY=$(printf "Filenames taken from $(echo $source)")
	echo $SUMMARY >> linecounts.out
fi

echo "Done ($(printf $files) files processed with $(printf $lines) total lines)"
exit 1
done