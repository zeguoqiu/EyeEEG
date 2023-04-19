%% LIMO for matchedDT analyses for Search study
% author: zeguo.qiu@uq.net.au
% last date modified: 040223

%% align EEG trial and epoch info (reformatting fields) for LIMO files
for p=[1:25 27 28 30:32]
    % update EEG.epoch for main analysis
    EEG = pop_loadset('filename',['sub-0' num2str(p) '.set'], 'filepath', '');
    for n=1:length(EEG.epoch)
        index=find(cell2mat(EEG.epoch(n).eventbini)~=-1,1);
        EEG.epoch(n).event=n;
        EEG.epoch(n).eventbepoch=cell2mat(EEG.epoch(n).eventbepoch(1,1));
        EEG.epoch(n).eventbini=cell2mat(EEG.epoch(n).eventbini(1,index));
        EEG.epoch(n).eventbinlabel=char(EEG.epoch(n).eventbinlabel(1,index));
        EEG.epoch(n).eventcodelabel=char(EEG.epoch(n).eventcodelabel(1,index));
        EEG.epoch(n).eventduration=cell2mat(EEG.epoch(n).eventduration(1,1));
        EEG.epoch(n).eventenable=cell2mat(EEG.epoch(n).eventenable(1,1));
        EEG.epoch(n).eventflag=cell2mat(EEG.epoch(n).eventflag(1,1));
        EEG.epoch(n).eventitem=cell2mat(EEG.epoch(n).eventitem(1,index));
        EEG.epoch(n).eventlatency=cell2mat(EEG.epoch(n).eventlatency(1,index));
        EEG.epoch(n).eventtype=char(EEG.epoch(n).eventtype(1,index));
    end
    EEG.epoch=rmfield(EEG.epoch,'eventbvmknum');
    EEG.epoch=rmfield(EEG.epoch,'eventbvtime');
    EEG.epoch=rmfield(EEG.epoch,'eventchannel');
    EEG.epoch=rmfield(EEG.epoch,'eventvisible');
    EEG.event=rmfield(EEG.event,'bvmknum');
    EEG.event=rmfield(EEG.event,'bvtime');
    EEG.event=rmfield(EEG.event,'channel');
    EEG.event=rmfield(EEG.event,'visible');
    EEG = pop_saveset( EEG, 'filename',['sub-0' num2str(p) '.set'],'filepath',...
        '');
end% pay attention to the naming and make changes if needed!

%% plot ERP waveforms
% reverse the AR-ed sets back to non-transformed sets AND THEN make ERPsets
for p=1:30
    EEG1 = ALLEEG(p);
    epochInd=[];
    for r=1:length(EEG1.epoch)
        epochInd_r=EEG1.epoch(r).eventbepoch(1,1);
        epochInd=[epochInd epochInd_r];
    end
    EEG = pop_loadset('filename',[ALLEEG(p).setname '.set'], 'filepath', ''); % load dataset
    EEG = pop_select( EEG, 'trial',epochInd ); %select clean epochs
end

% get epoch numbers from EEGsets
for p=1:30
    epochNo_indi=ALLEEG(p).EVENTLIST.trialsperbin;
    epochNo=[epochNo; epochNo_indi];
end
epochRange=[];
for n=1:4
    epochMin=min(epochNo(:,n));
    epochMax=max(epochNo(:,n));
    epochMean=mean(epochNo(:,n));
    epochRange=[epochRange; epochMin epochMax epochMean];
end

%% Main analysis - use previous artefact rejection information
% update new LIMO files with *eventitem* info for main analysis
for p=[10:25 27 28 30:32]%[1:25 27 28 30:32]
    EEG1=pop_loadset('filename',[num2str(p) 'AR.set'], 'filepath', ['addpath'  num2str(p) '\']);    
    eventIndex=[];
    for n=1:length(EEG1.epoch)
        eventIndex=[eventIndex cell2mat(EEG1.epoch(n).eventitem(1,find(cell2mat(EEG1.epoch(n).eventlatency)==0,1)))];
    end
    EEG=pop_loadset('filename',['sub-0' num2str(p) '.set'], 'filepath', '');    
    EEG=pop_selectevent( EEG, 'item',eventIndex ,'deleteevents','off','deleteepochs','on','invertepochs','off');
    EEG = pop_saveset( EEG, 'filename',['sub-0' num2str(p) '.set'],'filepath',...
        '');
end

%% MISC
% remove unused channels for the analyses when needed
ALLEEG = pop_select( ALLEEG, 'channel',{'Fpz','F7','F3','Fz','F4','F8','FC5','FC6','T7','C3','Cz','C4','T8','CP5','CP6','P7','P3','Pz','P4','P8','PO9','PO7','PO3','PO4','PO8','PO10','O1','Oz','O2'});
