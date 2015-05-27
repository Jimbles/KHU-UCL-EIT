function [KHUPROJ]=khu_projection_time(freq,ave)
%calculates the time for each projection and finds the correct byte values
%for a given frequency and average to put in the script file. This
%implements the logic given by the word document Bishal sent me found in
%technical folder on eit-nas

%clock cycles for injection
    tproj=60+((3+ave+1)/(freq))*45e6;
    
    %check if integer
    if (abs(round(tproj)-tproj)) >= eps('double')
    error('not an integer')

    end
    
    %convert to binary
    a=dec2bin(tproj,32);
    %set first byte to be 1s
    a(end-7:end)='1';
    %$output variables
    KHUPROJ.clockcycles=bin2dec(a);
    KHUPROJ.s=bin2dec(a)/45e6;
    KHUPROJ.high=bin2dec(a(1:8));
    KHUPROJ.mid=bin2dec(a(9:16));
    KHUPROJ.low=bin2dec(a(17:24));
end
