function files = generatePhase11Figures(evaluation,outputDirectory)
%GENERATEPHASE11FIGURES Create nine readable, single-purpose evidence figures.

    if ~isfolder(outputDirectory),mkdir(outputDirectory);end
    files=strings(0,1); t=evaluation.dataset.scenarioMetrics;
    names=shortNames(t.Scenario);

    f=newFigure();
    values=[double(t.GoalReached) double(t.SafeTermination) double(~t.GoalReached&~t.SafeTermination)];
    bar(values,'grouped'); ylabel('Outcome indicator'); ylim([0 1.2]);
    xticks(1:height(t));xticklabels(names);xtickangle(20);legend('Goal reached','Safe termination','Failure','Location','northoutside','Orientation','horizontal');
    title('Closed-loop benchmark outcomes by scenario');grid on;
    files=[files;exportPair(f,outputDirectory,'figure01_benchmark_outcomes')];close(f);

    f=newFigure();bar(t.MinimumActorDistance);ylabel('Minimum actor distance (m)');
    xticks(1:height(t));xticklabels(names);xtickangle(20);title('Minimum observed actor clearance');grid on;
    files=[files;exportPair(f,outputDirectory,'figure02_minimum_clearance')];close(f);

    f=newFigure();bar([t.MeanReplanningLatencyMs t.MaximumReplanningLatencyMs]);ylabel('Measured latency (ms)');
    xticks(1:height(t));xticklabels(names);xtickangle(20);legend('Mean','Maximum','Location','northoutside','Orientation','horizontal');
    title('MATLAB wall-clock replanning latency');grid on;
    files=[files;exportPair(f,outputDirectory,'figure03_replanning_latency')];close(f);

    cattle=evaluation.riskTimeline(evaluation.riskTimeline.Scenario=="Sudden Cattle Crossing",:);
    f=newFigure();yyaxis left;plot(cattle.Time,cattle.TotalRisk,'-o','MarkerIndices',1:5:height(cattle),'LineWidth',1.5);ylabel('Total risk');ylim([0 1]);
    yyaxis right;plot(cattle.Time,cattle.DesiredSpeed,'--','LineWidth',1.5);hold on;plot(cattle.Time,cattle.ActualEgoSpeed,'-','LineWidth',1.5);
    scatter(cattle.Time(cattle.ReplanEvent),cattle.ActualEgoSpeed(cattle.ReplanEvent),35,'filled','Marker','diamond');ylabel('Speed (m/s)');
    xlabel('Simulation time (s)');title('Cattle Crossing: risk, speed, and replanning response');legend('Total risk','Desired speed','Ego speed','Replan','Location','best');grid on;
    files=[files;exportPair(f,outputDirectory,'figure04_cattle_risk_speed_timeline')];close(f);

    c=evaluation.ablation.confidence;
    f=newFigure();hold on;
    modes=unique(c.Mode,'stable');markers={'o','s'};
    for i=1:numel(modes),q=c(c.Mode==modes(i),:);plot(q.DetectionConfidence,q.AdaptiveScale,['-' markers{i}],'LineWidth',1.5,'DisplayName',char(modes(i)));end
    xlabel('Detection confidence');ylabel('Adaptive envelope scale');title('Confidence sensitivity of ACARG scaling');legend('Location','best');grid on;
    files=[files;exportPair(f,outputDirectory,'figure05_confidence_adaptive_scale')];close(f);

    cpa=evaluation.ablation.cpa(evaluation.ablation.cpa.Mode=="FULL_ACARG",:);
    f=newFigure();yyaxis left;bar(categorical(cpa.Geometry),[cpa.PhysicalDistance cpa.CPADistance],'grouped');ylabel('Distance (m)');
    yyaxis right;plot(categorical(cpa.Geometry),cpa.ActorRisk,'kd-','LineWidth',1.5,'MarkerFaceColor','k');ylabel('Actor risk');ylim([0 1]);
    title('Physical distance versus closest-point-of-approach risk');legend('Physical distance','CPA distance','Actor risk','Location','northoutside','Orientation','horizontal');grid on;
    files=[files;exportPair(f,outputDirectory,'figure06_cpa_vs_distance')];close(f);

    f=newFigure();bar([t.TimeInNORMAL t.TimeInCAUTIOUS t.TimeInCONSERVATIVE_STOP],'stacked');ylabel('Simulation time (s)');
    xticks(1:height(t));xticklabels(names);xtickangle(20);legend('NORMAL','CAUTIOUS','CONSERVATIVE STOP','Location','northoutside','Orientation','horizontal');
    title('Time spent in ACARG states');grid on;
    files=[files;exportPair(f,outputDirectory,'figure07_acarg_state_time')];close(f);

    b=evaluation.baseline.table; scenarios=unique(b.Scenario,'stable');matrix=zeros(numel(scenarios),2);
    for i=1:numel(scenarios),matrix(i,1)=b.MinimumActorDistance(b.Scenario==scenarios(i)&b.Mode=="FIXED_MARGIN_BASELINE");matrix(i,2)=b.MinimumActorDistance(b.Scenario==scenarios(i)&b.Mode=="ACARG_ENHANCED");end
    f=newFigure();bar(matrix,'grouped');ylabel('Minimum actor distance (m)');xticks(1:numel(scenarios));xticklabels(shortNames(scenarios));xtickangle(20);
    legend('Fixed-margin baseline','ACARG enhanced','Location','northoutside','Orientation','horizontal');title('Baseline versus ACARG minimum clearance');grid on;
    files=[files;exportPair(f,outputDirectory,'figure08_baseline_vs_acarg')];close(f);

    r=evaluation.robustness.summaryTable;
    f=newFigure();bar([double(r.GoalReached) double(r.SafeTermination) double(r.RecoveryOccurred)],'grouped');ylabel('Outcome indicator');ylim([0 1.2]);
    xticks(1:height(r));xticklabels(shortNames(r.Scenario));xtickangle(25);legend('Goal reached','Safe termination','Recovered','Location','northoutside','Orientation','horizontal');
    title('Controlled disturbance outcomes');grid on;
    files=[files;exportPair(f,outputDirectory,'figure09_robustness_outcomes')];close(f);
end
function f=newFigure()
f=figure('Visible','off','Color','w','Position',[100 100 1000 620]);
set(f,'DefaultAxesFontSize',11);
end
function files=exportPair(f,folder,name)
png=fullfile(folder,[name '.png']);pdf=fullfile(folder,[name '.pdf']);
exportgraphics(f,png,'Resolution',200);exportgraphics(f,pdf,'ContentType','vector');
files=[string(png);string(pdf)];
end
function values=shortNames(values)
values=replace(string(values),["Unmarked Village Road","Unsignalized Urban Intersection", ...
    "Highway Slow-Vehicle Merge","Dense Mixed-Traffic Market","Sudden Cattle Crossing", ...
    "Temporary Detection Loss","Sudden Direction Reversal","Multiple Simultaneous Risks", ...
    "Temporary Path Obstruction","Replan Failure Recovery","Conservative Stop Recovery", ...
    "Rapid Risk Fluctuation"], ...
    ["Village","Urban","Highway","Market","Cattle","Detection Loss", ...
    "Direction Reversal","Multiple Risks","Obstruction","Replan Recovery","STOP Recovery","Risk Fluctuation"]);
end
