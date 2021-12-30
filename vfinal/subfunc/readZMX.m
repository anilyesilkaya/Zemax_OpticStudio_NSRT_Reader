%##########################################################################
%#  ZEMAX File Processor
%#  Author: Anil Yesilkaya - The University of Edinburgh
%#  Date: 05/02/2020
%#  USAGE:  [C_Ray,param_VEC] = readZMX(Zemax_Output_File)
%#  EXAMPLE: [C_Ray,param_VEC] = readZMX('data.txt')
%#  Reads data from Zemax text-output files
%#  INPUTS:
%#  F: The Zemax-generated text file

%#  OUTPUTS:
%#  C_Ray: Number of Rays X 1 cell
%#  Each cell is (#Seg X #Branch) X #Parameters
%#  In purely reflective simulation, #Branch=1
%#
%#  Column1-[Seg#], Column2-[Parent], Column3-[Level], Column4-[In],
%#  Column5-[Hit], Column6-[Face], Column7-[X], Column8-[R], Column9-[T],
%#  Column10-[S], Column11-[D], Column12-[G], Column13-[E], Column14-[F], 
%#  Column15-[B], Column16-[Z], Column17-[X-axis], Column18-[Y-axis],
%#  Column19-[Z-axis], Column20-[Intensity]
%#
%#  (specFlag=0) param_VEC: (6 x Number of Rays) Parameters vector
%#  1-Ray #, 2-Wavelength number(1), 3-Wavelength value,
%#  4-Wavelength unit, 5-Number of segments, 6-Number of branches
%
%#  (specFlag=1) param_VEC: (5 x Number of Rays)
%#  1-Ray #, 2-Wavelength, 3-Wavelength unit, 4-Number of segments
%#  5-Number of branches
%
%
%##########################################################################
function [C_Ray,param_VEC] = readZMX(F,specFlag)
%**************************************************************************
%**************************************************************************
% File check:
fid = -1;
flag_F = isfile(F);
if flag_F == 1
   % Open file:
   fid = fopen(F,'r');
end
if fid == -1
   error(['Error! File ' F ' cannot be opened.'])
end
%--------------------------------------------------------------------------
% Skip the Header
scanLine = fgetl(fid); % Scan a line
while isempty(sscanf(scanLine,'Ray %i'))
    scanLine = fgetl(fid); % Scan a line
end
%**************************************************************************
%**************************************************************************
%Data Process:
ind=0;
%Scan the document & save line by line until the end
while ischar(scanLine)
    ind = ind + 1;
    C{ind,:} = scanLine;
    scanLine = fgetl(fid); %Scan another line
end
%--------------------------------------------------------------------------
% Extracting Parameters:
% Parameters
% 1-Ray #, 2-Wavelength #, 3-Wavelength value, 
% 4-Wavelength unit 5-Number of segments, 6-Number of branches
% Search string
if specFlag == 0
    strSearch = 'Ray %i, Wavelength %f (%f %cm), %i segments, %i branches:';
    lengthParam = 6;
    idxnSegParam = 5; % index of the nSeg in param_VEC
else
    strSearch = 'Ray %i, Wavelength %f %cm, %i segments, %i branches:';
    lengthParam = 5;
    idxnSegParam = 4; % index of the nSeg in param_VEC
end
%
param_VEC = [];
locRay_VEC = []; %Ray locations vector
for ind_line=1:length(C)
    tempLine = C{ind_line};
    if length(sscanf(tempLine,strSearch)) == lengthParam
        param_VEC = [param_VEC sscanf(tempLine,strSearch)];
        locRay_VEC = [locRay_VEC ind_line];% Locations of the ray beginnings
    end
end
%
% Control of the extraction
if isempty(param_VEC) || isempty(locRay_VEC)
    error('Data extraction error! Check the TXT file headers!!')
end
%--------------------------------------------------------------------------
%Interpretation of the information:
%Fetching Numeric Information
strCompare = '%i %i %i %i %i %i %4c %4c %2c %f %f %f %f';
for ind_Ray=1:length(locRay_VEC)%rays
    data_VEC = [];
    for ind_Seg=1:(param_VEC(idxnSegParam,ind_Ray)+1)%
        pointer = locRay_VEC(ind_Ray)+1+ind_Seg; % +1 due to the header
        % Fetching the useful data from character string
        % #Seg/Prnt/Levl/In/Hit/Face/XRTS/DGEF/BZ/X/Y/Z/Intensity
        % Total of 13 numbers
        [dataFetch,n]=sscanf(C{pointer},strCompare,[1 13]);
        if n==13
            data_VEC=[data_VEC ; dataFetch];
        else
            error('Data fetching error!')
        end
    end
    C_Ray{ind_Ray,:} = data_VEC;
end

clear C; 
%**************************************************************************
%**************************************************************************
% Close file and exit:
fclose('all');
%
end % end function