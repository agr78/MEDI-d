% Center pad
%   [padded_im] = centerpad(im, end_size)
%   Outputs an image padded symmetrically around the input image
%   Specify dimensions by the end size
%   Hermitian operator of center_crop() function
% 
% Alexandra G. Roberts
% MRI Lab
% Cornell University
% 12/11/2020

function [padded_im] = center_pad(im, end_size)
m = size(im);

for j = 1:numel(end_size)
    n(j) = end_size(j);
end

padded_im = padarray(im, (n-m)./2, 'both');  
    
end