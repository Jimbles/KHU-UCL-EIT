function [ amp_setting, currentlevel,amp_actual ] = khu_amp_uA2setting( amp_desired )
%khu_amp_uA2setting finds the settings to give the nearest value possible
%to the desired amplitude. Lowest current level value chosen for maximal
%SNR from DAC
%   inputs:
%   amp_desired - desired peak to peak amplitude in uA
%   outputs:
%   amp_setting - the setting for closest possible amplitude for proj. file
%   currentlevet - the current level setting for this amp for script file
%   amp_actual - the actual amplitude for these settings

%% check inputs
if amp_desired > 1282
    error('current desired is too large. max is 1282 uA');
elseif amp_desired < 0
    error('current must be above 0');
end

%% calculate the current from the DAC
I_dac=(amp_desired/(413))/0.098;

%% find the current level and amp setting

currentlevel=-1;
amp_setting=0;
while amp_setting <2 
    currentlevel=currentlevel+1;
I_max=31.66/(2^currentlevel);
I_min=8.66/(2^currentlevel);

% find amp setting
amp_setting=1024*((I_dac-I_min)/(I_max-I_min));
end

%round amplitude_setting to integer
amp_setting=floor(amp_setting);

%find actual amplitude
amp_actual=khu_amp_setting2uA(amp_setting,currentlevel);




end

