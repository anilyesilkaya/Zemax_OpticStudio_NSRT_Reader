%##########################################################################
%#  OpticStudio Source & Coating & Detector Spectrum File Processor
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
addpath('..\..\..\MATLAB\EXPORT_FIG\export_fig')
%--------------------------------------------------------------------------
s.plotFlag = 0; %Source Plot? 0-NO, 1-YES
s.saveFlag = 0; %Source Save? 0-NO, 1-YES
c.plotFlag = 1; %Coating Plot? 0-NO, 1-YES
c.saveFlag = 0; %Coating Save? 0-NO, 1-YES
d.plotFlag = 0; %Detector Plot? 0-NO, 1-YES
%--------------------------------------------------------------------------
%Definition of the project folder
projectFolder = 'RIS_Wiley_book_chapter'; %Name of the project folder
s.folderNames = {'OSRAM_GW_QSSPA1_em','OSRAM_SFH_4253'};
%s.folderNames = {'PRO_ELEC_MR16_half_15','PRO_ELEC_MR16_half_60'};
% c.folderNames = {'splib07a_Plastic_HDPE_GDS384_Wht_Opaq_ASDFRa_AREF',...
%           'splib07a_Nylon_Fabric_GDS433_Blu_RpSt_ASDFRa_AREF',...
%           'splib07a_Polyester_Pile_GDS434_Blk_ASDFRa_AREF'};
c.folderNames = {'splib07a_Cobalt_green_GDS816_ASDFRa_AREF',...
                    'splib07a_Polyester_Pile_GDS434_Blk_ASDFRa_AREF'};
d.folderNames = {'OSRAM_SFH_2716','OSRAM_SFH_2704'};
%--------------------------------------------------------------------------
projectFilePath = ['..\..\',projectFolder];
cd(projectFilePath)
%Including the necessary subfunctions
addpath('..\NSRT_Reader\vfinal\subfunc')
%Figure Color Property
fig.linewidth=1.5;
fig.markersize=10;
fig.sourcecolors ={[1 0 1],[0 1 0],[1 0 0],[0 0 1],[0 1 1],[1 1 0]};
fig.coatcolors ={[0 0.4470 0.7410],[0.8500 0.3250 0.0980],[0.9290 0.6940 0.1250]...
    [0.4940 0.1840 0.5560],[0.4660 0.6740 0.1880],[0.3010 0.7450 0.9330],[0.6350 0.0780 0.1840]};
fig.detcolors = {[0 0 1],[0 0 1]};
%==========================================================================
%==========================================================================
%Source Processing
cd('.\sources')
for i=1:size(s.folderNames,2)
    cd(['.\',s.folderNames{i},'\spectral\'])
    %----------------------------------------------------------------------
    s_temp = readTXT(['.\',s.folderNames{i},'.txt'],'%f %f',1);
    s.wavelength{i} = s_temp{1};
    s.relweight{i} = s_temp{2};
    %----------------------------------------------------------------------
    %ZEMAX .spcd
    s.deltaw{i} = (s.wavelength{i}(end)-s.wavelength{i}(1))/199;
    %wavelength interpolation
    s.wavelengthI{i} = s.wavelength{i}(1):s.deltaw{i}:s.wavelength{i}(end);
    %rel_weight interpolation
    s.relweightI{i} = interp1(s.wavelength{i},s.relweight{i},s.wavelengthI{i},'pchip');
    %----------------------------------------------------------------------
    %Saving the source .spcd file
    if all(s.saveFlag)
        fid = fopen([s.folderNames{i},'.spcd'],'w'); 
        for ind=1:size(s.wavelengthI{i},2)
            %[wavelength in micrometers relative weights]
            fprintf(fid,'%6.4f %6.4f\n',s.wavelengthI{i}(ind),s.relweightI{i}(ind));
        end
        fid = fclose(fid);
    end
    %----------------------------------------------------------------------
    if all(s.plotFlag)
        %Source Plot
        figure('color','white');
        plot(s.wavelength{i},s.relweight{i},'LineWidth',fig.linewidth,...
            'MarkerSize',fig.markersize,'Color',fig.sourcecolors{i})
        hold on
        plot(s.wavelengthI{i},s.relweightI{i},'k:','LineWidth',fig.linewidth,...
            'MarkerSize',fig.markersize)
        grid on
        xlabel('Wavelength (\mu m)')
        ylabel('Relative Weight')
        set(gcf, 'Units', 'centimeters')
        set(findall(gcf,'-property','FontSize'),'FontSize',13.5)
        set(gca, 'FontName', 'Times New Roman')
        legend('Source File','Converted File')
        hold off
    end
%--------------------------------------------------------------------------
    cd('..\..')
end
cd('..')
%==========================================================================
%==========================================================================
%Coating Processing
cd('.\coating_materials')
cd(['.\',c.folderNames{1}])
%Wavelength Resolution for Coating Materials = 0.0010 micrometers
c_temp = readTXT('.\splib07a_Wavelengths_ASD_0.35-2.5_microns_2151_ch.txt','%f',1);
c.wavelength = c_temp{1};
cd('..')
%Matching coating files with sources
min_wavelengthI = min( horzcat(s.wavelengthI{:}) );
max_wavelengthI = max( horzcat(s.wavelengthI{:}) );
%
cidx_min = find( abs(c.wavelength-min_wavelengthI)<0.000001 );
cidx_max = find( abs(c.wavelength-max_wavelengthI)< 0.000001 );
%
c.wavelengthmatch = c.wavelength(cidx_min:cidx_max); %matching coating wavelengths
%--------------------------------------------------------------------------
for j=1:size(c.folderNames,2)
    cd(['.\',c.folderNames{j}])
    %----------------------------------------------------------------------
    c_temp = readTXT(['.\',c.folderNames{j},'.txt'],'%f',1);
    c.relweight{j} = c_temp{1};
    %----------------------------------------------------------------------
    c.relweightmatch{j} = c.relweight{j}(cidx_min:cidx_max); %matching coating relative weights
    %----------------------------------------------------------------------
    %Coating Interpolation
    for i=1:size(s.wavelengthI,2)
        c.relweightmatchI{i,j} = interp1(c.wavelengthmatch,c.relweightmatch{j},s.wavelengthI{i},'pchip');
    end
    %----------------------------------------------------------------------
    cd('..')
end
cd('..')
%--------------------------------------------------------------------------
%Coating Plot #1
if all(c.plotFlag)
    figure('color','white');
    for j=1:size(c.relweightmatch,2)
        plot(c.wavelength,c.relweight{j},'LineWidth',fig.linewidth,...
            'MarkerSize',fig.markersize,'Color',fig.coatcolors{j})
        c.legendInfo{j}=num2str(j);
        hold on
    end
    grid on
    xlabel('Wavelength (\mu m)')
    ylabel('Relative Weight')
    xlim([min(c.wavelength) max(c.wavelength)])
    set(gcf, 'Units', 'centimeters')
    set(gcf, 'units', 'normalized');
    set(gcf, 'Position', [0.1, 0.2, 0.3, 0.4]);
    set(findall(gcf,'-property','FontSize'),'FontSize',20)
    set(gca, 'FontName', 'Times New Roman')
    hold off
    legend(c.legendInfo,'Location','South')
end
%--------------------------------------------------------------------------
%Coating Plot #2
if all(c.plotFlag)
    for j=1:size(c.relweightmatchI,2)
        figure('color','white');
        plot(c.wavelengthmatch,c.relweightmatch{j},'LineWidth',fig.linewidth,...
                'MarkerSize',fig.markersize,'Color',fig.coatcolors{j})
        hold on
        for i=1:size(c.relweightmatchI,1)
            plot(s.wavelength{i},s.relweight{i},'-','LineWidth',fig.linewidth,...
                'MarkerSize',fig.markersize,'Color',fig.sourcecolors{i})
            plot(s.wavelengthI{i},s.relweightI{i}.*c.relweightmatchI{i,j},...
                'Color',fig.sourcecolors{i},'LineStyle','-.','LineWidth',fig.linewidth,'MarkerSize',fig.markersize)
        end
        hold off
        grid on
        xlabel('Wavelength (\mu m)')
        ylabel('Relative Weight')
        xlim([min(c.wavelengthmatch) max(c.wavelengthmatch)])
        set(gcf, 'units', 'normalized');
        set(gcf, 'Position', [0, 0.1, 0.3, 0.4]);
        set(findall(gcf,'-property','FontSize'),'FontSize',20)
        set(gca, 'FontName', 'Times New Roman')
        legend(num2str(j),'Location','NorthWest')
    end
end
%--------------------------------------------------------------------------
%Saving the coating table into a txt file
if all(c.saveFlag)
    for j=1:size(c.relweightmatch,2)
        rw_temp = c.relweightmatch{j};
        w_temp = c.wavelengthmatch;

        fid = fopen([c.folderNames{j},'.txt'],'w');
        fprintf(fid,'TABLE %s\n',c.folderNames{j});
        fprintf(fid,'ANGL %i\n',0);
        for ind=1:length(c.wavelengthmatch)
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
%==========================================================================
%==========================================================================
%Detector Processing
cd('.\detectors')
%--------------------------------------------------------------------------
for k=1:size(d.folderNames,2)
    cd(['.\',d.folderNames{k},'\spectral\'])
    d_temp = readTXT(['.\',d.folderNames{k},'.txt'],'%f %f',1);
    d.wavelength{k} = d_temp{1};
    d.relweight{k} = d_temp{2};
    %----------------------------------------------------------------------
    %Matching detector files with sources
    for i=1:size(s.wavelengthI,2)
        d.relweightI{i,k} = interp1(d.wavelength{k},d.relweight{k},s.wavelengthI{i},'pchip');
    end
    %----------------------------------------------------------------------
    %----------------------------------------------------------------------
    cd('..\..')
end
cd('..')
%--------------------------------------------------------------------------
%Detector Plot #1
if all(d.plotFlag)
    for k=1:size(d.relweight,2)
        figure('color','white');
        for i=1:size(s.wavelengthI,2)
            plot(d.wavelength{k},d.relweight{k},'LineWidth',fig.linewidth,...
                'MarkerSize',fig.markersize,'Color',fig.detcolors{k})
            hold on
            plot(s.wavelengthI{i},s.relweightI{i},'LineWidth',fig.linewidth,...
                'MarkerSize',fig.markersize,'Color',fig.sourcecolors{i})
            plot(s.wavelengthI{i},s.relweightI{i}.*d.relweightI{i,k},'k:','LineWidth',fig.linewidth,...
                'MarkerSize',fig.markersize)
        end
        hold off
        grid on
        xlabel('Wavelength (\mu m)')
        ylabel('Relative Weight')
        xlim([min(d.wavelength{k}) max(d.wavelength{k})])
        set(gcf, 'Units', 'centimeters')
        set(findall(gcf,'-property','FontSize'),'FontSize',13.5)
        set(gca, 'FontName', 'Times New Roman')
    end
end
%==========================================================================
%==========================================================================
