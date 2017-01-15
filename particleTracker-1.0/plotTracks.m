function varargout = plotTracks(varargin)
% varargout = plotTracks(tracksFinal, I)
% tracksFinal - As outputed from u-track
% I           - Cell array containing each frame of the movie. For best
%               result they should have high contrast. 
%
% gP 2/25/2013

% Last Modified by GUIDE v2.5 25-Feb-2013 14:35:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @plotTracks_OpeningFcn, ...
                   'gui_OutputFcn',  @plotTracks_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before plotTracks is made visible.
function plotTracks_OpeningFcn(hObject, ~, handles, varargin)
handles.output = hObject;
                                            
%ixArgin = find(strcmp(varargin, 'tracksFinal'));
tracksFinal = varargin{1};    
%ixArgin = find(strcmp(varargin, 'img'));
I = varargin{2}; 

Nt = length(tracksFinal);
Nfr = length(I);
                                            % Set up slider properties
slider = findall(0,'Tag','slider1');
set(slider, 'Max', Nfr,'Min', 1, 'Value', 1, 'SliderStep',...
    [1/Nfr 5/Nfr]);

% Set up the plotTracks matrix
tmp = vertcat(tracksFinal.seqOfEvents);
numTimePoints = max(tmp(:,1));
clear tmp
% Get number of segments making each track
numSegments = zeros(Nt,1);
for i = 1 : Nt
    numSegments(i) = size(tracksFinal(i).tracksCoordAmpCG,1);
end
% If all tracks have only one segment ...
if max(numSegments) == 1
    
    % Locate the row of the first track of each compound track in the
    % Big matrix of all tracks (to be constructed in the next step)
    % in this case of course every compound track is simply one track
    % without branches
    trackStartRow = (1:Nt)';
    
    % Store tracks in a matrix
    trackedFeatureInfo = NaN(Nt,8*numTimePoints);
    times = zeros(Nt,2);
    for i = 1 : Nt
        times(i,1) = tracksFinal(i).seqOfEvents(1,1);        % Start time
        times(i,2)   = tracksFinal(i).seqOfEvents(end,1);    % End time
        trackedFeatureInfo(i,8*(times(i,1)-1)+1:8*times(i,2)) = ...
            tracksFinal(i).tracksCoordAmpCG;
    end
    
else %if some tracks have merging/splitting branches
    
    %locate the row of the first track of each compound track in the
    %big matrix of all tracks (to be constructed in the next step)
    trackStartRow = ones(Nt,1);
    for iTrack = 2 : Nt
        trackStartRow(iTrack) = trackStartRow(iTrack-1) + numSegments(iTrack-1);
    end
    
    %put all tracks together in a matrix
    trackedFeatureInfo = NaN(trackStartRow(end)+numSegments(end)-1,8*numTimePoints);
    times = zeros(Nt,2);
    for i = 1 : Nt
        times(i,1) = tracksFinal(i).seqOfEvents(1,1);        % Start time
        times(i,2)   = tracksFinal(i).seqOfEvents(end,1);    % End time
        trackedFeatureInfo( trackStartRow(i):trackStartRow(i)+...
            numSegments(i)-1,8*(times(i,1)-1)+1:8*times(i,2) ) = ...
            tracksFinal(i).tracksCoordAmpCG;
    end
end

% Save data in handles
                % Define colors to loop through in case colorTime = '2'
handles.colorLoop = [.8 .8 .8; 1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1]; %colors: k,r,g,b,y,m,c
handles.Isize = size(I{1});
handles.tracksFinal = tracksFinal;
handles.I = I;
handles.Nt = Nt;
handles.Nfr = Nfr;
                % Get the times, and x,y-coordinates of features in all tracks
handles.tracksX = trackedFeatureInfo(:,1:8:end)';
handles.tracksY = trackedFeatureInfo(:,2:8:end)';
handles.times = times;
                % First zoom includes the whole image
handles.zoomxy = [1 1; handles.Isize(2) handles.Isize(1)];
handles.trackStartRow = trackStartRow(end);   % Matters if there are splitted tracks
handles.numSegments = numSegments(end);
                % Plot trajectories 
imshow(handles.I{1});
hold on;

guidata(hObject, handles);


% --- Executes on slider movement.
function slider1_Callback(hObject, ~, handles)

frIx = round(get(hObject,'Value'));                 % Slider gives the time
cla;                        % To refresh faster
imshow(handles.I{frIx});    % Max & min taken from 1st frame

% Select plot area (zoom), take the max/min since the zoom square
% can have different 1st and 2nd points
set(gca, 'XLim', [min(handles.zoomxy(:,1)) max(handles.zoomxy(:,1))],...
    'YLim', [min(handles.zoomxy(:,2)) max(handles.zoomxy(:,2))])

trackIx = find(handles.times(:,1) < frIx & ...      % Index of tracks that begin 
               handles.times(:,2) > frIx)';         %  before the slider position
                                                    %  & and and after it.
for i = trackIx                                      
                                                    % Aca obtiene los gap intervals
    obsAvail = find(~isnan(handles.tracksX(1:frIx,i)));     
                    % plot in dotted lines all non NaN points
    plot(handles.tracksX(obsAvail,i), handles.tracksY(obsAvail,i),'w:');
                    % Plot in colored line all points up to time t
    plot(handles.tracksX(1:frIx,i), handles.tracksY(1:frIx,i),'color',...
        handles.colorLoop(mod(i-1,7)+1,:), 'marker','none');
end



% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, ~, ~)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --------------------------------------------------------------------
function uipushtool2_ClickedCallback(hObject, ~, handles)
% zoom out
set(gca, 'XLim', [1 handles.Isize(2)], 'YLim', [1 handles.Isize(1)])
handles.zoomxy = [1 1; handles.Isize(2) handles.Isize(1)];
guidata(hObject, handles);


% --------------------------------------------------------------------
function uipushtool3_ClickedCallback(hObject, ~, handles)
%zoom in
waitforbuttonpress;
point1 = get(gca,'CurrentPoint');                   % button down detected
rbbox;                                              % return figure units
point2 = get(gca,'CurrentPoint');                   % button up detected
handles.zoomxy = [point1(1,1:2);point2(1,1:2)];     % extract x and y
set(gca, 'XLim', [min(handles.zoomxy(:,1)) max(handles.zoomxy(:,1))],...
    'YLim', [min(handles.zoomxy(:,2)) max(handles.zoomxy(:,2))])
guidata(hObject, handles);


% --------------------------------------------------------------------
function varargout = plotTracks_OutputFcn(~, ~, handles) 

varargout{1} = handles.output;
