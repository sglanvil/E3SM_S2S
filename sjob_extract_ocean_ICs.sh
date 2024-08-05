#!/bin/bash
# location: /global/homes/s/sglanvil/S2S/E3SM_S2S_Forecasts/E3SM-Realtime-Forecast/bin

for iyear in {2006..2020}; do
        nohup bash extract_ocean_ICs.sh ${iyear} > out_${iyear} 2>&1 &
done
