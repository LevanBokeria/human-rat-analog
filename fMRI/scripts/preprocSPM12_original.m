function preprocSPM12_original(subName)
%preprocSPM12   Preprocesses brain images.
%   Imaging files of defined subjects are preprocessed, without ignoring
%   the first 5 files.
%
%   FORMAT BART_preprocSPM12(subName).
%   
%   subName         - single string containing the Subject number / name of
%   the subject folder. It is assumed that this is the only difference
%   between subjects
%                     ('S8888').

%   Example:   BART_preprocSPM12('S8888').
%

%   Author: Lisa Wagels (modifiziert nach Ruben Scholle :)), adapted by NK   
%   Version: 1.01     Date: 2017/10/11




%% ***** Definition of root directories *****
%you can leave that commented
%brauchen wir nicht, weil wir das nicht auf verschiedenen Systemn nutzen
%udn wenn, dann muss man lediglich die Variable 'rootDir' ändern, dafür
%brauchen wir keinen GUI :)
% if nargin == 0
%     fprintf(2, 'Input error. Please specify the subject-number\n');
%     return
% elseif nargin == 1
%     rootDir = '/server/data/eternus/storage1/data8/emlang/TOOVELS/';
%     tPMFile =  fullfile('/server/global/matlab', 'spm12', 'tpm', 'TPM.nii');
%     fprintf(1, 'Operating system: Linux\nrootDir = ''/server/data/eternus/storage1/data8/emlang/TOOVELS/''\n');
% elseif nargin == 2   
%     switch lower(operatingSystem)
%     case 'windows'
%         rootDir = 'U:\05_Neurologie\';
%         tPMFile = fullfile(matlabroot, 'spm12\tpm\TPM.nii');
%     case 'linux'
%         rootDir = '/server/data/eternus/storage1/data8/emlang/TOOVELS/';
%         tPMFile =  fullfile('/server/global/matlab', 'spm12', 'tpm', 'TPM.nii');
%     otherwise
%         rootDir = uigetdir(matlabroot,...
%             'Select root directory of the paradigm');
%         [tPMFileName, tPMDir] = uigetfile({'*.nii',...
%             'NIfTI-files (*.nii)'; '*.*', 'All Files (*.*)'},...
%             'Select the TPM.nii-file of SPM', fullfile(matlabroot,...
%             'SPM12', 'tpm', 'TPM.nii'));
%         tPMFile = fullfile(tPMDir, tPMFileName);
%     end 
% elseif nargin > 2
%     fprintf(2, 'Too many input arguments!');
%     return
% end  

%% ***** Preprocessing *****
%rootDir    = '/izkf/storage/storage1/projects/tdrisk/DATA/BART';
rootDir    = '/bif/storage/storage1/projects/tdrisk/DATA/BART'; % directory where your subject folders are stored
epiDir = fullfile(rootDir,subName, 'Orig','EPI'); %assumend folder names in every folder, change if different
epiFileArray = spm_select('ExtFPList', epiDir,'^y-vol_.*\.nii$'); %
anatomyDir = fullfile(rootDir,subName, '3D');   %assumed name of the folder in which the T1 file is stored, change if necessary

tPMFile    =  fullfile('/server/global/matlab', 'spm12', 'tpm', 'TPM.nii');  % Possibly adjust to own path of SPM install
anatomyFile = spm_select('ExtFPList', anatomyDir,'^y-vol_.*\.nii$');         % adjust to how your images are called

if ~exist(fullfile(rootDir, 'Preproc', subName), 'dir')
    mkdir(fullfile(rootDir, 'Preproc', subName));
end

preprocDir = fullfile(rootDir, 'Preproc', subName);


%build a matlabbatch Here you can see which steps in the preprocessing are
%taken
matlabbatch{1}.cfg_basicio.file_dir.file_ops.file_move.files = {anatomyFile};
matlabbatch{1}.cfg_basicio.file_dir.file_ops.file_move.action.copyren.copyto = {epiDir};
matlabbatch{1}.cfg_basicio.file_dir.file_ops.file_move.action.copyren.patrep.pattern = 'y-vol_00001';
matlabbatch{1}.cfg_basicio.file_dir.file_ops.file_move.action.copyren.patrep.repl = 'MPRAGE';
matlabbatch{1}.cfg_basicio.file_dir.file_ops.file_move.action.copyren.unique = false;

matlabbatch{2}.spm.spatial.realign.estwrite.data = {cellstr(epiFileArray)};
matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.sep = 4;
matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.rtm = 1;
matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.interp = 2;
matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.weight = '';
matlabbatch{2}.spm.spatial.realign.estwrite.roptions.which = [0 1];
matlabbatch{2}.spm.spatial.realign.estwrite.roptions.interp = 4;
matlabbatch{2}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
matlabbatch{2}.spm.spatial.realign.estwrite.roptions.mask = 1;
matlabbatch{2}.spm.spatial.realign.estwrite.roptions.prefix = 'r';

matlabbatch{3}.spm.spatial.coreg.estimate.ref(1) = cfg_dep('Realign: Estimate & Reslice: Mean Image', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','rmean'));
matlabbatch{3}.spm.spatial.coreg.estimate.source(1) = {anatomyFile}; %cfg_dep('Move/Delete Files: Moved/Copied Files', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
matlabbatch{3}.spm.spatial.coreg.estimate.other = {''};
matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];

matlabbatch{4}.spm.spatial.normalise.estwrite.subj.vol(1) = cfg_dep('Coregister: Estimate: Coregistered Images', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','cfiles'));
matlabbatch{4}.spm.spatial.normalise.estwrite.subj.resample(1) = cfg_dep('Realign: Estimate & Reslice: Realigned Images (Sess 1)', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{1}, '.','cfiles'));
matlabbatch{4}.spm.spatial.normalise.estwrite.subj.resample(2) = cfg_dep('Realign: Estimate & Reslice: Mean Image', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','rmean'));
matlabbatch{4}.spm.spatial.normalise.estwrite.eoptions.biasreg = 0.0001;
matlabbatch{4}.spm.spatial.normalise.estwrite.eoptions.biasfwhm = 60;
matlabbatch{4}.spm.spatial.normalise.estwrite.eoptions.tpm = {tPMFile};
matlabbatch{4}.spm.spatial.normalise.estwrite.eoptions.affreg = 'mni';
matlabbatch{4}.spm.spatial.normalise.estwrite.eoptions.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{4}.spm.spatial.normalise.estwrite.eoptions.fwhm = 0;
matlabbatch{4}.spm.spatial.normalise.estwrite.eoptions.samp = 3;
matlabbatch{4}.spm.spatial.normalise.estwrite.woptions.bb = [-78 -112 -70
                                                             78 76 85];
matlabbatch{4}.spm.spatial.normalise.estwrite.woptions.vox = [2 2 2];
matlabbatch{4}.spm.spatial.normalise.estwrite.woptions.interp = 4;
matlabbatch{4}.spm.spatial.normalise.estwrite.woptions.prefix = 'w';
matlabbatch{5}.spm.spatial.normalise.write.subj.def(1) = cfg_dep('Normalise: Estimate & Write: Deformation (Subj 1)', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','def'));
matlabbatch{5}.spm.spatial.normalise.write.subj.resample(1) = cfg_dep('Coregister: Estimate: Coregistered Images', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','cfiles'));
matlabbatch{5}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                          78 76 85];
matlabbatch{5}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
matlabbatch{5}.spm.spatial.normalise.write.woptions.interp = 4;
matlabbatch{5}.spm.spatial.normalise.write.woptions.prefix = 'w';

matlabbatch{6}.spm.spatial.smooth.data(1) = cfg_dep('Normalise: Estimate & Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
matlabbatch{6}.spm.spatial.smooth.fwhm = [8 8 8];
matlabbatch{6}.spm.spatial.smooth.dtype = 0;
matlabbatch{6}.spm.spatial.smooth.im = 0;
matlabbatch{6}.spm.spatial.smooth.prefix = 's';

matlabbatch{7}.cfg_basicio.file_dir.file_ops.file_move.files(1) = cfg_dep('Realign: Estimate & Reslice: Realignment Param File (Sess 1)', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{1}, '.','rpfile'));
matlabbatch{7}.cfg_basicio.file_dir.file_ops.file_move.files(2) = cfg_dep('Realign: Estimate & Reslice: Mean Image', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','rmean'));
matlabbatch{7}.cfg_basicio.file_dir.file_ops.file_move.files(3) = cfg_dep('Coregister: Estimate: Coregistered Images', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','cfiles'));
matlabbatch{7}.cfg_basicio.file_dir.file_ops.file_move.files(4) = cfg_dep('Normalise: Estimate & Write: Deformation (Subj 1)', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','def'));
matlabbatch{7}.cfg_basicio.file_dir.file_ops.file_move.files(5) = cfg_dep('Normalise: Estimate & Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
matlabbatch{7}.cfg_basicio.file_dir.file_ops.file_move.files(6) = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
matlabbatch{7}.cfg_basicio.file_dir.file_ops.file_move.files(7) = cfg_dep('Smooth: Smoothed Images', substruct('.','val', '{}',{6}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
matlabbatch{7}.cfg_basicio.file_dir.file_ops.file_move.action.moveto = {preprocDir};
save(fullfile(preprocDir, 'preprocbatch.mat'), 'matlabbatch');

fprintf(1, 'Created matlabbatch for subject %s.\nMatlabbatch is being executed now.\n', subName);
tStart = tic;    
spm_jobman('initcfg');
spm_jobman('run', matlabbatch);
toc(tStart);

fidPreproc = fopen(fullfile(rootDir, 'Preproc', 'Logfile_Preprocessing.txt'), 'a');
fprintf(fidPreproc, '%s\t%s\tpreproc\tdone\r\n', datestr(now), subName);   %\r\n for windows OS
fprintf(1, 'Preprocessing for subject %s successful.\n', subName);

%%%%%%%%%% End of script %%%%%%%%%%