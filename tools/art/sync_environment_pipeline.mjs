import fs from 'node:fs';

const catalog = JSON.parse(fs.readFileSync('art/environment-remodel.json', 'utf8'));
const path = 'art/process.json';
const pipeline = JSON.parse(fs.readFileSync(path, 'utf8'));
let count = 0;
for (const asset of catalog.assets) {
  if (!fs.existsSync(`art/${asset.source}`)) continue;
  const output = `res://${asset.output}`;
  let entry = pipeline.sprites.find(s => s.output === output);
  if (!entry) {
    entry = {key: `${asset.group}_${asset.id}`, group: asset.group, output};
    pipeline.sprites.push(entry);
  }
  entry.source = asset.source;
  entry.mode = 'remodel';
  count++;
}
// Split deco kits used numbered filenames; regenerated pieces are independent.
pipeline.sprites = pipeline.sprites.filter(s => !(s.group === 'deco' && s.mode === 'split' && catalog.assets.filter(a => a.group === 'deco').every(a => fs.existsSync(`art/${a.source}`))));
fs.writeFileSync(path, JSON.stringify(pipeline, null, 1) + '\n');
console.log(`ENVIRONMENT_PIPELINE: ${count}/${catalog.assets.length}`);
