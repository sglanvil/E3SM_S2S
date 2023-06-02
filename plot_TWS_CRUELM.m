% June 1, 2023

clear; clc; close all;


file_ERA5='/glade/campaign/cesm/development/cross-wg/S2S/sglanvil/forSanjiv/H2OSOI_ERA5/ERA5_SM_global_daily_19990101_20211231.nc';
lon_ERA5=ncread(file_ERA5,'lon');
lat_ERA5=ncread(file_ERA5,'lat');

file='/glade/campaign/cesm/development/cross-wg/S2S/sglanvil/forSanjiv/H2OSOI_s2sLandRunSE_perl_ICRUELM/TWS_ICRUELM.199901-201512.nc';
time_ELM=datetime('Jan/1/1999'):datetime('Dec/31/2015');
time_ELM=time_ELM(day(time_ELM)==15);
TWS_0=ncread(file,'TWS');

lon=ncread(file,'lon');
lat=ncread(file,'lat');
TWS_1=TWS_0(~isnan(lat),:);

lat=lat(~isnan(lat));
lon=lon(~isnan(lon));
[latNew,lonNew]=meshgrid(lat_ERA5,lon_ERA5);

TWS_ELM=NaN(length(lon_ERA5),length(lat_ERA5),length(time_ELM));
for itime=1:length(time_ELM)
    itime
    TWS_ELM(:,:,itime)=griddata(lon,lat,...
        squeeze(TWS_1(:,itime)),lonNew,latNew);   
end
lon=lon_ERA5;
lat=lat_ERA5;

blah=squeeze(mean(mean(TWS_ELM,1,'omitnan'),2,'omitnan'));
