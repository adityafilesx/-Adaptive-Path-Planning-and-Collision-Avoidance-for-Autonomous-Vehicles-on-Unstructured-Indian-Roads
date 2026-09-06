function result = testIDDIntegration(options)
%TESTIDDINTEGRATION Pure contract tests plus explicitly conditional REAL data.
% Numeric SCHEMA_TEST records are not an IDD dataset or perception evidence.
% Training never runs unless options.enabled and options.runTraining are true.
addpath(genpath(fileparts(fileparts(mfilename('fullpath')))));
if nargin<1,options=struct();end
cfg=getIDDConfig(options);base=getIDDConfig();cap=validateIDDEnvironment(cfg);
dataset=findIDDDataset(cfg);data=[];dataError="";training=[];detector=[];model=[];initial=[];
if dataset.available
    try,data=prepareIDDData(cfg);catch info,dataError=string(info.message);end
end
core=config();core.perception.missedDetectionProbability=0;
truth=struct('ID',11,'ClassID',1,'Position',[10 0 0],'Velocity',[4 0 0]);
ego=struct('Position',[0 0 0],'Velocity',[0 0 0]);
sim=simulatePerception(truth,ego,core);
d=createImageDetection([2 3 10 12],.9,"autorickshaw",[100 200 3],"SCHEMA_TEST",["car" "autorickshaw"],NaN,"SCHEMA_TEST");
rows=struct('Test',{},'Status',{},'Detail',{});
for n=1:65
    try
        check(n);status="PASS";detail="";
    catch info
        if strcmp(info.identifier,'IDDTest:Skip'),status="SKIP";else,status="FAIL";end
        detail=string(info.message);
    end
    rows(end+1)=struct('Test',n,'Status',status,'Detail',detail); %#ok<AGROW>
    fprintf('IDD TEST %02d: %s %s\n',n,status,detail);
end
result=struct('passed',sum([rows.Status]=="PASS"),'failed',sum([rows.Status]=="FAIL"), ...
    'skipped',sum([rows.Status]=="SKIP"),'tests',struct2table(rows));
fprintf('testIDDIntegration: %d passed, %d failed, %d skipped.\n',result.passed,result.failed,result.skipped);
if isfolder(cfg.outputDir),writetable(result.tests,fullfile(cfg.outputDir,'integration_test_results.csv'));end
assert(result.failed==0,'IDDTest:Failures','One or more IDD integration tests failed.');
    function requireData()
        if ~dataset.available,error('IDDTest:Skip','Genuine external IDD dataset not configured.');end
        assert(strlength(dataError)==0,'IDDTest:DataSetup','Actual dataset preparation failed: %s',dataError);
    end
    function requireModel()
        requireData();
        if isempty(detector)
            if strlength(cfg.detectorFile)==0,error('IDDTest:Skip','No IDD-trained model configured.');end
            [detector,model]=loadIDDDetector(cfg.detectorFile);
        end
    end
    function check(n)
        switch n
            case 1,assert(isstruct(base)&&base.model=="YOLOX");
            case 2,assert(~base.enabled&&~base.runTraining&&~base.allowWeightDownload);
            case 3
                q=base;q.root=string(tempname);r=findIDDDataset(q);assert(~r.available&&strlength(r.message)>0);
            case 4
                q=base;q.root=base.projectRoot;mustError(@() findIDDDataset(q),'IDD:DatasetInRepository');
                assert(~isfolder(fullfile(base.projectRoot,'JPEGImages'))&&~isfolder(fullfile(base.projectRoot,'Annotations')));
            case 5
                q=getIDDConfig(struct('root',string(fullfile(tempdir,'external_idd_location'))));
                assert(q.root==string(fullfile(tempdir,'external_idd_location')));
            case 6,assert(isequal(mapIDDClass(["CAR" "person"]),mapIDDClass(["car" "person"])));
            case 7,assert(mapIDDClass("autorickshaw")=="auto");
            case 8,assert(mapIDDClass("person")=="pedestrian");
            case 9,assert(mapIDDClass("unrecognised_label")=="unknown");
            case 10,assert(mapIDDClass("animal")=="animal"&&isempty(base.targetLabels));
            case 11,assert(mapIDDClass("pushcart")=="unknown"&&mapIDDClass("rider")=="unknown");
            case 12
                assert(d.Schema=="ImageDetection"&&d.Class=="auto"&&d.OriginalIDDClass=="autorickshaw");
                assert(~isfield(d,'Position')&&~isfield(d,'Velocity')&&d.ClassID==2&&isnan(d.Timestamp));
            case 13,p=simulatedDetectionToCanonical(sim);assert(isequaln(p.Detections,sim)&&p.MetricReady);assert(p.Semantics.Class=="car"&&p.Semantics.Confidence==sim.Confidence);
            case 14
                adapter=createPerceptionSource();p=adapter(struct('actorTruth',truth,'egoState',ego),core);
                assert(p.Source=="SIMULATED"&&isequaln(p.Detections,sim));
            case 15
                p=simulatedDetectionToCanonical(sim);
                a=initializeTracker(sim,.1,core,0);b=initializeTracker(p.Detections,.1,core,0);
                assert(isequal(a.CurrentState,b.CurrentState)&&isequal(a.CurrentCovariance,b.CurrentCovariance));
                assert(a.Confidence==b.Confidence&&isequal(a.PerceivedClass,b.PerceivedClass));
                pred=struct('Position',[10 0;14 0],'Velocity',[4 0;4 0],'Time',[0;1]);
                riskA=computeActorRisk(a,pred,ego,[],core);riskB=computeActorRisk(b,pred,ego,[],core);
                assert(isequaln(riskA,riskB)&&isfinite(riskA.risk));
            case 16
                assert(height(cap.functions)==7&&cap.yoloxAvailable==all(cap.functions.Available(1:2))&&cap.gpuCount>=0);
            case 17,requireData();assert(any(data.inventory.files.Split=="train"));
            case 18,requireData();assert(any(data.inventory.files.Split=="val"));
            case 19,requireData();assert(all(isfile(data.train.imageFilename))&&all(isfile(data.val.imageFilename)));
            case 20,requireData();assert(~isempty(data.records)&&all(isfile(string({data.records.AnnotationFile}))));
            case 21
                requireData();for j=1:numel(data.records),[boxes,ok]=validateIDDBoxes(data.records(j).Boxes,data.records(j).ImageSize);assert(all(ok)&&isequal(boxes,data.records(j).Boxes));end
            case 22,requireData();assert(~isempty(data.classes)&&height(data.classSummary)>0);
            case 23,requireData();ds=buildIDDDetectionDatastore(data.train);assert(hasdata(ds));read(ds);
            case 24,requireData();ds=buildIDDDetectionDatastore(data.val);assert(hasdata(ds));read(ds);
            case 25,requireData();assert(isempty(intersect(data.train.imageFilename,data.val.imageFilename)));
            case 26
                requireData();ds=buildIDDDetectionDatastore(data.train);sample=read(ds);aug=augmentIDDTrainingData(sample,cfg);
                [~,ok]=validateIDDBoxes(aug{2},size(aug{1}));assert(all(ok)&&size(aug{2},1)==numel(aug{3}));
            case 27
                requireData();if ~cap.trainingAvailable,error('IDDTest:Skip','YOLOX capability absent.');end
                if ~cfg.allowWeightDownload&&strlength(cfg.pretrainedDetectorFile)==0,error('IDDTest:Skip','Pretrained weights require explicit opt-in or a local detector.');end
                initial=createIDDYOLOXDetector(data.classes,cfg);assert(isa(initial,'yoloxObjectDetector'));
            case 28
                requireData();if ~cfg.enabled||~cfg.runTraining,error('IDDTest:Skip','Smoke training requires explicit enabled/runTraining opt-in.');end
                if ~cap.trainingAvailable,error('IDDTest:Skip','YOLOX capability absent.');end
                assert(cfg.profile=="SMOKE",'IDDTest:Profile','Tests only authorize SMOKE, never FULL training.');
                training=trainIDDYOLOX(data,cfg);assert(training.status=="PASS"&&~training.finalTraining);
                detector=training.detector;cfg.detectorFile=training.savedModel;
            case 29
                requireData();if isempty(training),error('IDDTest:Skip','No smoke training ran in this test invocation.');end
                assert(isfile(fullfile(training.checkpointDirectory,'completed_call_checkpoint.mat')));
            case 30,requireModel();assert(isa(detector,'yoloxObjectDetector')||~isempty(model));
            case 31,requireModel();out=runIDDInference(detector,data.val.imageFilename(1),cfg);p=iddDetectionToCanonical(out);assert(~p.MetricReady);
            case 32,requireModel();out=runIDDInference(detector,data.val.imageFilename(1),cfg);assert(all([out.Confidence]>=0&[out.Confidence]<=1));
            case 33,requireModel();e=evaluateIDDDetector(detector,data,cfg);assert(e.status=="PASS"&&e.imageCount==height(data.val));
            case 34,requireModel();demo=mainIDDPerceptionDemo(cfg);assert(demo.status=="PASS"&&~isempty(demo.files)&&all(isfile(demo.files)));
            case 35
                q=base;q.root=string(tempname);r=mainPhase12_5(q);
                assert(r.architecture.status=="COMPLETE"&&r.parsing=="PENDING DATASET"&&r.validation=="NOT RUN");
            case 36,[b,ok]=validateIDDBoxes([1 1 200 100],[100 200 3]);assert(ok&&isequal(b,[1 1 200 100]));
            case 37,[b,ok]=validateIDDBoxes([-2 -2 6 6],[100 200 3]);assert(ok&&isequal(b,[1 1 3 3]));
            case 38,[~,ok]=validateIDDBoxes([1 1 0 4;1 1 -2 4],[100 200 3]);assert(~any(ok));
            case 39,[~,ok]=validateIDDBoxes([NaN 1 2 4;1 Inf 2 4],[100 200 3]);assert(~any(ok));
            case 40,[~,ok]=validateIDDBoxes([201 1 3 4;1 101 3 4],[100 200 3]);assert(~any(ok));
            case 41,mustError(@() createImageDetection([1 1 2 2],1.1,"car",[10 10 3],"SCHEMA_TEST","car"),'IDD:Confidence');
            case 42,mustError(@() createImageDetection([1 1 2 2],.5,"car",[10 10 3],"SCHEMA_TEST","bus"),'IDD:Class');
            case 43,p=iddDetectionToCanonical(d);assert(~p.MetricReady&&p.CoordinateSpace=="IMAGE_PIXELS"&&isequal(d.BBoxCenter,[6.5 8.5]));assert(p.Semantics.Class=="auto"&&p.Semantics.Confidence==.9);
            case 44,e=createImageDetection(zeros(0,4),[],strings(0,1),[10 10 3],"SCHEMA_TEST",strings(0,1));p=iddDetectionToCanonical(e);assert(isempty(p.Detections)&&~p.MetricReady);
            case 45,q=d;q.Position=[1 2 3];mustError(@() iddDetectionToCanonical(q),'IDD:MetricLeak');
            case 46,mustError(@() estimateActorStateFromVision(d),'IDD:MetricStateRequired');
            case 47,assert(~validateCanonicalActorDetection(d));mustError(@() simulatedDetectionToCanonical(d),'IDD:MetricSchema');
            case 48,q=core;q.perception.missedDetectionProbability=1;miss=simulatePerception(truth,ego,q);p=simulatedDetectionToCanonical(miss);assert(isequaln(p.Detections,miss)&&~miss.IsDetected);
            case 49,q=getIDDConfig(struct('profile',"DEVELOPMENT"));assert(q.maxEpochs==20&&q.trainLimit==512&&~q.runTraining);
            case 50,q=getIDDConfig(struct('profile',"FULL"));assert(isinf(q.trainLimit)&&isinf(q.valLimit)&&~q.runTraining);
            case 51,mustError(@() getIDDConfig(struct('maxEpochs',3)),'IDD:SmokeBudget');mustError(@() getIDDConfig(struct('profile',"FULL",'trainLimit',3)),'IDD:FullSubset');
            case 52,r=checkIDDDiskSpace(base.outputDir,0,true);assert(r.sufficient);mustError(@() checkIDDDiskSpace(base.outputDir,Inf,true),'IDD:DiskSpace');
            case 53,mustError(@() createPerceptionSource("INVALID"),'IDD:Source');adapter=createPerceptionSource("ROADRUNNER");mustError(@() adapter(struct(),core),'IDD:RoadRunnerBoundary');
            case 54,mustError(@() iddDetectionToCanonical(struct()),'IDD:Schema');q=d;q.Class="cattle";mustError(@() iddDetectionToCanonical(q),'IDD:Mapping');
            case 55,mustError(@() trainIDDYOLOX(struct(),base),'IDD:TrainingOptIn');mustError(@() getIDDConfig(struct('batchSize',Inf)),'IDD:Config');
            case 56,c=getIDDMilestone1Config();assert(c.profile=="SMOKE"&&c.pretrainedName=="tiny-coco"&&~c.enabled&&~c.runTraining&&~c.allowWeightDownload);
            case 57,c=getIDDMilestone1Config();assert(c.trainLimit==32&&c.valLimit>=20&&c.maxEpochs<=2&&c.randomSeed==125);
            case 58,mustError(@() getIDDMilestone1Config(struct('profile',"FULL")),'IDD:MilestoneProfile');
            case 59,mustError(@() getIDDMilestone1Config(struct('pretrainedName',"small-coco")),'IDD:MilestoneModel');
            case 60,c=getIDDMilestone1Config();assert(c.augmentation.flipProbability==0);q=c;q.augmentation.flipProbability=1;mustError(@() getIDDMilestone1Config(q),'IDD:MilestoneAugmentation');
            case 61,c=getIDDMilestone1Config();assert(c.minimumTrainingFreeGB>=5&&c.minimumConversionFreeGB>=2&&endsWith(c.outputDir,fullfile('idd','milestone1')));
            case 62,c=validateIDDExecutionEnvironment();assert(all(isfield(c,{'YOLOXAvailable','TrainYOLOXAvailable','DeepLearningAvailable','ComputerVisionAvailable','ParallelComputingAvailable','GPUAvailable','GPUName','ExecutionEnvironment','Reason'})));
            case 63,c=validateIDDExecutionEnvironment();assert(c.TrainYOLOXAvailable==~isempty(which('trainYOLOXObjectDetector'))&&c.TrainingOptionsAvailable==~isempty(which('trainingOptions'))&&strlength(c.Reason)>0);
            case 64,c=getIDDMilestone1Config(struct('idd',struct('root',"/EXTERNAL_EXAMPLE_NOT_A_DATASET")));assert(c.root=="/EXTERNAL_EXAMPLE_NOT_A_DATASET"&&~c.runTraining);
            case 65,mustError(@() getIDDMilestone1Config(struct('resumeFile',"NOT_A_CHECKPOINT")),'IDD:MilestoneResume');
        end
    end
end
function mustError(callback,identifier)
try,callback();catch info,assert(strcmp(info.identifier,identifier),'Expected %s, got %s: %s',identifier,info.identifier,info.message);return;end
error('IDDTest:ExpectedError','Expected error %s was not raised.',identifier);
end
