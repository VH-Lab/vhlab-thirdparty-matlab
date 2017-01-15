function movieInfo = peakDetector(I, bitDepth, minDiam, maxEcce, VERBOSE)
% movieInfo = peakDetector(I, bitDepth, minDiam, maxEcce, VERBOSE)
%
% I        - Image stack, cell array with one frame per array
% bitDepth - Bit depth of the images - should be 12, 14, or 16
% minDiam  - Minimum diameter of the spots to accept. Meausured in pixels, 
%            assuming a circular object. Default 2
% maxEcce  - Maximum eccentricity of the spots to accept. 0 is a perfect circle,
%            1 is a line. Default 0.8
% VERBOSE  - Verbose option. Default true
%
% OUTPUT movieInfo - nFrames-structure containing x/y coordinates
%


% get bit depth if not given
if nargin < 2 || isempty(bitDepth)
    bitDepth = 16;
end

if nargin < 3 || isempty(minDiam)
    minDiam = 2;
end

if nargin < 4 || isempty(maxEcce)
    maxEcce = 0.8;
end

if nargin < 5 
    VERBOSE = true;
end

Nfr = length(I);
[Nr,Nc] = size(I{1});
maxIntensity = max(I{1}(:));

% check bit depth to make sure it is 12, 14, or 16 and that its dynamic
% range is not greater than the provided bitDepth
if sum(bitDepth==[8 12 14 16])~=1 || maxIntensity > 2^bitDepth-1
    error('--peakDetector: bit depth should be 12, 14, or 16');
end

% START DETECTION

% initialize structure to store info for tracking
[movieInfo(1:Nfr,1).xCoord] = deal([]);
[movieInfo(1:Nfr,1).yCoord] = deal([]);
[movieInfo(1:Nfr,1).amp] = deal([]);
[movieInfo(1:Nfr,1).int] = deal([]);

% create kernels for gauss filtering 
% sigma1 = 0.21*lambda/(NA*Pxy). Should be the std of the microscope PSF
% sigma2 depends on the average size of the the spot. Check supplementary
% info for these parameteres.

blurKernelLow = fspecial('gaussian', 21, 4);
blurKernelHigh  = fspecial('gaussian', 21, 1);
mask = ones(size(I{1}));
lowPassMask = imfilter(mask, blurKernelLow);
highPassMask = imfilter(mask, blurKernelHigh);

if VERBOSE
    progressText(0,'Detecting Peaks');
end
for i = 1:Nfr                   % Loop though frames and filter 

    img = double(I{i})./(2^bitDepth-1);     % Normalize to 0-1

    
    lowPass = imfilter(img, blurKernelLow) ./ lowPassMask;      % Gets rido of 
    highPass = imfilter(img, blurKernelHigh) ./ highPassMask;   %  edge effects

    % get difference of gaussians image
    filterDiff = highPass - lowPass;

    stdFr = std(filterDiff(:));       % STD of the cell area controls the 
                                      % thresh step size
    % thickness of intensity slices is average std from filterDiffs over
    % from one frame before to one frame after. In their technical report
    % they say they average the std over i-2 <= i <= i+2. If I didn't use
    % averaging I could stop writing fiterDiff to disk and run the whole
    % analysis for every frame. 
    
    thresh = 3*stdFr;                    
    
    % we assume each step size down the intensity profile should be on
    % the order of the size of the background std; here we find how many
    % steps we need and what their spacing should be. we also assume peaks
    % should be taller than 3*std
    nSteps = round((nanmax(filterDiff(:))-thresh)/stdFr);
    threshList = linspace(nanmax(filterDiff(:)),thresh,nSteps);
    slice2 = zeros(size(img));              % In case it doesn't detect anything
    
    % compare features in z-slices startest from the highest one
    for p = 1:length(threshList)-1

        % slice1 is top slice; slice2 is next slice down
        % here we generate BW masks of slices
        if p==1
            slice1 = filterDiff > threshList(p);
        else
            slice1 = slice2;
        end
        slice2 = filterDiff > threshList(p+1);

        % now we label them
        featMap1 = bwlabel(slice1);
        featMap2 = bwlabel(slice2);
        featProp2 = regionprops(featMap2,'PixelIdxList');

        % loop thru slice2 features and replace them if there are 2 or
        % more features from slice1 that contribute
        for iFeat = 1:max(featMap2(:))
            pixIdx = featProp2(iFeat,1).PixelIdxList; % pixel indices from slice2
            featIdx = unique(featMap1(pixIdx)); % feature indices from slice1 using same pixels
            featIdx(featIdx==0) = []; % 0's shouldn't count since not feature
            if length(featIdx)>1 % if two or more features contribute...
                slice2(pixIdx) = slice1(pixIdx); % replace slice2 pixels with slice1 values
            end
        end

    end

    % label slice2 again and get region properties
    featMap2 = bwlabel(slice2);
    featProp2 = regionprops(featMap2,...
        'PixelIdxList','EquivDiameter','Eccentricity');

    % here we sort through features and retain only the "good" ones
    % we assume the good features have area > 2 pixels, and are circular
    % hence eccentricity > 0.8
    goodFeatIdxD = vertcat(featProp2(:,1).EquivDiameter) > minDiam;
    goodFeatIdxE = vertcat(featProp2(:,1).Eccentricity) < maxEcce;
%     goodFeatIdxI = find(vertcat(featProp2(:,1).MaxIntensity)>2*cutOffValueInitInt);
    goodFeatIdx = goodFeatIdxD & goodFeatIdxE;


    % make new label matrix and get props
    featureMap = zeros(Nr,Nc);
    featureMap(vertcat(featProp2(goodFeatIdx,1).PixelIdxList)) = 1;
    [featMapFinal,nFeats] = bwlabel(featureMap);
    
    featPropFinal = regionprops(featMapFinal,filterDiff,...
        'PixelIdxList','Area','WeightedCentroid','MaxIntensity'); %'Extrema'

    if nFeats==0
        yCoord = [];
        xCoord = [];
        amp = [];
        featI = [];
        
    else
        % centroid coordinates with 0.5 uncertainties for Khuloud's tracker
        yCoord = 0.5*ones(nFeats,2);
        xCoord = 0.5*ones(nFeats,2);
        temp = vertcat(featPropFinal.WeightedCentroid);
        yCoord(:,1) = temp(:,2);
        xCoord(:,1) = temp(:,1);

        % area
        featArea = vertcat(featPropFinal(:,1).Area);
        amp = zeros(nFeats,2);
        amp(:,1) = featArea;

        % intensity
        featInt = vertcat(featPropFinal(:,1).MaxIntensity);
        featI = zeros(nFeats,2);
        featI(:,1) = featInt;
    end

    % make structure compatible with Khuloud's tracker
    movieInfo(i,1).xCoord = xCoord;  	% Can't save it as single for Khuloud's tracker
    movieInfo(i,1).yCoord = yCoord;
    movieInfo(i,1).amp = amp;           % amp should be intensity not area!
    movieInfo(i,1).int = featI;

    
    if VERBOSE
        progressText(i/Nfr,'Detecting peaks');
    end
end

