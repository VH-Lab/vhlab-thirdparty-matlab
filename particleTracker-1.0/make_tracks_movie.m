%OVERLAYTRACKSMOVIENEW overlays tracks obtained via trackCloseGapsKalman on movies with 
% variable color-coding schemes
%
%SYNPOSIS overlayTracksMovieNew(tracksFinal, startend, dragtailLength,...
%     saveMovie, movieName, filterSigma, classifyGaps, highlightES,...
%     showRaw, imageRange, onlyTracks, classifyLft, diffAnalysisRes,...
%     intensityScale, colorTracks, firstImageFile, dir2saveMovie,...
%     minLength, plotFullScreen, movieType, DT)
%
%INPUT  tracksFinal   : Output of trackCloseGapsKalman.
%       startend      : Row vector indicating first and last frame to
%                       include in movie. Format: [startframe endframe].
%                       Optional. Default: [(first frame with tracks) (last frame with tracks)]
%       dragtailLength: Length of drag tail (in frames).
%                       Optional. Default: 10 frames.
%                       ** If dragtailLength = 0, then no dragtail.
%                       ** To show tracks from their beginning to their end,
%                       set dragtailLength to any value longer than the
%                       movie.
%                       ** To show tracks statically while features dance
%                       on them, use -1.
%                       ** To show tracks from their beginning to their
%                       end, and to retain tracks even after the particle
%                       disappears, use -2.
%       saveMovie     : 1 to save movie (as Quicktime), 0 otherwise.
%                       Optional. Default: 0.
%       movieName     : filename for saving movie.
%                       Optional. Default: TrackMovie (if saveMovie = 1).
%       filterSigma   : 0 to overlay on raw image, PSF sigma to overlay on
%                       image filtered with given filterSigma.
%                       Optional. Default: 0.
%       classifyGaps  : 1 to classify gaps as "good" and "bad", depending
%                       on their length relative to the legnths of the
%                       segments they connect, 0 otherwise.
%                       Optional. Default: 1.
%       highlightES   : 1 to highlight track ends and starts, 0 otherwise.
%                       Optional. Default: 1.
%       showRaw       : 1 to add raw movie to the left of the movie with
%                       tracks overlaid, 2 to add raw movie at the top of
%                       the movie with tracks overlaid, 0 otherwise.
%                       Optional. Default: 0.
%       imageRange    : Image region to make movie out of, in the form:
%                       [min pixel X, max pixel X; min pixel Y, max pixel Y].
%                       Optional. Default: Whole image.
%       onlyTracks    : 1 to show only tracks without any symbols showing
%                       detections, closed gaps, merges and splits; 0 to
%                       show symbols on top of tracks.
%                       Optional. Default: 0.
%       classifyLft   : 1 to classify objects based on (1) whether they
%                       exist throughout the whole movie, (2) whether they
%                       appear OR disappear, and (3) whether they appear
%                       AND disappear; 0 otherwise.
%                       Optional. Default: 1.
%       diffAnalysisRes:Diffusion analysis results (either output of
%                       trackDiffusionAnalysis1 or trackTransientDiffusionAnalysis2).
%                       Needed if tracks/track segments are to be
%                       colored based on their diffusion classification.
%                       With this option, classifyGaps, highlightES and
%                       classifyLft are force-set to zero, regardless of input.
%                       Optional. Default: None.
%       intensityScale: 0 to autoscale every image in the movie, 1
%                       to have a fixed scale using intensity mean and std,
%                       2 to have a fixed scale using minimum and maximum
%                       intensities.
%                       Optional. Default: 1.
%       colorTracks   : 1 to color tracks by rotating through 7 different
%                       colors, 0 otherwise. With this option,
%                       classifyGaps, highlightES and classifyLft are
%                       force-set to zero, regardless of input.
%                       Option ignored if diffAnalysisRes is supplied.
%                       Optional. Default: 0.
%       firstImageFile: Name of the first image file in the folder of
%                       images that should be overlaid. The file has to be
%                       the first image that has been analyzed even if not
%                       plotted. If file is not specified [], user will be
%                       prompted to select the first image.
%                       Optional. Default: [].
%       dir2saveMovie:  Directory where to save output movie.
%                       If not input, movie will be saved in directory where
%                       images are located.
%                       Optional. Default: [].
%       minLength     : Minimum length of tracks to be ploted.
%                       Optional. Default: 1.
%       plotFullScreen: 1 the figure will be sized to cover the whole
%                       screen. In this way the movie will be of highest
%                       possible quality. default is 0.
%       movieType     : 'mov' to make a Quicktime movie using MakeQTMovie,
%                       'avi' to make AVI movie using Matlab's movie2avi,
%                       'mp4_unix', 'avi_unix' to make an MP4 or AVI movie
%                       using ImageMagick and ffmpeg. These options works
%                       only under linux or mac.
%                       Optional. Default: 'mov'.
%       DT            : Interval between frames in seconds. If empty it defaults to frame
%                       number 
%       IMrotate      : Rotate image 180 deg. Some movies need this...
%       fps           : Frames per second of the resulting video. Default 10

% If filename body has a number it must be separated. ie. can't be XX1001, can be XX1-001
% Also, number has to start with 001 not 000
% Run from within desired .tif folder 
% I doesn't work for linux with avi and mov format. It works from mac


tracksFinal = load('../tracksFinal.mat'); tracksFinal = tracksFinal.tracksFinal;
startend = []; 
dragtailLength = 100;           % Tail length in frames 
saveMovie = 1;   
movieName = 'movie';
filterSigma = 0;
classifyGaps = 1;
highlightES = 1;
showRaw = 0;
imageRange = [];
onlyTracks = 0;
classifyLft = 1;
diffAnalysisRes = [];
intensityScale = 0;
colorTracks = 1;
firstImageFile = [pwd '/test0001.jpg'];
dir2saveMovie = [];
minLength = 5;
plotFullScreen = 0;
movieType = 'mov';
DT = 1/30;                      % sec
IMrotate = false;
fps = 30;                       % Frames per second 


overlayTracksMovieNew(tracksFinal, startend, dragtailLength,...
    saveMovie, movieName, filterSigma, classifyGaps, highlightES,...
    showRaw, imageRange, onlyTracks, classifyLft, diffAnalysisRes,...
    intensityScale, colorTracks, firstImageFile, dir2saveMovie,...
    minLength, plotFullScreen, movieType, DT, IMrotate, 30)

