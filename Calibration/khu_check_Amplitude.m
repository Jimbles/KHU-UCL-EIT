function [ Amplitude_data ] = khu_check_Amplitude( varargin )
%CHECK_Amplitude check Amplitude for all channels and all frequencies by
%default
%CHANGE MATLAB FOLDER TO BE ROOT OF CALIBRATION e.g. Calibration\eit2
%   input can be for single frequency only in the format:
%   '10','50','100','1k','5k','10k','50k','100k','500k'
%or vector of numbers from 1:9 corresponding to each frequency 1 is 10Hz
%and 9 is 500kHz

% look for folders to check if we are in the right place

dirlist=dir;
foldernames={dirlist.name};

if isempty(find(strcmp('Amplitude',foldernames),1)) == 1
    disp('Couldnt Find OutputImpedance folder, Please point me in the right direction');
    newfolder=uigetdir('','Please point me to the ROOT calibration folder which has DCOffset/Amplitude/Outputimpedance/Voltmeter folders');
    cd(newfolder);
end



thresholdvalue=0.1; %value which constitutes a bad channel
thresholdrange=0.1; %max variation between channels before warning

%strings corresponding to the folder names for each frequency in cell array
foldernames{1}='11.25Hz';
foldernames{2}='56.25Hz';
foldernames{3}='112.5Hz';
foldernames{4}='1.125kHz';
foldernames{5}='5.625kHz';
foldernames{6}='11.25kHz';
foldernames{7}='56.25kHz';
foldernames{8}='112.5kHz';
foldernames{9}='247.5kHz';
foldernames{10}='450kHz';

%textfilename
fname='Amplitude.txt';
rootname='Amplitude';


%is no inputs
if isempty(varargin) == 1
    freqsv=1:10; %use all frequencies if none specified
elseif isnumeric(varargin{1,1})==1 %if the argument is a number then use that one
    temp=varargin{1,1};
    freqsv=temp(temp<11); %only use values in range!
    if length(temp) ~= length(freqsv)
        warning('too high value used in input - only taking those in range');
    end
else %if not number then string entry for specific value
    switch varargin{1,1}
        case '10'
            freqsv=1;
        case '50'
            freqsv=2;
        case '100'
            freqsv=3;
        case '1k'
            freqsv=4;
        case '5k'
            freqsv=5;
        case '10k'
            freqsv=6;
        case '50k'
            freqsv=7;
        case '100k'
            freqsv=8;
        case '250k'
            freqsv=9;
        case '500k'
            freqsv=10;
        otherwise
            warning('unknown input - using them all instead!');
            freqsv=1:10;
    end
    
end

%make cell array first of all the data - to cope with 16 and 32 channel
%data in there

Ampdata=cell(size(freqsv));
Chn=nan(size(freqsv));


%load data from all the folders and keep in cell array
freq_counter=0;
for f=freqsv %loop through every freq selected
    freq_counter=freq_counter+1; %
    filepath=[rootname '\' foldernames{f} '\' fname]; % load the DCOffset.txt files
    Ampdata{freq_counter}=dlmread(filepath);
    Chn(freq_counter)=length(Ampdata{freq_counter}); %find number of channels
end

Chn_uni=unique(Chn);
if length(Chn_uni) ~= 1
    prompt='Which of the data sets do you want to use? 16/32/(b)oth [b]: ';
    disp('Mixed number of channels detected! You probably copied a folder from a different system')
    str=input(prompt,'s');
    if isempty(str)
        str='b';
    end
    
    if str == 'b'
        Chn_use=1:length(freqsv);
        Chn_select=max(Chn_uni);
    else
        Chn_select=str2num(str);
        
        if  Chn_select==16||Chn_select ==32
            
            Chn_use=freqsv(Chn == Chn_select);
        else
            disp('Number of channels entered doesnt make sense, I"m just gonna use all of them');
            Chn_use=1:length(freqsv);
            Chn_select=max(Chn_uni);
        end
    end
    
else
    Chn_select=max(Chn_uni);
    Chn_use=1:length(freqsv);
    
end

%stick all of the Amplitude data in a matrix for easier calling
cal_data=nan(Chn_select,length(Chn_use));
%save the number of bad channels
bad_chns=nan(Chn_select,length(Chn_use));

chn_cnt=0;
for N=Chn_use
    chn_cnt=chn_cnt+1;
    %find the channels that are less than the rough 25 setting which means
    %they are ok
    temp_cal=Ampdata{N}; %get DC calibration data
    cal_data(1:length(temp_cal),chn_cnt)=temp_cal; %store in big matrix
    bad_idx=find(abs(1-temp_cal) > thresholdvalue); %these are bad channels
    
    bad_chns(1:length(bad_idx),chn_cnt)=bad_idx;
    
    %for plotting bad channels a different colour
    good_chn=temp_cal;
    good_chn(bad_idx)=NaN;  %set bad channels to NaN
    bad_chn=nan(size(good_chn));
    bad_chn(bad_idx)=temp_cal(bad_idx);
    
    figure
    hold on
    
    %ylim fixed as values must be close to 1
    ymins=0.75;
    ymax=1.25;
    
    xlim([0 length(temp_cal)+1])
    ylim([ ymins; ymax])
    
    for ii=ymins:0.01:ymax
        line([0 length(temp_cal)+1],[ii ii],'color','k','linestyle',':')
    end
    
    
    
    
    set(gca,'XTick',1:length(temp_cal))
    
    bar(good_chn,'b')
    
    if isempty(bad_idx) ==0;
        bar(bad_chn,'r')
    end
    
    %guide lines for threshold value - centred around 1
    line([0  length(temp_cal)+1],[1+thresholdvalue 1+thresholdvalue],'color','r','linestyle','-','linewidth',4)
    line([0  length(temp_cal)+1],[1-thresholdvalue 1-thresholdvalue],'color','r','linestyle','-','linewidth',4)
    line([0  length(temp_cal)+1],[1 1],'color','k','linestyle','-','linewidth',2)
    
    text(1,1+thresholdvalue+.02,'FUZZY LOGIC LINE OF BADNESS','BackgroundColor',[1 1 1],'color','r')
    text(1,1-thresholdvalue-.02,'FUZZY LOGIC LINE OF BADNESS','BackgroundColor',[1 1 1],'color','r')
    text(Chn_select-16,1+0.02,'FUZZY LOGIC LINE OF GOODNESS','BackgroundColor',[1 1 1],'color',[0 0.5 0])
    
    title(['Amplitude Calibration data for ' foldernames{freqsv(N)}]);
    xlabel('Channel Number')
    ylabel('Amplitude calibration value')
    hold off
    
    %display message about the data
    if isempty(bad_idx) ==1;
        %hooray if not bad channels
        disp(['There were no bad channels for frequency ' foldernames{freqsv(N)} ' HOORAY! :)']);
        title(['Amplitude Calibration data for ' foldernames{freqsv(N)} ' \color[rgb]{0 0.5 0}EVERYTHING IS FINE! :)'],'FontWeight','bold');
    else
        badchnstr='';
        %make string out of bad channels
        for jjj=1:length(bad_idx);
            if jjj==1
                badchnstr=[num2str(bad_idx(jjj))];
            else
                badchnstr=[badchnstr ', ' num2str(bad_idx(jjj))];
            end
        end
        %moan about it
        disp(['BOO bad channels for for frequency ' foldernames{freqsv(N)} ': ' badchnstr]);
        title(['Amplitude Calibration data for ' foldernames{freqsv(N)} ' \color{red}Bad Channels: ' badchnstr ],'FontWeight','bold');
    end
    
    %range of values IGNORING BAD CHANNELS AND ONLY IF THERE ARENT ALL BAD
    
    if length(bad_idx) < Chn_select
        
        cal_rng=range(good_chn);
        
        if cal_rng < thresholdrange && isnan(cal_rng) == 0
            disp(['Range of values (excluding bad channels) of : ' num2str(cal_rng) ' is OK! GET IN! :)']);
        else
            disp(['WARNING! Range (excluding bad channels) of : ' num2str(cal_rng) ' is above threshold']);
        end
        
    end
    
end
%     figure;


Amplitude_data.cal_data=cal_data; %%%change this WOOOOPPPPP
Amplitude_data.bad_chns=bad_chns;



end

