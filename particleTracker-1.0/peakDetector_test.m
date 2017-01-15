
I = imread('/DIskC/Data/HIV_movies/detection_test_set/sas032211beads-F.03_R3D-1.tif');
img_double = double(I)./((2^16)-1);                % Convert to double in the range 0-1
img_adj = imadjust(img_double);
figure, imshow(img_adj,[])

%%
peakDetector({I}, 16, 0, [])

%% DoG 

% sigma1 = 0.21*676/(1.4*322)
% sigma2 = sqrt(2)*5/2 
sigma1 = 1;
sigma2 = 4;
blurKernelHigh  = fspecial('gaussian', 21, sigma1);
blurKernelLow = fspecial('gaussian', 21, sigma2);
mask = ones(size(img_double));

lowPass = imfilter(img_double,blurKernelLow);
W = imfilter(mask, blurKernelLow);
lowPass = lowPass ./ W;                     % Take care of edge effects
highPass = imfilter(img_double,blurKernelHigh);
W = imfilter(mask, blurKernelHigh);
highPass = highPass ./ W;

% get difference of gaussians image
filterDiff = highPass - lowPass;
figure, imshow(imadjust(filterDiff))

%%
e = edge(filterDiff, 'canny');
figure, imshow(e);
%%
radii = 1:0.5:30;
h = circle_hough(e, radii, 'same','normalise');
stackSlider(h), axis image
hHist = h(find(h ~= 0));
figure, hist(hHist,300)

%% Find some peaks in the accumulator
% We use the neighbourhood-suppression method of peak finding to ensure
% that we find spatially separated circles. We select the 10 most prominent
% peaks, because as it happens we can see that there are 10 coins to find.

peaks = circle_houghpeaks(h, radii, 'nhoodxy', 3, 'nhoodr', 3, 'Threshold',4.7);

%% Look at the results
% We draw the circles found on the image, using both the positions and the
% radii stored in the |peaks| array. The |circlepoints| function is
% convenient for this - it is also used by |circle_hough| so comes with it.
figure,
imshow(img_adj);
hold on;
for peak = peaks
    [x, y] = circlepoints(peak(3));
    plot(x+peak(1), y+peak(2), 'g-');
end
hold off

%% CircularHough_Grd() test
rawimg = img_double;

[accum, circen, cirrad] = CircularHough_Grd(rawimg, [1 30], 0.05);


figure; imagesc(accum); axis image off;
title('Accumulation Array from Circular Hough Transform');

figure; imagesc(img_adj); colormap(gray); axis image off;
hold on;
plot(circen(:,1), circen(:,2), 'r+');
for k = 1 : size(circen, 1),
    DrawCircle(circen(k,1), circen(k,2), cirrad(k), 32, 'b-');
end
