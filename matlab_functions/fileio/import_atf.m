function [header, labels, comments, data] = import_atf(file)

%   [HEADER, LABELS, COMMENTS, DATA] = IMPORT_ATF(FILE)
%
%     Import Axon's .ATF text files (incorporating a special text header) into Matlab.
%
%     This function loads data from an Axon Text File (.ATF 1.0) (Copyright © 1995 Axon Instruments)
%     and automatically import columns of values into Matlab, as a numerical data matrix. 
%
%     The input filename must be a string, including the file extension (e.g. 'patchexperiment.atf').
%
%     Do you want to know more about .ATF files?
%     An .ATF file is a structured text file format that is commonly used for data export and import
%     by all of Axon's programs (http://www.axon.com), whether for the PC or the Mac.
%
%     The first output:  HEADER,   is the header information, returned as a text array.
%     The second output: LABELS,   is a (1xNc) cell array containing the (Nc) column titles and corresponding units.
%     The third output:  COMMENTS, is a (1xNcm) cell array containing the (Ncm) existing comments and corresponding indexes to DATA.
%     The fourth output: DATA,     is a double array, with the same size as the data in the file, one row per line of ASCII data in the file.
%
%     © 2002 - Michele Giugliano, PhD (http://www.giugliano.info) (Bern, Friday March 8th, 2002 - 20:09)
%                               (bug-reports to michele@giugliano.info)
%
%     For further information, see the "Axon PC File Support Package for Developers", freely downloadable
%     at http://www.axon.com/pub/utility/axonfsp/.
%
%     See also IMPORT_ABF, LOAD, SAVE, SPCONVERT, FSCANF, FPRINTF, STR2MAT, HDRLOAD.
%     See also the IOFUN directory.


%----------------------------------------------------------------------------------------------------------------------------
%----------------------------------------------------------------------------------------------------------------------------
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%
% In the following, I assumed (as it is not clearly specified by Axon) that when the 'Comment ()' field exists, it 
% corresponds to the rightmost column in the .ATF file (i.e. comments are always the last rightmost column).
%
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%----------------------------------------------------------------------------------------------------------------------------
%----------------------------------------------------------------------------------------------------------------------------


%----------------------------------------------------------------------------------------------------------------------------

% Let's check the number and the type of input arguments.
if nargin < 1
  error('Function requires one input argument (the ATF filename)');
elseif ~isstr(file)
  error('Input must be a string representing an ATF filename');
end % if

% Let's check the number of output arguments.
if nargout < 4
 error('Function requires 4 output arguments');
end % if

%----------------------------------------------------------------------------------------------------------------------------

fid = fopen(file);              % Open the file.  If this returns a -1, we did not open the file successfully.
if fid==-1
 error(sprintf('File %s has not been found or permission denied',file));
 return;
end % if

header   = '';                  % I initialize output variables, in case the function should immediately return for an error.
labels   = {};                  % I initialize output variables, in case the function should immediately return for an error.
comments = {};                  % I initialize output variables, in case the function should immediately return for an error.
data     = [];                  % I initialize output variables, in case the function should immediately return for an error.

hlines = 0;
%----------------------------------------------------------------------------------------------------------------------------
line   = fgetl(fid);              % I get one line from the file (discard the newline character at its end).
%----------------------------------------------------------------------------------------------------------------------------
if (size(line,2)<7)               % I return an error if the length of the first line is not 7 or if it's not 'ATF<tab>1.0'
 error(sprintf('File %s is not a valid ATF 1.0 file (first line length error)',file));
 fclose(fid);
 return;
else
 if (~strcmp(line(1:3),'ATF') | ~strcmp(line(5:7),'1.0'))
  error(sprintf('File %s is not a valid ATF 1.0 file (first line format error)',file));
  fclose(fid);
  return;
 end % if
end % if
%----------------------------------------------------------------------------------------------------------------------------
header = sprintf('%s\n%s',header,line); % I start storing the header on the output argument.
 
%----------------------------------------------------------------------------------------------------------------------------
line   = fgetl(fid);              % I get one line from the file (discard the newline character at its end).
%----------------------------------------------------------------------------------------------------------------------------
tmp  = str2num(line);           % Temporary data structure (to facilitate addressing of individual elements).
N    = tmp(1);                  % Now I know the number of optional header records.
M    = tmp(2);                  % Now I know how many columns of data are contained in the file, after the header.
%----------------------------------------------------------------------------------------------------------------------------
header = sprintf('%s\n%s',header,line);

for c = 1:N                               % I want to go through each remaining lines composing the header..
 line   = fgetl(fid);                     % I get one line from the file (discard the newline character at its end).  
 header = sprintf('%s\n%s',header,line);  % I add the current line to the output header structure, to be returned as text.
end % for 

line   = fgetl(fid);              % I get one line from the file (discard the newline character at its end).  
index  = find(line=='"');         % I extract the positions inside the actual line, containing the '"' elements, assumed to be spacer for the labels.
if (size(index,2) ~= (M*2))       % If the number of labels found in the header does not match to M, there is a file format error.
 error(sprintf('File %s is not a valid ATF 1.0 file (wrong number of comments in the file)',file));
 fclose(fid);
 return;
end % if

d = 1;                            % I initialize the running index on labels{}, being a cell array of strings.
c = 1;                            % I initialize the running index on line, extracting individual labels.
while (c<=(M*2))
 labels{d} = line(index(c)+1:index(c+1)-1);
 c = c + 2;                       % Number '2' is *magic* as I assumed there exist always two '"' for each comment..
 d = d + 1;                       % Let's proceed with the next element.
end;

%----------------------------------------------------------------------------------------------------------------------------
if strcmp(labels(d-1),'Comment ()') % I assumed that if the 'Comment ()' label exists, it is the rigthmost (last) column.
 commt = 1;                         % and if this is the case I use a boolean variable to distinguish the file format parsing.
else                                
 commt = 0;                         % When no comment is included in the ATF file, columns elements are homogenous (i.e. numbers).
end % if
%----------------------------------------------------------------------------------------------------------------------------

if (~commt)
 [data, count] = fscanf(fid, '%f'); % No comments columb has been included in the ATF file. Data can be acquired quickly. 
 
else                                % There is a comment row.. so appropriate action to parse items correctly must be undertaken!

 d = 1;                             % Running index on the current comment number.
 format = '';                       % Format of the data parsing (as in standard C programming).
 for c=1:(M-1),                     %
  format = sprintf('%s%%f ',format);% Of course I wish (M-1)-times '%f' symbols (the column is NOT a %f-loat item).
 end % for                          %
 while (~feof(fid))                 % Old style data parsing, while I did not reach the end of file..
  line = fgetl(fid);                % I acquire a line and I put in 'line' as a string (retaining all the elements as characters).
  tmp = find(line=='"');            % I extract delimiters for the comment at that line.
  [datatmp,count,errormsg,nextindex] = sscanf(line,format);  % I read only part of the string contained in 'line'.
  if ((tmp(2) - tmp(1)) > 1)       % If there is a non-null comment between '"' symbols
   comments{d,1} = datatmp(1);      % I put the data-stamp for loggin purpouses
   comments{d,2} = line(tmp(1)+1:tmp(2)-1); % I write the comment as a string.
   d = d + 1;                               % I am ready to the next non-null comment.
  end % if
  data = [data;datatmp];            % I accumulate acquired (numerical) data, for further reshaping at the end of the processing.
 end % while
 M = M - 1;                         % To reshape the data vector I must keep in mind the I have (M-1) columns of numerical values.
end % if

% I now resize output data, based on the number of (data)columns (as reported in the header and contained 
% in M, and the total number of data elements acquired from the file. Since the data was read in row-wise,
% and MATLAB stores data in columnwise format, I have to reverse the size arguments and then transpose the
% data.  If I read in irregularly spaced data, then the division we are about to do will not work. Therefore,
% we will trap the error with an EVAL call; if the reshape fails, we will just return the data as is.

 eval('data = reshape(data, M, length(data)/M)'';', '');     % This is taken from Mathworks' Tech-Note 1402 
 fclose(fid);                                                % (http://www.mathworks.com/support/tech-notes/1400/1402.shtml)
 
 % Job done!
