function [ khu_proj ] = khu_makeprojectionfile( outputfilename,injections,chn,freq,amp,gain )
%khu_makeprojectionfile creates properly formatted text file from list of
%injections and chn/freq/amp/gain. Assumes single injection pair, all at
%the same frequency and amplitude (at the moment)
%   Inputs required are:
%   Outputfilename - the path of the desired projection text file
%   injections - N x 2 Matrix. Col 1 is source Col 2 is sink. N is the number of injection pairs.
%   chn - the number of channels either 16 or 32
%   freq - the frequency of injection as string e.g. '100kHz'
%   amp - amplitude of injection - digital value e.g. 360 from 1-1024
%   gain - gain(1) is gain for measurement channels, gain (2) is gain for
%   injection channels OR gain_vec for each individual channel
%
%   Output structure:
%   proj.gain = gains across ALL measurements as vector
%   proj.cell_master = is backup of what was written to textfile

%% header stuff and data conversion
%headers for each projection
header={'%','Ch','Amp','Freq','Gain'};

%check channel number
chn_legit=[16 32];
if ismember(chn,chn_legit) == 0
    error(['Number of Channels not legit please pick one of the following: ' num2str(chn_legit)])
end

%check amplitude
if (amp > 0 && amp <= 1024) == 0
    error('Incorrect amplitude setting, must be between 1 and 1024')
end

%check frequency
freq_legit=['MIXED1','MIXED2','MIXED3','10Hz','50Hz','100Hz','1kHz','5kHz','10kHz','50kHz','100kHz','250kHz','450kHz'];
if ismember(freq,freq_legit) == 0
    error(['Frequency legit please pick one of the following: ' num2str(freq_legit)])
end


%create input parser for 8bit integer
p_i=inputParser;
addRequired(p_i,'thing',@checkint);


%parse gains
parse(p_i,gain);






inj_N=size(injections,1); %number of injections

Amplitude=[num2str(amp) 'uA'];%amplitude setting string from input amp

%sort out gain vector - if gain is only 2 values then make the vector
if length(gain) ==2
%populate gain vector with measurement values
gain_vec=repmat(gain(1),inj_N*chn,1);
gain_flag=1;
elseif length(gain) == (inj_N*chn)
    %otherwise take full vector of gains
    gain_vec=gain;
    gain_flag=0;
else
    error('Gain vector not correct size');
end


%% Cell array initialisation
%make cell array for storing strings
proj_cell=cell(chn,4);
%fill it with the default strings for channel number and gain and injection
proj_cell(:,1)=cellfun(@num2str,num2cell(1:chn),'uniformoutput',0); %make the list of channels in the first column
proj_cell(:,2)=cellstr(repmat('Null',chn,1)); %set all of the channels to 'Null' by default for amplitude
proj_cell(:,3)=proj_cell(:,2); %nulls for frequency (copy and pasted because i dont know how repmat/cellstr work)
proj_cell(:,4)=cellstr(repmat(['x' num2str(gain(1))],chn,1)); %set all of the gains to the default value


%master cell array for all injections
proj_master=repmat(proj_cell,[1 1 inj_N]);


%%
%open file
fid=fopen(outputfilename,'w+');

%loop through each injection and update the cell array and write to file
for proj_counter=1:inj_N
    
    %make temp copy of the default array
    proj_cell_temp=proj_cell;
    
    %add the frequency in the freq column for the current injection
    proj_cell_temp(injections(proj_counter,:),3)=cellstr(repmat(freq,2,1));
    
    %add the amplitude in the amplitude column
    proj_cell_temp{injections(proj_counter,1),2}=Amplitude; %source
    proj_cell_temp{injections(proj_counter,2),2}=['-' Amplitude]; %sink
    
    %add the appropriate gain
    
    %index in gain_vec for this projection
    start_idx =(proj_counter-1)*chn; 
    
    if gain_flag == 1
    
        %change the gain on the injection channels
        proj_cell_temp(injections(proj_counter,:),4)=cellstr(repmat(['x' num2str(gain(2))],2,1));
        
        %update gain_vec
        gain_vec(injections(proj_counter,:)+start_idx)=gain(2);
    else
        %stick the values in for all channels
        
        for jjj=1:chn
                
        proj_cell_temp{jjj,4}=['x' num2str(gain_vec(start_idx+jjj))];
        end
        
    end
    
    
    
    
    
    %save the new one in to the master cell array
    proj_master(:,:,proj_counter)=proj_cell_temp;
    
    
    %write the thing to the text file
    
    fprintf(fid,'%s\r\n',['projection' num2str(proj_counter)]); % write projection number
    fprintf(fid,'%s\t%s\t%s\t%s\t%s\r\n',header{:}); % write header
    
    %loop through proj_cell and write each line to fine
    for iii=1:chn
        fprintf(fid,'\t%s\t%s\t%s\t%s\r\n',proj_cell_temp{iii,:});
    end
    
    %write "end"
    
    fprintf(fid,'%s\r\n','end');
    
    

end
fclose(fid);

khu_proj.gain = gain_vec;
khu_proj.cell_master=proj_master;

end

function TF = checkint(x)
   TF = false;

   if ~isnumeric(x)
       error('Input is not numeric');
   elseif (x < 0)
       error('Input must be >= 0');
          elseif (x > 255)
       error('Input must be < 255');
   else
       TF = true;
   end
end
