% Center crop
%   [cropped_im] = centercrop(im, crop_factor)
%   Outputs an image cropped from the center of the input image
%   Specify dimensions by the crop factor
%   Hermitian operator of center_pad() function
% 
% Alexandra G. Roberts
% MRI Lab
% Cornell University
% 12/11/2020

function [cropped_im] = centercrop(im, crop_factor)

n = crop_factor;
    
    
    if numel(size(im)) == 2
        [x y] = size(im);
        mx = round(x/2); my = round(y/2);
        cropped_im = im((mx-round((1/(2*n))*x)+1):(mx+round((1/(2*n))*x)),(my-round((1/(2*n)*y))+1):(my+(round(1/(2*n)*y))));
    end
    
     if numel(size(im)) == 3
        [x y z] = size(im);
        mx = round(x/2); my = round(y/2); mz = round(z/2);
        cropped_im = im((mx-round((1/(2*n))*x)+1):(mx+round((1/(2*n))*x)),(my-round((1/(2*n)*y))+1):(my+(round(1/(2*n)*y))),(mz-round((1/(2*n)*z))+1):(mz+(round(1/(2*n)*z))));
        % why does the striping occur in the below line???
        %cropped_im = im((mx-round((1/(2*n))*x)):(mx+round((1/(2*n))*x)-1),(my-round((1/(2*n)*y))):(my+(round(1/(2*n)*y))-1),(mz-round((1/(2*n)*z))):(mz+(round(1/(2*n)*z))-1));
     end
    
    if numel(size(im)) == 4
        [w x y z] = size(im);
        mw = round(w/2); mx = round(x/2); my = round(y/2); mz = round(z/2);
        cropped_im = im((mw-round(1/(2*n)*w)):(mw+round(1/(2*n)*w)-1),(mx-round(1/(2*n)*x)):(mx+round(1/(2*n)*x)-1),(my-round(1/(2*n)*y)):(my+round(1/(2*n)*y)-1),:);%,(mz-round(1/(2*n)*z)):(mz+round(1/(2*n)*z)-1));
        
    end
    

 end