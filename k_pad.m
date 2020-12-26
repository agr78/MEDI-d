% k-space pad
%   [z_upsampled_im] = kpad(im, pad_factor)
%   Outputs an image padded symmetrically in k-space
%   Specify dimensions by the pad factor
%   Note this zero-padding decreases pixel size but does not increase
%   resolution
% 
% Alexandra G. Roberts
% MRI Lab
% Cornell University
% 12/12/2020

function [z_upsampled_im] = k_pad(im, end_size)

n = end_size; 

im_k = center_pad(Hann_window(fftshift(fftn(im))), n);

z_upsampled_im = ifftn(ifftshift(im_k));
   
    
end