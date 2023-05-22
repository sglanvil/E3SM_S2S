% May 16, 2023

clear; clc; close all;

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

% ---------- SMYLE TRENDY -------- Monthly
% top layer (0-2cm, 2cm thick)
% second layer (2-6cm, 4cm)
% third layer (6-12cm, 6cm)
% fourth layer (12-20cm, 8cm)
% fifth layer (20-32cm, 12cm)
file_TRENDY='/glade/campaign/cesm/development/espwg/SMYLE/initial_conditions/CLM5_SMYLE-Trendy/proc/tseries/month_1/smyle_Transient.clm2.h0.H2OSOI.185001-201912.nc';
time_TRENDY=datetime('Jan/1/1999'):datetime('Dec/31/2019');
time_TRENDY=time_TRENDY(day(time_TRENDY)==15);
H2OSOI=ncread(file_TRENDY,'H2OSOI',[1 1 1 1789],[Inf Inf 5 Inf]); % top levs
DZSOI=ncread(file_TRENDY,'DZSOI',[1 1 1],[Inf Inf 5])*1000; % top levs
DZSOI=repmat(DZSOI,[1,1,1,252]);
H2OSOI_TRENDY=squeeze(sum(H2OSOI.*DZSOI,3,'omitnan')./sum(DZSOI,3,'omitnan'));
lon=ncread(file_TRENDY,'lon');
lat=ncread(file_TRENDY,'lat');

X=H2OSOI_ERA5(:,:,year(time_ERA5)>=1999 & year(time_ERA5)<=2019);
Y=H2OSOI_TRENDY(:,:,year(time_TRENDY)>=1999 & year(time_TRENDY)<=2019);

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
title('H2OSOI Correlation (TRENDY vs ERA5)')
print('/glade/work/sglanvil/CCR/E3SM_SMYLE/H2OSOI_TRENDY','-r300','-dpng');
