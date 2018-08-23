%% Load log files
clear; clc; close all;
dbstop if error;

warning('off','MATLAB:table:RowsAddedExistingVars');

home = 'C:\Users\levan\human-rat-analog\LOG';

filepaths = sort_nat(lsDir(home,{'log'}))';

% Create a report table
error_table = table;
error_counter = 1;

for iLog = 1:length(filepaths)
    tbl = import_log_files(filepaths{iLog});
    tbl.pseudo_row = zeros(height(tbl),1); % This column will tell whether a row was artificially added.
     
    % Get sub_ID and conditions
    split_name = strsplit(filepaths{iLog},'_');
    sub_ID = strsplit(split_name{1},'\');
    sub_ID = sub_ID{end};
    if strfind(filepaths{iLog},'learning')
        stage = 'learning';
    elseif strfind(filepaths{iLog},'retest')
        stage = 'retest';
    else
        error('Somethings up with names');
    end
    if strfind(split_name{end},'ego')
        condition = 'ego';
    elseif strfind(split_name{end},'allo')
        condition = 'allo';
    else
        error('Somethings up with getting condition name');
    end
    
    % Check the first event type. Sometimes, its "end" which is an error.
    % In that case get rid of first row, and adjust trial_IDs.
    if strcmp(tbl.event_type{1},'End')
        error_table.sub_ID    {error_counter} = sub_ID;
        error_table.condition {error_counter} = condition;
        error_table.stage     {error_counter} = stage;        
        error_table.filepath  {error_counter} = filepaths{iLog};
        error_table.error_type{error_counter} = 'Starts with End';
        
        error_counter = error_counter + 1;
        
        if ~strcmp(tbl.trial_Name{1},tbl.trial_Name{2})
            tbl(1,:) = [];
            tbl.trial_ID = tbl.trial_ID - 1;
        else
            error('First event type is End, but the trial name doesn''t change')
        end
    end
    
    % Check the last trial type. It should be "end". 
    % If its "Begin" then remove it.
    % If its "Stopped", add a pseudo "End" row
    if strcmp(tbl.event_type{end},'Begin')
        if tbl.trial_ID(end) == tbl.trial_ID(end-1)
            tbl(end,:) = [];
            % Update error_table.
            error_table.sub_ID    {error_counter} = sub_ID;
            error_table.condition {error_counter} = condition;
            error_table.stage     {error_counter} = stage;
            error_table.filepath  {error_counter} = filepaths{iLog};
            error_table.error_type{error_counter} = 'Last row was Begin, removed it';
            
            error_counter = error_counter + 1;
        else
            error('Last row is Begin, but of a new trial')
        end
        
    elseif strcmp(tbl.event_type{end},'Stopped')
            tbl = [tbl; {tbl.trial_ID(end),tbl.trial_Name{end},'End',NaN,NaN,NaN,NaN,NaN,1}];
            tbl.pseudo_row(end) = 1;
            
            % Update error_table.
            error_table.sub_ID    {error_counter} = sub_ID;
            error_table.condition {error_counter} = condition;
            error_table.stage     {error_counter} = stage;
            error_table.filepath  {error_counter} = filepaths{iLog};
            error_table.error_type{error_counter} = 'Did not end with "End". Added pseudo "End" row';
            
            error_counter = error_counter + 1;
        else
            error('Check last trial type')
    end
    
    %% Find indices where event_type was changed
    idx_event_change = ~cellfun(@strcmp,tbl.event_type(1:end-1),tbl.event_type(2:end));
%     assert(strcmp(tbl.event_type{end},'Begin'),'Last trial_type is not Begin'); 
    % The above line just makes sure it ends with the "begin" trial_type. 
    % idx_event_change won't tag onto the very last row, because of how 
    % its defined. But thats ok if the last row is "Begin" trial type.
    
    % Filter the table to keep only relevant rows.
    tbl_filt = tbl(idx_event_change,:);
    
    % Add one row of "begin" to the table
    if ~strcmp(tbl_filt.event_type{1},'Begin')
        tbl_filt = [{1,tbl_filt.trial_Name{1},'Begin',0,7000,7000,0,0,1}; tbl_filt];
        
        % Update error_table.
        error_table.sub_ID    {error_counter} = sub_ID;
        error_table.condition {error_counter} = condition;
        error_table.stage     {error_counter} = stage;
        error_table.filepath  {error_counter} = filepaths{iLog};
        error_table.error_type{error_counter} = 'Added a Begin row';
        
        error_counter = error_counter + 1;
        
    elseif (tbl_filt.sync_onset(2) - tbl_filt.sync_onset(1)) < 2000
        % So, in this case, the trial started and ended very abruptly. Its
        % a bug that sometimes happened.
        % Remove that trial, and adjust trial_IDs accordingly.
        if strcmp(tbl_filt.event_type{2},'Stopped') && strcmp(tbl_filt.event_type{3},'End')
            % So, if you have Begin, Stopped, and End rows, then remove all
            % three.
           tbl_filt(1:3,:) = []; 
           
           % Adjust trial_IDs
           tbl_filt.trial_ID = tbl_filt.trial_ID - 1;
           
           % Update error_table.
           error_table.sub_ID    {error_counter} = sub_ID;
           error_table.condition {error_counter} = condition;
           error_table.stage     {error_counter} = stage;
           error_table.filepath  {error_counter} = filepaths{iLog};
           error_table.error_type{error_counter} = 'First trial is an empty one, with no movement';
           
           error_counter = error_counter + 1;
        else
            error('First trial is empty cause of a bug. But its not properly defined')
        end
    end
    
    % Check that Begin is followed by Stopped, Stopped is followed by End
    % and End is followed by Begin
    for iRow = 1:height(tbl_filt)-1
       if strcmp(tbl_filt.event_type{iRow},'Begin') && ~strcmp(tbl_filt.event_type{iRow+1},'Stopped')
           input('Begin not followed by Stopped') 
           tbl_filt = [tbl_filt(1:iRow,:); ...
                       tbl_filt(iRow+1,:); ...
                       tbl_filt(iRow+1:end,:)];
           tbl_filt.event_type{iRow+1} = 'Stopped';
           tbl_filt.pseudo_row(iRow+1) = 1;
       elseif strcmp(tbl_filt.event_type{iRow},'Stopped') && ~strcmp(tbl_filt.event_type{iRow+1},'End')
           input('Stopped not followed by End') 
       elseif strcmp(tbl_filt.event_type{iRow},'End') && ~strcmp(tbl_filt.event_type{iRow+1},'Begin')
           input('End not followed by Begin') 
       end
       
       
    end
    
    % Record n trials.
    n_trials = numel(unique(tbl_filt.trial_ID));
    assert(isequal(1:n_trials,unique(tbl_filt.trial_ID)'),'Trials do not progress smoothly');    
    
    % Get indices of begin, stopped, and end trials
    idx_begin   = find(strcmp(tbl_filt.event_type,'Begin'));
    idx_stopped = find(strcmp(tbl_filt.event_type,'Stopped'));
    idx_end     = find(strcmp(tbl_filt.event_type,'End'));
    
    assert(isequal(numel(idx_begin),numel(idx_end)),'Number of Begin and End lines don''t match');
    assert(isequal(numel(idx_begin),numel(idx_stopped)),'Number of Begin and Stopped lines don''t match');    
    % Sanity checks: make sure "stopped" "end" "begin" repeats as it
    % should.
    
    %% Create a new table, with trial_ID, trial_onset, trial_offset.
    eval(['onsets.' condition '.sub_' sub_ID '.' stage ' = table;']);
    for iTrial = 1:n_trials      
        eval(['onsets.' condition '.sub_' sub_ID '.' stage '.trial_ID(iTrial) = iTrial;']);
        eval(['onsets.' condition '.sub_' sub_ID '.' stage '.trial_onset(iTrial) = tbl_filt.sync_onset(idx_begin(iTrial));']);
        eval(['onsets.' condition '.sub_' sub_ID '.' stage '.target_lock(iTrial) = tbl_filt.sync_onset(idx_stopped(iTrial));']);
        eval(['onsets.' condition '.sub_' sub_ID '.' stage '.trial_dur(iTrial) = tbl_filt.sync_onset(idx_stopped(iTrial)) - tbl_filt.sync_onset(idx_begin(iTrial));']);
        eval(['onsets.' condition '.sub_' sub_ID '.' stage '.trial_dur_30_sec(iTrial) = 30;']);
        eval(['onsets.' condition '.sub_' sub_ID '.' stage '.trial_name(iTrial) = tbl_filt.trial_Name(idx_begin(iTrial));']);
        eval(['onsets.' condition '.sub_' sub_ID '.' stage '.distance_moved_1(iTrial) = tbl_filt.distance_moved_1(idx_stopped(iTrial));']);
        eval(['onsets.' condition '.sub_' sub_ID '.' stage '.distance_moved_2(iTrial) = tbl_filt.distance_moved_2(idx_stopped(iTrial));']);
        eval(['onsets.' condition '.sub_' sub_ID '.' stage '.ITI(iTrial) = tbl_filt.sync_onset(idx_end(iTrial)) - tbl_filt.sync_onset(idx_stopped(iTrial));']);
    end
end
    

%% working with CSV files
% CSVs are not accurate. Use LOGs instead.
% clear; clc; close all;
% 
% home = 'C:\Users\levan\human-rat-analog\DATA';
% 
% filePaths = lsDir(home,{'csv'})';
% onsets = [];
% 
% %% Define fMRI related variables
% TR = 2;
% n_TRs_till_sync = 4;
% 
% ITI = 15; % inter trial interval.
% 
% 
% 
% %%
% for iFile = 1:length(filePaths)
%     
%     [a,filename,ext] = fileparts(filePaths{iFile});
%     
%     % Get details of subject and conditions
%     if strfind(filename,'learning')
%         session = 'learning';
%     elseif strfind(filename,'retest')
%         session = 'retest';
%     else
%         display('something is wrong with file name');
%     end
%     
%     if strfind(filename,'allo')
%         condition = 'allo';
%     elseif strfind(filename,'ego')
%         condition = 'ego';
%     else
%         display('something is wrong with condition');
%     end
%     
%     subjID = str2double(filename(1:2));
%     if ~isnan(subjID) % for the 1 file thats called testtest
%                 
%         % Open the file and read the data
%         fileID = fopen(filePaths{iFile});
%         splitFile = textscan(fileID,'%s %s %s %s %s %s','Delimiter',';');
%         splitFile = horzcat(splitFile{:});
%         fclose(fileID);
%         
%         % Convert trial times into onset times.
%         trialDurs = str2double(splitFile(3:end,4));
% %         for iTrial = 1:length(trialDurs)
% %             trialDurs(iTrial) = 
%         
%         % Save the data into the onsets variable
%         expression = ['onsets.' session '.' condition '.subj' int2str(subjID) ' = str2double(splitFile(3:end,4));'];
%         eval(expression);
%     end
% end