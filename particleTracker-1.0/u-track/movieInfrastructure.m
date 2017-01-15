function movieVar = movieInfrastructure(whatToDo,movieType,dir2saveMovie,...
    movieName,numFramesMovie,movieVar,iFrame,fps)

if nargin < 8 || isempty(fps)
    fps = 10;
end 

switch whatToDo
    
    case 'initialize' %initialize movie

        switch movieType
            case 'mov'
                eval(['MakeQTMovie start ', fullfile(dir2saveMovie,movieName) '.mov']);
            case {'mp4_unix','avi_unix'}
                frameDir = [dir2saveMovie filesep 'tmpFramesMovie'];
                [~,~] = mkdir(frameDir);
        end
        
    case 'addFrame' %add frame to movie
        
        switch movieType
            case 'mov'
                MakeQTMovie addfigure
                MakeQTMovie('framerate',fps);
            case 'avi'
                movieVar(iFrame) = getframe(gcf);
            case {'mp4_unix','avi_unix'}
                frameDir = [dir2saveMovie filesep 'tmpFramesMovie'];
                ndigit = num2str(ceil(log10(numFramesMovie)));
                kformat = ['%.' ndigit 'd'];
                ext = '.png';
                %generate temporary EPS file
                print('-depsc2', '-loose', '-r300', [frameDir filesep 'frame.eps']);
                %save each frame as PNG in the 'tmpFramesMovie' directory
                options = '-quiet -colorspace rgb -density 150 -depth 8';
                src = [frameDir filesep 'frame.eps'];
                dest = [frameDir filesep 'frame_' num2str(iFrame, kformat) ext];
                cmd = ['convert ' options ' ' src ' ' dest];
                system(cmd);
        end
        
    case 'finalize' %finalize movie
        
        switch movieType
            case 'mov'
                MakeQTMovie finish
            case 'avi'
                movie2avi(movieVar,fullfile(dir2saveMovie,movieName),'compression',...
                    'None','fps', fps)
            case {'mp4_unix','avi_unix'}
                frameDir = [dir2saveMovie filesep 'tmpFramesMovie'];
                ndigit = num2str(ceil(log10(numFramesMovie)));
                ext = '.png';
                cmd = ['ffmpeg -y -r 10 -i ' frameDir filesep 'frame_%0' ndigit 'd' ...
                    ext ' -b 20M -r 10 ' fullfile(dir2saveMovie,movieName) '.' ...
                    movieType(1:end-5)];
                system(cmd);
                rmdir(frameDir,'s')
        end
        
end