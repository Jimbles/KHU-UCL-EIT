function [ gain_digital,gain_actual ] = khu_gain_act2dig( gain_desired )
%khu_gain_act2dig calculates closest gain setting to desired actual gain,
%and gives the resultant actual gain for that value
%   gain_desired - actual gain desired
%   gain_digital - the digital gain which gives the value closest to desired
%   gain_actual - the actual gain for the closest setting possible (rounded
%   down)

gain_digital=floor(gain_desired*(200/40));

% keep value in range
gain_digital(gain_digital < 1) =1;
gain_digital(gain_digital > 255 ) =255;

gain_actual=khu_gain_dig2act(gain_digital);


end

