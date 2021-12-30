%##########################################################################
%#  ZEMAX Spectrum File Processor
%#  For sources and coating materials
%#  Author: Anil Yesilkaya - The University of Edinburgh
%#  Date: 22/02/2020
%#  Modified: 08/06/2020
%#  
%#
%#  INPUTS:
%#  -
%#  -
%#  -
%#
%#  OUTPUTS:
%#  -
%#  -
%#  NOTES:
%#  - The wavelengths must be in micrometers in order to comly with ZEMAX
%#  - Spectral files (.spcd) for the sources in ZEMAX is restricted to have
%#      200 data points.
%#  - Spectral files for the coating in ZEMAX is not restricted
%#      in terms of data points.
%#
%##########################################################################
%--------------------------------------------------------------------------
clc
clf
clear
close all
%--------------------------------------------------------------------------
plotFlag = 1; %Plot? 0-NO, 1-YES
saveFlag = 0; %Save? 0-NO, 1-YES
%--------------------------------------------------------------------------
%Definition of the project folder
projectFolder = 'A320_simplified'; %Name of the project folder
s_FolderName = 'OSRAM_SFH_4253';
s_specFile = 'SFH_4253_spectral_micron.mat'; %Source spectral file
%--------------------------------------------------------------------------
projectFilePath = ['..\..\',projectFolder];
cd(projectFilePath)
cd(['.\sources\',s_FolderName,'\spectral\'])
load(['.\',s_specFile]); %wavelength, relative_weight
%--------------------------------------------------------------------------
%Printing the Source File Characteristics
fprintf('Source File Properties\n')
fprintf('------------------------\n')
fprintf(['File Name: ',s_specFile,'\n'])
fprintf(['Number of Wavelengths: ',num2str(length(wavelength)),'\n'])
fprintf(['Min & Max Wavelengths: ',num2str(min(wavelength)),' / ',num2str(max(wavelength)),' micrometers \n'])
fprintf(['Optical Bandwidth: ',num2str(max(wavelength)-min(wavelength)),' micrometers\n'])
fprintf('------------------------\n')
%--------------------------------------------------------------------------
delta_w = (wavelength(end)-wavelength(1))/199;
w_interp = wavelength(1):delta_w:wavelength(end);
r_weight_interp = interp1(wavelength,relative_weight,w_interp,'pchip');
fprintf(['Spectral Resolution of the Output File: ',num2str(delta_w),' micrometers \n'])
%--------------------------------------------------------------------------
%Saving the source .spcd file
if all(saveFlag)
    fid = fopen([fileSource(1:end-4),'.spcd'],'w'); 
    for ind=1:length(w_interp)
        fprintf(fid,'%f %f\n',w_interp(ind),r_weight_interp(ind));
    end
    fid = fclose(fid);
end
%--------------------------------------------------------------------------
if all(plotFlag)
    %PLOTTING
    fig_linewidth=1.5;
    fig_markersize=8;
    %--------------------------------------------------------------------------
    figure('color','white');
    plot(wavelength,relative_weight,'k','LineWidth',fig_linewidth,'MarkerSize',fig_markersize)
    hold on
    plot(w_interp,r_weight_interp,'r:','LineWidth',fig_linewidth,'MarkerSize',fig_markersize)
    grid on
    xlabel('Wavelength (\mu m)')
    ylabel('Relative Weight')
    set(gcf, 'Units', 'centimeters')
    set(findall(gcf,'-property','FontSize'),'FontSize',13.5)
    set(gca, 'FontName', 'Times New Roman')
    legend('Source File','Converted File')
    hold off
end