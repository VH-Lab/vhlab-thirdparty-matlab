function vhlabthirdpartyInit
% VHLABTHIRDPARTYINIT - add paths for vhlab-thirdparty-matlab toolbox
% 
% This toolbox is a collection of third-party open source software for use with the
% VHLAB toolbox.
%
% See: http://code.vhlab.org
% 

mypath = fileparts(which('vhlabthirdpartyInit'));

 % remove any paths that have the string 'vhlab-thirdparty-matlab' so we don't have stale
% paths confusing anyone

pathsnow = path;
pathsnow_cell = strsplit(pathsnow,pathsep);
matches = contains(pathsnow_cell, 'vhlab-thirdparty-matlab');
pathstoremove = char(strjoin(pathsnow_cell(matches),pathsep));
rmpath(pathstoremove);

  % add everything except '.git' directories
pathstoadd = genpath(mypath);
pathstoadd_cell = strsplit(pathstoadd,pathsep);
matches=(~contains(pathstoadd_cell,'.git'));
pathstoadd = char(strjoin(pathstoadd_cell(matches),pathsep));
addpath(pathstoadd);

javaaddpath([mypath filesep 'java']);
D = dir([mypath filesep 'java' filesep '*.jar']);
for i=1:numel(D),
    javaaddpath([mypath filesep 'java' filesep D(i).name]);
end;


