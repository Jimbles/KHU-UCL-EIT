function [ khu_settings ] = khu_makepairwise( outputfilename, injection_pairs,freq,amp,gain,chn,ave,cal, varargin)
%khu_makepairwise makes script and projection files for pair wise injection
%for KHU 16 or 32 channel systems. User gives certain inputs and the the
%projection and script files are written and a structure saved with the
%info.
%inputs(defaults) are:
%outputfilename('unnamed') - the name of the protocol. _proj.txt and _script.txt will %be appended to files.
%injection_pairs('neighbouring') - 'neighbouring','polar','spiral','eeg' automagically generates pairs. Otherwise Nx2 array. col 1 is source col 2 is sink N is number of injections. either array
%freq('10kHz') - string for injection frequency in projection file, e.g. '10kHz' or 'MIXED2'. can be abreviated as '10k' 'm2'
%amp(400) - either [uA] desired peak to peak amplitude in uA. or [CL, AMP] current level and amplitude settings
%found.
%gain([10,1]) - either 2x1 vector where gain(1) is gain for measurement
%channels, gain (2) is gain for injection channels OR gain_vec for each individual channel
%chn(32) - number of channels, either 16 or 32
%ave(64) - number of averages - must be either 1 or power of 2 up to 2^6 =64
%cal('ON','ON','ON','OFF','2DNeighbouring_mV.txt') - structure with 'ON' or 'OFF' strings and protocol file: cal.dc cal.outputz cal.amp cal.voltmeter cal.voltmeter_prot
% varargin either:
% comment string - this is the comment added to the script file
% override structure - if input is strucutre then settings autocalculated
% for the script file (timeinfohigh etc.) or defaults like INJdelay can be
% overwritten. i.e. to change the timeinfohigh setting call function with
% varargin.TimeInfoHigh
%
%outputs are:
%khu_settings.proj - outputs from khu_makeprojectionfile
%khu_settings.script - outputs from khu_makescriptfile
%khu_settings.time - time and date script was made
%khu_settings.gain_act - vectr of actual gains actual
%khu_settings.gain_dig - vactor of digital gain values
%
% script and proj file also written to .txt - ASSUMES SCRIPT AND PROJ FILE
% IN SAME DIRECTORY
%
%
% Written in hurry by the considerate yet trenchant Jimmy 2014
%% set some default values

if isempty(chn) ==1;
    chn =32;
    disp('no chns stated, using 32');
end

if isempty(gain) ==1;
    gain =[10,1];
    disp('no gains specified, using x10 (meas) and x1 (inj)');
end

if isempty(freq) ==1;
    freq ='10kHz';
    disp('no freq specified, ising 10 kHz');
end

if isempty(amp) ==1;
    amp =400;
    disp('no Amplitude specified, using setting of 400');
end

if isempty(ave) ==1;
    ave =64;
    disp('no average specified, using 64');
end

if isempty(injection_pairs) ==1;
    injection_pairs =makeneighbouring(chn); %neighbouring protocol if none specified
    disp('no protocol specified, using neighbouring');
end

if isempty(cal) ==1;
    cal.dc ='ON';
    cal.outputz='ON';
    cal.amp ='ON';
    cal.voltmeter='OFF';
    cal.voltmeter_prot='2DNeighbouring_mV.txt';
    disp('no calibration specified, using ON ON ON OFF');
end

if isempty(outputfilename) ==1;
    outputfilename='Unnamed';
    disp('default file name used');
end


if isempty(varargin) ==1;
    comment='No Comment';
else
    %add comment if varagin is string
    if ischar(varargin{1,1})
        comment=varargin;
    elseif isstruct(varargin{1,1}) %otherwise it is a structure for the overide function
        override=varargin{1,1};
        comment='No Comment';
    end
end

%% check and parse inputs

%check channel number
chn_legit=[16 32];
if ismember(chn,chn_legit) == 0
    error(['Number of Channels not legit please pick one of the following: ' num2str(chn_legit)])
end

% make fuzzy input 'n' 'p' 'eeg31' 'sprial16' etc.
if ischar(injection_pairs) ==1
    injection_pairs=get_protocol(injection_pairs,chn);
end

%check injection pair array
if size(injection_pairs,2) ~= 2
    error('Incorrect injection pair format, must be 2 columns');
end

%check amplitude - UPDATE THIS TO CHECK SETTINGS ALSO

if amp > 1282
    error('current desired is too large. max is 1282 uA');
elseif amp < 0
    error('current must be above 0');
end

%check number of averages
ave_legit=2.^(0:6);
if ismember(ave,ave_legit) == 0
    error(['Number of Averages not legit please pick one of the following: ' num2str(ave_legit)])
end


%check frequency
freq_legit={'MIXED1','MIXED2','MIXED3','10Hz','50Hz','100Hz','1kHz','5kHz','10kHz','50kHz','100kHz','250kHz','450kHz'};
if ismember(freq,freq_legit) == 0
    freq=freq_abr(freq);
    if ismember(freq,freq_legit) ==0;
        error(['Frequency legit please pick one of the following: ' num2str(freq_legit)])
    end
end






%% calculate settings for script file

%get amplitude settings

if size(amp,2) ==1
    %if only one number then take this as desried uA setting
    
    [amp_setting, current_level, amp_actual]=khu_amp_uA2setting(amp);
    fprintf('User requested %d uA, actual value is %f uA\n',amp,amp_actual);
    
else
    %if two numbers use this as desired settings - useful if used existing
    %protocol etc. and want to generate the protocol file
    current_level=amp(1);
    amp_setting=amp(2);
    amp_actual=khu_amp_setting2uA(amp_setting,current_level);
    fprintf('User specified settings of CL:%d, AMP:%d. Actual current %fuA\n',current_level,amp_setting,amp_actual);
    
end


setting.CurrentLevel=current_level;
setting.amp_setting=amp_setting;
setting.amp_actual=amp_actual;

%get frequency setting
if ismember(freq,freq_legit(1:3)) == 1 % if its a mixed
    setting.freq=3; %then set to 3
else
    setting.freq=1; %else set to 1
end


%========USE SAFE TIMING VALUES========%
% timing values may have been causing shit data so use the safe but slower
% values

%get timing settings for as fast as possible
% timingsettings=khu_projection_time(freq_hz(freq),ave);

disp('USING SAFE BUT SLOW TIMING SETTINGS!!!!');
disp('NEW FOR AUGUST 2014!!!!');
timingsettings=safetime(freq,ave);



setting.TimeInfoHigh=timingsettings.high;
setting.TimeInfoMid=timingsettings.mid;
setting.TimeInfoLow=timingsettings.low;

%set channel
setting.chn=chn;
%set amplitude
setting.ave=ave;
setting.frequency=freq;

%set things that arent expected to change!
setting.InjDelayHigh=0;
setting.InjDelayLow=60;
setting.delay=5;

%projection
proj.list=1:size(injection_pairs,1);
proj.file=[outputfilename '_proj.txt'];


%% overide settings
%settings can be manually overwritten by including them in a structure
if exist('override','var') ==1
    setting=override_settings(setting,override);
end

%% make files

%add file info to comment string
comment=[comment '||Script= ' outputfilename 'Freq=' freq 'Amp =' num2str(amp_actual) 'uA||'];

%make projection file
khu_settings.proj=khu_makeprojectionfile([outputfilename '_proj.txt'],injection_pairs,chn,freq,amp_setting,gain);
%make script file
khu_settings.script=khu_makescriptfile([outputfilename '_script.txt'],proj,setting,cal,comment);

%% save outputs and make a few more

%make prt file
khu_settings.prt=makeprtfile(injection_pairs,chn);
%get time and date
khu_settings.time=datestr(clock);

%save gain vector as digital and actual
khu_settings.gain_act=khu_gain_dig2act(khu_settings.proj.gain); %actual
khu_settings.gain_dig=khu_settings.proj.gain;
khu_settings.fname_proj=[outputfilename '_proj.txt'];
khu_settings.fname_script=[outputfilename '_script.txt'];

%save current too!
khu_settings.current=amp_actual;
%save frequ aswell!
khu_settings.frequency=freq;

%save file - point to this one in IMPORT_KHU or whatever the gain adjust
%script is called
save(['KHU_script_info_' outputfilename],'khu_settings');
%write prt file
dlmwrite([outputfilename '.prt'],khu_settings.prt,'delimiter','\t','newline','pc');



end

function safetimesettings=safetime(freqin,ave)
%get the safe timing values for the projection times. Basically calculated
%is fine up intil 50 upwards. Above this use the "safe" values. for the
%mixed injections use the lowest frequency for the calc.
switch freqin
    case {'10Hz','50Hz','100Hz','1kHz','5kHz','10kHz'} %calc for low frew
        safetimesettings=khu_projection_time(freq_hz(freqin),ave);
    case {'50kHz','100kHz','250kHz','450kHz'} % "safe" defaults for high
        safetimesettings.high=0;
        safetimesettings.mid=7;
        safetimesettings.low=0;
    case 'MIXED1';
        safetimesettings=khu_projection_time(freq_hz(11.25),ave);
    case 'MIXED2';
        safetimesettings=khu_projection_time(freq_hz(1125),ave);
    case 'MIXED3';
        safetimesettings.high=0;
        safetimesettings.mid=7;
        safetimesettings.low=0; 
end
end



function prt_mat=makeprtfile(inj_pairs,chn)
%make complete prt in format C_source C_sink V+ V-


%voltage measurements
vp=(1:chn)';
vm=circshift(vp,1);

prt_mat=[];
for iii=1:size(inj_pairs,1)
    temp=[repmat(inj_pairs(iii,:),chn,1) vp vm];
    
    prt_mat=[prt_mat ; temp];
end

end


function inj_pairs=makeneighbouring(chn)

%make neighbouring injections 1 2; 2 3 etc.

sources=(1:chn)';
sinks=circshift(sources,1);
inj_pairs=[sources sinks];

end

function inj_pairs=makepolar(chn)

%make polar injections 1 16;2 17 etc. for 32chn

sources=(1:chn/2)';
sinks=sources+chn/2;
inj_pairs=[sources sinks];

end

function inj_pairs=makeeeg

%hardcoded "eeg31" measurment protocol
inj_pairs=[
    1    30;
    2    29;
    7    23;
    17    13;
    27     3;
    6    23;
    11    13;
    22     3;
    26     1;
    24     2;
    19    17;
    8    27;
    4    30;
    5    24;
    10    19;
    16     8;
    21     4;
    25     6;
    20    11;
    14    22;
    9    26;
    ];
end

function inj_pairs=makespiral
%hardcoded spiral_16

inj_pairs= [
    1     6;
    1    11;
    1    13;
    1    14;
    2     7;
    2    11;
    2    14;
    2    15;
    3     8;
    3    11;
    3    16;
    4     9;
    4    12;
    4    13;
    4    16;
    5    10;
    5    13;
    5    16;
    6    11;
    6    13;
    6    14;
    7    11;
    7    13;
    7    14;
    7    15;
    8    12;
    8    15;
    9    12;
    9    15;
    9    16;
    10    11;
    10    12;
    11    14;
    12    16;
    ];
end

function freqout=freq_abr(freqin)
switch freqin
    case '10'
        freqout='10Hz';
    case '50'
        freqout='50Hz';
    case '100'
        freqout='100Hz';
    case '1k'
        freqout='1kHz';
    case '5k'
        freqout='5kHz';
    case '10k'
        freqout='10kHz';
    case '50k'
        freqout='50kHz';
    case '100k'
        freqout='100kHz';
    case '250k'
        freqout='250kHz';
    case '500k'
        freqout='450kHz';
    case 'm1'
        frequout='MIXED1';
    case 'm2'
        frequout='MIXED2';
    case 'm3'
        frequout='MIXED3';
    otherwise
        freqout='nope';
end

end

function freqhz=freq_hz(freqin)
%convert string of frequencies into number Hz for projection time func
switch freqin
    case '10Hz';
        freqhz=11.25;
    case '50Hz';
        freqhz=56.25;
    case '100Hz';
        freqhz=112.5;
    case '1kHz';
        freqhz=1125;
    case '5kHz';
        freqhz=5625;
    case '10kHz';
        freqhz=11250;
    case '50kHz';
        freqhz=56250;
    case '100kHz';
        freqhz=112500;
    case '250kHz';
        freqhz=247500;
    case '450kHz';
        freqhz=450000;
    case 'MIXED1';
        freqhz=11.25;
    case 'MIXED2';
        freqhz=1125;
    case 'MIXED3';
        freqhz=112500;
end
end

function inj=get_protocol(injtxt,chn)
%lazy mans way of converting text input for protocol into injection table
switch injtxt
    case 'n'
        inj=makeneighbouring(chn);
    case 'neighbour'
        inj=makeneighbouring(chn);
    case 'neighbouring'
        inj=makeneighbouring(chn);
    case 'p'
        inj=makepolar(chn);
    case 'pol'
        inj=makepolar(chn);
    case 'polar'
        inj=makepolar(chn);
    case 'e'
        inj=makeeeg;
    case 'eeg'
        inj=makeeeg;
    case 'eeg31'
        inj=makeeeg;
    case 'spiral'
        inj=makespiral;
    case 's'
        inj=makespiral;
    case 'spiral16'
        inj=makespiral;
end
end

function outstr=override_settings(instr,overstr)
%function to find the fields in the override structure and replace the
%outgoing structure with them 

%this bit is basically pointless...

%possible options for the override structre (could have just used
%"fieldnames probably)
C={'CurrentLevel','freq','TimeInfoHigh','TimeInfoMid','TimeInfoLow', 'chn','ave','InjDelayHigh','InjDelayLow','delay'};

%find which fields are in the override struct
over_idx=find(isfield(overstr,C) ==1);

%number of overrides
overN=length(fieldnames(overstr));

disp('--------------------------------');
disp('overriding settings - here be dragons');
disp('--------------------------------');

%should be the same length
if length(over_idx) ~= length(overN)
    warning('There are incorrect fieldnames in the override structure')
end

%carry over input struct
outstr=instr;

%loop through displaying which thigns have been changed. yes this could be
%a vector manipulation

if isempty(over_idx)
    disp(['No overides understood. Did you type them ok? Legit inputs are: ' C]);
end

for iii=over_idx
    outstr.(C{iii})=overstr.(C{iii});
    disp([C{iii} ' was overwritten. Was ' num2str(instr.(C{iii})) ' now ' num2str(outstr.(C{iii}))]);
    
end


disp('--------------------------------');

end

