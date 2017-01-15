% EL ERROR PARECE VENIR DEL JAVA VM. PUEDO USAR MATLAB SIN JAVA PERO IMSHOW LO NECESITA

addpath('~/Documents/MATLAB/file_tools/',...
    genpath('~/Documents/MATLAB/u-track_peakDetector'))

VERBOSE = true;

%% Detection parameters 

detParam.bitDepth = 16;
detParam.pxSize = 0.322;                % In um/px
detParam.DT = 0.15;                     % In seconds
detParam.area = 2;                      % Minimum area
detParam.ecce = 0.8;                    % Maximum eccentricity

%% Tracking parameters

% General tracking parameters

    % Gap closing time window. Depends on SNR and fluorophore blinking. Critical
    %  if too small or too large. Robust in proper range (default 10 frames)
trackParam.gapCloseParam.timeWindow = 6;
    % Flag for merging and splitting
trackParam.gapCloseParam.mergeSplit = 0;

    % Minimum track segment length used in the gap closing, merging and
    %  splitting step. Excludes short tracks from participatin in the gap
    %  closing, mergin and splitting step.
trackParam.gapCloseParam.minTrackLen = 3;

    % Time window diagnostics: 1 to plot a histogram of gap lengths in
    %  the end of tracking, 0 or empty otherwise
trackParam.gapCloseParam.diagnostics = 0;

% Cost functions

    % Frame-to-frame linking
trackParam.costMatrices(1).funcName = 'costMatRandomDirectedSwitchingMotionLink';
    % Gap closing, merging and splitting
trackParam.costMatrices(2).funcName = 'costMatRandomDirectedSwitchingMotionCloseGaps';

    % Kalman filter functions
    % Memory reservation
trackParam.kalmanFunctions.reserveMem = 'kalmanResMemLM';
    % Filter initialization
trackParam.kalmanFunctions.initialize = 'kalmanInitLinearMotion';
    % Gain calculation based on linking history
trackParam.kalmanFunctions.calcGain = 'kalmanGainLinearMotion';
    % Time reversal for second and third rounds of linking
trackParam.kalmanFunctions.timeReverse = 'kalmanReverseLinearMotion';

% Cost function specific parameters: Frame-to-frame linking

    % Flag for motion model, 0 for only random motion;
    %                        1 for random + directed motion;
    %                        2 for random + directed motion with the
    % possibility of instantaneous switching to opposite direction (but 
    % same speed),i.e. something like 1D diffusion.
parameters.linearMotion = 2;
    % Search radius lower limit
parameters.minSearchRadius = 2;
    % Search radius upper limit
parameters.maxSearchRadius = 5;
    % Standard deviation multiplication factor -> default is 3 INFLUYE MUCHO
parameters.brownStdMult = 3;
    % Flag for using local density in search radius estimation
parameters.useLocalDensity = 1;
    % Number of past frames used in nearest neighbor calculation
parameters.nnWindow = trackParam.gapCloseParam.timeWindow;

    % Optional input for diagnostics: To plot the histogram of linking distances
    %  up to certain frames. For example, if parameters.diagnostics = [2 35],
    %  then the histogram of linking distance between frames 1 and 2 will be
    %  plotted, as well as the overall histogram of linking distance for frames
    %  1->2, 2->3, ..., 34->35. The histogram can be plotted at any frame except
    %  for the first and last frame of a movie.
    % To not plot, enter 0 or empty
trackParam.parameters.diagnostics = [];

    % Store parameters for function call
trackParam.costMatrices(1).parameters = parameters;
clear parameters

% Cost function specific parameters: Gap closing, merging and splitting

    % Same parameters as for the frame-to-frame linking cost function
parameters.linearMotion = trackParam.costMatrices(1).parameters.linearMotion;
parameters.useLocalDensity = trackParam.costMatrices(1).parameters.useLocalDensity;
parameters.maxSearchRadius = trackParam.costMatrices(1).parameters.maxSearchRadius;
parameters.minSearchRadius = trackParam.costMatrices(1).parameters.minSearchRadius;
parameters.brownStdMult = trackParam.costMatrices(1).parameters.brownStdMult*...
    ones(trackParam.gapCloseParam.timeWindow,1);
parameters.nnWindow = trackParam.costMatrices(1).parameters.nnWindow;

    % Formula for scaling the Brownian search radius with time.
    % Power for scaling the Brownian search radius with 
    %  time, before and after timeReachConfB (next parameter).     
parameters.brownScaling = [0.5 0.01]; 
    % Before timeReachConfB, the search radius grows with time with the power in 
    %  brownScaling(1); after timeReachConfB it grows with the power in brownScaling(2).
parameters.timeReachConfB = 4; 

    % Amplitude ratio lower and upper limits
parameters.ampRatioLimit = [0.7 4];
    % Minimum length (frames) for track segment analysis
parameters.lenForClassify = 5;
    % Standard deviation multiplication factor along preferred direction of
    %  motion -> default 3
parameters.linStdMult = 3*ones(trackParam.gapCloseParam.timeWindow,1);

    % Formula for scaling the linear search radius with time.
parameters.linScaling = [0.5 0.01]; %power for scaling the linear search radius with time (similar to brownScaling).
parameters.timeReachConfL = trackParam.gapCloseParam.timeWindow;
    % Maximum angle between the directions of motion of two linear track
    %  segments that are allowed to get linked ->Default 30 creo que no esta
    %  implementado, no hace un sorete al menos.
parameters.maxAngleVV = 35;

    % Gap length penalty (disappearing for n frames gets a penalty of gapPenalty^n)
    % Note that a penalty = 1 implies no penalty, while a penalty < 1 implies
    %  that longer gaps are favored 
parameters.gapPenalty = 1.5;

    % Resolution limit in pixels, to be used in calculating the merge/split search radius
    % Generally, this is the Airy disk radius, but it can be smaller when
    %  iterative Gaussian mixture-model fitting is used for detection
parameters.resLimit = 3.4;

    % Store parameters for function call
trackParam.costMatrices(2).parameters = parameters;
clear parameters

% Additional input

trackParam.saveResults.dir = pwd;                          % save results to current folder 
trackParam.saveResults.filename = 'TrackingParam.mat';     % name of file where input and output are saved
trackParam.saveResults = 0;                                % don't save results

trackParam.probDim = 2;                                    % Problem dimension

%% Run script

pathList = uipickfiles('Prompt','Select *.dv movies');
batchTrack(pathList, detParam, trackParam, VERBOSE);
