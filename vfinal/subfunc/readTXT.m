%##########################################################################
%#  Simple .txt Reader
%#  Author: Anil Yesilkaya - The University of Edinburgh
%#  Date: 08/06/2020
%#  
%#  INPUTS:
%#  filePath - Path for the .txt file
%#  format - format of the data e.g. '%.4f %c'
%#  numHL - number of header lines
%#
%#  OUTPUTS:
%#  C - output cell
%##########################################################################
function [C] = readTXT(filePath,format,numHL)
fileFlag = isfile(filePath);
fid = -1;
%File Check
if fileFlag == 1
    fid = fopen(filePath);
    C = textscan(fid,format,'HeaderLines',numHL);
else
    error(['Error! File ' filePath ' is not a readable file.'])
end
%Open Check
if fid == -1
    error(['Error! File ' filePath ' cannot be opened.'])
end
%--------------------------------------------------------------------------
%Close file and exit:
fclose('all');
end