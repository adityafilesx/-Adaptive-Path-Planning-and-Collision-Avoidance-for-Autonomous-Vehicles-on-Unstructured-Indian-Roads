function path = drawIDDArchitecture(outputDirectory)
%DRAWIDDARCHITECTURE Architecture diagram, not fabricated dataset/model evidence.
if ~isfolder(outputDirectory),mkdir(outputDirectory);end
f=figure('Visible','off','Color','white','Position',[50 50 1350 800]);
guard=onCleanup(@() close(f)); %#ok<NASGU>
annotation(f,'textbox',[.04 .91 .94 .07],'String','Perception branches | shared semantics, explicit geometry boundary', ...
    'EdgeColor','none','Color',[.1 .15 .2],'FontWeight','bold','FontSize',18);
box([.06 .71 .37 .13],{'SIMULATION (existing)','Actor truth -> simulated perception','CanonicalActorDetection: metres, m/s'},[.90 .95 1]);
box([.57 .71 .37 .13],{'IDD IMAGE (new, data/model required)','Genuine RGB -> YOLOX -> class mapping','ImageDetection: pixels, class, confidence'},[1 .95 .85]);
arrow([.245 .42],[.71 .60]);arrow([.755 .58],[.71 .60]);
box([.20 .47 .60 .13],{'CANONICAL PERCEPTION PACKET','Common class/confidence semantics; CoordinateSpace + MetricReady','Image fields and metric actor fields remain distinct'},[.93 .94 .96]);
arrow([.32 .245],[.47 .38]);arrow([.68 .755],[.47 .38]);
box([.06 .25 .37 .13],{'METRIC-READY ONLY','Existing tracking -> prediction','ACARG -> occupancy / planning / control'},[.90 .96 .91]);
box([.57 .25 .37 .13],{'IMAGE-ONLY: STOP AT THIS BOUNDARY','Needs depth, calibration or sensor fusion','NOT IMPLEMENTED: metric state estimation'},[1 .91 .90]);
annotation(f,'textbox',[.09 .07 .84 .10],'String', ...
    {'An RGB bounding box does not provide distance, metric velocity, yaw or physical dimensions.', ...
    'No image-only CPA, no fabricated world positions, no claim that pretrained COCO weights are IDD training.'}, ...
    'EdgeColor','none','Color',[.15 .18 .22],'HorizontalAlignment','center','FontSize',12);
path=string(fullfile(outputDirectory,'idd_perception_architecture.png'));
exportgraphics(f,path,'Resolution',120,'BackgroundColor','white');
    function box(position,lines,color)
        annotation(f,'textbox',position,'String',lines,'BackgroundColor',color, ...
            'EdgeColor',[.3 .35 .4],'Color',[.1 .15 .2],'HorizontalAlignment','center', ...
            'VerticalAlignment','middle','FontSize',12,'Interpreter','none');
    end
    function arrow(x,y),annotation(f,'arrow',x,y,'Color',[.25 .3 .35],'LineWidth',1.5);end
end
