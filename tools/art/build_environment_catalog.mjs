import fs from 'node:fs';
import crypto from 'node:crypto';

const path = 'art/environment-remodel.json';
const existing = fs.existsSync(path) ? JSON.parse(fs.readFileSync(path, 'utf8')).assets : [];
const pipeline = JSON.parse(fs.readFileSync('art/process.json', 'utf8')).sprites;
const legacy = JSON.parse(fs.readFileSync('art/manifest.json', 'utf8')).assets;
const assets = [];
for (const group of ['buildings', 'props', 'deco', 'tiles']) {
  for (const file of fs.readdirSync(`assets/sprites/${group}`).filter(f => f.endsWith('.png')).sort()) {
    const id = file.replace('.png', '');
    const output = `assets/sprites/${group}/${file}`;
    const previous = existing.find(a => a.output === output);
    if (previous) { assets.push(previous); continue; }
    const base = output.replace(/_\d+\.png$/, '.png');
    const entry = pipeline.find(a => a.output === `res://${output}` || a.output === `res://${base}`);
    const original = entry && legacy.find(a => a.key === entry.key || entry.source.split('/').at(-1).startsWith(a.key + '_s'));
    let identity = original?.prompt.split('plain white background, ').at(-1) ?? id.replaceAll('_', ' ');
    if (id === 'house_stone') identity = 'Small cottage of pale exposed limestone masonry, muted olive-grey tiled roof, stout wooden door and arched stone windows; distinct from the blue plaster cottage';
    if (group === 'deco') identity += `. ONE independent ${id.split('_')[0]} only, natural variation ${id.split('_').at(-1)}, not a collection or kit`;
    if (id === 'rocks') identity = 'One low clustered outcrop of pale limestone and grey mineral rock, clean readable three-quarter top-down silhouette';
    const pixels = fs.readFileSync(output);
    const tile = group === 'tiles';
    const style = 'Production pixel art for a detailed chibi fantasy survivors RPG. Crisp intentional pixels, clean dark outlines for objects, readable material clusters, consistent three-quarter top-down RPG perspective, light from upper left, restrained saturated accent colors, varied natural stone/wood/metal/foliage palette. Match attached character reference in rendering quality ONLY. No characters, no monsters, no face, no cyan amulet, no UI, no writing, no watermark.';
    const layout = tile
      ? 'ONE seamless repeating flat TOP-DOWN ground texture, full opaque square image. No perspective, no vignette, no central composition, no frame or borders, no raised objects, no trees or buildings. Quiet low contrast ground, tiny sparse detail, uniform illumination. The left/right and top/bottom edges must join seamlessly. Ground must not compete with combat sprites.'
      : 'ONE single independent object or building, entire silhouette visible, centered, transparent background, at least 12% clear margins on all sides. No floor base, no ground plate, no cast shadow, no landscape, no room, no terrain, no decorative extra objects detached from the subject. Buildings show roof and front entrance; objects are independently placeable. Never turn this into a whole environment scene.';
    assets.push({id, group, output, source: `raw/environment-v2/${group}/${id}.png`, width: pixels.readUInt32BE(16), height: pixels.readUInt32BE(20), previous_sha256: crypto.createHash('sha256').update(pixels).digest('hex'), transparent: !tile, identity, prompt: `${style} Subject: ${identity}. ${layout} Square image 1024x1024.`});
  }
}
fs.writeFileSync(path, JSON.stringify({revision: 2, provider: 'OpenAI image generation, no PixelForge', reference: 'art/raw/animations/eloa_walk_v2.png', assets}, null, 2) + '\n');
console.log(`ENVIRONMENT_CATALOG: ${assets.length} independently generated assets`);
