% June 7, 2023

% ncrcat -O -v TOTECOSYSC,lon,lat *h0*nc TOTECOSYSC.nc
% ncrcat -O -v TOTSOMC,lon,lat *h0*nc TOTSOMC.nc
% ncrcat -O -v TOTVEGC,lon,lat *h0*nc TOTVEGC.nc
% ncrcat -O -v TLAI,lon,lat *h0*nc TLAI.nc
% ncrcat -O -v GPP,lon,lat *h0*nc GPP.nc
% ncrcat -O -v TWS,lon,lat *h0*nc TWS.nc
% ncrcat -O -v H2OSNO,lon,lat *h0*nc H2OSNO.nc

clear; clc; close all;

file_ERA5='/glade/campaign/cesm/development/cross-wg/S2S/sglanvil/forSanjiv/H2OSOI_ERA5/ERA5_SM_global_daily_19990101_20211231.nc';
lon_ERA5=ncread(file_ERA5,'lon');
lat_ERA5=ncread(file_ERA5,'lat');

varList={'TOTECOSYSC','TOTSOMC','TOTVEGC','TLAI','GPP','TWS','H2OSNO'};
unitsList={'gC/m^2','gC/m^2','gC/m^2',' ','gC/m^2/s','mm','mm'};

for ivar=1:7
    ivar
    varName=varList{ivar};
    unitsName=unitsList{ivar};
    file=sprintf('/glade/scratch/sglanvil/E3SM_s2sLandSpinupSE_perl/archive/lnd/hist/%s.nc',varName);
    time_ELM=1:5160;
    var0=ncread(file,varName);
    lon=ncread(file,'lon');
    lat=ncread(file,'lat');
    var1=var0(~isnan(lat),:);
    lat=lat(~isnan(lat));
    lon=lon(~isnan(lon));
    
    [latNew,lonNew]=meshgrid(lat_ERA5,lon_ERA5);
    VARfull=NaN(length(lon_ERA5),length(lat_ERA5),length(time_ELM));
    for itime=1:12:length(time_ELM)
        VARfull(:,:,itime)=griddata(lon,lat,...
            squeeze(var1(:,itime)),lonNew,latNew);   
    end
    VARfull(abs(VARfull)>5*std(VARfull,'omitnan'))=NaN;
    lon=lon_ERA5; lat=lat_ERA5;
    VARzm=squeeze(mean(VARfull,1,'omitnan'));
    VARgm=squeeze(mean(VARzm(abs(lat)<=50,:),1,'omitnan'))/1000;
    
    subplot(3,3,ivar)
    hold on; grid on; box on;
    plot(time_ELM(1:12:end),VARgm(1:12:end),'k','linewidth',2);
    title(varName);
    ylabel(unitsName)
    xlabel('Spinup Month')
    set(gca,'fontsize',10)
end

print('/glade/work/sglanvil/CCR/E3SM_SMYLE/land_equil','-r300','-dpng');

