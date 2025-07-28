#!/bin/bash
# sglanvil | July 23, 2024
module unload climate-utils

# ----------------------- USER SPECIFIES --------------------------
DATE=$1 # format: 2000-02-07
ensembleSize=11 
# -----------------------------------------------------------------

YEAR=$(echo $DATE | cut -d'-' -f1)
MONTH=$(echo $DATE | cut -d'-' -f2)
DAY=$(echo $DATE | cut -d'-' -f3)
if [ $YEAR -lt 2014 ] || ( [ $YEAR -eq 2014 ] && [ $MONTH -lt 11 ] ); then
	COMPSET=WCYCL20TR
else
	COMPSET=WCYCLSSP370
fi
RESOLUTION=ne30pg2_EC30to60E2r2
MACHINE=pm-cpu
PROJECT=mp9
SOURCE_CODE=/global/cfs/cdirs/mp9/e3sm_tags/E3SMv2.1/cime/scripts/

mkdir -p ${SCRATCH}/v21.LR.S2S_v2/
this_full_path=$(realpath "$0")
CASE_BUILD_DIR=${SCRATCH}/v21.LR.S2S_v2/exeroot/bld/
NAMELISTS_DIR=/global/homes/s/sglanvil/S2S/E3SM_S2S_Forecasts/E3SM-Realtime-Forecast/bin/namelists/
SOURCEMODS_DIR=/global/homes/s/sglanvil/S2S/E3SM_S2S_Forecasts/E3SM-Realtime-Forecast/bin/sourceMods/
RUN_REFCASE=v21.LR.S2S_IC.${DATE}.01
MAIN_CASE_NAME=v21.LR.S2S_v2.${DATE}.001
MAIN_CASE_ROOT=${SCRATCH}/v21.LR.S2S_v2/${MAIN_CASE_NAME}/

# ------------------- CREATE LIST OF PERTURBATION FILE VALUES ----------------------
numbers=()
seen=()
for ((i=0; i<$(( ensembleSize/2 )); i++)); do
        rand_num=$(( RANDOM % 999 + 1 ))
        formatted_num=$(printf "%03d" "$rand_num")
        while [[ " ${seen[@]} " =~ " $formatted_num " ]]; do
        # ----- create a new number if it is not unique -----
        rand_num=$(( RANDOM % 999 + 1 ))
        formatted_num=$(printf "%03d" "$rand_num")
        done
        numbers+=("$formatted_num")
        seen+=("$formatted_num")
done
echo "${numbers[@]}" > /global/cfs/cdirs/mp9/E3SMv2.1-S2S_v2/eamic_txt_files/eamic_${DATE}.1-10.txt
# ----------------------------------------------------------------------------------

for ((i=1; i<=ensembleSize; i++)); do
	mbr=$(printf "%03d" $i)
	echo '---------------------------------------------------------------------'
	echo $mbr
	echo
	CASE_NAME=v21.LR.S2S_v2.${DATE}.${mbr}
	CASE_ARCHIVE_DIR=${MAIN_CASE_ROOT}/archive.${mbr}/
	CASE_SCRIPTS_DIR=${MAIN_CASE_ROOT}/case_scripts.${mbr}/
	CASE_RUN_DIR=${MAIN_CASE_ROOT}/run.${mbr}/

	# ------------------ CREATE NEWCASE ------------------ 
	cd ${SOURCE_CODE}
	./create_newcase --compset ${COMPSET} --res ${RESOLUTION} --case ${CASE_NAME} \
		--project ${PROJECT} --machine ${MACHINE} --output-root ${MAIN_CASE_ROOT} \
		--script-root ${CASE_SCRIPTS_DIR} --handle-preexisting-dirs u 
	cd ${CASE_SCRIPTS_DIR}

	# ---------------------------- CASE SETUP, COPY NAMELISTS, COPY SOURCE MODS, COPY ENV_MACH ----------------------------
	if [ -d ${CASE_BUILD_DIR} ]; then
		./xmlchange EXEROOT=${CASE_BUILD_DIR}
	fi
	./xmlchange RUNDIR=${CASE_RUN_DIR}
	./xmlchange DOUT_S_ROOT=${CASE_ARCHIVE_DIR}
	cp ${NAMELISTS_DIR}/user_nl* .
	./case.setup --reset
	# cp /global/u2/n/nanr/CESM_tools/e3sm/v2/scripts/v2.SMYLE/env_mach/env_mach_specific.xml ${CASE_SCRIPTS_DIR}/
	cp /global/homes/s/sglanvil/S2S/E3SM_S2S_Forecasts/E3SM-Realtime-Forecast/bin/env_mach_specific.xml ${CASE_SCRIPTS_DIR}/
	cp -r ${SOURCEMODS_DIR}/* ${CASE_SCRIPTS_DIR}/SourceMods/

	# ---------------------------- PRESTAGE IC FILES ----------------------------
	ATM_IC_DIR='/global/cfs/cdirs/mp9/E3SMv2.1-S2S/eami.HICCUP-ERA5-CATALYST.ne30np4.L72_MONDAYS/'
	original_file=${ATM_IC_DIR}/eami.HICCUP-ERA5-CATALYST.${DATE}.ne30np4.L72.c20240803.nc
	if [[ "$mbr" == "001" ]]; then
                # use original file
                echo "mbr: 001, use original file"
                echo ${original_file}
		cp ${original_file} ${CASE_RUN_DIR}/${RUN_REFCASE}.eam.i.${DATE}-00000.nc
		module load climate-utils 
		ncatted -O -h -a original_file,global,o,c,eami.HICCUP-ERA5-CATALYST.${DATE}.ne30np4.L72.c20240803.nc ${CASE_RUN_DIR}/${RUN_REFCASE}.eam.i.${DATE}-00000.nc
		module unload climate-utils
	else 
		mbr_num=$((10#$mbr))  # Convert to number to handle leading zeros
		if (( mbr_num % 2 == 0 )); then
			# mbr is even, use (mbr - 2) / 2
			inx=$(( (mbr_num - 2) / 2 ))
			weight=0.15
		else
			# mbr is odd, use (mbr - 3) / 2
			inx=$(( (mbr_num - 3) / 2 ))
			weight=-0.15
		fi
		pert_file=/global/cfs/cdirs/mp9/E3SMv2.1-SMYLE/S2S_perts_DIFF/05/v2.LR.historical_daily-cami_0241.eam.i.M05.diff.${numbers[$inx]}.nc
		echo "mbr: $mbr, inx: $inx, weight: $weight"
		echo ${pert_file}
		final_file=${CASE_RUN_DIR}/${RUN_REFCASE}.eam.i.${DATE}-00000.nc
		module load climate-utils
		ncflint -O -C -v time_bnds,lev,ilev,hyai,hybi,hyam,hybm,U,V,T,Q,PS -w ${weight},1.0 ${pert_file} ${original_file} ${final_file}
		ncrename -d ncol_d,ncol ${final_file}
		ncatted -O -h -a original_file,global,o,c,eami.HICCUP-ERA5-CATALYST.${DATE}.ne30np4.L72.c20240803.nc ${final_file}
		module unload climate-utils
	fi

	# LAND_IC_DIR='/global/cfs/cdirs/mp9/E3SMv2.1-S2S/v21.LR.I20TRELM_CRUNCEP-daily_MONDAYS/'
	LAND_IC_DIR='/global/cfs/cdirs/mp9/E3SMv2.1-S2S/v21.LR.I20TRELM_CRUNCEP_TRENDY_MONDAYS/'
	cp ${LAND_IC_DIR}/v21.LR.I20TRELM_CRUNCEP_TRENDY.elm.r.${DATE}-00000.nc ${CASE_RUN_DIR}/${RUN_REFCASE}.elm.r.${DATE}-00000.nc
	cp ${LAND_IC_DIR}/v21.LR.I20TRELM_CRUNCEP_TRENDY.mosart.r.${DATE}-00000.nc  ${CASE_RUN_DIR}/${RUN_REFCASE}.mosart.r.${DATE}-00000.nc
	module load climate-utils
	ncatted -O -h -a original_file,global,o,c,v21.LR.I20TRELM_CRUNCEP_TRENDY.elm.r.${DATE}-00000.nc ${CASE_RUN_DIR}/${RUN_REFCASE}.elm.r.${DATE}-00000.nc
	ncatted -O -h -a original_file,global,o,c,v21.LR.I20TRELM_CRUNCEP_TRENDY.mosart.r.${DATE}-00000.nc  ${CASE_RUN_DIR}/${RUN_REFCASE}.mosart.r.${DATE}-00000.nc
	module unload climate-utils

	OCEAN_IC_DIR='/global/cfs/cdirs/mp9/E3SMv2.1-S2S/cycle6_daily-restarts_MONDAYS/'
	oyear=$(printf "%04d" $(( YEAR - 1957 )))
	cp ${OCEAN_IC_DIR}/20240603_EC30to60_cycle6_daily_restarts_anvil.mpaso.rst.${oyear}-${MONTH}-${DAY}_00000.nc ${CASE_RUN_DIR}/${RUN_REFCASE}.mpaso.rst.${DATE}_00000.nc
	cp ${OCEAN_IC_DIR}/20240603_EC30to60_cycle6_daily_restarts_anvil.mpassi.rst.${oyear}-${MONTH}-${DAY}_00000.nc ${CASE_RUN_DIR}/${RUN_REFCASE}.mpassi.rst.${DATE}_00000.nc
	module load climate-utils
	ncrename -v xtime,xtime.orig ${CASE_RUN_DIR}/${RUN_REFCASE}.mpaso.rst.${DATE}_00000.nc
	ncrename -v xtime,xtime.orig ${CASE_RUN_DIR}/${RUN_REFCASE}.mpassi.rst.${DATE}_00000.nc
	ncatted -O -h -a original_file,global,o,c,20240603_EC30to60_cycle6_daily_restarts_anvil.mpaso.rst.${oyear}-${MONTH}-${DAY}_00000.nc ${CASE_RUN_DIR}/${RUN_REFCASE}.mpaso.rst.${DATE}_00000.nc
	ncatted -O -h -a original_file,global,o,c,20240603_EC30to60_cycle6_daily_restarts_anvil.mpassi.rst.${oyear}-${MONTH}-${DAY}_00000.nc ${CASE_RUN_DIR}/${RUN_REFCASE}.mpassi.rst.${DATE}_00000.nc
	module unload climate-utils

	# ---------------------------- BUILD CASE ----------------------------
	if [ -d ${CASE_BUILD_DIR} ]; then
		./xmlchange BUILD_COMPLETE=TRUE
	else
		./case.build
		sleep 5s
		# CREATE and COPY the EXEROOT on the very FIRST (and ONLY) build (literally, happens only once)
		bldDir=$(find ${SCRATCH}/v21.LR.S2S_v2/ -d -name "bld")
		exeDir=$(dirname ${bldDir})
		cp -r ${exeDir} ${SCRATCH}/v21.LR.S2S_v2/exeroot
		sleep 5s
	fi
	./preview_namelists

	# ---------------------------- XML CHANGES ----------------------------
	./xmlchange RUN_STARTDATE=${DATE}
	./xmlchange STOP_OPTION=ndays
	./xmlchange STOP_N=45
	./xmlchange BUDGETS=TRUE
	./xmlchange RUN_TYPE=hybrid
	./xmlchange CONTINUE_RUN=FALSE
	./xmlchange GET_REFCASE=FALSE
	./xmlchange RUN_REFCASE=${RUN_REFCASE}
	./xmlchange RUN_REFDATE=${DATE}
	./xmlchange DOUT_S=TRUE
	./xmlchange REST_OPTION=never
	./xmlchange JOB_WALLCLOCK_TIME=01:00:00 --subgroup case.run

	# ---------------------------- COPY PROVENANCE SCRIPT ---------------------------- 
	script_provenance_dir=${CASE_SCRIPTS_DIR}/run_script_provenance
	mkdir -p ${script_provenance_dir}
	this_script_name=$(basename "$this_full_path")
	script_provenance_name=${this_script_name}.`date +%Y%m%d-%H%M%S`
	cp -p ${this_full_path} ${script_provenance_dir}/${script_provenance_name}
	module load climate-utils
	echo "...original names for IC files..." >> ${script_provenance_dir}/${script_provenance_name}
	ls ${CASE_RUN_DIR}/${RUN_REFCASE}*.nc | xargs -I {} ncdump -h {} | grep -e "original_file" -e "netcdf" >> ${script_provenance_dir}/${script_provenance_name}
	module unload climate-utils

	# ---------------------------- EDITS FOR NODE RESERVAION ---------------------------- 
	#sed -i '/#SBATCH  --constraint=cpu/a #SBATCH  --reservation=e3sm_s2s_rsvp' .case.run.sh
	#sed -i '/#SBATCH  --constraint=cpu/a #SBATCH  --reservation=e3sm_s2s_rsvp' .case.run
	#sed -i '/#SBATCH  --constraint=cpu/a #SBATCH  --reservation=e3sm_s2s_rsvp' case.st_archive
	#sed -i '/      <directive> --constraint=cpu<\/directive>/a\      <directive> --reservation=e3sm_s2s_rsvp<\/directive>' env_batch.xml
	#sleep 1s

	# ---------------------------- EDITS FOR OVERRUN QUEUE ---------------------------- 
	#./xmlchange JOB_WALLCLOCK_TIME=01:00:00 --subgroup case.st_archive
	#./xmlchange JOB_QUEUE=overrun --force
	#sed -i '/      <directive> --exclusive <\/directive>/a\      <directive> --time-min=01:00:00 <\/directive>' env_batch.xml
	#sleep 1s
	

	# ---------------------------- EDITS FOR 2014Nov+ CASES ---------------------------- 
	if [ $YEAR -lt 2014 ] || ( [ $YEAR -eq 2014 ] && [ $MONTH -lt 11 ] ); then
		echo 
		echo "...using regular, pre-2014Nov, user_nl_eam..."
		echo
	else
		echo
		echo "...using special 2014Nov+ user_nl_eam..."
		echo
		cp /global/homes/s/sglanvil/S2S/E3SM_S2S_Forecasts/E3SM-Realtime-Forecast/bin/user_nl_eam_2014NOV_v2 .
		mv user_nl_eam user_nl_eam_ORIG
		mv user_nl_eam_2014NOV_v2 user_nl_eam
	fi

	# ---------------------------- SUBMIT RUN ----------------------------
	./case.submit
done

echo "Totally Done"

