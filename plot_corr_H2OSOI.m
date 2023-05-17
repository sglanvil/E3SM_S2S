% May 16, 2023

clear; clc; close all;

% --------- ERA5 "OBS" --------- Daily
% top layer (0-7cm, 7cm thick) 
% second layer (7-28cm, 21cm) 
fileERA='/glade/campaign/cesm/development/cross-wg/S2S/sglanvil/forSanjiv/H2OSOI_ERA5/ERA5_SM_global_daily_19990101_20211231.nc';
swvl1ERA=ncread(fileERA,'swvl1');
swvl2ERA=ncread(fileERA,'swvl2');
H2OSOIdaily_ERA=(swvl1ERA.*0.07+swvl2ERA.*0.21)./sum(0.07+0.21);
timeERA=datetime('Jan/1/1999'):datetime('Dec/31/2021');
icount=0;
for iyear=1999:2021
    for imonth=1:12
        icount=icount+1; icount
        H2OSOI_ERA(:,:,icount)=nanmean(...
            H2OSOIdaily_ERA(:,:,year(timeERA)==iyear & month(timeERA)==imonth),3);
    end
end
timeERA=timeERA(day(timeERA)==15);

% ---------- SMYLE TRENDY -------- Monthly
fileTRENDY='/glade/campaign/cesm/development/espwg/SMYLE/initial_conditions/CLM5_SMYLE-Trendy/proc/tseries/month_1/smyle_Transient.clm2.h0.H2OSOI.185001-201912.nc';
timeTRENDY=datetime('Jan/1/1999'):datetime('Dec/31/2019');
timeTRENDY=timeTRENDY(day(timeTRENDY)==15);
H2OSOI=ncread(fileTRENDY,'H2OSOI',[1 1 1 1789],[Inf Inf 5 Inf]); % top levs
DZSOI=ncread(fileTRENDY,'DZSOI',[1 1 1],[Inf Inf 5])*1000; % top levs
DZSOI=repmat(DZSOI,[1,1,1,252]);
H2OSOI_TRENDY=squeeze(sum(H2OSOI.*DZSOI,3,'omitnan')./sum(DZSOI,3,'omitnan'));
lon=ncread(fileTRENDY,'lon');
lat=ncread(fileTRENDY,'lat');
