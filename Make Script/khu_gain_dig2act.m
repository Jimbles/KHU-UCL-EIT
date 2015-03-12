function [ gain_actual ] = khu_gain_dig2act( gain_digital )
%khu_gain_dig2act converts digital value gain setting in projection files
%to the actual gain. Assumes range is 1-255;
%   

% keep value in range
gain_digital(gain_digital < 1) =1;
gain_digital(gain_digital > 255 ) =255;


gain_actual=gain_digital*(40/200);


end

