function x_out = LT_ROI_reg(Mask_ROI,x,numROIs,N_std)
nu = zeros(1,numROIs);
Mask_ROI_wmap = Mask_ROI;
for j = 1:numROIs
    if x(Mask_ROI{j}) ~= 0
        nu(j) = sum(sum(sum(Mask_ROI{j}.*N_std)));
        x = x-mean(x(Mask_ROI{j}));
        x = nu(j).*Mask_ROI{j}.*(x-mean(x(Mask_ROI{j})));
        Mask_ROI_wmap{j} = nu(j);
        %m{j} = mean(x(Mask_ROI{j})>0);
    else
        %x{j} = x;
        %m{j} = 0;
    end
end
%xL = xL-m;
x_out = x;%sum(cat(4,x{:}),4);

end
