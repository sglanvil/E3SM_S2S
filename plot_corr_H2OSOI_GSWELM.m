% May 22, 2023

clear; clc; close all;

% Nan ran E3SM LE with monthly outputs, on NERSC Cori (not ELM or CLM)
% /global/cscratch1/sd/nanr/E3SMv2-monthlyRestarts/v2.LR.historical_monthly-restarts_0201/archive/lnd/hist

% Sasha concatenated and saved H2OSOI timeseries
% ncrcat -O -v H2OSOI,DZSOI,lon,lat *h0*nc ~/v2.LR.historical_monthly-restarts_0201.elm.h0.197001-201001.nc
% /glade/campaign/cesm/development/cross-wg/S2S/sglanvil/forSanjiv/H2OSOI_ELM

% -------- GENERAL SETUP ---------
subpos=[.06 .70 .4 .23; .06 .40 .4 .23; .06 .10 .4 .23; .55 .70 .4 .23; .55 .40 .4 .23];
gradsmap=flip([103 0 31; 178 24 43; 214 96 77; 244 165 130; 253 219 199; ...
    209 229 240; 146 197 222; 67 147 195; 33 102 172; 5 48 97]/256);
gradsmap1=interp1(1:5,gradsmap(1:5,:),linspace(1,5,10));
gradsmap2=interp1(6:10,gradsmap(6:10,:),linspace(6,10,10));
gradsmap=[gradsmap1; gradsmap2];


% --------- ERA5 "OBS" --------- Daily
% top layer (0-7cm, 7cm thick) 
% second layer (7-28cm, 21cm) 
file_ERA5='/glade/campaign/cesm/development/cross-wg/S2S/sglanvil/forSanjiv/H2OSOI_ERA5/ERA5_SM_global_daily_19990101_20211231.nc';
swvl1ERA5=ncread(file_ERA5,'swvl1');
swvl2ERA5=ncread(file_ERA5,'swvl2');
H2OSOIdaily_ERA5=(swvl1ERA5.*0.07+swvl2ERA5.*0.21)./sum(0.07+0.21);
time_ERA5=datetime('Jan/1/1999'):datetime('Dec/31/2021');
icount=0;
for iyear=1999:2021
    for imonth=1:12
        icount=icount+1; icount
        H2OSOI_ERA5(:,:,icount)=nanmean(...
            H2OSOIdaily_ERA5(:,:,year(time_ERA5)==iyear & month(time_ERA5)==imonth),3);
    end
end
time_ERA5=time_ERA5(day(time_ERA5)==15);
lon_ERA5=ncread(file_ERA5,'lon');
lat_ERA5=ncread(file_ERA5,'lat');

% --------- s2sLandRunSE_perl_noCROP_1999start --------- Monthly
file='/glade/campaign/cesm/development/cross-wg/S2S/sglanvil/forSanjiv/H2OSOI_s2sLandRunSE_perl_GSW/s2sLandRunSE_perl_GSW.elm.h0.199901-201312.nc';
time_ELM=datetime('Jan/1/1999'):datetime('Dec/31/2013');
time_ELM=time_ELM(day(time_ELM)==15);
H2OSOI=ncread(file,'H2OSOI',[1 1 1],[Inf 5 Inf]); % top levs
DZSOI=ncread(file,'DZSOI',[1 1],[Inf 5])*1000; % top levs
DZSOI=repmat(DZSOI,[1,1,length(time_ELM)]);
lon=ncread(file,'lon');
lat=ncread(file,'lat');
levgrnd=ncread(file,'levgrnd');
H2OSOI_0=squeeze(sum(H2OSOI.*DZSOI,2,'omitnan')./sum(DZSOI,2,'omitnan'));
H2OSOI_1=H2OSOI_0(~isnan(lat),:);
lat=lat(~isnan(lat));
lon=lon(~isnan(lon));
[latNew,lonNew]=meshgrid(lat_ERA5,lon_ERA5);
H2OSOI_ELM=NaN(length(lon_ERA5),length(lat_ERA5),length(time_ELM));
for itime=1:length(time_ELM)
    itime
    H2OSOI_ELM(:,:,itime)=griddata(lon,lat,...
        squeeze(H2OSOI_1(:,itime)),lonNew,latNew);   
end

lon=lon_ERA5;
lat=lat_ERA5;

for ilon=1:length(lon)
    for ilat=1:length(lat)
        if isnan(squeeze(H2OSOI_ERA5(ilon,ilat,1)))
            H2OSOI_ELM(ilon,ilat,:)=NaN;
        end
    end
end

X=H2OSOI_ERA5(:,:,year(time_ERA5)>=1999 & year(time_ERA5)<=2012);
Y=H2OSOI_ELM(:,:,year(time_ELM)>=1999 & year(time_ELM)<=2012);

%
figure
contourf(lon,lat,squeeze(Y(:,:,33))',0:0.01:0.5,'linestyle','none');
colormap(gradsmap); colorbar; clim([0 0.5])
title('H2OSOI GSWELM')
print('/glade/work/sglanvil/CCR/E3SM_SMYLE/H2OSOI_GSWELM_raw','-r300','-dpng');

R=NaN(length(lon),length(lat));
for ilon=1:length(lon)
    for ilat=1:length(lat)
        R0=corrcoef(squeeze(X(ilon,ilat,:)),squeeze(Y(ilon,ilat,:)),...
            'rows','pairwise');
        R(ilon,ilat)=R0(1,2);
    end
end

figure
contourf(lon,lat,R','linestyle','none');
colormap(gradsmap); colorbar; clim([-0.8 0.8])
title('H2OSOI Correlation (GSWELM vs ERA5)')
print('/glade/work/sglanvil/CCR/E3SM_SMYLE/H2OSOI_GSWELM','-r300','-dpng');

