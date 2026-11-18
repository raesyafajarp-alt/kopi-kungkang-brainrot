# Kopi Kungkang Brainrot

A 3D brainrot game for Roblox, built for make.fun's **roblox-brainrot-01**
bounty ("Make the best AI Roblox brainrot game"). Collect absurd,
original Indonesian meme characters as they walk the conveyor, keep them
on your own base, earn money every second, climb the rarity ladder,
mutate, rebirth — and run home when the tsunami comes, before another
player steals your best brainrot.

All characters, names and the world are original. Nothing here copies a
character from Steal a Brainrot or any other game in the genre.

## How to play

1. **Watch the conveyor.** Brainrots spawn at the green pad and walk the
   belt from one end of the map to the other. Each one shows its name,
   rarity and $/second on a billboard above its head.
2. **Buy one.** Walk up to a brainrot and hold the **Beli** prompt
   (ProximityPrompt). It costs the price on its billboard, and it hops
   over to a free slot in your base.
3. **Earn.** Every brainrot in your base pays its $/second, once a
   second, forever. Your money ticks up in the top-right HUD.
4. **Climb the ladder.** Rarer brainrots cost more and pay far more.
   Mutations (Golden x2, Diamond x3, Pelangi x5) multiply the rate.
   **Rebirth** (bottom-right button, costs grow each time) resets your
   money and collection but adds a permanent +50% income multiplier.
5. **Defend your base.** Other players can hold the **Curi!** prompt on
   your brainrots for 3 seconds and walk away with them — unless your
   base is locked. Press **Kunci Base** to raise the red door for 60
   seconds (150 second cooldown).
6. **Outrun the tsunami.** Every few minutes a warning banner counts
   down 15 seconds, then a giant wave sweeps the map. Anyone caught
   outside their own base loses 10% of their cash and is thrown back to
   spawn. Inside your base you are safe.
7. **Sell** any brainrot from the Koleksiku panel for half its cost.

## The cast

| Character | Rarity | Cost | $/second |
|---|---|---|---|
| Kopi Kungkang | Common | $100 | 5 |
| Meong Micin | Common | $250 | 8 |
| Bakso Berlari | Common | $500 | 12 |
| Nasi Goreng Ninja | Rare | $1,200 | 25 |
| Es Teh Manis Terbang | Rare | $2,500 | 40 |
| Gorengan Sakti | Epic | $6,000 | 70 |
| Sate Klathak Raksasa | Epic | $12,000 | 120 |
| Rendang Raja | Legendary | $30,000 | 250 |
| Durian Meledak | Legendary | $60,000 | 450 |
| Kerupuk Kosmik | Mythic | $150,000 | 1,000 |

Spawn chances: Common 55%, Rare 25%, Epic 12%, Legendary 6%, Mythic 2%.
Mutations: Normal 87.5%, Golden (x2) 8%, Diamond (x3) 3%, Pelangi (x5) 1.5%.

## The world

A 3D map built in `default.project.json`: a 180-stud conveyor with
neon rails down the middle, 8 player bases (6 collection slots each)
along both sides, a shop stall by the spawn, trees, lamps, clouds and
mountains around the edges, and a giant wave that sleeps off-map until
the tsunami event. The HUD is a ScreenGui over the 3D world: money,
income, collection, leaderboard, rebirth/lock buttons and the tsunami
banner.

## Code layout

- `src/shared/Config.luau` — every tuning number in one place.
- `src/shared/BrainrotData.luau` — the cast, rarities, mutations, rates.
- `src/server/GameState.luau` — the single source of live state.
- `src/server/BrainrotFactory.luau` — builds each brainrot's 3D model.
- `src/server/Actions.luau` — buy, steal, sell, rebirth, lock (all
  re-validated on the server).
- `src/server/GameLoop.luau` — spawning, walking, income tick, HUD sync.
- `src/server/Tsunami.luau` — warning, wave sweep, safe-zone checks.
- `src/server/init.server.luau` — boots the systems above.
- `src/client/Hud.client.luau` — the whole ScreenGui.
- `src/client/Effects.client.luau` — floating +$ popups, tsunami flash.

Progress is kept in memory for the session (no DataStore), which is
enough for judging the game loop in Studio.

## Build and hand in

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` (Node 22, standard library only) copies `game.rbxl`, `src/`,
`screenshots/` and `PLAY.json` to the output directory and writes
`dossier.json` with the vendored `vendor/makefun-roblox.ts` (unchanged).
If `screenshots/` has no image yet it stops with a plain message
telling you to capture in Studio first, instead of failing inside the
dossier builder.

Verified 2026-11-18 (Rojo 7.7.1, Luau 0.700): `rojo build` succeeds;
all 10 Luau files compile (`luau-compile`); the full `main.ts`
pipeline was run end-to-end against a scratch copy with stand-in
images and produced a valid `dossier.json` — 199 instances
(163 Parts), 10 scripts / 53,723 bytes matched to `src/` at 100.0%,
`game.rbxl` 27,776 bytes, dossier 119,791 bytes, no dotted names in
the output. The stand-in images were deleted afterwards and never
entered this repo.

## Status: what still needs a human

- **Screenshots:** `screenshots/` is intentionally empty right now. The
  three captures (start, play, tsunami) must be taken in Roblox Studio
  while the game runs, 16:9, each under 256 KiB, and the first by name
  must be the game's thumbnail on Roblox. No placeholder image is
  shipped — a fake screenshot would fail finalist review.
- **Publish + PLAY.json:** `PLAY.json` still names place 0. The place
  must be published from Roblox Studio as a Public experience, its
  description must carry the account's make.fun play code, and its icon
  and first thumbnail must be uploaded on the Creator Dashboard (the
  thumbnail must be the same file as one of the screenshots). Only the
  Roblox account owner can do these steps, on Windows/Mac with Studio.
  After that, fill in `PLAY.json` with the real place and universe ids
  and submit again.
