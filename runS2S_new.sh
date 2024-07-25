#!/bin/bash
# sglanvil | July 23, 2024
source /global/common/software/e3sm/anaconda_envs/load_latest_e3sm_unified_pm-cpu.sh

DATE=2012-05-01

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
mkdir -p ${SCRATCH}/v21.LR.S2Ssmbb/
CASE_BUILD_DIR=${SCRATCH}/v21.LR.S2Ssmbb/exeroot/bld/
NAMELISTS_DIR=/global/homes/s/sglanvil/S2S/E3SM_S2S_Forecasts/E3SM-Realtime-Forecast/bin/namelists/
SOURCEMODS_DIR=/global/homes/s/sglanvil/S2S/E3SM_S2S_Forecasts/E3SM-Realtime-Forecast/bin/sourceMods/



# ------------------- CREATE LIST OF PERTURBATION FILE VALUES ----------------------
ensembleSize=11
numbers=()
seen=()
for ((i = 0; i < $(( ensembleSize/2 )); i++)); do
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
echo "${numbers[@]}" > eamic_2012-05-01.1-10.txt
# ----------------------------------------------------------------------------------



for mbr in {001..011}; do
        RUN_REFDIR=/global/homes/s/sglanvil/S2S/E3SM_S2S_Forecasts/E3SM-Realtime-Forecast/bin/StageIC/
        RUN_REFCASE=v21.LR.SMYLE_IC.${YEAR}-${MONTH}.01
        MAIN_CASE_NAME=v21.LR.S2Ssmbb.${YEAR}-${MONTH}-${DAY}.001
        CASE_NAME=v21.LR.S2Ssmbb.${YEAR}-${MONTH}-${DAY}.${mbr}
        MAIN_CASE_ROOT=${SCRATCH}/v21.LR.S2Ssmbb/${MAIN_CASE_NAME}/
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
        cp /global/u2/n/nanr/CESM_tools/e3sm/v2/scripts/v2.SMYLE/env_mach/env_mach_specific.xml ${CASE_SCRIPTS_DIR}/
        cp -r ${SOURCEMODS_DIR}/* ${CASE_SCRIPTS_DIR}/SourceMods/

        # ---------------------------- PRESTAGE IC FILES ----------------------------
        original_file='/global/cfs/cdirs/mp9/E3SMv2.1-SMYLE/inputdata/e3sm_init/v21.LR.SMYLE_IC.2012-05.01/2012-05-01/v21.LR.SMYLE_IC.2012-05.01.eam.i.2012-05-01-00000.nc'
        if [[ "$mbr" == "001" ]]; then
                # use original file
                echo "mbr: 001, use original file"
                echo ${original_file}
                cp ${original_file} ${CASE_RUN_DIR}/
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
                final_file=${CASE_RUN_DIR}/v21.LR.SMYLE_IC.2012-05.01.eam.i.2012-05-01-00000.nc
                ncflint -O -C -v time_bnds,lev,ilev,hyai,hybi,hyam,hybm,U,V,T,Q,PS -w ${weight},1.0 ${pert_file} ${original_file} ${final_file}
                ncrename -d ncol_d,ncol ${final_file}
        fi
        # 1. grab elm.r and mosart.r
        # 2. grab mpaso.rst mpassi.rst (do year conversion and ncrename xtime)
        # 3. do we need rpointers?
        cp /global/homes/s/sglanvil/S2S/E3SM_S2S_Forecasts/E3SM-Realtime-Forecast/bin/StageIC/v21.LR.SMYLE_IC.2012-05.01.elm.r.2012-05-01-00000.nc ${CASE_RUN_DIR}/
        cp /global/homes/s/sglanvil/S2S/E3SM_S2S_Forecasts/E3SM-Realtime-Forecast/bin/StageIC/v21.LR.SMYLE_IC.2012-05.01.mosart.r.2012-05-01-00000.nc ${CASE_RUN_DIR}/
        cp /global/homes/s/sglanvil/S2S/E3SM_S2S_Forecasts/E3SM-Realtime-Forecast/bin/StageIC/v21.LR.SMYLE_IC.2012-05.01.mpaso.rst.2012-05-01_00000.nc ${CASE_RUN_DIR}/
        cp /global/homes/s/sglanvil/S2S/E3SM_S2S_Forecasts/E3SM-Realtime-Forecast/bin/StageIC/v21.LR.SMYLE_IC.2012-05.01.mpassi.rst.2012-05-01_00000.nc ${CASE_RUN_DIR}/
        cp /global/homes/s/sglanvil/S2S/E3SM_S2S_Forecasts/E3SM-Realtime-Forecast/bin/StageIC/rpointer* ${CASE_RUN_DIR}/

        # ---------------------------- BUILD CASE ----------------------------
        if [ -d ${CASE_BUILD_DIR} ]; then
                ./xmlchange BUILD_COMPLETE=TRUE
        else
                ./case.build
                sleep 5s
                # CREATE and COPY the EXEROOT on the very FIRST (and ONLY) build (literally, happens only once)
                bldDir=$(find ${SCRATCH}/v21.LR.S2Ssmbb/ -d -name "bld")
                exeDir=$(dirname ${bldDir})
                cp -r ${exeDir} ${SCRATCH}/v21.LR.S2Ssmbb/exeroot
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
        ./xmlchange RUN_REFDIR=${RUN_REFDIR}
        ./xmlchange RUN_REFCASE=${RUN_REFCASE}
        ./xmlchange RUN_REFDATE=${DATE}
        ./xmlchange DOUT_S=TRUE
        ./xmlchange JOB_WALLCLOCK_TIME=01:00:00 --subgroup case.run

        # ---------------------------- SUBMIT RUN ----------------------------
        ./case.submit
done

# DONE: add output variables (SourceMod)
# DONE: organize fincl variables (user_nl) to match CESM
# DONE: make if statement for BUILD_COMPLETE bit
# DONE: make the generate eami, rename bits

