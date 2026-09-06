function dataset = findIDDDataset(cfg)
%FINDIDDDATASET Inspect only explicit configuration/environment, not the whole disk.
if nargin<1,cfg=getIDDConfig();end
root=string(cfg.root);if strlength(root)==0,root=string(getenv('IDD_ROOT'));end
dataset=struct('available',false,'root',root,'message',"IDD dataset not configured. Set cfg.idd.root to an external, licensed IDD-Detection extraction.");
if strlength(root)==0,return;end
root=iddCanonicalPath(root);project=iddCanonicalPath(cfg.projectRoot);
assert(~strcmpi(root,project)&&~startsWith(lower(root),lower(project+filesep)), ...
    'IDD:DatasetInRepository','Dataset must live outside the project, including symlink targets.');
dataset.root=root;
if ~isfolder(root),dataset.message="Configured IDD directory does not exist: "+root;return;end
dataset.available=true;dataset.message="Configured directory found; genuine annotation/file validation still required.";
end
