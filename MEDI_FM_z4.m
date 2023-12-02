% Morphology Enabled Dipole Inversion (MEDI)
%   [x, cost_reg_history, cost_data_history] = MEDI_L1(varargin)
%
%   output
%   x - the susceptibility distribution 
%   cost_reg_history - the cost of the regularization term
%   cost_data_history - the cost of the data fidelity term
%   
%   input
%   RDF.mat has to be in current folder.  
%   MEDI_L1('lambda',lam,...) - lam specifies the regularization parameter
%                               lam is in front of the data fidelity term
%
%   ----optional----   
%   MEDI_L1('smv', radius,...) - specify the radius for the spherical mean
%                                value operator using differential form
%   MEDI_L1('merit',...) - turn on model error reduction through iterative
%                          tuning
%   MEDI_L1('zeropad',padsize,...) - zero pad the matrix by padsize
%   MEDI_L1('lambda_CSF',lam_CSF,...) - automatic zero reference (MEDI+0)
%                                       also require Mask_CSF in RDF.mat
%
%   When using the code, please cite 
%   Z. Liu et al. MRM 2017;DOI:10.1002/mrm.26946
%   T. Liu et al. MRM 2013;69(2):467-76
%   J. Liu et al. Neuroimage 2012;59(3):2560-8.
%   T. Liu et al. MRM 2011;66(3):777-83
%   de Rochefort et al. MRM 2010;63(1):194-206
%
%   Adapted from Ildar Khalidov
%   Modified by Tian Liu on 2011.02.01
%   Modified by Tian Liu and Shuai Wang on 2011.03.15
%   Modified by Tian Liu and Shuai Wang on 2011.03.28 add voxel_size in grad and div
%   Last modified by Tian Liu on 2013.07.24
%   Last modified by Tian Liu on 2014.09.22
%   Last modified by Tian Liu on 2014.12.15
%   Last modified by Zhe Liu on 2017.11.06

function [x, cost_reg_history, cost_data_history, resultsfile] = MEDI_FM(varargin)

[lambda, ~, RDF, N_std, iMag, Mask, matrix_size, matrix_size0, voxel_size, ...
    delta_TE, CF, B0_dir, merit, smv, radius, data_weighting, gradient_weighting, ...
    Debug_Mode, lam_CSF, Mask_CSF, solver, percentage] = parse_QSM_input(varargin{:});

%%%%%%%%%%%%%%% weights definition %%%%%%%%%%%%%%
cg_max_iter = 100;
cg_tol = 0.01;
max_iter = 10;
tol_norm_ratio = 0.1;
data_weighting_mode = data_weighting;
gradient_weighting_mode = gradient_weighting;
grad = @fgrad;
div = @bdiv;
crop_factor = 2;
lam_Downsample_its = 250;
lam_ROI = 15;
% grad = @cgrad;
% div = @cdiv;
end_size = size(iMag);
N_std = N_std.*Mask;
tempn = single(N_std);
D=dipole_kernel(matrix_size, voxel_size, B0_dir);
Mask_ds = imresize3(Mask,1/crop_factor);
n_vox = voxel_size./max(voxel_size(:));
vox_min = min(voxel_size(:));
vox_max = max(voxel_size(:));
[labeledImage, numROIs] = bwlabeln(imbinarize(Mask.*N_std,'adaptive'));%bwlabeln(imbinarize(imgaussfilt3(Mask.*N_std,round(3.*vox_min)),'adaptive'));
labeledImage_Nstd = labeledImage.*imbinarize(N_std,'adaptive');

%Mask_s = Mask.*(~imbinarize(imgaussfilt3(Mask.*N_std,round(3.*vox_min)),'adaptive'));
[labeledImage_inner,nnROIs] = bwlabeln(labeledImage_Nstd == 1 ...
& MaskErode(Mask,matrix_size,voxel_size,5));
labeledImage_Nstd = labeledImage_Nstd+labeledImage_inner;
numROIs = numROIs+nnROIs;
LT_reg_ROI = {};    

disp('Loop reg call')
tic
for j = 1:numROIs
    Mask_ROI{j} = labeledImage_Nstd == j;    
%    LT_reg_ROI{j} = @(x) Mask_ROI{j}.*(x-mean(x(Mask_ROI{j})));
end
toc



if (smv)
%     S = SMV_kernel(matrix_size, voxel_size,radius);
    SphereK = single(sphere_kernel(matrix_size, voxel_size,radius));
    Mask = SMV(Mask, SphereK)>0.999;
    D=(1-SphereK).*D;
    RDF = RDF - SMV(RDF, SphereK);
    RDF = RDF.*Mask;
    tempn = sqrt(SMV(tempn.^2, SphereK)+tempn.^2);
end

m = dataterm_mask(data_weighting_mode, tempn, Mask);
b0 = m.*exp(1i*RDF);
wG = gradient_mask(gradient_weighting_mode, iMag, Mask, grad, voxel_size, percentage);
[wG_ds, Mask_ds] = gradient_mask_ds(gradient_weighting_mode, iMag, Mask, grad, voxel_size, percentage, crop_factor);

Mask_s_ds = Mask_ds.*(~imbinarize((Mask_ds.*imresize3(N_std,...
    [size(wG_ds,1) size(wG_ds,2) size(wG_ds,3)])),'adaptive'));
Mask_s_ds = imerode(Mask_s_ds,strel('cube',double(round(3*vox_min))));


for j = 1:min(size(wG_ds))
    wG_ds(:,:,:,j) = Mask_s_ds.*wG_ds(:,:,:,j);
end

%[wG_ds, Mask_ds] = gradient_mask_ds(gradient_weighting_mode, iMag, Mask, grad, voxel_size, percentage, crop_factor);
%disp('Mask hemo mode')



% CSF regularization
flag_CSF = ~isempty(Mask_CSF);
if flag_CSF
    fprintf('CSF regularization used\n');
end
oldN_std=N_std;
fprintf(['Using ' solver '\n']);
switch solver
    case 'gaussnewton'
        [x, cost_reg_history, cost_data_history] = gaussnewton();
end

    function [x, cost_reg_history, cost_data_history] = gaussnewton()
        
        if flag_CSF
            LT_reg = @(x) Mask_CSF.*(x - mean(x(Mask_CSF)));
        end
        
        iter=0;
        x = zeros(matrix_size); %real(ifftn(conj(D).*fftn((abs(m).^2).*RDF)));
        
        if (~isempty(findstr(upper(Debug_Mode),'SAVEITER')))
            store_CG_results(x/(2*pi*delta_TE*CF)*1e6.*Mask);%add by Shuai for save data
        end
        res_norm_ratio = Inf;
        cost_data_history = zeros(1,max_iter);
        cost_reg_history = zeros(1,max_iter);
        
        e=0.000001; %a very small number to avoid /0
        badpoint = zeros(matrix_size);
        Dconv = @(dx) real(ifftn(D.*fftn(dx)));
        while (res_norm_ratio>tol_norm_ratio)&&(iter<max_iter)
            tic
            iter=iter+1;
            if iter < 2
                lam_Downsample = 0;
            else
                lam_Downsample = lam_Downsample_its/2;
                %disp('Lambda hemo mode')
            end
            
            Vr = 1./sqrt(abs(wG.*grad(real(x),voxel_size)).^2+e);
            Vr_ds = 1./(sqrt(abs(wG_ds.*(grad(k_crop(real(x),crop_factor),crop_factor*voxel_size)))+e));
            w = m.*exp(1i*ifftn(D.*fftn(x)));
            reg = @(dx) div(wG.*(Vr.*(wG.*grad(real(dx),voxel_size))),voxel_size);
            
            reg_ds = @(dx) real(k_pad(div(wG_ds.*Vr_ds.*(wG_ds...
                .*grad(k_crop(real(dx),crop_factor),crop_factor*voxel_size)),...
                crop_factor*voxel_size),end_size));
            reg = @(dx) reg(dx) + lam_Downsample*reg_ds(dx);
            
            L = @(dx) LT_ROI_reg(Mask_ROI,dx,numROIs,N_std); 
 
            reg = @(dx) reg(dx)+lam_ROI.*L(dx);
            
            if flag_CSF
                reg_CSF = @(dx) lam_CSF.*LT_reg(LT_reg(real(dx)));
                reg = @(dx) reg(dx) + reg_CSF(dx);
            end
            fidelity = @(dx)Dconv(conj(w).*w.*Dconv(dx) );
            
            A =  @(dx) reg(dx) + 2*lambda*fidelity(dx);
            b = reg(x) + 2*lambda*Dconv( real(conj(w).*conj(1i).*(w-b0)) );
                      
            
            dx = real(cgsolve(A, -b, cg_tol, cg_max_iter, 0));
            res_norm_ratio = norm(dx(:))/norm(x(:));
            x = x + dx;
            
            wres=m.*exp(1i*(real(ifftn(D.*fftn(x))))) - b0;
            
            cost_data_history(iter) = norm(wres(:),2);
            cost=abs(wG.*grad(x));
            cost_reg_history(iter) = sum(cost(:));
            
            
            if merit
                wres = wres - mean(wres(Mask(:)==1));
                a = wres(Mask(:)==1);
                factor = std(abs(a))*6;
                wres = abs(wres)/factor;
                wres(wres<1) = 1;
                badpoint(wres>1)=1;
                 N_std(Mask==1) = N_std(Mask==1).*wres(Mask==1).^2;
                tempn = double(N_std);
                if (smv)
                    tempn = sqrt(SMV(tempn.^2, SphereK)+tempn.^2);
                end
                m = dataterm_mask(data_weighting_mode, tempn, Mask);
                b0 = m.*exp(1i*RDF);
            end
            
            fprintf('iter: %d; res_norm_ratio:%8.4f; cost_L2:%8.4f; cost:%8.4f.\n',iter, res_norm_ratio,cost_data_history(iter), cost_reg_history(iter));
            toc
            
            
        end
        
        
        
        %convert x to ppm
        x = x/(2*pi*delta_TE*CF)*1e6.*Mask;
        
        % Zero reference using CSF
        if flag_CSF
            x = x - mean(x(Mask_CSF));
        end
        
        if (matrix_size0)
            x = x(1:matrix_size0(1), 1:matrix_size0(2), 1:matrix_size0(3));
            iMag = iMag(1:matrix_size0(1), 1:matrix_size0(2), 1:matrix_size0(3));
            RDF = RDF(1:matrix_size0(1), 1:matrix_size0(2), 1:matrix_size0(3));
            Mask = Mask(1:matrix_size0(1), 1:matrix_size0(2), 1:matrix_size0(3));
            matrix_size = matrix_size0;
        end
        
        resultsfile = store_QSM_results(x, iMag, RDF, Mask,...
            'Norm', 'L1','Method','MEDIN','Lambda',lambda,...
            'SMV',smv,'Radius',radius,'IRLS',merit,...
            'voxel_size',voxel_size,'matrix_size',matrix_size,...
            'Data_weighting_mode',data_weighting_mode,'Gradient_weighting_mode',gradient_weighting_mode,...
            'L1_tol_ratio',tol_norm_ratio, 'Niter',iter,...
            'CG_tol',cg_tol,'CG_max_iter',cg_max_iter,...
            'B0_dir', B0_dir);
        
    end
end





              
