%% Identify and label fixation events for different analyses using triggers
% author: zeguo.qiu@uq.net.au

%% Get the number of fixation events
EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString',...
 { 'boundary' } ); 
filename = '';
xlsrange=1;
for r=1:height([EEG.EVENTLIST.eventinfo.code].')
    if EEG.EVENTLIST.eventinfo(r).code == 19
        numberFixFearful=0;
        numberFixNeutral=0;
    end
    if EEG.EVENTLIST.eventinfo(r).code == 11 %fearful blocks
        numberFixFearful=numberFixFearful+1;
    elseif EEG.EVENTLIST.eventinfo(r).code == 21 %neutral blocks
        numberFixNeutral=numberFixNeutral+1;
    end
    if EEG.EVENTLIST.eventinfo(r).code == 18
        if numberFixFearful>0
            range=strcat('A',num2str(xlsrange));
            writematrix(numberFixFearful,filename,'Sheet',1,'Range',range);
            xlsrange=xlsrange+1;
        elseif numberFixNeutral>0
            range=strcat('B',num2str(xlsrange));
            writematrix(numberFixNeutral,filename,'Sheet',1,'Range',range);
            xlsrange=xlsrange+1;
        end
    end
end

%% Detect bad trials
%[EEG.EVENTLIST.eventinfo(1:height([EEG.EVENTLIST.eventinfo.code].')).goodbad] = deal([]);
EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString',...
 { 'boundary' } ); 
for r=1:height([EEG.EVENTLIST.eventinfo.code].')
    if EEG.EVENTLIST.eventinfo(r).code == 19
        numberFixFearful=0;
        numberFixNeutral=0;
        indexTrial=r;
    end
    if EEG.EVENTLIST.eventinfo(r).code == 11            %fearful blocks
        numberFixFearful=numberFixFearful+1;
    elseif EEG.EVENTLIST.eventinfo(r).code == 21        %neutral blocks
        numberFixNeutral=numberFixNeutral+1;
    end
    if EEG.EVENTLIST.eventinfo(r).code == 18
        if numberFixFearful>9                                              % get this number from the outlier test for every participant
            EEG.EVENTLIST.eventinfo(indexTrial).code = 29;
        elseif numberFixNeutral>13                                          % get this number from the outlier test for every participant
            EEG.EVENTLIST.eventinfo(indexTrial).code = 29;
        end
    end
end

%% Modify triggers to identify every fixation event
for r=1:height([EEG.EVENTLIST.eventinfo.code].')
    if EEG.EVENTLIST.eventinfo(r).code == 19
        numberFixFearful=0;
        numberFixNeutral=0;
    end
    if EEG.EVENTLIST.eventinfo(r).code == 11 & exist('numberFixFearful','var') == 1	%fearful blocks
        numberFixFearful=numberFixFearful+1;
        EEG.EVENTLIST.eventinfo(r).code = numberFixFearful*100+11;
    elseif EEG.EVENTLIST.eventinfo(r).code == 21 & exist('numberFixNeutral','var') == 1	%neutral blocks
        numberFixNeutral=numberFixNeutral+1;
        EEG.EVENTLIST.eventinfo(r).code = numberFixNeutral*100+21;
    end
    if EEG.EVENTLIST.eventinfo(r).code == 18
        clear numberFixFearful;
        clear numberFixNeutral;
    end
end

%% Make Epoched Datasets
EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' } );
EEG  = pop_binlister( EEG , 'BDF', 'Z:\Experiment_Search\EEGsets\Bin_descriptor_Search_lastFixPrep.txt', 'IndexEL',  1,...
 'SendEL2', 'EEG', 'UpdateEEG', 'on', 'Voutput', 'EEG' );
EEG = pop_epochbin( EEG , [-100.0  1000.0],  'pre');
filename = strcat(num2str(sscanf(EEG.setname,'%d')),'lastFixPrep');
EEG = pop_saveset(EEG, filename);

%% Extract binned signal amplitudes for every epoch on AR-ed datasets
output = '';
xlsrange = 1;
time_window = [400 900];
samples = find( EEG.times>=time_window(1) & EEG.times<=time_window(2) );
meanFRP = squeeze( mean( EEG.data( :, samples, : ), 2 ) )';
trialNum = 0;
outputMatrix = [];
summedFRP = zeros(1,31);

% Add up all epochs within one trial
for r=1:EEG.trials
    if EEG.epoch(r).eventbini{1,1}~= -1
        binNum = EEG.epoch(r).eventbini{1,1};
    elseif EEG.epoch(r).eventbini{1,1}== -1
        if EEG.epoch(r).eventbini{1,2}~= -1
            binNum = EEG.epoch(r).eventbini{1,2};
        elseif EEG.epoch(r).eventbini{1,2}== -1
            binNum = EEG.epoch(r).eventbini{1,3};
        end
    end
    if EEG.epoch(r+1).eventbini{1,1}~= -1
        nextBinNum = EEG.epoch(r+1).eventbini{1,1};
    elseif EEG.epoch(r+1).eventbini{1,1}== -1
        if EEG.epoch(r+1).eventbini{1,2}~= -1
            nextBinNum = EEG.epoch(r+1).eventbini{1,2};
        elseif EEG.epoch(r+1).eventbini{1,2}== -1
            nextBinNum = EEG.epoch(r+1).eventbini{1,3};
        end
    end
    if binNum<=nextBinNum
        tempMeanFRP = meanFRP(r,:);
        summedFRP = summedFRP + tempMeanFRP;
    else
        trialNum = trialNum+1;
        for n=1:length(EEG.epoch(r).eventbini)
            if EEG.epoch(r).eventbini{1,n}>=11   %neutral face; IMPORTANT: remember to change the number according to diff. bdf
                outputMatrix =[trialNum 2 summedFRP];
                break
            elseif EEG.epoch(r).eventbini{1,n}>0 & EEG.epoch(r).eventbini{1,n}<=10
                outputMatrix =[trialNum 1 summedFRP];	%fearful face
                break
            end
        end
        range=strcat('A',num2str(xlsrange));
        writematrix(outputMatrix,output,'Sheet',1,'Range',range);
        xlsrange=xlsrange+1;
        summedFRP = zeros(1,31);
    end
end

%% successive fixations prior to the final aware fixation in multiple-fixations condition (n, n-1, n-2); 010922
codeTemp = 101;
for r=1:size([EEG.EVENTLIST.eventinfo.code].',1)
    if sscanf(EEG.EVENTLIST.eventinfo(r).codelabel,'S%d')==11 & EEG.EVENTLIST.eventinfo(r).code > 101
        if EEG.EVENTLIST.eventinfo(r).code > codeTemp
            codeTemp = EEG.EVENTLIST.eventinfo(r).code;
            rowN = r;
        elseif EEG.EVENTLIST.eventinfo(r).code < codeTemp & EEG.EVENTLIST.eventinfo(rowN).code > 300
            EEG.EVENTLIST.eventinfo(rowN).code = 1003;
            EEG.EVENTLIST.eventinfo(rowN-2).code = 1002;
            EEG.EVENTLIST.eventinfo(rowN-4).code = 1001;
            EEG.EVENTLIST.eventinfo(rowN).binlabel = '1003';
            EEG.EVENTLIST.eventinfo(rowN-2).binlabel = '1002';
            EEG.EVENTLIST.eventinfo(rowN-4).binlabel = '1001';
            codeTemp = 101;
        end
    elseif sscanf(EEG.EVENTLIST.eventinfo(r).codelabel,'S%d')==21 & EEG.EVENTLIST.eventinfo(r).code > 101
        if EEG.EVENTLIST.eventinfo(r).code > codeTemp
            codeTemp = EEG.EVENTLIST.eventinfo(r).code;
            rowN = r;
        elseif EEG.EVENTLIST.eventinfo(r).code < codeTemp & EEG.EVENTLIST.eventinfo(rowN).code > 300
            EEG.EVENTLIST.eventinfo(rowN).code = 1006;
            EEG.EVENTLIST.eventinfo(rowN-2).code = 1005;
            EEG.EVENTLIST.eventinfo(rowN-4).code = 1004;
            EEG.EVENTLIST.eventinfo(rowN).binlabel = '1006';
            EEG.EVENTLIST.eventinfo(rowN-2).binlabel = '1005';
            EEG.EVENTLIST.eventinfo(rowN-4).binlabel = '1004';
            codeTemp = 101;
        end
    end
end
