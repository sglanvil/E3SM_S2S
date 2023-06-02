% June 1, 2023

clear; clc; close all;


file_ERA5='/glade/campaign/cesm/development/cross-wg/S2S/sglanvil/forSanjiv/H2OSOI_ERA5/ERA5_SM_global_daily_19990101_20211231.nc';
lon_ERA5=ncread(file_ERA5,'lon');
lat_ERA5=ncread(file_ERA5,'lat');

file='/glade/campaign/cesm/development/cross-wg/S2S/sglanvil/forSanjiv/TWS_ICRUELM/TWS_s2sLandSpinupSE_perl_ICRUELM.elm.h0.0001-0449.nc';
time_ELM=1:449;
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
TWSzm=squeeze(mean(TWS_ELM,1,'omitnan'));
TWSgm=squeeze(mean(TWSzm(abs(lat)<=50,:),1,'omitnan'))/1000;

figure
hold on; grid on; box on;
plot(time_ELM,TWSgm,'k','linewidth',2);
ylabel('TWS (m)');
xlabel('Spinup Year')
title('Global Mean TWS (CRUELM)');
set(gca,'fontsize',13)
print('/glade/work/sglanvil/CCR/E3SM_SMYLE/TWS_CRUELM','-r300','-dpng');
