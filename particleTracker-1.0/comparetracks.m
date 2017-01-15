function [manualpts, autopts, matches, handles] = comparetracks(dataFile, tracksFinal, frames)
% Takes MtrackJ and tracksFinal data file inputs and generates output cell
% arrays containing tracked data points for specified frames and an array
% containing statistical information.

% Requires function barweb.m.

% Input dataFile is the manually tracked MtrackJ data file (rename
% extension to .dat). Input tracksFinal is the automatically tracked data
% file. Input frames is a vector containing all of the frame numbers to be
% matched.

% Outputs manualpts and autopts are cell arrays where each entry
% corresponds to a set of points tracked on a certain frame. Each row
% contains the coordinates of a tracked point. Column 1 is x, column 2 is
% y, column 3 is the frame number, and column 4 is the matching indicator.
% Nonzero values in column 4 indicate a match between points in manualpts
% and points in autopts to within a tolerance level of abstol.

% Output matches is an array that contains statistical information. Each
% column of the array corresponds to a specified input frame. Row 1 is the
% frame number, row 2 is the number of automatically tracked points on that
% frame, row 3 is the number of manually tracked points on that frame, rows
% 4 and 5 are the number of matching points (should be the same), row 6 is
% the percentage of false positives, and row 7 is the percentage of false
% negatives.

% Donald 2011

% Load manual and automatic tracking data files
manual = mtrackj(dataFile);
auto = tracks2cell(tracksFinal);

% Calculate the length of the frames input vector
frameind = length(frames);

% Dimension output cell arrays manualpts, autopts
manualpts = cell(frameind, 1);
autopts = cell(frameind, 1);

% Each cell array contains an N x 3 array for each specified input frame,
% where N is the number of points discovered on that frame
for ii = 1 : frameind
    manualct = 0; autoct = 0;
    for jj = 1 : length(manual)
        % Look for frame number frames(ii) in each manually obtained track
        if find(manual{jj}(:, 3) == frames(ii)) > 0
            manualct = manualct + 1;
        end
    end
    for jj = 1 : length(auto)
        % Look for frame number frames(ii) in each automatic obtained track
        if find(auto{jj}(:, 3) == frames(ii)) > 0
            autoct = autoct + 1;
        end
    end
    manualpts{ii} = zeros(manualct, 4);
    autopts{ii} = zeros(autoct,4);
end

% Populate output arrays manualpts, autopts
for ii = 1 : frameind
    kk = 0;
    for jj = 1 : length(manual)
        % Find row in the manual track array and transfer to output array
        if find(manual{jj}(:, 3) == frames(ii)) > 0
            kk = kk + 1;
            index = manual{jj}(:, 3) == frames(ii);
            manualpts{ii}(kk, 1:3) = manual{jj}(index, :);
        end
    end
    kk = 0;
    for jj = 1 : length(auto)
        % Find row in the auto track array and transfer to output array
        if find(auto{jj}(:, 3) == frames(ii)) > 0
            kk = kk + 1;
            index = auto{jj}(:, 3) == frames(ii);
            autopts{ii}(kk, 1:3) = auto{jj}(index, :);
        end
    end
end

% Set absolute tolerance in number of frames
abstol = 2.5;

% Dimension output array matches
% Array is a 7 x M array where M is the number of input frames
matches = zeros(7, frameind);

% Compare all auto detected points to all manual detected points for each input frame
% Matching points are indicated by a value in column 4
for ii = 1 : frameind
    autoptnum = size(autopts{ii});
    manualptnum = size(manualpts{ii});
    for jj = 1 : autoptnum(1)
        for kk = 1 : manualptnum(1)
            if abs(autopts{ii}(jj, :) - manualpts{ii}(kk, :)) < abstol
                autopts{ii}(jj, 4) = 10 * abstol;
                manualpts{ii}(kk, 4) = 10 * abstol;
            end
        end
    end
    % Populate output array matches
    % Frame #, auto tracked points, manual tracked points
    matches(1:3, ii) = [frames(ii); autoptnum(1); manualptnum(1)];
    % # of matching points
    matches(4, ii) = sum(autopts{ii}(:, 4)) / (10 * abstol);
    matches(5, ii) = sum(manualpts{ii}(:, 4)) / (10 * abstol);
    % % of false positives
    matches(6, ii) = 100 * (1 - (matches(4, ii) / matches(2, ii)));
    % % of false negatives
    matches(7, ii) = 100 * (1 - (matches(5, ii) / matches(3, ii)));
end

% Calculate mean and error values for %FP and %FN
meanstat = [mean(matches(6, :)) mean(matches(7, :))]; % [%FP %FN]
errorstat = [std(matches(6, :)) std(matches(7, :))] / sqrt(frameind); % [%FP %FN]

% Plot mean and error values for %FP and %FN using barweb.m
handles = barweb(meanstat, errorstat, 0.75, [], ...
    'Plot of %FP and %FN mean and error', 'Test', 'Percentage', ...
    'jet', 'y', {'FP', 'FN'}, [], 'axis');

end