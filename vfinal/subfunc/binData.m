%##########################################################################
%#  ZEMAX Ray Data Binner
%#  Author: Anil Yesilkaya - The University of Edinburgh
%#  Date: 19/02/2020
%#  
%#  INPUTS:
%#  time_VEC: Time vector
%#  I_VEC: Intensity vector
%#  binWidth
%#
%#  OUTPUTS:
%#  btime_VEC
%#  bI_VEC
%#  numBins
%#  
%##########################################################################
function [btime_VEC,bI_VEC,numBins] = binData(time_VEC,I_VEC,binWidth)
%**************************************************************************
%**************************************************************************
numBins=ceil( (time_VEC(end)-time_VEC(1))/binWidth );
binEdges = time_VEC(1)+((0:numBins).*binWidth);
%Control numBins
if numBins == 0
    error('Error! Check the temporal resolution value!')
end
%
btime_VEC = [];
bI_VEC = [];
for ind_e=1:numBins
    
    if ind_e ~= numBins
        logic_VEC = (binEdges(ind_e) <= time_VEC) & (time_VEC < binEdges(ind_e+1));
    else
        logic_VEC = (binEdges(ind_e) <= time_VEC) & (time_VEC <= binEdges(ind_e+1));
    end
    %----------------------------------------------------------------------
    if any(logic_VEC)~=0
            btime_VEC = [btime_VEC (binEdges(ind_e)+binEdges(ind_e+1))/2];
            bI_VEC = [bI_VEC sum(I_VEC(logic_VEC))];
    else
            btime_VEC = [btime_VEC (binEdges(ind_e)+binEdges(ind_e+1))/2];
            bI_VEC = [bI_VEC 0];
    end
    
end
%
if isempty(btime_VEC) || isempty(bI_VEC)
    error('Error! Please check the temporal resolution')
end
%

end %end function