%##########################################################################
%#  ZEMAX Data Binner (Integer Time Binning)
%#  Author: Anil Yesilkaya - The University of Edinburgh
%#  Date: 19/02/2020
%#  
%#  Bins the ZEMAX Ray Data
%#  INPUTS:
%#  time_VEC: Time vector
%#  inten_VEC: Intensity vector
%#  binWidth
%#
%#  OUTPUTS:
%#  binTime_VEC
%#  binInten_VEC
%#  
%#
%##########################################################################
function [btime_VEC,binten_VEC] = intBinData(time_V,inten_V,binWidth)
%**************************************************************************
%**************************************************************************
time_V = 1e9*time_V;
binWidth = 1e9*binWidth;
%
numBins=ceil( ( time_V(end)-floor(time_V(1)) )/binWidth );
binEdges = floor(time_V(1))+([0:numBins].*binWidth);
%Control numBins
if numBins == 0
    error('Error! Check the temporal resolution value!')
end
%
btime_VEC = [];
binten_VEC = [];
for ind_e=1:numBins
    if ind_e ~= numBins
        logic_VEC = (binEdges(ind_e) <= time_V) & (time_V < binEdges(ind_e+1));
        if any(logic_VEC)~=0
            btime_VEC = [btime_VEC mean( [binEdges(ind_e) binEdges(ind_e+1)] )];
            binten_VEC = [binten_VEC sum(inten_V(logic_VEC))];
        else
            btime_VEC = [btime_VEC mean( [binEdges(ind_e) binEdges(ind_e+1)] )];
            binten_VEC = [binten_VEC 0];
        end
    else
        logic_VEC = (binEdges(ind_e) <= time_V) & (time_V <= binEdges(ind_e+1));
        if any(logic_VEC)~=0
            btime_VEC = [btime_VEC mean( [binEdges(ind_e) binEdges(ind_e+1)] )];
            binten_VEC = [binten_VEC sum(inten_V(logic_VEC))];
        else
            btime_VEC = [btime_VEC mean( [binEdges(ind_e) binEdges(ind_e+1)] )];
            binten_VEC = [binten_VEC 0];
        end
    end
end
%
if isempty(btime_VEC) || isempty(binten_VEC)
    error('Error! Please check the temporal resolution')
end
%
btime_VEC = 1e-9*btime_VEC;
end %end function