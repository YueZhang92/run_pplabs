%adapted from readTobiiJson_word2.m
%reading .csv files from pupilLabs for SSD project
%20191212 Yue ZHANG
%how to use:
%1. add the .m file to the matlab path; either by running
%addpath([path_to_the_.mfile]) in the command line or click set path under
%home button and select the location of the .m file to add it into Matlab
%path
%2. move into the folder with the .csv files, and run
% readpupil('pupil_positions.csv','annotations.csv',200)



function  [excTrials] = readpupil(dataFile, annotateFile, SampFreq)

%% MACROS
delimiter = '\n';
if nargin<=2
    startRow = 1;
    endRow = inf;
end
%all the MSG information used
Events = {'baseline','listen','waitpeak','response'};
%the criteria for trial exclusion due to blinking
excRule = 0.2 ; % more than 20% of the blinks happened in one trial is excluded; more than 20% of the trace being abnormal are excluded
%SampFreq as defined by the inputs
valBlink = 0.4; %defining abnormal data over 0.4s invalid: (Bristow et al., 2005) pupil being fully occluded by the eyelid for 100-150ms

%% 1. read and combine two files
pupilData = readtable(dataFile); 
msgData = readtable(annotateFile,'Delimiter',',');

% prepare two files, one for data, one for event info
nLines = size(pupilData,1); %a very rough guess of how many lines... to be trimmed later
% the raw data has six columns: timestamp, pupil size left, pupil size right, validity code, gaze position
%first column is timestamp, second is the event type, third is SNR summary, fourth is correct
% put construct rawData from dataFile
%migrating essential info from pupil
rawData.world_timestamp = pupilData.pupil_timestamp;
rawData.pd = pupilData.diameter;
rawData.eye_id = pupilData.eye_id;
rawData.event = repmat({'undefined'},nLines,1);
%rawData.correct = repmat({'0'},nLines,1);
rawData.SNR = repmat({'0'},nLines,1);
rawData.mode = repmat({'undefined'},nLines,1);
%rawData.block = repmat({'0'},nLines,1);
rawData.listNumber= repmat({'0'},nLines,1);
rawData.trialCount = repmat({'0'},nLines,1);


% getting the basic information from the annotation
    genInfo = strsplit(msgData.label{2},'_'); %read in the first line
    Listener = genInfo{1};
    SNR = genInfo{3};
    mode = genInfo{4};
    ListNumber = genInfo{7};
    
    rawData.listener = repmat({Listener},nLines,1);
    
% contructuing pupildata cells from rawData and rawMSG
%columns of: listener {1}, validity{2}, left pupil {3},  event {4}, trial {6},
%block position {7}, word list {8}, manipulate type {9}, SNR {10},
%trialcount {11}, recallornot{12}, gaze position{13}
trialCount = 1;
%going through each row of rawMSG to find events timestamp
for i = 1:size(msgData,1)
 if trialCount <= 20
    if strcmp(msgData.label{i}, 'baseline')
        %find tstamp corresponding to each event
        tStamp_baseline = msgData.timestamp(i);
        tStamp_listen = msgData.timestamp(i + 1);
        tStamp_waitpeak = msgData.timestamp(i + 2);
        tStamp_response = msgData.timestamp(i + 3);
        tStamp_stop = msgData.timestamp(i+4);
        %going back to rawData to find
        [num,baseline_ind]= min(abs(rawData.world_timestamp - tStamp_baseline));
        [num,listen_ind]= min(abs(rawData.world_timestamp - tStamp_listen));
        [num,waitpeak_ind]= min(abs(rawData.world_timestamp - tStamp_waitpeak));
        [num,response_ind]= min(abs(rawData.world_timestamp - tStamp_response));
        [num,stop_ind]= min(abs(rawData.world_timestamp - tStamp_stop));
        
        %fill in rawdata with other info for the selected section
        rawData.event(baseline_ind:listen_ind) = Events(1);
        rawData.event(listen_ind:waitpeak_ind) = Events(2);
        rawData.event(waitpeak_ind:response_ind) = Events(3);
        rawData.event(response_ind : stop_ind) = Events(4);
        
        rawData.SNR(baseline_ind:stop_ind) = {SNR} ;
        rawData.listNumber(baseline_ind:stop_ind)= {ListNumber};
        rawData.trialCount(baseline_ind:stop_ind) = {trialCount};
        rawData.mode(baseline_ind:stop_ind) = {mode};
        
        %jump to the next trial
        trialCount = trialCount + 1;
        i = i+4;
        
    end
    
 end
end
%tidy up rawData and rawMSG to exclude all empty ones;
real_ind = find ( ~strcmp(rawData.event, 'undefined'));%find all columns filled
rawData = IndexedStruct(rawData, real_ind);



        %------- organise folders ....
        %where to save figs
        otraceDir = fullfile('pupil_traces',[Listener '_' mode '_' SNR],'unprocessed');
        traceDir = fullfile('pupil_traces',[Listener '_' mode  '_' SNR],'processed');
        s = mkdir(traceDir);
        if s ~= 1
            fprintf('Cannot make trace output directory');
        end
        %setting the outpurdir of raw data plots
        s = mkdir(otraceDir);
        if s ~= 1
            fprintf('Cannot make trace output directory')
        end
        %where to save all results
        dataFile = [ Listener '_' mode  '_' SNR '_pupildata.csv'];
        %---------
        %visualising the original traces
        %getting an ID
        rawData.ID = strcat(string(rawData.listNumber), string(rawData.trialCount));
        trace_ID = unique(rawData.ID);
%         for i = 1:length(unique(trace_ID))
%             trace_l = rawData.pd(strcmp(rawData.ID, trace_ID(i)) & rawData.eye_id == 1); %selecting the trace for this trial
%             trace_r = rawData.pd(strcmp(rawData.ID, trace_ID(i)) & rawData.eye_id == 0 );
%             %--------
%             %visualisations of original traces
%             % In Matlab 2013a or later, when figure handles are not double anymore, do...
%             %     tracePlot = plot(linspace(0,length(trace)/SampFreq, length(trace)),trace); %creating the plot, with x axis from 0 to the end of
%             %     % of the trace in units of seconds, with the total number of data points in between.
%             %     hgsave(tracePlot,fullfile(otraceDir, [char(trialLevel(i)) '.fig'])); %saving the plot under the name of trial
%             
%             % Else in Matlab2013a or before, when figures are double, do...
%             f = figure;
%             %draw the left eye blue
%             plot(linspace(0,length(trace_l)/SampFreq, length(trace_l)),trace_l,'blue');
%             hold;
%             plot(linspace(0,length(trace_r)/SampFreq, length(trace_r)),trace_r,'red');
%             
%             
%             %draw out lines for timing
%             %          line([0.5, 0.5], ylim); %intertrial
%             %          line([1.5,1.5], ylim); %baseline
%             %! more to go!
%             %and then save
%             saveas(f, fullfile(otraceDir, char(trace_ID(i))), 'fig');
%             %
%             close;
%             %drawing the gaze distribution of the trial
%             
%         end
        




%% 2. pre-processing the data (deblinking, excluding trials/subject, smoothing)


%%  deblinking & low-pass filtering
%constructing low-pass filter,performing first order Butterworth 10Hz low-pass filter,
%backward and forward on all traces (Klingner et al., 2008)
[z,pEnv,k]=butter(1, 10/(SampFreq/2),'low');
[sosLo,gLo] = zp2sos(z,pEnv,k);	     % Convert to SOS form
hLo=dfilt.df2sos(sosLo,gLo);

%count blinks for both eyes and pick one with less abnormalities

%finding index of traces of full and partial blinks and wrong validity:
% 1) validity code is 0
% 2) pupil diamter is 0
% 3) pupil diamter is below or above 3sd from the mean of all recording
% 4) gaze position is 3sd away from the mean of all recording

% ffinding blinks for the left
pd_l = rawData.pd(rawData.eye_id == 1);
pointBlink_l = find( pd_l  == 0 | pd_l  < (mean(pd_l ) - 3*std(pd_l)) ...
    |pd_l > (mean(pd_l ) + 3*std(pd_l )));

if ~isempty(pointBlink_l) %if there are blinks inside the recording
    temp = pointBlink_l - (1:length(pointBlink_l))'; temp = [true; diff(temp(:)) ~=0; true];
    blockBlink = mat2cell(pointBlink_l(:).', 1, diff(find(temp))); %breaking the blinking index into cells containing each blink block
    %trialBlink_l(trialLevel(i)) = trialBlink_l(trialLevel(i)) + size(blockBlink,2) ; %recording number of blinks in each trial
    %totalBlink = totalBlink + 1; %recording total number of blinks for the individual
    j=1;
    
    %going through each block of blinks
    while j <= size(blockBlink,2)
        curBlink = blockBlink{j}; %selecting the current blink block
        %if length(curBlink) < valPoint %if it's a permittable data loss (less than 0.4s)
            %if there is a next blink block, and it's within 0.2s of
            %the end of the previous block, and it's a valid blink
            if j+1 <= size(blockBlink,2) && blockBlink{j+1}(1) - curBlink(length(curBlink)) < 0.2*SampFreq
                    %&& length(blockBlink{j+1}) < valPoint
                
                nexBlink = blockBlink{j+1}; %selecting the next blink
                sBlink = curBlink(1) - 0.1*SampFreq; eBlink = nexBlink(length(nexBlink)) + 0.1*SampFreq; %combining the two blinks to one interpolation block
                j = j+2; %continue to the next next blink
            else %if there is one blink, or the current blink is serpate from the next one, or the next blink is not valid
                sBlink = curBlink(1) - 0.1*SampFreq; eBlink = curBlink(length(curBlink)) + 0.1*SampFreq;
                j=j+1; %continue to the next blink
            end
            
            
            %when the blink occurs near the beginning or end of the
            %trace, extrapolate linearly;
            %otherwise, interpolate cubically;
            if eBlink >= length(pd_l ) %when the blink is at the end of the trace
                pd_l(sBlink:length(pd_l )) = interp1(1:sBlink,pd_l (1:sBlink),sBlink:length(pd_l ),'linear','extrap');
            elseif sBlink <= 0 %when the blink is at the start of the trace
                pd_l(1:eBlink) = interp1(eBlink:length(pd_l ),pd_l(eBlink:length(pd_l )), 1:eBlink,'linear','extrap'); % note that matlab subscription starts with 1
            else
                %interpolate...
                intRange = setdiff(1:length(pd_l ), sBlink:eBlink, 'stable'); %to be interpolated range
                pd_l (sBlink:eBlink) = interp1(intRange',pd_l(intRange'), sBlink:eBlink, 'pchip'); %replace the original blinking part with the newly interpolated values
            end
            
        %else %if the blink block is longer than 0.4s to be invalid
            %j = j+1; %go to the next blink block
            %faultBlink_l(trialLevel(i)) = faultBlink_l(trialLevel(i)) + 1 ; %marking it as too long of missing data, to be excluded later
        %end
    end
end
%replacing the trialTrace with (newly interpolated and) low-pass filtered trace
rawData.pd(rawData.eye_id == 1)  = filtfilt(sosLo, gLo, pd_l ); 

%do the same for the right eye
pd_r = rawData.pd(rawData.eye_id == 0);
pointBlink_r = find( pd_r  == 0 | pd_r  < (mean(pd_r ) - 3*std(pd_r)) ...
    |pd_r > (mean(pd_r ) + 3*std(pd_r )));

if ~isempty(pointBlink_r) %if there are blinks inside the recording
    temp = pointBlink_r - (1:length(pointBlink_r))'; temp = [true; diff(temp(:)) ~=0; true];
    blockBlink = mat2cell(pointBlink_r(:).', 1, diff(find(temp))); %breaking the blinking index into cells containing each blink block
    %trialBlink_l(trialLevel(i)) = trialBlink_l(trialLevel(i)) + size(blockBlink,2) ; %recording number of blinks in each trial
    %totalBlink = totalBlink + 1; %recording total number of blinks for the individual
    j=1;
    
    %going through each block of blinks
    while j <= size(blockBlink,2)
        curBlink = blockBlink{j}; %selecting the current blink block
        %if length(curBlink) < valPoint %if it's a permittable data loss (less than 0.4s)
            %if there is a next blink block, and it's within 0.2s of
            %the end of the previous block, and it's a valid blink
            if j+1 <= size(blockBlink,2) && blockBlink{j+1}(1) - curBlink(length(curBlink)) < 0.2*SampFreq
                    %&& length(blockBlink{j+1}) < valPoint
                
                nexBlink = blockBlink{j+1}; %selecting the next blink
                sBlink = curBlink(1) - 0.1*SampFreq; eBlink = nexBlink(length(nexBlink)) + 0.1*SampFreq; %combining the two blinks to one interpolation block
                j = j+2; %continue to the next next blink
            else %if there is one blink, or the current blink is serpate from the next one, or the next blink is not valid
                sBlink = curBlink(1) - 0.1*SampFreq; eBlink = curBlink(length(curBlink)) + 0.1*SampFreq;
                j=j+1; %continue to the next blink
            end
            
            
            %when the blink occurs near the beginning or end of the
            %trace, extrapolate linearly;
            %otherwise, interpolate cubically;
            if eBlink >= length(pd_r ) %when the blink is at the end of the trace
                pd_r(sBlink:length(pd_r )) = interp1(1:sBlink,pd_r (1:sBlink),sBlink:length(pd_r ),'linear','extrap');
            elseif sBlink <= 0 %when the blink is at the start of the trace
                pd_r(1:eBlink) = interp1(eBlink:length(pd_r ),pd_r(eBlink:length(pd_r )), 1:eBlink,'linear','extrap'); % note that matlab subscription starts with 1
            else
                %interpolate...
                intRange = setdiff(1:length(pd_r ), sBlink:eBlink, 'stable'); %to be interpolated range
                pd_r (sBlink:eBlink) = interp1(intRange',pd_r(intRange'), sBlink:eBlink, 'pchip'); %replace the original blinking part with the newly interpolated values
            end
            
        %else %if the blink block is longer than 0.4s to be invalid
            %j = j+1; %go to the next blink block
            %faultBlink_l(trialLevel(i)) = faultBlink_l(trialLevel(i)) + 1 ; %marking it as too long of missing data, to be excluded later
        %end
    end
end
%replacing the trialTrace with (newly interpolated and) low-pass filtered trace
rawData.pd(rawData.eye_id == 0)  = filtfilt(sosLo, gLo, pd_r ); 



%and saving the processed pupil traces
for i = 1:length(unique(trace_ID)) 
  trace_l = rawData.pd(strcmp(rawData.ID, trace_ID(i)) & rawData.eye_id == 1); %selecting the trace for this trial
  trace_r = rawData.pd(strcmp(rawData.ID, trace_ID(i)) & rawData.eye_id == 0 );

 %--------
    %visualisations of original traces
    % In Matlab 2013a or later, when figure handles are not double anymore, do...
%     tracePlot = plot(linspace(0,length(trace)/SampFreq, length(trace)),trace); %creating the plot, with x axis from 0 to the end of
%     % of the trace in units of seconds, with the total number of data points in between.
%     hgsave(tracePlot,fullfile(otraceDir, [char(trialLevel(i)) '.fig'])); %saving the plot under the name of trial
    
    % Else in Matlab2013a or before, when figures are double, do...
         f = figure;
         %draw the left eye blue
          plot(linspace(0,length(trace_l)/SampFreq, length(trace_l)),trace_l,'blue');
          hold on;
          plot(linspace(0,length(trace_r)/SampFreq, length(trace_r)),trace_r,'red');

      
         %draw out lines for timing
%          line([0.5, 0.5], ylim); %intertrial
%          line([1.5,1.5], ylim); %baseline
         %! more to go!
         %and then save
         saveas(f, fullfile(traceDir, char(trace_ID(i))), 'fig'); 
         %
         close;
                  %drawing the gaze distribution of the trial
      
end





%-----
%excluding trials when the number of blinks in one trial is more than 20%
%of all the blinks
%excTrials =  [find((trialBlink / (totalBlink/2)) > excRule)', find(faultBlink ~=0)']; %index of trials needs to be excluded
excTrials = find(trialBlink > 0.2);
%going through the entire trace to mark up trials to be excluded
    % for i =  1: size(pupilData,1)
    %     for t = 1:length(excTrials)
    %         if pupilData{i,6} == excTrials(t) 
    %             pupilData{i,3} = {}; %annulling the excluded trials by setting the event to empty cell
    %         end
    %     end
    % end

    



%% downsampling to 60 Hz (from 120Hz);
%note that downsampling doesn't hide blinking since the resolution after
%downsampling is 0.02s, which is far shorter than a blink.
%Also best to downsample after all the pre-processing, to prevent sharp
%edges in traces coming from downsampling
%create a file
pupilData = downsample(rawData,SampFreq/60);
%pupilData = struct2table(pupilData, 'AsArray',true);



%% writing the final datafile to a txt file
struct2csv(pupilData,dataFile);
%copyfile(dataFile, '/Users/yuezhang/Google Drive/Projects/ALPORT_LE/results/pupil_results/pupils');
%%

%%attaching the function for struct selection
    function T = IndexedStruct(S, Condition, FieldList)
        if nargin == 2
            FieldList = fieldnames(S);
        end
        for iField = 1:numel(FieldList)
            Field    = FieldList{iField};
            T.(Field) = S.(Field)(Condition);
        end
    end

    function struct2csv(s,fn)
        % STRUCT2CSV(s,fn)
        %
        % Written by James Slegers, james.slegers_at_gmail.com
        % Covered by the BSD License
        %
        FID = fopen(fn,'w');
        headers = fieldnames(s);
        m = length(headers);
        sz = zeros(m,2);
        t = length(s);
        for rr = 1:t
            l = '';
            for ii = 1:m
                sz(ii,:) = size(s(rr).(headers{ii}));
                if ischar(s(rr).(headers{ii}))
                    sz(ii,2) = 1;
                end
                l = [l,'"',headers{ii},'",',repmat(',',1,sz(ii,2)-1)];
            end
            l = [l,'\n'];
            fprintf(FID,l);
            n = max(sz(:,1));
            for ii = 1:n
                l = '';
                for jj = 1:m
                    c = s(rr).(headers{jj});
                    str = '';
                    
                    if sz(jj,1)<ii
                        str = repmat(',',1,sz(jj,2));
                    else
                        if isnumeric(c)
                            for kk = 1:sz(jj,2)
                                str = [str,num2str(c(ii,kk)),','];
                            end
                        elseif islogical(c)
                            for kk = 1:sz(jj,2)
                                str = [str,num2str(double(c(ii,kk))),','];
                            end
                        elseif ischar(c)
                            str = ['"',c(ii,:),'",'];
                        elseif iscell(c)
                            if isnumeric(c{1,1})
                                for kk = 1:sz(jj,2)
                                    str = [str,num2str(c{ii,kk}),','];
                                end
                            elseif islogical(c{1,1})
                                for kk = 1:sz(jj,2)
                                    str = [str,num2str(double(c{ii,kk})),','];
                                end
                            elseif ischar(c{1,1})
                                for kk = 1:sz(jj,2)
                                    str = [str,'"',c{ii,kk},'",'];
                                end
                            end
                        end
                    end
                    l = [l,str];
                end
                l = [l,'\n'];
                fprintf(FID,l);
            end
            fprintf(FID,'\n');
        end
        fclose(FID);
    end
end
