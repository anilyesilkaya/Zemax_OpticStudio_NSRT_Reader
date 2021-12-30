if plotFlag == 1
    figure('color','white');
    hold on
    grid on
    xlabel(['X (',lensUnit,')'])
    ylabel(['Y (',lensUnit,')'])
    zlabel(['Z (',lensUnit,')'])
    view([40 25])
end

%==========================================================================
        %Plot the scenario:
        %Plotting the source
        if plotFlag == 1
            line([dataTemp(1,17),dataTemp(1,17)],...
            [dataTemp(1,18),dataTemp(1,18)],...
            [dataTemp(1,19),dataTemp(1,19)],...
            'LineWidth',2,'MarkerSize',8,'Color','r','Marker','*')
            %Plotting the destination
            line([dataTemp(nsegHit+1,17),dataTemp(nsegHit+1,17)],...
            [dataTemp(nsegHit+1,18),dataTemp(nsegHit+1,18)],...
            [dataTemp(nsegHit+1,19),dataTemp(nsegHit+1,19)],...
            'LineWidth',2,'MarkerSize',8,'Color','b','Marker','.')
            %Plotting the ray segments
            plot3([dataTemp(ind_Seg,17) dataTemp(ind_Seg+1,17)],...
            [dataTemp(ind_Seg,18) dataTemp(ind_Seg+1,18)],...
            [dataTemp(ind_Seg,19) dataTemp(ind_Seg+1,19)])
            pause(0.1);
            drawnow;
        end