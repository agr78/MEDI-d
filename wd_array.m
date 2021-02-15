% Create wavelet decomposition array
%   [regw_array] = wd_array(x, dx)
%   Outputs an array of wavelet decomposition from wavedec3() structure
%   Computes regularization term derivative
%   Applies Hermitian conjugate waverec3
%   Specify input susceptibilty x and update dx
%    
% Alexandra G. Roberts
% MRI Lab
% Cornell University
% 02/15/2021
function regw_array = wd_array(x,dx)
 wave_size = size(x)/2;
 x_t = wavedec3(x,1,'db1');
 dx_t = wavedec3(dx,1,'db1');
 x_tweights = [zeros(size(x_t.dec{1})) zeros(size(x_t.dec{2}))...
     zeros(size(x_t.dec{3})) zeros(size(x_t.dec{4}))...
     ones(size(x_t.dec{5})) zeros(size(x_t.dec{6}))...
     zeros(size(x_t.dec{7})) zeros(size(x_t.dec{8}))];
 x_nums = cell2mat(x_t.dec);   
 dx_nums = cell2mat(dx_t.dec);
 x_array = zeros([wave_size length(x_t.dec)]);
 dx_array = x_array;
 Vrw = x_array;

 for k = 1:length(x_t.dec)
    x_array(:,:,:,k) = x_tweights(:,((k-1)*max(wave_size)+1):k*max(wave_size),:).*x_nums(((k-1)*max(wave_size)+1):k*max(wave_size),:,:);
    dx_array(:,:,:,k) = dx_nums(((k-1)*max(wave_size)+1):k*max(wave_size),:,:);
    Vrw(:,:,:,k) = 1./sqrt(abs(x_array(:,:,:,k).^2+0.00001));
    x_t.dec(k) = mat2cell(dx_array(:,:,:,k).*Vrw(:,:,:,k),max(wave_size));
 end
 regw_array = waverec3(x_t);
 
end