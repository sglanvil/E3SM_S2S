#!/bin/bash

# location: /global/homes/s/sglanvil/S2S

imonth=01

# load NCO module on NERSC
module load cray-netcdf
module load nco

inDir=/global/cscratch1/sd/sglanvil/S2S_perts/${imonth}/
files=(${inDir}/*)
outDir=/global/cscratch1/sd/sglanvil/S2S_perts_DIFF/${imonth}/
mkdir -p ${outDir}

# initialize an empty array to keep track of generated pairs
declare -a generated_pairs=()

# loop 1000 times to generate 1000 pairs of random numbers
for (( i=1; i<=999; i++ )); do
        # generate num1 and num2
        num1=$((RANDOM % 350 + 1)) # First number is between 1-350
        num2=$((RANDOM % 350 + 351)) # Second number is between 351-700

        # check if the pair has been generated before
        while [[ "${generated_pairs[*]}" =~ "$num1 $num2" || "${generated_pairs[*]}" =~ "$num2 $num1" ]]; do
                num1=$((RANDOM % 350 + 1))
                num2=$((RANDOM % 350 + 351))
        done

        # add the generated pair to the array
        generated_pairs+=("$num1 $num2")

        # calculate the difference between num1 and num2
        diff=$((num2 - num1))
        iPadded=$(printf "%03d" $i)

        # print the output with the unique pair of numbers
        datestr1=$(echo $(basename ${files[$num1-1]}) | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
        datestr2=$(echo $(basename ${files[$num2-1]}) | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
        echo "$iPadded,$num1,$num2,$datestr1,$datestr2"
        echo

#       outFile=${outDir}/v2.LR.historical_daily-cami_0241.eam.i.M{$imonth}.diff.{$iPadded}.nc
#       ncdiff ${files[$num1-1]} ${files[$num2-1]} $outFile

done > random_numbers.txt

