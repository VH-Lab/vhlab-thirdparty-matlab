function batchTrack(pathList, detParam, trackParam, VERBOSE, OVERWRITE)
% batchTrack(pathList, detParam, trackParam, VERBOSE, OVERWRITE)
% pathList   - Path list to the movies to proccess. Same format as the
%              uipickfiles() output. If no input it will prompt to select movies.
% detParam   - Has the fields:
%               bitDepth - Image bit depth. Default 16
%               pxSize - Pixel size. Default 0.322 um (HIV movies)
%               DT - Time between frames. Default 0.15 seconds (HIV movies)
% trackParam - Has the fields required for u-track
% VERBOSE    - Verbose output, only affects the u-track program. Default false 
% OVERWRITE  - Overwrite track folder if it exists, otherwise skipt it. Default
%              false
%
% Outputs ~ It saves the following files to each movie folder:
%           Trajectories.png - Image of the tracks
%           tracksFinal.mat  - Containing tracksFinal, im, Tr_parameters, DA and
%                              DAmean
%           T.mat            - Containing T, DT, pxSize
%
% File tools and u-track_peakDetector have to be on the path. 
% Saves results to /tracks on the folder on which the movies are
%
% TODO: Solve memory issue. Memory grows with each iteration until it crashes,
% everything points to a leakage in the java memory. 
% 
% gP 10/31/2012

if nargin < 1 || isempty(pathList)      % If didn't provide pathList prompt to select it
    pathList = uipickfiles('Prompt','Select *.dv movies');
    VERBOSE = true;
end

if nargin < 2 || isempty(detParam)
    detParam.bitDepth = 16;
    detParam.pxSize = 0.322;                     % In um/px
    detParam.DT = 0.15;                          % In seconds
end

if nargin < 3 || isempty(trackParam)
    error('Need to input track parameters')
end

if nargin < 4 || isempty(VERBOSE)
    VERBOSE = false;
end

if nargin < 5 || isempty(OVERWRITE)
    OVERWRITE = false;
end

PWD = pwd;
MOVPATH = fileparts(pathList{1});
TRACKSPATH = [MOVPATH '/../tracks'];    % One level below movies

if isdir(TRACKSPATH)
    cd(TRACKSPATH)
else
    mkdir(TRACKSPATH)
    cd(TRACKSPATH)
end

%% Cycle through movies 
if VERBOSE
    tic;
end

parfor iM=1:length(pathList);              % Go through movies
    
    cd(TRACKSPATH)
    [~, movName] = fileparts(pathList{iM});
    
    if ~OVERWRITE
        if isdir(movName)                   % If folder exist skip it
            disp(['Folder ' movName ' already exists, skipping...'])
            continue
        else
            mkdir(movName)
            cd(movName)
        end
    else
        if isdir(movName)                   % If folder exist overwrite tracks
            cd(movName)
        else
            mkdir(movName)
            cd(movName)
        end
    end
    
    fprintf(['\n--------Processing movie ' movName '--------\n\n'])

    data = bfopen(pathList{iM});          	% Load data 
    I = data{1}(:,1);
                                            % Detection     
    movieInfo = peakDetector(I, detParam.bitDepth, detParam.area,...
        detParam.ecce, VERBOSE);
                                            % Tracking function call
    tracksFinal = trackCloseGapsKalmanSparse(movieInfo,...
        trackParam.costMatrices, trackParam.gapCloseParam,...
        trackParam.kalmanFunctions, trackParam.probDim,...
        trackParam.saveResults, VERBOSE);
    
% -----------------------Analysis---------------------------------
                                            
    T = tracks2cellT(tracksFinal);           
%     T_msd = msdAtTau(T, 3, detParam.DT, detParam.pxSize);     % Only need 3 pts for diffCoeff2
%     [D, alpha] = diffCoeff2(T_msd, 2);
%     DA = [D', alpha'];
%     DAmean = nanmean(DA, 1);
    
% -----------------------Save Results------------------------------

    if isempty(tracksFinal)                 % If no tracks
        disp('No tracks detected to plot...');
        continue
    end
                                            % Plot trajectories
    im = I{1};
    htracks = figure('Visible','off');
    imagesc(imadjust(im));  axis image off;  colormap(gray(256))
    plotTracks2D(tracksFinal, [], '3', [], 0, 0, [], [], 0);
    title(movName, 'Interpreter', 'none','FontSize',16)
    print(htracks,'-dpng','-r200','Trajectories.png');
    close(htracks)
                                        % Save parameters
    Tr_parameters = {['Maximum gap length: ', num2str(trackParam.gapCloseParam.timeWindow)];...
           ['Minimum track segment length: ', num2str(trackParam.gapCloseParam.minTrackLen)]};

    parsave('tracksFinal.mat', tracksFinal, im, Tr_parameters)

    DT = detParam.DT;
    if isscalar(detParam.pxSize)
        pxSize = detParam.pxSize;
    else                                % If variable pixelSize
        pxSize = detParam.pxSize(iM);
    end
    parsave('T.mat', T, DT, pxSize)
                                            % Save to ascii
%     parsave('D_and_alpha.txt', DA, '-ascii')
%     parsave('mean_D_and_A.txt',DAmean, '-ascii')
%     saveASCII(tracksFinal)
    
end

if VERBOSE
    toc
end

cd(PWD)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function saveASCII(tracksFinal)
% Save tracksFinal in Gianguido format
T = tracks2cellT(tracksFinal);      % Gaps are not interpolated.
for i=1:length(T)
    Tfilename = 'tracks.txt';
    M = [i*ones(length(T{i}),1) - 1, T{i}];
    
    if (exist(Tfilename,'file') ~= 2)
        dlmwrite(Tfilename, M, 'delimiter', '\t','precision', 6)
    elseif (exist(Tfilename,'file') == 2)
        dlmwrite(Tfilename, M,'-append','delimiter', '\t','precision', 6)
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function msd = msdAtTau(T, tauAna, DT, pxSize)
% tauAna - Tau at which MSD is calculated. In frames
% DT     - Time interval, in seconds
% pxSize - Pixel size in um

Nt = length(T);                             % Number of walkers
msd = cell(1,Nt);

for i = 1:Nt
    Np = size(T{i},1);
    msd{i} = zeros(tauAna,2);
    
    for dt = 1:tauAna                     % Time interval (Dt)
        
        lag = 1:(Np-dt);                    % Shift
                                            % Average of all shifted time windows of length dt
        meanRsq = mean(sum((T{i}(lag+dt,:) - T{i}(lag,:)).^2, 2));
        
        msd{i}(dt+1,1) = dt*DT;             % dt+1 to make first point cero
        msd{i}(dt+1,2) = pxSize^2*meanRsq;  
    end
end


