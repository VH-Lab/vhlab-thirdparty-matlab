% [frameInfo imgDenoised] = detectSpotsWT(img, S, dthreshold, postProcLevel)
%
% Performs detection of local intensity clusters through a combination of 
% multiscale products and denoising by iterative filtering from
% significant coefficients:
% Olivo-Marin, "Extraction of spots in biological images using multiscale products," Pattern Recoginition 35, pp. 1989-1996, 2002.
% Starck et al., "Image Processing and Data Analysis," Section 2.3.4, p. 73
%
% INPUTS:   img             : input image (2D array)
%           {S}             : postprocessing level.
%           {dthreshold}    : minimum allowed distance of secondary maxima in large clusters
%           {postProcLevel} : morphological post processing level for mask 

% Parts of this function are based on code by Henry Jaqaman.
% Francois Aguet, March 2010

function [frameInfo imgDenoised] = spotDetector(img, S, dthreshold, postProcLevel)

if nargin<2
    S = 4;
end
if nargin<3
    dthreshold = 5;
end
if nargin<4
    postProcLevel = 1;
end


maxI = max(img(:));
minI = min(img(:));
[ny nx] = size(img);

%===================================================
% Iterative filtering from significant coefficients
%===================================================
imgDenoised = significantCoefficientDenoising(img, S);


res = img - imgDenoised; % residuals
sigma_res0 = std(res(:));

delta = 1;
while delta > 0.002
    resDenoised = significantCoefficientDenoising(res, S);
    imgDenoised = imgDenoised + resDenoised; % add significant residuals
    res = img - imgDenoised;
    sigma_res1 = std(res(:));
    delta = abs(sigma_res0/sigma_res1 - 1);
    sigma_res0 = sigma_res1;
end

%===================================================
% Multiscale product of wavelet coefficients
%===================================================
% The support of the objects is given by the multiscale product in the wavelet domain.
W = awt(imgDenoised, S);
imgMSP = abs(prod(W(:,:,1:S),3));


%===================================================
% Binary mask
%===================================================
% Establish thresholds
[imAvg imStd] = localAvgStd2D(imgDenoised, 9);

mask = zeros(ny,nx);
mask((imgDenoised >= imAvg+0.5*imStd) & (imgDenoised.*imgMSP >= mean(imgDenoised(:)))) = 1;


% Morphological postprocessing
mask = bwmorph(mask, 'clean'); % remove isolated pixels
mask = bwmorph(mask, 'fill'); % fill isolated holes
mask = bwmorph(mask, 'thicken');
mask = bwmorph(mask, 'spur'); % remove single pixels 8-attached to clusters
mask = bwmorph(mask, 'spur');
mask = bwmorph(mask, 'clean');

if postProcLevel >= 1
    mask = bwmorph(mask, 'erode');
    if postProcLevel == 2
        mask = bwmorph(mask, 'spur');
    end
    mask = bwmorph(mask, 'clean');
    mask = bwmorph(mask, 'thicken');
end


% rescale denoised image
imgDenoised = (imgDenoised-min(imgDenoised(:))) * (maxI-minI) / (max(imgDenoised(:))-min(imgDenoised(:)));

imgDenoised = mask.*imgDenoised;
localMax = locmax2d(imgDenoised, [9 9]);

%===================================================
% Process connected components
%===================================================
[labels, nComp] = bwlabel(mask, 8);

area = zeros(nComp, 1);
totalInt = zeros(nComp, 1);
nMaxima = zeros(nComp, 1);
xmax = zeros(nComp, 1);
ymax = zeros(nComp, 1);
xcom = zeros(nComp, 1);
ycom = zeros(nComp, 1);
labelVect = zeros(nComp, 1);

xmax2 = cell(nComp, 1);
ymax2 = cell(nComp, 1);
area2 = cell(nComp, 1);
totalInt2 = cell(nComp, 1);
labelVect2 = cell(nComp, 1);

% Compute area and center of mass for each component
stats = regionprops(labels, imgDenoised, 'Area', 'WeightedCentroid', 'PixelIdxList');

% component labels of local maxima
maxLabels = labels .* (labels & localMax>0);
maxCoords(1:nComp) = struct('PixelIdxList', []);
mc = regionprops(maxLabels, 'PixelIdxList');
maxCoords(1:length(mc)) = deal(mc);


for n = 1:nComp
    %[yi,xi] = find(labels == n); % coordinates of nth component
    [yi,xi] = ind2sub([ny nx], stats(n).PixelIdxList);
    [ym,xm] = ind2sub([ny nx], maxCoords(n).PixelIdxList);
    area(n) = stats(n).Area;
    com = stats(n).WeightedCentroid;
    xcom(n) = com(1);
    ycom(n) = com(2);
    
    values = imgDenoised(stats(n).PixelIdxList);
    totalInt(n) = sum(values);
    
    nMaxima(n) = length(xm);
    if nMaxima(n)==1
        xmax(n) = xm;
        ymax(n) = ym;
        nMaxima(n) = 1;
        labelVect(n) = labels(ym,xm);
    elseif nMaxima(n)==0 % no maximum was detected for this cluster
        maxValueIdx = find(values == max(values));
        xmax(n) = xi(maxValueIdx(1));
        ymax(n) = yi(maxValueIdx(1));
        nMaxima(n) = 1;
        labelVect(n) = labels(ymax(n), xmax(n));
    else % resolve multiple maxima cases
        maxValues = localMax(sub2ind(size(localMax), ym, xm)); % highest local max
        maxIdx = find(maxValues == max(maxValues));
        xmax(n) = xm(maxIdx(1));
        ymax(n) = ym(maxIdx(1));
        labelVect(n) = labels(ymax(n), xmax(n));
        
        % remove highest max from list
        xm(maxIdx(1)) = [];
        ym(maxIdx(1)) = [];
        
        % compute distance of secondary maxima to primary
        dist2max = sqrt((xmax(n)-xm).^2 + (ymax(n)-ym).^2);
        dist2com = sqrt((xcom(n)-xm).^2 + (ycom(n)-ym).^2);
        mindist = min(dist2max,dist2com);
        
        % retain secondary maxima where mindist > threshold
        idx2 = find(mindist > dthreshold);
        if ~isempty(idx2)
            xmax2{n} = xm(idx2);
            ymax2{n} = ym(idx2);
            nSecMax = length(idx2);
            nMaxima(n) = nSecMax+1;
            
            % split area
            area2{n} = area(n)*ones(nSecMax,1)/nMaxima(n);
            area(n) = area(n)/nMaxima(n);
            labelVect2{n} = labels(sub2ind(size(labels), ymax2{n}, xmax2{n}));
            
            %intensity values
            totalInt2{n} = totalInt(n)*ones(nSecMax,1)/nMaxima(n);
            totalInt(n) = totalInt(n)/nMaxima(n);
        end
    end
end

xmax2 =  vertcat(xmax2{:});
ymax2 = vertcat(ymax2{:});
totalInt2 = vertcat(totalInt2{:});
area2 = vertcat(area2{:});
labelVect2 = vertcat(labelVect2{:});

% assign results to output structure
frameInfo.xmax = [xmax; xmax2(:)];
frameInfo.ymax = [ymax; ymax2(:)];
frameInfo.xcom = [xcom; xmax2(:)];
frameInfo.ycom = [ycom; ymax2(:)];
frameInfo.totalInt = [totalInt; totalInt2(:)];
frameInfo.area = [area; area2(:)];

frameInfo.nMaxima = nMaxima; % maxima per component
frameInfo.labels = [labelVect; labelVect2(:)];
frameInfo.nComp = nComp;

frameInfo.maxI = maxI;
frameInfo.minI = minI;


% prepare fields for tracker
nObj = length(frameInfo.xmax);
frameInfo.amp = zeros(nObj,2);
frameInfo.xCoord = zeros(nObj,2);
frameInfo.yCoord = zeros(nObj,2);

frameInfo.amp(:,1) = frameInfo.totalInt;
frameInfo.xCoord(:,1) = frameInfo.xcom;
frameInfo.yCoord(:,1) = frameInfo.ycom;

frameInfo.path = [];
frameInfo.maskPath = [];




%=======================
% Subfunctions
%=======================
function result = significantCoefficientDenoising(img, S)
mask = zeros(size(img));
result = zeros(size(img));
W = awt(img, S);
for s = 1:S
    tmp = W(:,:,s);
    mask(abs(tmp) >= 3*std(tmp(:))) = 1;
    result = result + tmp.*mask;
end