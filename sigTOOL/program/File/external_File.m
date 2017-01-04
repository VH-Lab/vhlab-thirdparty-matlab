function varargout=external_File(varargin)
% external_File sets up File Import menu items from CORE/File folder
%
% [a b c]=external_File(0)
%   will be called by dir2menu. Not user-callable.
%
% -------------------------------------------------------------------------
% Author: Malcolm Lidierth 11/06
% Copyright � The Author & King's College London 2006-2007
% -------------------------------------------------------------------------

folder=fullfile(scGetBaseFolder, 'CORE', filesep, 'File');

if ~exist(folder,'dir')
    varargout{1}=false;
    varargout{2}='File';
    varargout{3}='';
else
    varargout{1}=true;
    varargout{2}='File';
    varargout{3}=folder;
end