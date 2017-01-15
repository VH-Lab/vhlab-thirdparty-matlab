function [movieInfo, featMask] = partDetector(I, area, maxEcce, PRCTILE, VERBOSE)
% [movieInfo, featMask] = partDetector(I, area, maxEcce, PRCTILE, VERBOSE)
% I       - Cell array containg one frame per cell. Must be gray scale
% area    - 1x2 array [minArea maxArea]. Values in number of pixels. 
%           Default [100 500]
% maxEcce - Maximum eccentricity. Default 0.5
% VERBOSE - Verbose flag
% PRCTILE - Percentile to use in setting the threshold based on each
%           frame histogram. If PRCTILE>50 it finds the values above threshold,
%           else it find the values below threshold. This way it can take bright
%           spots on a dark background and the opposite. Default 95%
% movieInfo ~ Detected feature properties: movieInfo.xCoord..yCoord..amp..int. 
%             Where amp is the area and int is the maximum intensity of detected 
%             features.
% featMask  ~ Mask of the detected features. It returns a cell array of sparse
%             binary matrices. 
%
% gP 02/2013

if nargin < 2 || isempty(area)
    area = [100 500];  end
if nargin < 3 || isempty(maxEcce)
    maxEcce = 0.5;  end
if nargin < 4 || isempty(PRCTILE)
    PRCTILE = 95; end
if nargin < 5 
    VERBOSE = true; end


Nfr = length(I);
[h, w] = size(I{1});

% START DETECTION

% initialize structure to store info for tracking
[movieInfo(1:Nfr,1).xCoord] = deal([]);
[movieInfo(1:Nfr,1).yCoord] = deal([]);
[movieInfo(1:Nfr,1).amp] = deal([]);
[movieInfo(1:Nfr,1).int] = deal([]);

featMask = cell(size(I));
featMask(:) = {false(h,w)};

if VERBOSE
    progressText(0,'Detecting Peaks');
end
for iF = 1:Nfr                   % Loop though frames and filter 
                                 % Binary image with thr at half maxIntensity 
    thr = prctile(I{iF}(:), PRCTILE);
    if PRCTILE > 50
        Ii = I{iF} > thr;
    else
        Ii = I{iF} < thr;
    end
    
    featProp = regionprops( Ii, 'PixelIdxList', 'Area', 'Eccentricity');
                                % Sort through features and retain only 
                                % the "good" ones
    goodFeatIdx = vertcat(featProp(:,1).Area) > area(1) &...
                   vertcat(featProp(:,1).Area) < area(2) &...
                   vertcat(featProp(:,1).Eccentricity) < maxEcce;
%     goodFeatIdxI = find(vertcat(featProp2(:,1).MaxIntensity)>2*cutOffValueInitInt);

    % make new label matrix and get props
    featMask{iF}(vertcat(featProp(goodFeatIdx,1).PixelIdxList)) = true;
    [featMapFinal,nFeats] = bwlabel(featMask{iF});
    
    if nargout > 1                              % Fill gaps in mask
        BWedge = edge(featMask{iF}, 'sobel');
        se90 = strel('line', 2, 90);            % Dilete the image to connect
        se0 = strel('line', 2, 0);              %  gaps on the edge
        BWsdil = imdilate(BWedge, [se90 se0]);
        BWfill = imfill(BWsdil, 'holes');       % Fill interior gaps
        se = strel('disk',1);                   % Get rid of the border (1 px)
        BWeroded = imerode(BWfill,se);
        featMask{iF} = sparse(BWeroded);        % To save memory
    end
    
    featPropFinal = regionprops(featMapFinal, Ii,...
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
    movieInfo(iF,1).xCoord = xCoord;         % Can't save it as single for Khuloud's tracker
    movieInfo(iF,1).yCoord = yCoord;
    movieInfo(iF,1).amp = amp;          % amp should be intensity not area!
    movieInfo(iF,1).int = featI;

    
    if VERBOSE
        progressText(iF/Nfr,'Detecting peaks');
    end
end

