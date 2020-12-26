% k-space crop
%   [downsampled_im] = kcrop(im, crop_factor)
%   Outputs a downsampled image by cropping from the center of k-space
%   Specify downsampling by the crop factor
%    
% Alexandra G. Roberts
% MRI Lab
% Cornell University
% 12/12/2020

function [downsampled_im] = kcrop(im, crop_factor)


n = crop_factor;
    
im_k = center_crop(fftshift(fftn(im)), n);

downsampled_im = ifftn(ifftshift(Hann_window(im_k)));

end