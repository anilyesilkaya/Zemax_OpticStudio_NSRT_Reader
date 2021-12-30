%ZEMAX Ray Data Base Interpreter
%Author: Anil Yesilkaya - The University of Edinburgh
% Date: 05/02/2020
% Modified: 01/06/2020 (Detector angular & spectral characteristics added)
%previously scatter into multiple child rays was not considered properly)
%--------------------------------------------------------------------------
clc
%clf
clear
close all
%--------------------------------------------------------------------------
plotFlag = 0; %Plot the segments 0-NO, 1-YES
%--------------------------------------------------------------------------
%Definition of the project folder
projectFolder = 'A320_simplified'; %Name of the project folder
rayFile = 'seated_realistic_SFH4253_r3A3_H22_test.txt'; %Name of the ray file
configFile = 'fileConfig.txt'; %Name of the configuration file
d_FolderName = 'OSRAM_SFH_2704';
d_specFile = 'SFH_2704_spectral_micron.mat';%Name of the detector spectral file
d_angFile = 'SFH_2704_angular.mat';%Name of the detector angular file
lensUnit = 'cm'; %Lens unit
detID = 22; %ID of the intended receive detector
%--------------------------------------------------------------------------
projectFolderPath = ['..\..\',projectFolder];
cd(projectFolderPath);
configFilePath = ['.\',configFile];
rayFilePath = ['.\ray_database\',rayFile];
d_specFilePath = ['.\detectors\',d_FolderName,'\spectral\',d_specFile];
d_angFilePath = ['.\detectors\',d_FolderName,'\angular\',d_angFile];
%Including the necessary subfunctions
addpath('..\NSRT_Reader\vfinal\subfunc')
%--------------------------------------------------------------------------
%Reading the config file
% 1)Psource 2)areaPD 3)s_specFlag 4)d_specFlag 5)d_angFlag 6)detHA
% 7)objID 8)thetaX 9)thetaY 10)thetaZ
paramConfig = importdata(configFilePath,' ');
%
Psource = paramConfig.data(1); %Transmit power per luminary in Watts
areaPD = paramConfig.data(2); %area of the PD (in lens unit^2)
s_specFlag = paramConfig.data(3); %Source spectral file is used? 0-NO, 1-YES
d_specFlag = paramConfig.data(4); %Detector spectral file is used? 0-NO, 1-YES
d_angFlag = paramConfig.data(5); %Detector angular file is used? 0-NO, 1-YES
detHA = paramConfig.data(6); %Detector FOV half-angle if d_angflag=0
objID = paramConfig.data(7); %ID of an environment object (CAD)
thetaX = paramConfig.data(8); %Tilt of the detector w.r.t x-axis (in degrees)
thetaY = paramConfig.data(9); %Tilt of the detector w.r.t y-axis (in degrees)
thetaZ = paramConfig.data(10); %Tilt of the detector w.r.t z-axis (in degrees)
%--------------------------------------------------------------------------
%Load Detector Spectral and/or Angular Profile
if all(d_specFlag)
    %spectral_weight: normalized weights for PD spectral responsivity
    %wavelength in microns
    load(d_specFilePath)
    d_specWeight = spectral_weight;
    d_wave = wavelength;
    clear spectral_weight wavelength
end
%
if all(d_angFlag)
    %f: normalized weights for PD angle response [0 1]
    %angle: angle in degrees [0 90]
    load(d_angFilePath)
    d_angWeight = f;
    d_angle  = angle;
    clear f angle
end
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
tempRes = 0.2e-9; %Temporal resolution for binning
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
%--------------------------------------------------------------------------
%Reading the RDB files
%#  C_Ray: Number of Rays X 1 cell
%#  Each cell is (#Seg X #Branch) X #Parameters
%#  In purely reflective simulation, #Branch=1
[C_Ray,param_VEC] = readZMX(rayFilePath,s_specFlag);
fprintf('--------- Ray Data Base ---------\n')
fprintf([rayFile,'\n'])
fprintf(['Total Number of Hitting Rays: ',num2str(size(C_Ray,1)),'\n'])
%**************************************************************************
I_VEC = []; %received intensity vector
time_VEC = []; %elapsed time vector
nHitsMax = 0; %number of maximum reflections
%==========================================================================
for n_Ray=1:length(C_Ray) %parfor loop
    segLength_VEC =[];
    %C_Ray: #1-Seg / 2-Prnt / 3-Levl / 4-In / 5-Hit / 6-Face / [7 10]-XRTS
    %[11 14]-DGEF / [15 16]-BZ / 17-X / 18-Y / 19-Z / 20-Intensity
    dataTemp = C_Ray{n_Ray};
    dataTemp(:,20) = dataTemp(:,20)./Psource; %Optical power normalization
    %
    idxSegHit = find(dataTemp(:,5) == detID)-1; %Find the segment indexes that hit the detector
    %----------------------------------------------------------------------
    %Check the ray segment which hits the detector
    if isempty(idxSegHit)
        error('Error! Detector object cannot be found')
    end
    %----------------------------------------------------------------------
    %Calculating the number of reflections
    nHitsTemp = max(dataTemp(:,3))-1; %(nmax levls. - 1) = nmax reflections
    nHitsMax = max(nHitsMax,nHitsTemp);
    %======================================================================
    %Processing the segments
    for n_Seg=1:idxSegHit
        %Path Length and Time of Fly Calculations:
        %Segment vector originates from ind_Seg+1 and terminates in ind_Seg
        seg_VEC = [dataTemp(n_Seg,17) dataTemp(n_Seg,18) dataTemp(n_Seg,19)]...
            -[dataTemp(n_Seg+1,17) dataTemp(n_Seg+1,18) dataTemp(n_Seg+1,19)];
        segLength_VEC = [segLength_VEC norm(seg_VEC)];
    end
    %======================================================================
    %Angle of incidence (degrees)
    incAngle = acosd( (dot(seg_VEC,normalPD))/(norm(seg_VEC)*norm(normalPD)) );
    %Total ray length
    rayLength = sum(segLength_VEC);
    %Time of fly (seconds)
    elapsedTime = rayLength/c;
    %----------------------------------------------------------------------
    %Spectral and angular processing all the LoS segments (k = 0,1,...,K)
    if d_angFlag==1 && d_specFlag==1
        %#  (specFlag=1) param_VEC: (5 x Number of Rays)
        %#  1-Ray #, 2-Wavelength, 3-Wavelength unit, 4-Number of segments
        %#  5-Number of branches
        id_specWeight = interp1(d_wave,d_specWeight,param_VEC(2,n_Ray),'pchip');
        id_angWeight = interp1(d_angle,d_angWeight,incAngle,'pchip');
        %
        I_VEC = [I_VEC id_specWeight*id_angWeight*dataTemp(n_Seg+1,20)];
        time_VEC = [time_VEC elapsedTime];
        %
    elseif d_angFlag==1 && d_specFlag==0
        %
        I_VEC = [I_VEC id_angWeight*dataTemp(n_Seg+1,20)];
        time_VEC = [time_VEC elapsedTime];
        %
    elseif d_angFlag==0 && d_specFlag==1
        %
        I_VEC = [I_VEC id_specWeight*cosd(incAngle)*dataTemp(n_Seg+1,20)];
        time_VEC = [time_VEC elapsedTime];
        %
    else
        %
        I_VEC = [I_VEC cosd(incAngle)*dataTemp(n_Seg+1,20)];
        time_VEC = [time_VEC elapsedTime];
        %
    end
    %----------------------------------------------------------------------
end
%**************************************************************************
%
%CIR Post Processing
%Sorting the time and intensity vectors
[stime_VEC,tidx_VEC] = sort(time_VEC,'ascend');
sI_VEC = I_VEC(tidx_VEC);
%--------------------------------------------------------------------------
%Binning the data
[bstime_VEC,bsI_VEC,numBins] = binData(stime_VEC,sI_VEC,tempRes);
%==========================================================================
%Calculation of the channel parameters
H0 = sum(bsI_VEC);
kappa = nHitsMax;
tau_bar = sum(bstime_VEC.*(bsI_VEC.^2)) / sum(bsI_VEC.^2);
tau_RMS = sqrt( sum(((bstime_VEC-tau_bar).^2).*(bsI_VEC.^2)) / sum(bsI_VEC.^2) );
%
%--------------------------------------------------------------------------
fprintf(['Kappa: ',num2str(kappa),'\n'])
fprintf(['H(0;S,R) (W): ',num2str(H0),'\n'])
fprintf(['tau_RMS (ns): ',num2str(round(tau_RMS*1e9,3)),'\n'])
%--------------------------------------------------------------------------
%%
%Plotting the channel impulse response
fig_linewidth=2;
fig_markersize=3;
%
figure('color','white');
plot([0 bstime_VEC(1)-(1e-100) bstime_VEC]*1e9, [0 0 bsI_VEC],'b','LineWidth',fig_linewidth,'MarkerSize',fig_markersize)
grid on
xlabel('time (ns)')
ylabel('Channel Impulse Response')
set(gcf, 'Units', 'centimeters')
set(findall(gcf,'-property','FontSize'),'FontSize',13)
xlim([0 10])
%legend(['MCRT (Simp.)'])
%--------------------------------------------------------------------------