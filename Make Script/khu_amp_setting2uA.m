function [ amplitude_pp ] = khu_amp_setting2uA( ampsetting,currentlevel )
%khu_amp_setting2uA converts the settings in projection file and current
%level into uA peak to peak
%   amp setting - value 0 to 1024 in projection file
%   current level - value in script file, incease of 1 means 1 bit removed
%   from DAC and thus half current ampltiude

%% check variables

if exist('currentlevel','var') ==0;
    disp('Using current level 0');
    currentlevel=0;
end

    

%check amplitude
if (ampsetting > 0 && ampsetting <= 1024) == 0
    error('Incorrect amplitude setting, must be between 1 and 1024')
end

if (currentlevel >= 0 && currentlevel < 16) == 0
    error('Incorrect current level setting, must be between 0 and 16');
end

%% calculate range of values
% current from DAC
I_max=31.66/(2^currentlevel);
I_min=8.66/(2^currentlevel);
I_dac=(I_max-I_min)/(1024)*ampsetting+I_min;

%voltage before HCP
V_dac=I_dac*0.0980;

%current from HCP
amplitude_pp=413.33*V_dac;


end

