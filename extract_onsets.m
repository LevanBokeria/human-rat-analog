%% extract_onsets.m function
% This function takes the .log files, and extracts the onset times for the
% start and stop events within the trial. 

% If cleans up the .log files in many ways, and generates an output table
% that states if there were any errors.

%% Define global variables
clear; clc; close all;
dbstop if error;

warning('off','MATLAB:table:RowsAddedExistingVars');

% Define where the files are
home = 'C:\Users\levan\human-rat-analog';

% Create an array of paths to each log file
filepaths = sort_nat(lsDir(fullfile(home,'LOG'),{'log'}))';

% Create a report table
error_table   = table;
error_counter = 1;

general_counter = 1;

% Two variables below are used to record differences between beging events
% and end events, and between end events and stopped events.

delay_table = table;
delay_table_counter = 1;

% Two variables below are used to calculate duration of button pressed.
stopped_diff_counter = 1;
stopped_diffs = [];
%% Start looping over files
for iLog = 1:length(filepaths)
    tbl_filt = table; % reset the variable
    iLog
    tbl = import_log_files(filepaths{iLog});
    tbl.pseudo_row = zeros(height(tbl),1); % This column will tell whether a row was artificially added.
     
    %% Get sub_ID and conditions
    
    % Look inside the path to see which subject this file belongs to
    split_name = strsplit(filepaths{iLog},'_');
    sub_ID = strsplit(split_name{1},'\');
    sub_ID = sub_ID{end};
    
    % Look inside the path to see which stage this log belongs to: learning or retest
    if strfind(filepaths{iLog},'learning')
        stage = 'learning';
    elseif strfind(filepaths{iLog},'retest')
        stage = 'retest';
    else
        error('Somethings up with names');
    end
    
    % Look inside the path to see which condition this log file belongs to: allo or ego
    if strfind(split_name{end},'ego')
        condition = 'ego';
    elseif strfind(split_name{end},'allo')
        condition = 'allo';
    else
        error('Somethings up with getting condition name');
    end
    
    %% Check the first event type. 
    
    % Sometimes, the very first event type is "end" which is an error.
    % In that case get rid of first row, and adjust trial_IDs.
    if strcmp(tbl.event_type{1},'End')
       
        if ~strcmp(tbl.trial_Name{1},tbl.trial_Name{2})
            tbl(1,:) = [];
            tbl.trial_ID = tbl.trial_ID - 1;
        else
            error('First event type is End, but the trial name doesn''t change')
        end
        
        % Update error table
        error_table.sub_ID    {error_counter} = sub_ID;
        error_table.condition {error_counter} = condition;
        error_table.stage     {error_counter} = stage;        
        error_table.filepath  {error_counter} = filepaths{iLog};
        error_table.error_type{error_counter} = 'Starts with End';
        
        error_counter = error_counter + 1;        
    elseif strcmp(tbl.event_type{1},'Stopped')
        % If its stopped, add a "Begin" row with sync_onset 0;
        tbl = [{tbl.trial_ID(1),tbl.trial_Name{1},'Begin',0,NaN,NaN,0,0,1}; tbl];
        
        % Update error_table. No need to do that, cause otherwise the
        % error_table gets too cluttered.
        
%         error_table.sub_ID    {error_counter} = sub_ID;
%         error_table.condition {error_counter} = condition;
%         error_table.stage     {error_counter} = stage;
%         error_table.filepath  {error_counter} = filepaths{iLog};
%         error_table.error_type{error_counter} = '1st row is "Stopped". Added a "Begin" row';
%         
%         error_counter = error_counter + 1;
    elseif strcmp(tbl.event_type{1},'Begin')
        % If it starts with "Begin" thats good. Just check that next row has same trial_name and trial_ID
        assert(isequal(tbl.trial_ID(1),tbl.trial_ID(2)),'First row is Begin, but next row has diff trial ID');
        assert(isequal(tbl.trial_Name(1),tbl.trial_Name(2)),'First row is Begin, but next row has diff trial name');        
    end
    
    % Check the last trial type. It should be "end". 
    % If its "Begin" then remove it.
    % If its "Stopped", add a pseudo "End" row
    
    if strcmp(tbl.event_type{end},'Begin')
%         if tbl.trial_ID(end) == tbl.trial_ID(end-1)
            tbl(end,:) = [];
            
            % Update error_table.
            error_table.sub_ID    {error_counter} = sub_ID;
            error_table.condition {error_counter} = condition;
            error_table.stage     {error_counter} = stage;
            error_table.filepath  {error_counter} = filepaths{iLog};
            error_table.error_type{error_counter} = 'Last row was Begin, removed it';
            
            error_counter = error_counter + 1;
%         else
%             error('Last row is Begin, but of a new trial')
        
    elseif strcmp(tbl.event_type{end},'Stopped')
        % If "Stopped", just add a pseudo "End" trial at the end.
        tbl = [tbl; {tbl.trial_ID(end),tbl.trial_Name{end},'End',NaN,NaN,NaN,NaN,NaN,1}];
        
        % Update error_table.
        error_table.sub_ID    {error_counter} = sub_ID;
        error_table.condition {error_counter} = condition;
        error_table.stage     {error_counter} = stage;
        error_table.filepath  {error_counter} = filepaths{iLog};
        error_table.error_type{error_counter} = 'Last row was "Stopped". Added pseudo "End" row';
        
        error_counter = error_counter + 1;
    elseif strcmp(tbl.event_type{end},'End')
        % If its "End" that is correct. Just check that trial ID and trial names correspond for last two rows.
        assert(isequal(tbl.trial_ID(end),tbl.trial_ID(end-1)),'Last row is "End", but previous row has diff trial ID');
        assert(isequal(tbl.trial_Name(end),tbl.trial_Name(end-1)),'Last row is "End", but previous row has diff trial name');               
    else 
        error('Check last trial type')
    end
    
    %% Find indices where event_type was changed. And get rid of redundant "stopped" rows.
%     idx_event_change = ~cellfun(@strcmp,tbl.event_type(1:end-1),tbl.event_type(2:end));
% %     assert(strcmp(tbl.event_type{end},'Begin'),'Last trial_type is not Begin'); 
%     % The above line just makes sure it ends with the "begin" trial_type. 
%     % idx_event_change won't tag onto the very last row, because of how 
%     % its defined. But thats ok if the last row is "Begin" trial type.
%     
%     % Filter the table to keep only rows where change happened, including
%     % last row.
%     tbl_filt = []; % reset the variable. Might not be necessary
%     tbl_filt = [tbl(idx_event_change,:); tbl(end,:)];

    %% Get rid of redundant "stopped" rows.  
    filt_counter = 1;
    for iRow = 1:height(tbl)
%         stopped_diff_counter
        % If the event_type is not stopped, record that row in the filtered
        % table.
        if ~strcmp(tbl.event_type{iRow},'Stopped')
            tbl_filt(filt_counter,:) = tbl(iRow,:);

            filt_counter = filt_counter + 1;
        
        else % if it is "Stopped":
            
            % Check if previous row was NOT a "Stopped", then add to
            % filtered table. So this means its the first "Stopped" event.
            if ~strcmp(tbl.event_type{iRow - 1},'Stopped')
                tbl_filt(filt_counter,:) = tbl(iRow,:);    
                
                filt_counter = filt_counter + 1;
                
                % record when exactly that first "Stopped" press happened.
                % Used later to calculate how long the button was pressed.
                assert(size(stopped_diffs,1) < stopped_diff_counter); %sanity check.
                
                stopped_diffs(stopped_diff_counter,1) = tbl.sync_onset(iRow);
            elseif ~strcmp(tbl.event_type{iRow + 1},'Stopped') % So if its the last "Stopped" entry
                % Calculate how long the button was pressed.
                stopped_diffs(stopped_diff_counter,2) = tbl.sync_onset(iRow);
                stopped_diffs(stopped_diff_counter,3) = stopped_diffs(stopped_diff_counter,2) - stopped_diffs(stopped_diff_counter,1);
                
                stopped_diff_counter = stopped_diff_counter + 1;
            end    
        end
    end
    %% If trial started and ended very quickly, its a bug. Remove that trial and adjust trial_ID    
    if (tbl_filt.sync_onset(2) - tbl_filt.sync_onset(1)) < 2000
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
           error_table.error_type{error_counter} = 'First trial is with no movement. Must be a bug. Removed that trial';
           
           error_counter = error_counter + 1;
        else
            error('First trial is empty cause of a bug. But doesn''t have a "Stopped" and "End" rows.')
        end
    end
    
    %% Check that Begin is followed by Stopped, Stopped is followed by End
    % and End is followed by Begin
    for iRow = 1:height(tbl_filt)-1
       if strcmp(tbl_filt.event_type{iRow},'Begin') && ~strcmp(tbl_filt.event_type{iRow+1},'Stopped')
%            input('Begin not followed by Stopped') 
           tbl_filt = [tbl_filt(1:iRow,:); ...
                       tbl_filt(iRow+1,:); ...
                       tbl_filt(iRow+1:end,:)];
           tbl_filt.event_type{iRow+1} = 'Stopped';
           tbl_filt.pseudo_row(iRow+1) = 1;
           
           % Update error_table.
           error_table.sub_ID    {error_counter} = sub_ID;
           error_table.condition {error_counter} = condition;
           error_table.stage     {error_counter} = stage;
           error_table.filepath  {error_counter} = filepaths{iLog};
           error_table.error_type{error_counter} = 'Begin not followed by Stopped. Added a pseudo "Stopped" row';
           
           error_counter = error_counter + 1;
           
           
       elseif strcmp(tbl_filt.event_type{iRow},'Stopped') && ~strcmp(tbl_filt.event_type{iRow+1},'End')
           input('Stopped not followed by End') 
       elseif strcmp(tbl_filt.event_type{iRow},'End') && ~strcmp(tbl_filt.event_type{iRow+1},'Begin')
           disp(filepaths{iLog});
           iRow
           input('End not followed by Begin.') 
       end
       
    end
    
    % Record n trials.
    n_trials = numel(unique(tbl_filt.trial_ID));
    assert(isequal(1:n_trials,unique(tbl_filt.trial_ID)'),'Trials do not progress smoothly');    
    
    % Get indices of begin, stopped, and end trials
    idx_begin   = find(strcmp(tbl_filt.event_type,'Begin'));
    idx_stopped = find(strcmp(tbl_filt.event_type,'Stopped'));
    idx_end     = find(strcmp(tbl_filt.event_type,'End'));
    
%     assert(isequal(numel(idx_begin),numel(idx_end)),'Number of Begin and End lines don''t match');
%     assert(isequal(numel(idx_begin),numel(idx_stopped)),'Number of Begin and Stopped lines don''t match');    
    % Sanity checks: make sure "stopped" "end" "begin" repeats as it
    % should.
    
    %% Create a new table, with trial_ID, trial_onset, trial_offset.
    onsets.(condition).(['sub_' sub_ID]).(stage) = table;
    
    for iTrial = 1:n_trials  
        onsets.(condition).(['sub_' sub_ID]).(stage).trial_ID(iTrial)         = iTrial;
        onsets.(condition).(['sub_' sub_ID]).(stage).trial_onset(iTrial)      = tbl_filt.sync_onset(idx_begin(iTrial));
        onsets.(condition).(['sub_' sub_ID]).(stage).target_lock(iTrial)      = tbl_filt.sync_onset(idx_stopped(iTrial));
        onsets.(condition).(['sub_' sub_ID]).(stage).trial_dur(iTrial)        = tbl_filt.sync_onset(idx_stopped(iTrial)) - tbl_filt.sync_onset(idx_begin(iTrial));
        onsets.(condition).(['sub_' sub_ID]).(stage).trial_dur_30_sec(iTrial) = 30000;
        onsets.(condition).(['sub_' sub_ID]).(stage).trial_name(iTrial)       = tbl_filt.trial_Name(idx_begin(iTrial));
        onsets.(condition).(['sub_' sub_ID]).(stage).distance_moved_1(iTrial) = tbl_filt.distance_moved_1(idx_stopped(iTrial));
        onsets.(condition).(['sub_' sub_ID]).(stage).distance_moved_2(iTrial) = tbl_filt.distance_moved_2(idx_stopped(iTrial));
        onsets.(condition).(['sub_' sub_ID]).(stage).ITI(iTrial)              = tbl_filt.sync_onset(idx_end(iTrial)) - tbl_filt.sync_onset(idx_stopped(iTrial));
        
        % Record differences between begin-end, end-stopped.
        if iTrial > 1
            delay_table.begin_min_end  (delay_table_counter) = tbl_filt.sync_onset(idx_begin(iTrial)) - tbl_filt.sync_onset(idx_end(iTrial-1));
            delay_table.end_min_stopped(delay_table_counter) = tbl_filt.sync_onset(idx_end(iTrial))   - tbl_filt.sync_onset(idx_stopped(iTrial));
            
            delay_table_counter = delay_table_counter + 1;
        end
        
    end
end % iLog

%% Do some checks on output trials
condNames = fieldnames(onsets);

for iCond = 1:numel(condNames)
   condition = condNames{iCond};
   
   subj_IDs = fieldnames(onsets.(condition));
   
   for iSub = 1:numel(subj_IDs)
       % Check that both learning and retest have same trial amounts
       if ~isequal(size(onsets.(condition).(subj_IDs{iSub}).learning),size(onsets.(condition).(subj_IDs{iSub}).retest))
          % Update error table
           error_table.sub_ID    {error_counter} = subj_IDs{iSub};
           error_table.condition {error_counter} = condition;
           error_table.stage     {error_counter} = NaN;
           error_table.filepath  {error_counter} = NaN;
           error_table.error_type{error_counter} = ['Amount of trials differ. Learning has ' ...
               int2str(height(onsets.(condition).(subj_IDs{iSub}).learning)) ' and retest has ' ...
               int2str(height(onsets.(condition).(subj_IDs{iSub}).retest)) ' trials'];
           
           error_counter = error_counter + 1;
           
       end
   end
end

% Sort the error table for inspection

%% Save variables
saveVars = input('Save the files?\n');

if saveVars
    save(fullfile(home,'onsets.mat'),'onsets','error_table');
end

