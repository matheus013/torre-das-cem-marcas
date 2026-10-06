import fs from 'node:fs';

const catalog = JSON.parse(fs.readFileSync('art/actor-animations.json', 'utf8'));
const pipeline = JSON.parse(fs.readFileSync('art/process.json', 'utf8'));
let count = 0;
for (const actor of catalog.actors) {
  if (!fs.existsSync(`art/${actor.source}`)) continue;
  const item = pipeline.sprites.find(s => s.output === `res://assets/sprites/${actor.group}/${actor.id}.png`);
  if (!item) throw new Error(`Unknown actor: ${actor.id}`);
  item.source = actor.source;
  item.mode = 'animation';
  count++;
}
fs.writeFileSync('art/process.json', JSON.stringify(pipeline, null, 1) + '\n');
console.log(`ACTOR_PIPELINE: ${count}/${catalog.actors.length}`);
