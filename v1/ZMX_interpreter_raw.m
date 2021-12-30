%ZEMAX Ray Data Base Interpreter
%Author: Anil Yesilkaya - The University of Edinburgh
%Date: 05/02/2020
%--------------------------------------------------------------------------
clc
clf
clear
close all
%--------------------------------------------------------------------------
projectFolder = '5_5_3_room'; %Project folder
fileName = '5_5_3_room.txt'; %Name of the Ray database file
filePath =['..\',projectFolder,'\ray_database\',fileName]; %Path to the ZEMAX analysis file
lensUnit = 'cm'; %Lens unit value
tempRes = 0.2*10^(-9);
%Source
s_specFlag = 1; %Spectral file for the source is used? 0-NO, 1-YES
s_angFlag = 1; %Angular file for the source is used? 0-NO, 1-YES
%Receiver
d_specFlag = 1; %Spectral file for the detector is used? 0-NO, 1-YES
d_angFlag = 1; %%Angular file for the detector is used? 0-NO, 1-YES
thetaX = 90; %Tilt of the detector w.r.t x-axis (in degrees)
thetaY = 0; %Tilt of the detector w.r.t y-axis (in degrees)
thetaZ = 0; %Tilt of the detector w.r.t z-axis (in degrees)
detHA = 85; %the FOV half-angle of the detector
detID = 6; %ID of the intended receive detector
%areaPD = 100; %area of the PD (in lens unit^2)
%
plotFlag = 0; %Plot the segments 0-NO, 1-YES
%--------------------------------------------------------------------------
%ZEMAX Definitions
vectorPD = [0 0 -1].'; %Default orientation vector of the PD in ZEMAX
%--------------------------------------------------------------------------
switch upper(lensUnit)
    case 'M'
        c = 299792458; %Speed of light (m/s)
    case 'CM'
        c = (299792458)*100; %Speed of light (cm/s)
    otherwise
        error('Undefined Lens Unit!')
end
%
%tempRes = sqrt(areaPD)/c; %Time (x-axis) resolution
%--------------------------------------------------------------------------
%Definition of the rotation vectors
%Rotation matrix for  z-axis
G_z = [cosd(thetaZ) -sind(thetaZ) 0 ; sind(thetaZ) cosd(thetaZ) 0 ; 0 0 1];
%Rotation matrix for  y-axis
G_y =[cosd(thetaY) 0 sind(thetaY) ; 0 1 0 ; -sind(thetaY) 0 cosd(thetaY)];
%Rotation matrix for  x-axis
G_x =[1 0 0 ; 0 cosd(thetaX) -sind(thetaX) ; 0 sind(thetaX) cosd(thetaX)];
%--------------------------------------------------------------------------
%Calculate the normal vector of the PD
normalPD = G_x*G_y*G_z*vectorPD;
%--------------------------------------------------------------------------
%Fetch the data for Rays and Segments
[C_Ray,param_VEC] = readZMX(filePath,s_specFlag);
%C_Ray: Number of Rays X 1 cell
%Each cell has Number of Segments X Number of Parameters
%
%**************************************************************************
%**************************************************************************
CIRintensity_VEC = [];
CIRtime_VEC = [];
for ind_Ray=1:length(C_Ray) %parfor loop
    dataTemp = C_Ray{ind_Ray};
    nsegHit = find(dataTemp(:,5) == detID)-1;
    segLength_VEC =[];
    %
    if isempty(nsegHit)
        error('Error! Detector object cannot be found')
    end
    %
    for ind_Seg=1:nsegHit
%==========================================================================
        %Path Length and Time of Fly Calculations:
        %
        %Segment vector starting from ind_Seg+1 and terminates in ind_Seg
        seg_VEC = [dataTemp(ind_Seg,17) dataTemp(ind_Seg,18) dataTemp(ind_Seg,19)]...
            -[dataTemp(ind_Seg+1,17) dataTemp(ind_Seg+1,18) dataTemp(ind_Seg+1,19)];
        segLength_VEC = [segLength_VEC norm(seg_VEC)];
        %
        %Angle of incidence calculation:
        if ind_Seg == nsegHit
            incAngle = acosd( (dot(seg_VEC,normalPD))/(norm(seg_VEC)*norm(normalPD)) );
            %--------------------------------------------------------------
            if incAngle <= detHA
                rayLength = sum(segLength_VEC); %Total length (Ray Length)
                elapsedTime = rayLength/c; %time of fly (seconds)
                
                CIRintensity_VEC = [CIRintensity_VEC dataTemp(ind_Seg+1,20)];
                CIRtime_VEC = [CIRtime_VEC elapsedTime];
            end
            %--------------------------------------------------------------
        end
%==========================================================================
    end
end
%**************************************************************************
%**************************************************************************
%Sorting the CIR Vectors
[time_VEC,index_VEC] = sort(CIRtime_VEC,'ascend');
intensity_VEC = CIRintensity_VEC(index_VEC);

%
clear C_Ray CIRtime_VEC CIRintensity_VEC
%Binning the data
[binTime_VEC,binInten_VEC] = binData(time_VEC,intensity_VEC,tempRes);

%
clear time_VEC intensity_VEC
%--------------------------------------------------------------------------
%Plotting the CIR
fig_linewidth=1.5;
fig_markersize=8;

figure('color','white');
plot(binTime_VEC*1e9, binInten_VEC,'b','LineWidth',fig_linewidth,'MarkerSize',fig_markersize)
grid on
xlabel('time (ns)')
ylabel('Received Optical Intensity (W)')
set(gcf, 'Units', 'centimeters')
set(findall(gcf,'-property','FontSize'),'FontSize',11)
%--------------------------------------------------------------------------