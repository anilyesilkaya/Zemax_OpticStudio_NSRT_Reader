%##########################################################################
%#  ZEMAX Ray Branch Constructor
%#  Author: Anil Yesilkaya - The University of Edinburgh
%#  Date: 06/08/2020
%#  
%#  INPUTS:
%#
%#
%#
%#
%#  OUTPUTS:
%#
%#
%#
%#  
%##########################################################################
function [branchFamTree] = branchConstructor(dataTemp,idxSegHit_VEC)
nBranch = length(idxSegHit_VEC);
%
branchFamTree =[];
for iB = 1:nBranch
    idxSegHit = idxSegHit_VEC(iB); % 0:nSeg-1
    segFamTree = []; % family tree of the segment indexes
    nLevel = dataTemp(idxSegHit+1,3); % number of steps to reach the source segment
    segFamTree = [segFamTree idxSegHit];
    idxSegPrnt = idxSegHit;
    %
    for iL = 1:nLevel
        idxSegPrnt = dataTemp(idxSegPrnt+1,2);% index of the parent segment
        segFamTree = [segFamTree idxSegPrnt];
    end
    branchFamTree{iB} = fliplr(segFamTree).';
end
%
end % end function