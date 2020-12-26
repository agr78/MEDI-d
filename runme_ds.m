% Clear workspace
clear;
clc;

% Set path
MEDI_set_path

% STEP 1: Import data
[iField, voxel_size, matrix_size, CF,delta_TE, TE, B0_dir, files]=Read_DICOM('AXL_QSM');

% Generate the magnitude image 
iMag = squeeze(sqrt(sum(abs(iField).^2,4)));

% Provide a Mask here if possible
if (~exist('Mask','var'))                     
    %Mask = genMask(iField, voxel_size);
    Mask = BET(iMag, matrix_size, voxel_size);
end

% Provide a noise_level here if possible 
if (~exist('noise_level','var'))
    noise_level = calfieldnoise(iField, Mask);
end

% Normalize signal intensity by noise to get SNR 
iField = iField/noise_level;


% STEP 2a: Field Map Estimation
% Estimate the frequency offset in each of the voxel using a complex fitting 
[iFreq_raw N_std] = Fit_ppm_complex(iField);

% STEP 2b: Spatial phase unwrapping %%%%
iFreq = unwrapPhase(iMag, iFreq_raw, matrix_size);

% STEP 2c: Background Field Removal
% Background field removal 
[RDF shim] = PDF(iFreq,N_std,Mask,matrix_size,voxel_size,B0_dir,0,100);

% CSF Mask for zero referencing
R2s = arlo(TE,abs(iField));
Mask_CSF = extract_CSF(R2s,Mask,voxel_size);

% STEP 3: Dipole Inversion
save RDF.mat RDF iFreq iFreq_raw iMag N_std Mask matrix_size...
     voxel_size delta_TE CF B0_dir Mask_CSF;

%%
% Run MEDI 
clc

QSM_ds = MEDI_d('filename', 'RDF.mat','lambda', 1000, 'merit', 'lam_Downsample', 1000, 'crop_factor', 4);
% Save to DICOM, ignore warnings...
Write_DICOM(QSM_ds,files,'QSM')

vis(QSM_ds)
Data = sprintf('GE_MEDI_d_%s.mat', datestr(now,'mm-dd-yyyy HH-MM'))


