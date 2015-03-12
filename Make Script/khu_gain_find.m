function [ gain_vec_new_d, gain_vec_new_a , Vnew] = khu_gain_find( khu_data, gain_setting ,varargin)
%khu_gain_find Approximates optimal gain settings based on previous data
%and gain settings. data is from IMPORT_KHU and gain_vec is from
%khu_makepairwise or khu_makeprojectionfile
%   given the gain settings for a set of data, approximates the new setting
%   which would give a voltage ~85% of the dynamic range. Outputs new
%   vector for use with khu_makepairwise or khu_makeprojectionfile
% inputs:
% khu_data - STRUCT FROM IMPORT KHU. Z (digital values) and Sat , preferably recorded on the
% object used for subsequent experiments. 
% gain_vec_old - vector of gain settings used to collect the above data.
% this is generated either by khu_makeprojectionfile (proj.gain) or
% khu_makepairwise (khu_settings.gain_dig) OR STRUCT FROM MAKEPAIRWISE
% varargin - if this exisits plot graphs of wh
%outputs;
%gain_vec_new_d - gain settings which give closest possible value to actual
%desired gain
%gain_vec_new_a - the actual gain these settings give
% Vnew - guess at new values 
%% constants
Vmax=2^15; %range of ADC
Vtarg=0.75*Vmax; %target voltage. chosen to be 85% of max to give some headroom


%% process input data

%if inputs are structs then find the correct field
 if isstruct(khu_data) ==1
     Z=khu_data.raw.Z; %take the raw Z values from output of IMPORT_KHU.m
     sat=khu_data.raw.Sat; %take the saturated channels too
 else
    error('khu_data not structure');
 end
 
 %if inputs are structs then find the correct field
 if isstruct(gain_setting) ==1
     gain_old=gain_setting.gain_dig; %take the gain setting vector from output of khu_makepairwise.m
 else
     gain_old=gain_setting; %otherwise input is vector 
 end
 
 %if extra input plot approx new values
 if isempty(varargin{1,1}) == 0
     plot_flag=1;
 else
     plot_flag=0;
 end
 
 
 
% average input Z and take absolute only
Zave=mean(abs(Z),2);

% get real boundary voltages
Vold=Zave./khu_gain_dig2act(gain_old);

%find desired actual gains
gain_desired_a=Vtarg./Vold;

%to avoid confusion. find the saturated channels and set their desired
%gains to 0;

gain_desired_a(mean(sat,2) ~= 0) =0;


%find closest gain settings and the resulant actual gain
[gain_vec_new_d ,gain_vec_new_a]=khu_gain_act2dig(gain_desired_a);

Vnew=Vold.*gain_vec_new_a;




%% plot data is necessary

if plot_flag ==1
    
    %make vector of only saturated channels
    Zsat=nan(size(Zave));
    Zsat(mean(sat,2) ~= 0)=Zave(mean(sat,2) ~= 0);
    
    figure
    hold on
    plot(Zave,'b-')
    plot(Vnew,'r-')
    plot(Zsat,'b^')
    line([1 length(Zave)],[Vtarg Vtarg],'linestyle','--','color','k')
    hold off
    title('Estimated new measured voltages with new gains - saturated channels are probs way off')
    xlabel('Channel')
    ylabel('Digital Value')
    
    legend('Original meas V','Est. new meas V','saturated channels')
    
end


    



end

