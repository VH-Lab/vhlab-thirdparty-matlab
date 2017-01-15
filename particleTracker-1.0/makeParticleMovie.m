function makeParticleMovie(firstImageFile, Irange, XYt, fpsOut)
% Irange  - Image region to make movie out of, in the form:
%               [min pixel X, max pixel X; min pixel Y, max pixel Y].
%               Optional. Default: Whole image.
% tracksFinal - Should only have one track! 

warning('off','all');

% ------------------ Constants --------------------
movieName = 'movie';
movieType = 'mov';
dir2saveMovie = pwd;
DT = 1/30;
dtLabel = ' sec';
frames = XYt(:,3)';         % It's always sequential
Nfr = frames(1) - frames(2)+ 1; 

% ------------------ Get file list --------------------
if iscell(firstImageFile)
    [fpath,fname,fno,fext] = getFilenameBody(firstImageFile{1});
    dirName = [fpath,filesep];
    fName = [fname,fno,fext];
elseif ischar(firstImageFile)
    [fpath,fname,fno,fext] = getFilenameBody(firstImageFile);
    dirName = [fpath,filesep];
    fName = [fname,fno,fext];
end
    
%if input is valid ...
if(isa(fName,'char') && isa(dirName,'char'))
    
    %get all file names in stack
    outFileList = getFileStackNames([dirName,fName]);
    numFiles = length(outFileList);
    
    %determine which frames the files correspond to, and generate the inverse map
    %indicate missing frames with a zero
    frame2fileMap = zeros(numFiles,1);
    for iFile = 1 : numFiles
        [~,~,frameNumStr] = getFilenameBody(outFileList{iFile});
        frameNum = str2double(frameNumStr);
        frame2fileMap(frameNum) = iFile;
    end        
%                             % Read first image to get image size
%     currentImage = imread(outFileList{1});
%     [isx,isy,~] = size(currentImage);       % Dummy output in case is RGB
    
else 
    disp('--makeParticleMovie: Bad file selection');
    return
end
    
% Initialize movie if it is to be saved
movieVar = struct('cdata',[],'colormap',[]);
movieVar = movieInfrastructure('initialize', movieType,...
    dir2saveMovie, movieName, Nfr ,movieVar,[], fpsOut);
    
textDeltaCoord = 5;

figure                          % Only go through frames with tracks
for iFr=frames
    
    I = imread(outFileList{frame2fileMap(iFr)});
    % Should check if square falls inside image!!! and if is RGB
    I = I((XYt(iFr,2)-Irange):(XYt(iFr,2)+Irange),...
          (XYt(iFr,1)-Irange):(XYt(iFr,1)+Irange), :);
    
    if iFr == 1
        axes('Position',[0 0 1 1]);
        imshow(I, 'border','tight');
        text(textDeltaCoord, textDeltaCoord,...
            'Set desired image size and press any key...',...
                'Color','white','FontSize',18);

        hold on
        pause
    end
    
    clf;
    axes('Position',[0 0 1 1]);
    imshow(I, 'border','tight');
    text(textDeltaCoord,textDeltaCoord,...
        [num2str(DT*(iFr-1),'%6.2f') dtLabel],...
        'Color','white','FontSize',18);
    hold on;
    
                                % Add frame to movie if movie is saved
    movieVar = movieInfrastructure('addFrame', movieType,...
        dir2saveMovie, movieName, Nfr, movieVar, iFr, fpsOut);
    
%     pause(0.1);                 % Pause for a moment to see frame
    
end

movieInfrastructure('finalize',movieType,...
    dir2saveMovie, movieName, Nfr, movieVar, [], fpsOut);

warning('on','all');

