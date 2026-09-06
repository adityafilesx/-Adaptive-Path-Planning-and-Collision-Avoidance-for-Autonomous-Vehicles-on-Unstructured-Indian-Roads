// Hash existing Phase 11/12 evidence before/after the required regression.
// Derived replay cache and Finder metadata are intentionally excluded.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const output = path.join(root, 'results/idd/milestone1');
async function digest(file) {
  const h = crypto.createHash('sha256');
  for await (const chunk of fs.createReadStream(path.join(root, file))) h.update(chunk);
  return h.digest('hex');
}
function list(dir) {
  return fs.readdirSync(path.join(root, dir), {withFileTypes: true}).flatMap(e => {
    if (e.name === '.DS_Store' || e.name === 'cache') return [];
    const file = path.join(dir, e.name);
    return e.isDirectory() ? list(file) : e.isFile() ? [file] : [];
  });
}
(async () => {
  const baseline = path.join(output, 'evidence_baseline.json');
  fs.mkdirSync(output, {recursive: true});
  if (process.argv[2] === 'baseline') {
    if (fs.existsSync(baseline)) throw new Error('Baseline already exists; refusing overwrite.');
    const rows = [];
    for (const file of [...list('results/phase11'), ...list('results/phase12')].sort()) {
      rows.push({file, bytes: fs.statSync(path.join(root,file)).size, sha256: await digest(file)});
    }
    fs.writeFileSync(baseline, JSON.stringify(rows, null, 2));
    console.log(`Baseline: ${rows.length} evidence files.`);
  } else if (process.argv[2] === 'verify') {
    const rows = JSON.parse(fs.readFileSync(baseline, 'utf8')), mismatches = [];
    for (const r of rows) {
      try {
        if (fs.statSync(path.join(root,r.file)).size !== r.bytes || await digest(r.file) !== r.sha256) mismatches.push(r.file);
      } catch (e) { mismatches.push({file:r.file, error:e.message}); }
    }
    const report = {status:mismatches.length ? 'FAIL' : 'PASS', checkedFiles:rows.length,
      checkedAt:new Date().toISOString(), mismatches};
    fs.writeFileSync(path.join(output,'evidence_verification.json'),JSON.stringify(report,null,2));
    console.log(JSON.stringify(report));
    if (mismatches.length) process.exitCode = 1;
  } else throw new Error('Usage: node tests/verifyIDDMilestoneEvidence.cjs baseline|verify');
})().catch(error => {console.error(error);process.exitCode=1;});
