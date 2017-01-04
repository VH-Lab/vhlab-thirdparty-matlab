function vhtools_thirdparty_startup(toolsprefix, verbose);

% VHTOOLS_THIRDPARTY_STARTUP - Include paths and initialize variables for VHTOOLS
%
%  VHTOOLS_THIRDPARTY_STARTUP(TOOLSPREFIX, [, VERBOSE])
%
%  Initializes tools written used by VHTOOLS
%
%  TOOLSPREFIX should be the directory where the third party tool directories reside.
%
%  If VERBOSE is present and is 1, then each library is installed with a
%  startup message like 'Initializing NewStim library'
%

if nargin>1, vb = verbose; else, vb = 0; end;

thirdparty_prefix = [toolsprefix filesep];

if 1&exist([thirdparty_prefix])==7, % add tcp_udp_ip package for function pnet
	addpath([thirdparty_prefix filesep 'tcp_udp_ip']);
	if vb, disp(['Initializing third party tool tcp_udp_ip']); end;
end;

if 1&exist([thirdparty_prefix])==7, % add matlab_functions 
	addpath(genpath([thirdparty_prefix filesep 'matlab_functions']));
end;

if 1&exist([thirdparty_prefix])==7, % add sigTOOL package for reading Spike2 files
	addpath(genpath([thirdparty_prefix filesep 'sigTOOL' filesep 'sigTOOL Neuroscience Toolkit']));
	addpath(genpath([thirdparty_prefix filesep 'sigTOOL' filesep 'CORE']));
	if vb, disp(['Initializing third party tool sigTOOL']); end;
end;

if 1&exist([thirdparty_prefix])==7, % add KwikTeam tools
	addpath(genpath([thirdparty_prefix filesep 'KwikTeam']));
end;

if 1&exist([thirdparty_prefix])==7,
	addpath(([thirdparty_prefix filesep 'CircStat2012a']));
end;

if 1&exist([thirdparty_prefix])==7,
	addpath((genpath([thirdparty_prefix filesep 'drtoolbox'])));
end;

