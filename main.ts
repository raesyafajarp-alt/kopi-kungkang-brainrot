// Kopi Kungkang Brainrot — entrypoint for make.fun roblox-brainrot-01.
// Node 22, standard library only. No installs, no network, no build step.
//
// What it does, in order:
//   1. Copies this repo's game files into the output directory:
//      game.rbxl (the Rojo-built place), src/ (every Luau script),
//      screenshots/ (captures of the game running in Studio) and
//      PLAY.json (the published experience's play link).
//   2. Writes dossier.json with buildDossier from the vendored kit
//      library vendor/makefun-roblox.ts, which this program must not
//      modify. The gate rebuilds the same dossier and compares bytes.
//
// The output directory is /output inside the grader's container. When
// run anywhere else, MAKEFUN_OUTPUT_DIR stands in for it:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
//
// One rule shapes every copy below: no name under the output may start
// with a dot. A stray .gitkeep or .DS_Store fails the whole entry, so
// both directory copies filter dotted names out at every depth.

import { copyFileSync, cpSync, existsSync, mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { basename, join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

// The repository root: the folder this file lives in.
const repoRoot = fileURLToPath(new URL(".", import.meta.url));
// The grader's output directory, or the local stand-in for it.
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

// Keep out every file or directory whose name starts with a dot,
// such as .gitkeep, .DS_Store or .git, at any depth of the copy.
function keepUndotted(path: string): boolean {
	return !basename(path).startsWith(".");
}

// The place file and the play link are single files: copy them verbatim.
mkdirSync(outputDir, { recursive: true });
copyFileSync(join(repoRoot, "game.rbxl"), join(outputDir, "game.rbxl"));
copyFileSync(join(repoRoot, "PLAY.json"), join(outputDir, "PLAY.json"));

// src/ and screenshots/ are trees: copy them recursively, dotted names out.
// screenshots/ may legitimately be empty while the captures are still
// being taken in Studio; its directory is created either way so the
// dossier builder always finds it.
cpSync(join(repoRoot, "src"), join(outputDir, "src"), { recursive: true, filter: keepUndotted });
mkdirSync(join(outputDir, "screenshots"), { recursive: true });
if (existsSync(join(repoRoot, "screenshots"))) {
	cpSync(join(repoRoot, "screenshots"), join(outputDir, "screenshots"), {
		recursive: true,
		filter: keepUndotted,
	});
}

// The dossier, with the gate's own caps. Only text_max_bytes changes the
// bytes; the other caps make this program fail exactly where the scorer
// would refuse the entry (too many screenshots, one too large, a place
// past its instance or script-source caps).
//
// Screenshots are required: the dossier builder refuses an entry with
// no cover image, so say so plainly instead of letting its error be
// the first thing a builder sees. Captures come from Roblox Studio
// (see README.md); until they exist this program cannot hand anything in.
const screenshotDir = join(repoRoot, "screenshots");
const hasScreenshot = existsSync(screenshotDir)
	&& readdirSync(screenshotDir)
		.filter((name) => !name.startsWith("."))
		.some((name) => /\.(png|jpe?g)$/i.test(name));
if (!hasScreenshot) {
	throw new Error(
		"main.ts: screenshots/ holds no PNG or JPEG yet. Capture 3 or 4 shots of the game running in Roblox Studio "
			+ "(16:9, each under 256 KiB, the first by name is the thumbnail) and put them in screenshots/ first.",
	);
}
const dossierCaps = {
	text_max_bytes: 65536,
	screenshots: { max: 4, max_bytes: 262144 },
	max_instances: 500000,
	scripts_max_source_bytes: 8388608,
	scripts_max_path_chars: 1048576,
};
writeFileSync(join(outputDir, "dossier.json"), buildDossier(outputDir, dossierCaps));

console.log("Kopi Kungkang Brainrot handed in to " + outputDir);
