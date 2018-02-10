clear; clc; close all;

home = 'C:\Users\levan\human-rat-analog\DATA';

filePaths = lsDir(home,{'csv'})';
onsets = [];

%% Define fMRI related variables
TR = 2;
n_TRs_till_sync = 4;

ITI = 15; % inter trial interval.



%%
for iFile = 1:length(filePaths)
    
    [a,filename,ext] = fileparts(filePaths{iFile});
    
    % Get details of subject and conditions
    if strfind(filename,'learning')
        session = 'learning';
    elseif strfind(filename,'retest')
        session = 'retest';
    else
        display('something is wrong with file name');
    end
    
    if strfind(filename,'allo')
        condition = 'allo';
    elseif strfind(filename,'ego')
        condition = 'ego';
    else
        display('something is wrong with condition');
    end
    
    subjID = str2double(filename(1:2));
    if ~isnan(subjID) % for the 1 file thats called testtest
                
        % Open the file and read the data
        fileID = fopen(filePaths{iFile});
        splitFile = textscan(fileID,'%s %s %s %s %s %s','Delimiter',';');
        splitFile = horzcat(splitFile{:});
        fclose(fileID);
        
        % Convert trial times into onset times.
        trialDurs = str2double(splitFile(3:end,4));
        for iTrial = 1:length(trialDurs)
            trialDurs(iTrial) = 
        
        % Save the data into the onsets variable
        expression = ['onsets.' session '.' condition '.subj' int2str(subjID) ' = str2double(splitFile(3:end,4));'];
        eval(expression);
    end
end