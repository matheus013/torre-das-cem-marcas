import fs from 'node:fs';

const pipeline = JSON.parse(fs.readFileSync('art/process.json', 'utf8'));
const legacy = JSON.parse(fs.readFileSync('art/manifest.json', 'utf8'));
const previous = fs.existsSync('art/actor-animations.json') ? JSON.parse(fs.readFileSync('art/actor-animations.json', 'utf8')).actors : [];
const reference = 'art/raw/animations/eloa_walk_v2.png';
const actors = pipeline.sprites.filter(s => /sprites\/(npcs|enemies)\//.test(s.output)).map(s => {
  const id = s.output.split('/').at(-1).replace('.png', '');
  const group = s.output.includes('/npcs/') ? 'npcs' : 'enemies';
  const existing = previous.find(a => a.id === id && a.group === group);
  if (existing) return existing;
  const original = legacy.assets.find(a => a.key === s.key || s.source.split('/').at(-1).startsWith(a.key + '_s'));
  if (!original) throw new Error(`Missing authored design: ${id}`);
  const identity = original.prompt.split('plain white background, ').at(-1);
  const motion = group === 'npcs' ? 'four distinct walking phases: contact, passing, opposite contact, opposite passing'
    : 'four distinct cyclic locomotion phases appropriate to its anatomy: crawl, stride, glide or hover; rooted creatures gently flex or pulse instead of growing human legs';
  const prompt = `Use case: stylized-concept. Production pixel-art RPG animation spritesheet for ${original.name}. Subject identity: ${identity}. Reference is STYLE AND GRID ONLY, not character identity. Match its detailed chibi pixel art, crisp dark outlines, readable materials, 3/4 top-down camera. Exactly 4 columns x 4 rows, 16 equally spaced full-body poses on transparent background. Rows in order: front/down, profile LEFT, profile RIGHT, back/up. Each row shows ${motion}. Keep identical anatomy, outfit, accessories, size and palette across all cells. Center each complete silhouette on a common baseline with generous transparent gutters. Square sheet 1024x1024. No room, landscape, ground plate, floor, background, grid lines, text, labels, shadows or extra actors. Scene references in the subject description are thematic only: depict the creature itself, not its habitat or buildings. Attached components such as shells, roots, rings and tools belong to the ONE coherent actor. Do not copy Eloa. No clipped bodies, wings, weapons or feet.`;
  return { id, group, identity, motion, source: `raw/animations/${group}/${id}_walk_v2.png`, output: `assets/sprites/${group}/animations/${id}_walk.png`, prompt };
});
const catalog = { provider: 'OpenAI image generation, no PixelForge', revision: 2, reference, directions: ['down', 'left', 'right', 'up'], columns: 4, frame_size: 64, content_height: 48, foot_baseline: 60, frames_per_second: 8, actors };
fs.writeFileSync('art/actor-animations.json', JSON.stringify(catalog, null, 2) + '\n');
console.log(`ACTOR_CATALOG_OK: ${actors.length}`);
