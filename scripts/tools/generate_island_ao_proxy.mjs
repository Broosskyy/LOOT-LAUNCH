/**
 * Derives a conservative AO proxy from the island albedo atlas.
 * Not a mesh bake — replace with Blender AO when available.
 */
import sharp from "sharp";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const albedo = path.join(
	root,
	"art/models/production/asset_02_floating_island/source_maps/baseColor_1.png"
);
const output = path.join(
	root,
	"art/models/production/asset_02_floating_island/texture_ao_proxy.png"
);

const { data, info } = await sharp(albedo).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
const out = Buffer.alloc(data.length);
const w = info.width;
const h = info.height;
const ch = info.channels;

for (let y = 0; y < h; y++) {
	for (let x = 0; x < w; x++) {
		const i = (y * w + x) * ch;
		const r = data[i] / 255;
		const g = data[i + 1] / 255;
		const b = data[i + 2] / 255;
		const lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
		let ao = 1.0 - Math.pow(1.0 - lum, 1.65);
		const left = x > 0 ? (y * w + (x - 1)) * ch : i;
		const right = x < w - 1 ? (y * w + (x + 1)) * ch : i;
		const up = y > 0 ? ((y - 1) * w + x) * ch : i;
		const down = y < h - 1 ? ((y + 1) * w + x) * ch : i;
		const lumL = 0.2126 * (data[left] / 255) + 0.7152 * (data[left + 1] / 255) + 0.0722 * (data[left + 2] / 255);
		const lumR = 0.2126 * (data[right] / 255) + 0.7152 * (data[right + 1] / 255) + 0.0722 * (data[right + 2] / 255);
		const lumU = 0.2126 * (data[up] / 255) + 0.7152 * (data[up + 1] / 255) + 0.0722 * (data[up + 2] / 255);
		const lumD = 0.2126 * (data[down] / 255) + 0.7152 * (data[down + 1] / 255) + 0.0722 * (data[down + 2] / 255);
		const edge = Math.abs(lum - lumL) + Math.abs(lum - lumR) + Math.abs(lum - lumU) + Math.abs(lum - lumD);
		ao = Math.min(1.0, ao + edge * 0.55);
		ao = Math.max(0.18, Math.min(1.0, ao));
		const byte = Math.round(ao * 255);
		out[i] = byte;
		out[i + 1] = byte;
		out[i + 2] = byte;
		out[i + 3] = 255;
	}
}

const blurred = await sharp(out, { raw: { width: w, height: h, channels: 4 } })
	.blur(1.2)
	.png({ compressionLevel: 9 })
	.toBuffer();

await sharp(blurred).toFile(output);
console.log("Wrote AO proxy:", output);
