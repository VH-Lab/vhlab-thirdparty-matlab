function [data,h,s] = import_abf(file, en, dt)

%   [DATA] = IMPORT_ABF(FILE, EN, DT)
%
%     Import Axon's .ABF binary files (incorporating a special text header) into Matlab.
%
%     This function loads data from an Axon Binary File (.ABF 1.65) (Copyright © 1995 Axon Instruments)
%     and automatically import columns of values into Matlab, as a numerical data matrix. 
%
%     The input argument FILE refers to the abf filename and it must be a string, including the file extension (e.g. 'patchexperiment.abf').
%     The second input argument EN refers to the episode number (among those available) the user wish to extract (e.g. 1, 2, 3,... ).
%     The third input argument DT refers to the sampling interval of the acquired data.
%
%     Do you want to know more about .ABF files?
%     The ABF format was created for the storage of binary experimental data. It originated with Axon's pCLAMP suite
%     of data acquisition and analysis programs, but it is also supported by other Axon scientific software such as
%     AxoTape and AxoScope. The ABF format is designed to accommodate all the features of Axon data acquisition programs.
%     All protocol and data information from acquisitions is stored in the ABF format. Consequently, not only data but
%     protocol information can be extracted from ABF. For further information browse through http://www.axon.com.
%
%     The output: DATA,     contains the data matrix.  This data matrix has the same size as the data in the file,
%                           one row per channel.
%
%     © 2002 - Michele Giugliano, PhD (http://www.giugliano.info) (Bern, Friday March 8th, 2002 - 20:09)
%                               (bug-reports to michele@giugliano.info)
%
%     This script partly incorporated the matlab script getpc6header.m, originally conceived and written by Carsten Hohnke
%     (http://www.ai.mit.edu/people/ch/).
%
%     See the "Axon PC File Support Package for Developers", freely downloadable at http://www.axon.com/pub/utility/axonfsp/.
%
%     See also IMPORT_ABF, LOAD, SAVE, SPCONVERT, FSCANF, FPRINTF, STR2MAT, HDRLOAD.
%     See also the IOFUN directory.
    

%
% An ABF file is composed by:
%
% -- The ABF Header Section
% -- The ABF Scope Config Section
% -- The ABF Data Section
% -- The ABF Synch Section
% -- The ABF Tag Section
% -- The ABF Deltas Section
% -- The DAC Data Section 
%

% Let's check the number and the type of input arguments.
if nargin < 2
  error('Function requires two input argument (the ABF filename and the en)');
elseif ~isstr(file)
  error('Input must be a string representing an ABF filename');
end % if

fid = fopen(file,'r','l');              % Open the file.  If this returns a -1, we did not open the file successfully.
if fid==-1
 error(sprintf('File %s has not been found or permission denied',file));
 return;
end % if

h =  get_abf_header(fid);           % Get header information from a 1.65 Axon Binary File (ABF)
s =  get_abf_scopecfg(fid, h.size); % Get scope config section from a 1.65 Axon Binary File (ABF)

ne = h.lActualEpisodes;      % Get the number of episodes contained in the data file...
if en < 1 | en > ne,         % and check for valid value of the user request.
   error('Invalid episode number.');
end


Nchan = h.nADCNumChannels;
ns    = h.lActualAcqLength / h.lActualEpisodes;

if (h.fHeaderVersionNumber >= 1.6)
 fseek(fid, (h.size+s.size)+1394 + (en-1) * 2 * ns, 'bof');
else
 fseek(fid, (2048+s.size)+370 + (en-1) * 2 * ns, 'bof'); % UNTESTED!
end % if


if (h.nDataFormat == 0) % Data representation. 0 = 2-byte integer; 1 = IEEE 4 byte float.
 xdata = fread(fid, ns, 'short');
else
 xdata = fread(fid, ns, 'float');
end % if 

% I now resize output data, based on the number of (data)columns (as reported in the header and contained 
% in M, and the total number of data elements acquired from the file. Since the data was read in row-wise,
% and MATLAB stores data in columnwise format, I have to reverse the size arguments and then transpose the
% data.  If I read in irregularly spaced data, then the division we are about to do will not work. Therefore,
% we will trap the error with an EVAL call; if the reshape fails, we will just return the data as is.

 eval('xdata = reshape(xdata, Nchan, length(xdata)/Nchan)'';', '');     % This is taken from Mathworks' Tech-Note 1402 
 data      = [];
 data      = zeros(size(xdata,1),Nchan+1);
 data(:,1) = dt*(0:size(xdata,1)-1)';
  
 for chan=1:Nchan,
  gain(chan)   = h.fADCRange / h.lADCResolution / (h.fInstrumentScaleFactor(chan) * h.x_fAutosampleAdditGain * h.fADCProgrammableGain(chan) * h.fSignalGain(chan));
  offset(chan) = h.fSignalOffset(chan);
  data(:,chan+1) = xdata(:,chan) * gain(chan) + offset(chan);  
 end % for

 fclose(fid);                                                % (http://www.mathworks.com/support/tech-notes/1400/1402.shtml)
 
 % Job done!


function [h] = get_abf_header(fid);
%   get_abf_header:
%   Get header information from a pClamp 6.x Axon Binary File (ABF).
%   h = get_abf_header(FID) returns a structure with all header information.
%   ABF files should be opened with the appropriate machineformat (IEEE floating
%   point with little-endian byte ordering, e.g., fopen(file,'r','l').
%   For a description of the fields, see the "abf.asc" file included with the 
%   "Axon PC File Support Package for Developers".
%
%   FID is an integer file identifier obtained from FOPEN.

if fid == -1, % Check for invalid fid.
   error('Invalid fid.');
end
fseek(fid,0,'bof'); % Set the pointer to beginning of the file.

h.size  =   6144;                       % Was '2048' (bytes long) in the Axon Binary Format version 1.5.

%-----------------------------------------------------------------------------
% File ID and Size information
h.lFileSignature        = fread(fid,1,'int');   % Pointing to byte 0
h.fFileVersionNumber    = fread(fid,1,'float'); % 4
h.nOperationMode        = fread(fid,1,'short'); % 8
h.lActualAcqLength      = fread(fid,1,'int');   % 10
h.nNumPointsIgnored     = fread(fid,1,'short'); % 14
h.lActualEpisodes       = fread(fid,1,'int');   % 16
h.lFileStartDate        = fread(fid,1,'int');   % 20
h.lFileStartTime        = fread(fid,1,'int');   % 24
h.lStopwatchTime        = fread(fid,1,'int');   % 28
h.fHeaderVersionNumber  = fread(fid,1,'float'); % 32
h.nFileType             = fread(fid,1,'short'); % 36
h.nMSBinFormat          = fread(fid,1,'short'); % 38
%-----------------------------------------------------------------------------
% File Structure
h.lDataSectionPtr       = fread(fid,1,'int');   % 40
h.lTagSectionPtr        = fread(fid,1,'int');   % 44
h.lNumTagEntries        = fread(fid,1,'int');   % 48
h.lScopeConfigPtr       = fread(fid,1,'int');   % 52
h.lNumScopes            = fread(fid,1,'int');   % 56
h.x_lDACFilePtr         = fread(fid,1,'int');   % 60
h.x_lDACFileNumEpisodes = fread(fid,1,'int');   % 64
h.sUnused68             = fread(fid,4,'char');  % 4char % 68
h.lDeltaArrayPtr        = fread(fid,1,'int');   % 72
h.lNumDeltas            = fread(fid,1,'int');   % 76
h.lVoiceTagPtr          = fread(fid,1,'int');   % 80
h.lVoiceTagEntries      = fread(fid,1,'int');   % 84
h.lUnused88             = fread(fid,1,'int');   % 88
h.lSynchArrayPtr        = fread(fid,1,'int');   % 92
h.lSynchArraySize       = fread(fid,1,'int');   % 96
h.nDataFormat           = fread(fid,1,'short'); % 100
h.nSimultaneousScan     = fread(fid,1,'short'); % 102
h.sUnused104            = fread(fid,16,'char'); % 16char % 104
%-----------------------------------------------------------------------------
% Trial Hierarchy Information
h.nADCNumChannels       = fread(fid,1,'short'); % 120
h.fADCSampleInterval    = fread(fid,1,'float'); % 122
h.fADCSecondSampleInterval=fread(fid,1,'float');% 126
h.fSynchTimeUnit        = fread(fid,1,'float'); % 130
h.fSecondsPerRun        = fread(fid,1,'float'); % 134
h.lNumSamplesPerEpisode = fread(fid,1,'int');   % 138
h.lPreTriggerSamples    = fread(fid,1,'int');   % 142
h.lEpisodesPerRun       = fread(fid,1,'int');   % 146
h.lRunsPerTrial         = fread(fid,1,'int');   % 150
h.lNumberOfTrials       = fread(fid,1,'int');   % 154
h.nAveragingMode        = fread(fid,1,'short'); % 158
h.nUndoRunCount         = fread(fid,1,'short'); % 160
h.nFirstEpisodeInRun    = fread(fid,1,'short'); % 162
h.fTriggerThreshold     = fread(fid,1,'float'); % 164
h.nTriggerSource        = fread(fid,1,'short'); % 168
h.nTriggerAction        = fread(fid,1,'short'); % 170
h.nTriggerPolarity      = fread(fid,1,'short'); % 172
h.fScopeOutputInterval  = fread(fid,1,'float'); % 174
h.fEpisodeStartToStart  = fread(fid,1,'float'); % 178
h.fRunStartToStart      = fread(fid,1,'float'); % 182
h.fTrialStartToStart    = fread(fid,1,'float'); % 186
h.lAverageCount         = fread(fid,1,'int');   % 190
h.lClockChange          = fread(fid,1,'int');   % 194
h.nAutoTriggerStrategy  = fread(fid,1,'short'); % 198
%-----------------------------------------------------------------------------
% Display Parameters
h.nDrawingStrategy      = fread(fid,1,'short'); % 200
h.nTiledDisplay         = fread(fid,1,'short'); % 202
h.nEraseStrategy        = fread(fid,1,'short'); % 204
h.nDataDisplayMode      = fread(fid,1,'short'); % 206
h.lDisplayAverageUpdate = fread(fid,1,'int');   % 208
h.nChannelStatsStrategy = fread(fid,1,'short'); % 212
h.lCalculationPeriod    = fread(fid,1,'int');   % 214
h.lSamplesPerTrace      = fread(fid,1,'int');   % 218
h.lStartDisplayNum      = fread(fid,1,'int');   % 222
h.lFinishDisplayNum     = fread(fid,1,'int');   % 226
h.nMultiColor           = fread(fid,1,'short'); % 230
h.nShowPNRawData        = fread(fid,1,'short'); % 232
h.fStatisticsPeriod     = fread(fid,1,'float'); % 234
h.lStatisticsMeasurements=fread(fid,1,'int');   % 238
%-----------------------------------------------------------------------------
% Hardware Information
h.nStatisticsSaveStrategy=fread(fid,1,'short'); % 242
h.fADCRange             = fread(fid,1,'float'); % 244
h.fDACRange             = fread(fid,1,'float'); % 248
h.lADCResolution        = fread(fid,1,'int');   % 252
h.lDACResolution        = fread(fid,1,'int');   % 256
%-----------------------------------------------------------------------------
% Environmental Information
h.nExperimentType       = fread(fid,1,'short'); % 260
h.x_nAutosampleEnable   = fread(fid,1,'short'); % 262
h.x_nAutosampleADCNum   = fread(fid,1,'short'); % 264
h.x_nAutosampleInstrument=fread(fid,1,'short'); % 266
h.x_fAutosampleAdditGain= fread(fid,1,'float'); % 268
h.x_fAutosampleFilter   = fread(fid,1,'float'); % 272
h.x_fAutosampleMembraneCapacitance=fread(fid,1,'float'); % 276
h.nManualInfoStrategy   = fread(fid,1,'short'); % 280
h.fCellID1              = fread(fid,1,'float'); % 282
h.fCellID2              = fread(fid,1,'float'); % 286
h.fCellID3              = fread(fid,1,'float'); % 290
h.sCreatorInfo          = fread(fid,16,'char'); % 16char % 294
h.x_sFileComment        = fread(fid,56,'char'); % 56char % 310
h.sUnused366            = fread(fid,12,'char'); % 12char % 366
%-----------------------------------------------------------------------------
% Multi-channel Information
h.nADCPtoLChannelMap    = fread(fid,16,'short');    % 378
h.nADCSamplingSeq       = fread(fid,16,'short');    % 410
h.sADCChannelName       = fread(fid,16*10,'char');  % 442
h.sADCUnits             = fread(fid,16*8,'char');   % 8char % 602
h.fADCProgrammableGain  = fread(fid,16,'float');    % 730
h.fADCDisplayAmplification=fread(fid,16,'float');   % 794
h.fADCDisplayOffset     = fread(fid,16,'float');    % 858
h.fInstrumentScaleFactor= fread(fid,16,'float');    % 922
h.fInstrumentOffset     = fread(fid,16,'float');    % 986
h.fSignalGain           = fread(fid,16,'float');    % 1050
h.fSignalOffset         = fread(fid,16,'float');    % 1114
h.fSignalLowpassFilter  = fread(fid,16,'float');    % 1178
h.fSignalHighpassFilter = fread(fid,16,'float');    % 1242
h.sDACChannelName       = fread(fid,4*10,'char');   % 1306
h.sDACChannelUnits      = fread(fid,4*8,'char');    % 8char % 1346
h.fDACScaleFactor       = fread(fid,4,'float');     % 1378
h.fDACHoldingLevel      = fread(fid,4,'float');     % 1394
h.nSignalType           = fread(fid,1,'short');     % 12char % 1410
h.sUnused1412           = fread(fid,10,'char');     % 10char % 1412
%-----------------------------------------------------------------------------
% Synchronous Timer Outputs
h.nOUTEnable            = fread(fid,1,'short');     % 1422
h.nSampleNumberOUT1     = fread(fid,1,'short');     % 1424
h.nSampleNumberOUT2     = fread(fid,1,'short');     % 1426
h.nFirstEpisodeOUT      = fread(fid,1,'short');     % 1428
h.nLastEpisodeOUT       = fread(fid,1,'short');     % 1430
h.nPulseSamplesOUT1     = fread(fid,1,'short');     % 1432
h.nPulseSamplesOUT2     = fread(fid,1,'short');     % 1434
%-----------------------------------------------------------------------------
% Epoch Waveform and Pulses
h.nDigitalEnable        = fread(fid,1,'short');     % 1436
h.x_nWaveformSource     = fread(fid,1,'short');     % 1438
h.nActiveDACChannel     = fread(fid,1,'short');     % 1440
h.x_nInterEpisodeLevel  = fread(fid,1,'short');     % 1442
h.x_nEpochType          = fread(fid,10,'short');    % 1444
h.x_fEpochInitLevel     = fread(fid,10,'float');    % 1464
h.x_fEpochLevelInc      = fread(fid,10,'float');    % 1504
h.x_nEpochInitDuration  = fread(fid,10,'short');    % 1544
h.x_nEpochDurationInc   = fread(fid,10,'short');    % 1564
h.nDigitalHolding       = fread(fid,1,'short');     % 1584
h.nDigitalInterEpisode  = fread(fid,1,'short');     % 1586
h.nDigitalValue         = fread(fid,10,'short');    % 1588
h.sUnavailable1608      = fread(fid,4,'char');      % 1608
h.sUnused1612           = fread(fid,8,'char');      % 8char % 1612
%-----------------------------------------------------------------------------
% DAC Output File
h.x_fDACFileScale       = fread(fid,1,'float');     % 1620
h.x_fDACFileOffset      = fread(fid,1,'float');     % 1624
h.sUnused1628           = fread(fid,2,'char');      % 2char % 1628
h.x_nDACFileEpisodeNum  = fread(fid,1,'short');     % 1630
h.x_nDACFileADCNum      = fread(fid,1,'short');     % 1632
h.x_sDACFileName        = fread(fid,12,'char');     % 12char % 1634
h.sDACFilePath=fread(fid,60,'char');                % 60char % 1646
h.sUnused1706=fread(fid,12,'char');                 % 12char % 1706
%-----------------------------------------------------------------------------
% Conditioning Pulse Train
h.x_nConditEnable       = fread(fid,1,'short');     % 1718
h.x_nConditChannel      = fread(fid,1,'short');     % 1720
h.x_lConditNumPulses    = fread(fid,1,'int');       % 1722
h.x_fBaselineDuration   = fread(fid,1,'float');     % 1726
h.x_fBaselineLevel      = fread(fid,1,'float');     % 1730
h.x_fStepDuration       = fread(fid,1,'float');     % 1734
h.x_fStepLevel          = fread(fid,1,'float');     % 1738
h.x_fPostTrainPeriod    = fread(fid,1,'float');     % 1742
h.x_fPostTrainLevel     = fread(fid,1,'float');     % 1746
h.sUnused1750           = fread(fid,12,'char');     % 12char % 1750
%-----------------------------------------------------------------------------
% Variable Parameter User List
h.x_nParamToVary        = fread(fid,1,'short');     % 1762
h.x_sParamValueList     = fread(fid,80,'char');     % 80char % 1764
%-----------------------------------------------------------------------------
% Statistics Measurement
h.nAutopeakEnable       = fread(fid,1,'short'); % 1844
h.nAutopeakPolarity     = fread(fid,1,'short'); % 1846
h.nAutopeakADCNum       = fread(fid,1,'short'); % 1848
h.nAutopeakSearchMode   = fread(fid,1,'short'); % 1850
h.lAutopeakStart        = fread(fid,1,'int');   % 1852
h.lAutopeakEnd          = fread(fid,1,'int');   % 1856
h.nAutopeakSmoothing    = fread(fid,1,'short'); % 1860
h.nAutopeakBaseline     = fread(fid,1,'short'); % 1862
h.nAutopeakAverage      = fread(fid,1,'short'); % 1864
h.sUnavailable1866      = fread(fid,2,'char');  % 1866
h.lAutopeakBaselineStart= fread(fid,1,'int');   % 1868
h.lAutopeakBaselineEnd  = fread(fid,1,'int');   % 1872
h.lAutopeakMeasurements = fread(fid,1,'int');   % 1876
%-----------------------------------------------------------------------------
% Channel Arithmetic
h.nArithmeticEnable     = fread(fid,1,'short'); % 1880
h.fArithmeticUpperLimit = fread(fid,1,'float'); % 1882
h.fArithmeticLowerLimit = fread(fid,1,'float'); % 1886
h.nArithmeticADCNumA    = fread(fid,1,'short'); % 1890
h.nArithmeticADCNumB    = fread(fid,1,'short'); % 1892
h.fArithmeticK1         = fread(fid,1,'float'); % 1894
h.fArithmeticK2         = fread(fid,1,'float'); % 1898
h.fArithmeticK3         = fread(fid,1,'float'); % 1902
h.fArithmeticK4         = fread(fid,1,'float'); % 1906
h.sArithmeticOperator   = fread(fid,2,'char');  % 2char % 1910
h.sArithmeticUnits      = fread(fid,8,'char');  % 8char % 1912
h.fArithmeticK5         = fread(fid,1,'float'); % 1920
h.fArithmeticK6         = fread(fid,1,'float'); % 1924
h.nArithmeticExpression = fread(fid,1,'short'); % 1928
h.sUnused1930           = fread(fid,2,'char');  % 2char % 1930
%-----------------------------------------------------------------------------
% On-line Subtraction
h.x_nPNEnable           = fread(fid,1,'short'); % 1932
h.nPNPosition           = fread(fid,1,'short'); % 1934
h.x_nPNPolarity         = fread(fid,1,'short'); % 1936
h.nPNNumPulses          = fread(fid,1,'short'); % 1938
h.x_nPNADCNum           = fread(fid,1,'short'); % 1940
h.x_fPNHoldingLevel     = fread(fid,1,'float'); % 1942
h.fPNSettlingTime       = fread(fid,1,'float'); % 1946
h.fPNInterpulse         = fread(fid,1,'float'); % 1950
h.sUnused1954           = fread(fid,12,'char'); % 12char % 1954
%-----------------------------------------------------------------------------
% Unused Space at End of Header Block
h.x_nListEnable         = fread(fid,1,'short'); % 1966
h.nBellEnable           = fread(fid,2,'short'); % 1968
h.nBellLocation         = fread(fid,2,'short'); % 1972
h.nBellRepetitions      = fread(fid,2,'short'); % 1976
h.nLevelHysteresis      = fread(fid,1,'int');   % 1980
h.lTimeHysteresis       = fread(fid,1,'int');   % 1982
h.nAllowExternalTags    = fread(fid,1,'short'); % 1986
h.nLowpassFilterType    = fread(fid,16,'char'); % 1988
h.nHighpassFilterType   = fread(fid,16,'char');% 2004
h.nAverageAlgorithm     = fread(fid,1,'short'); % 2020
h.fAverageWeighting     = fread(fid,1,'float'); % 2022
h.nUndoPromptStrategy   = fread(fid,1,'short'); % 2026
h.nTrialTriggerSource   = fread(fid,1,'short'); % 2028
h.nStatisticsDisplayStrategy= fread(fid,1,'short'); % 2030
h.sUnused2032           = fread(fid,14,'char'); % 2032  % modified by SV

%-----------------------------------------------------------------------------
% File Structure 2
h.lDACFilePtr           = fread(fid,2,'int'); % 2048
h.lDACFileNumEpisodes   = fread(fid,2,'int'); % 2056
h.sUnused2              = fread(fid,10,'char');%2064
%-----------------------------------------------------------------------------
% Multi-channel Information 2
h.fDACCalibrationFactor = fread(fid,4,'float'); % 2074
h.fDACCalibrationOffset = fread(fid,4,'float'); % 2090
h.sUnused7              = fread(fid,190,'char');% 2106
%-----------------------------------------------------------------------------
% Epoch Waveform and Pulses 2
h.nWaveformEnable       = fread(fid,2,'short'); % 2296
h.nWaveformSource       = fread(fid,2,'short'); % 2300
h.nInterEpisodeLevel    = fread(fid,2,'short'); % 2304
h.nEpochType            = fread(fid,10*2,'short');% 2308
h.fEpochInitLevel       = fread(fid,10*2,'float');% 2348
h.fEpochLevelInc        = fread(fid,10*2,'float');% 2428
h.lEpochInitDuration    = fread(fid,10*2,'int');  % 2508
h.lEpochDurationInc     = fread(fid,10*2,'int');  % 2588
h.sUnused9              = fread(fid,40,'char');   % 2668
%-----------------------------------------------------------------------------
% DAC Output File 2
h.fDACFileScale         = fread(fid,2,'float');     % 2708
h.fDACFileOffset        = fread(fid,2,'float');     % 2716
h.lDACFileEpisodeNum    = fread(fid,2,'int');       % 2724
h.nDACFileADCNum        = fread(fid,2,'short');     % 2732
h.sDACFilePath          = fread(fid,2*256,'char');  % 2736
h.sUnused10             = fread(fid,12,'char');     % 3248
%-----------------------------------------------------------------------------
% Conditioning Pulse Train 2
h.nConditEnable         = fread(fid,2,'short');     % 3260
h.lConditNumPulses      = fread(fid,2,'int');       % 3264
h.fBaselineDuration     = fread(fid,2,'float');     % 3272
h.fBaselineLevel        = fread(fid,2,'float');     % 3280
h.fStepDuration         = fread(fid,2,'float');     % 3288
h.fStepLevel            = fread(fid,2,'float');     % 3296
h.fPostTrainPeriod      = fread(fid,2,'float');     % 3304
h.fPostTrainLevel       = fread(fid,2,'float');     % 3312
h.nUnused11             = fread(fid,2,'short');     % 3320
h.sUnused11             = fread(fid,36,'char');     % 3324
%-----------------------------------------------------------------------------
% Variable Parameter User List 2
h.nULEnable             = fread(fid,4,'short');     % 3360
h.nULParamToVary        = fread(fid,4,'short');     % 3368
h.sULParamValueList     = fread(fid,4*256,'char');  % 3376
h.sUnused11             = fread(fid,56,'char');     % 4400
%-----------------------------------------------------------------------------
% On-line Subtraction 2
h.nPNEnable             = fread(fid,2,'short');     % 4456
h.nPNPolarity           = fread(fid,2,'short');     % 4460
h.nPNADCNum             = fread(fid,2,'short');     % 4464
h.fPNHoldingLevel       = fread(fid,2,'float');     % 4468
h.sUnused15             = fread(fid,36,'char');     % 4476
%-----------------------------------------------------------------------------
% Environmental Information 2
h.nTelegraphEnable      = fread(fid,16,'short');     % 4512
h.nTelegraphInstrument  = fread(fid,16,'short');     % 4544
h.fTelegraphAdditGain   = fread(fid,16,'float');     % 4576
h.fTelegraphFilter      = fread(fid,16,'float');     % 4640
h.fTelegraphMembraneCap = fread(fid,16,'float');     % 4704
h.nTelegraphMode        = fread(fid,16,'short');     % 4768
h.nManualTelegraphStrategy= fread(fid,16,'short');   % 4800
h.nAutoAnalyseEnable    = fread(fid,1,'short');      % 4832
h.sAutoAnalysisMacroName= fread(fid,64,'char');      % 4834
h.sProtocolPath         = fread(fid,256,'char');     % 4898
h.sFileComment          = fread(fid,128,'char');     % 5154
h.sUnused6              = fread(fid,128,'char');     % 5282
h.sUnused2048           = fread(fid,734,'char');     % 5410
%
%-----------------------------------------------------------------------------
%



function [s] = get_abf_scopecfg(fid, hsize);
%   get_abf_scopecfg:
%   Get scope config section information from a pClamp 6.x Axon Binary File (ABF).
%

if fid == -1, % Check for invalid fid.
   error('Invalid fid.');
end
fseek(fid,hsize,'bof'); % Set the pointer to beginning of the file.

s.size  = 654; 
s.dwFlags               = fread(fid,1,'int');      % 0
s.rgbColor              = fread(fid,10,'int');     % 4
s.fDisplayStart         = fread(fid,1,'float');    % 44
s.fDisplayEnd           = fread(fid,1,'float');    % 48
s.wScopeMode            = fread(fid,1,'short');    % 52 
s.bMaximized            = fread(fid,1,'char');     % 54
s.bMinimized            = fread(fid,1,'char');     % 55
s.xLeft                 = fread(fid,1,'short');    % 56
s.yTop                  = fread(fid,1,'short');    % 58
s.xRight                = fread(fid,1,'short');    % 60
s.yBottom               = fread(fid,1,'short');    % 62
s.LogFont               = fread(fid,40,'char');     % 64
%s.LogFont_nHeight       = fread(fid,1,'short');    % 64
%s.LogFont_nWeight       = fread(fid,1,'short');    % 66
%s.LogFont_cPitchAndFamily= fread(fid,1,'char');    % 68
%s.LogFont_Unused        = fread(fid,3,'char');     % 69
%s.LogFont_szFaceName    = fread(fid,32,'char');    % 72
s.TraceList             = fread(fid,544,'char');    % 104
%s.TraceList_szName      = fread(fid,12,'char');    % 104
%s.TraceList_nMxOffset   = fread(fid,1,'short');    % 106
%s.TraceList_RgbColor    = fread(fid,1,'int');      % 118
%s.TraceList_nPenWidth   = fread(fid,1,'char');     % 120
%s.TraceList_bDrawPoints = fread(fid,1,'char');     % 124
%s.TraceList_bHidden     = fread(fid,1,'char');     % 125
%s.TraceList_bFloatData  = fread(fid,1,'char');     % 126
%s.TraceList_fVertProportion = fread(fid,1,'float');% 127
%s.TraceList_fDisplayGain    = fread(fid,4,'char'); % 128
%s.TraceList_fDisplayOffset  = fread(fid,4,'char'); % 132
s.nYAxisWidth           = fread(fid,1,'short');    % 648
s.nTraceCount           = fread(fid,1,'short');    % 650
s.nEraseStrategy        = fread(fid,1,'short');    % 652
s.nDockState            = fread(fid,1,'short');    % 654





