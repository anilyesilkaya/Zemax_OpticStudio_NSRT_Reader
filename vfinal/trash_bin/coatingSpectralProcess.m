%##########################################################################
%#  ZEMAX Source& Coating Spectrum File Processor
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
%#  - The wavelengths must be in micrometers in order to comply with ZEMAX
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
%--------------------------------------------------------------------------
projectFilePath = ['..\..\',projectFolder];
cd(projectFilePath)
cd('.\coating_materials\')
%Reading the spectral reflectance values
fnames = {'splib07a_Plastic_HDPE_GDS384_Wht_Opaq_ASDFRa_AREF',...
          'splib07a_Nylon_Fabric_GDS433_Blu_RpSt_ASDFRa_AREF',...
          'splib07a_Polyester_Pile_GDS434_Blk_ASDFRa_AREF'};

fch = 'splib07a_Wavelengths_ASD_0.35-2.5_microns_2151_ch';
%--------------------------------------------------------------------------
if all(plotFlag)
    %PLOTTING
    fig_linewidth=1.5;
    fig_markersize=8;
    figure('color','white');
end
%--------------------------------------------------------------------------
for i=1:size(fnames,2)
    cd(['./' fnames{i}]);
    %
    relative_weight{i}=textread(['.\' fnames{i} '.txt'],'%f','headerlines', 1);
    %
    wavelength{i} = textread(['.\' fch '.txt'],'%f','headerlines', 1);
    %
    if all(plotFlag)
        plot(wavelength{i},relative_weight{i},'LineWidth',fig_linewidth,'MarkerSize',fig_markersize)
        hold on
    end
    %
    cd('../')
end
grid on
xlabel('Wavelength (\mu m)')
ylabel('Relative Weight')
set(gcf, 'Units', 'centimeters')
set(findall(gcf,'-property','FontSize'),'FontSize',13.5)
xlim([min(wavelength) max(wavelength)])
set(gca, 'FontName', 'Times New Roman')
legend('Opaque Plastic (White)','Nylon Fabric (Blue)','Polyester Pile Carpet (Black)','Location','Best')
hold off
%--------------------------------------------------------------------------
%Saving the coating table into a txt file
if all(saveFlag)
    for j=1:size(relative_weight,2)
        rw_temp = relative_weight{j};
        w_temp = wavelength{j};
        
        fid = fopen([fnames{j},'.txt'],'w');
        fprintf(fid,'TABLE %s\n',fnames{j});
        fprintf(fid,'ANGL %i\n',0);
        for ind=1:length(spectra_match)
            %Coating table syntax:
            %TABLE <coating name>
            %ANGL <angle in degrees>
            %WAVE <wavelength 1 in micrometers> Rs Rp Ts Tp
            fprintf(fid,'WAVE %.4f %.4f %.4f %.1f %.1f\n',...
                w_temp(ind),rw_temp(ind),rw_temp(ind),0,0);
        end
        fid = fclose(fid);
    end
end
%--------------------------------------------------------------------------