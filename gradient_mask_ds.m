function [wG_ds,Mask_ds]=gradient_mask_downsample(gradient_weighting_mode, iMag, Mask, grad, voxel_size, percentage, crop_factor)

if nargin < 6
    percentage = 0.9;
    crop_factor = 2
end
% Define and preallocate
grad = @fgrad;
[x,y,z] = size(iMag);
iMagk = fftn(iMag.*Mask);

% Crop in k-space and generate mask

iMag_ds = real(k_crop(iMag,crop_factor)); 
Mask_ds = BET(iMag_ds,size(iMag_ds),crop_factor.*voxel_size); 


% Find gradient

g = grad_kernel(size(iMag_ds), crop_factor.*voxel_size);
field_noise_level = 0.01*max(iMag_ds(:));
wG = abs(grad(iMag_ds.*(Mask_ds>0), crop_factor.*voxel_size));
denominator = sum(Mask_ds(:)==1);
numerator = sum(wG(:)>field_noise_level);

if  (numerator/denominator)>percentage
    while (numerator/denominator)>percentage
        field_noise_level = field_noise_level*1.05;
        numerator = sum(wG(:)>field_noise_level);
      end
else
    while (numerator/denominator)<percentage
        field_noise_level = field_noise_level*.95;
        numerator = sum(wG(:)>field_noise_level);
    end
end

wG_ds = (wG<=field_noise_level);

function E = grad_kernel(matrix_size,voxel_size)
[k{1}, k{2}, k{3}] = ndgrid(0:matrix_size(1)-1,...
                            0:matrix_size(2)-1,...
                            0:matrix_size(3)-1);
E = zeros([matrix_size 3]);
    for j=1:3
        E(:,:,:,j) = (1-exp(2i.*pi.*k{j}/matrix_size(j)))/voxel_size(j);
    end
end
end
