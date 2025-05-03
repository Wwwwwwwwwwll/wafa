clc;
clear;
close all;

%load the images and create MSE array
orig = imread("dogOriginal.bmp");
dist = imread("dogDistorted.bmp");
mse_values = zeros(7, 1);

%apply median filter
med1 = medfilt2(dist, [3 3]);

%fft transform and intensity graph
freq = fftshift(fft2(double(med1)));
iGraph = log(abs(freq));
imwrite( iGraph/max(iGraph(:)), "intensityGraph.png");

%loads mask image (created outside)
mask = imread("mask.png");
mask = mask(:,:,1);
mask = double((mask>0));

%applies mask and inverses fft
maskApplied = mask .* freq;
postMask = real(ifft2(ifftshift(maskApplied)));

%second median filter
med2 = medfilt2(postMask, [5, 5]);

%adjusts constrast
adjust = imadjust(uint8(med2));

%applies gaussian filter
gauss = imgaussfilt(adjust, 1.2);

% Calculate all MSE values
mse_values(1) = immse(orig, uint8(med1));
mse_values(2) = immse(orig, uint8(postMask));
mse_values(3) = immse(orig, uint8(med2));
mse_values(4) = immse(orig, uint8(adjust));
mse_values(5) = immse(orig, uint8(gauss));


% Display all the images
figure;
subplot(2,4,1);
imshow(uint8(dist));
title("Distorted Image");

subplot(2,4,2);
imshow(uint8(med1));
title("First Median Image");
xlabel(sprintf("MSE: %.2f", mse_values(1)));

subplot(2,4,3);
imshow(uint8(postMask));
title("After Mask Image");
xlabel(sprintf("MSE: %.2f", mse_values(2)));

subplot(2,4,4);
imshow(uint8(med2));
title("Second Median Image");
xlabel(sprintf("MSE: %.2f", mse_values(3)));

subplot(2,4,5);
imshow(uint8(adjust));
title("Contrast Adjust Image");
xlabel(sprintf("MSE: %.2f", mse_values(4)));

subplot(2,4,6);
imshow(uint8(gauss));
title("Gaussian Smoothed Image");
mse_values(6) = immse(orig, gauss);
xlabel(sprintf("MSE: %.2f", mse_values(5)));

subplot(2,4,7);
imshow(uint8(orig));
title("Original Image");
mse_values(7) = 0;

titleText = sprintf("Image Noise Removal: Mean Squared Error (MSE) at Each Stage\nFinal MSE: %.2f", mse_values(6));
sgtitle(titleText);
