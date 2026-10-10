# Getting RAID AREA 51 into Roblox Studio (macOS)

Three workflows exist. They stack rather than compete:

| | Workflow | What it gives | Needs |
|---|---|---|---|
| **C** | Open the built `.rbxl` | Look at and playtest the current build **today** | Roblox Studio only |
| **B** | Repo + Rojo sync | Edits in the repo appear in Studio; rebuild the world any time | Git, Rokit (installs Rojo/Lune/…), Rojo Studio plugin |
| **A** | Claude Code on your Mac + Studio's built-in MCP server | Claude can open playtests, run Luau in Studio, read Output, move the character and **take viewport screenshots** | Claude Code, latest Studio, MCP enabled |

**Recommendation:** use **C now** for the first look, then set up **B + A** as the permanent
setup. A cloud session like this one cannot reach Studio on your Mac, because Studio's MCP
server only talks to programs running on the same computer. A Claude Code session on your
Mac, in a clone of this repo, can do everything in this guide and verify it in Studio.

> **Never open the original game while an MCP client is connected, and never publish this
> build over it.** MCP clients can read and modify any place open in Studio.

---

## C. Open the built place (5 minutes)

1. Download `RaidArea51.rbxl` (attached in chat, or build it with workflow B).
2. Roblox Studio → **File → Open from File…** → choose `RaidArea51.rbxl`.
3. Run the checks in [STUDIO_VERIFICATION.md](STUDIO_VERIFICATION.md) § 1–2.
4. To keep it as a cloud place: **File → Publish to Roblox As…** → **Create new experience**.
   Name it `RAID AREA 51 [DEV]` and keep it private. **Do not pick the existing game.**

## B. Repository + Rojo (ongoing development)

```sh
# 1. Tools (one time)
xcode-select --install                     # only if `git --version` fails
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
# restart the terminal so ~/.rokit/bin is on PATH

# 2. Project
git clone -b claude/raid-area-51-roblox-xkij03 https://github.com/dkelwk/Roblox-Game.git
cd Roblox-Game
rokit install            # answer "y" to trust rojo, lune, selene, stylua, luau-lsp
rojo plugin install      # installs the Rojo plugin into Studio (restart Studio)

# 3. Build and verify
lune run scripts/build   # → build/RaidArea51.rbxl (code + generated world)
lune run scripts/check   # optional: format, lint, types, all specs (should end "All checks passed")
open build/RaidArea51.rbxl
```

**Live sync** (after publishing the dev experience once, as in C step 4):

1. Open the dev place in Studio.
2. In a terminal in the repo, run `rojo serve`.
3. In Studio: **Plugins → Rojo → Connect**.
4. Code edits sync immediately. After changing the world generator, run
   `lune run scripts/build` again; Rojo syncs the regenerated `Workspace.World`.

The code currently lives on the branch `claude/raid-area-51-roblox-xkij03`. Merging it into
`main` (through a pull request) makes it the default when cloning.

## A. Claude Code + Studio MCP (lets Claude see and test Studio)

1. Update Roblox Studio to the latest version.
2. Install Claude Code on the Mac (`curl -fsSL https://claude.ai/install.sh | bash`, or see
   the Claude Code docs). Sign in with `claude`.
3. Enable Studio's MCP server: **Assistant → ⋯ → Manage MCP Servers → Enable Studio as MCP
   server**.
4. Connect Claude Code. Either:
   - **Quick connect:** **Assistant Settings → MCP Servers → Quick connect** → turn on
     **Claude Code** (restart Studio if it isn't listed); or
   - **Manually:** `claude mcp add Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`
5. Open the **dev** place in Studio, then start Claude Code in the repo folder:
   `cd Roblox-Game && claude`. To drive that local session from the Claude app on your
   phone or browser, run `claude remote-control` instead.
6. Confirm the green "connected" indicator under **Manage MCP Servers**. Then ask Claude to
   run the first Studio verification. Everything it needs is in this repository.

Studio MCP tools a local session gets:

- `screen_capture` (viewport screenshots);
- `execute_luau` (Edit, Server or Client context);
- `start_stop_play` and `get_console_output`;
- `character_navigation`;
- `search_game_tree` and `inspect_instance`;
- script read/edit tools.

Source: Roblox Creator Docs, "Connect to the Roblox Studio MCP server".

## Troubleshooting

- **`rokit install` asks about trust:** expected; answer `y` once per tool.
- **`lune run scripts/build` says `rojo` not found:** restart the terminal, or run `rokit install`.
- **The place opens but `Workspace.World` is empty:** the file was built without the generated
  world. Run `lune run scripts/build`, which builds twice by design, and open the new file.
- **MCP not connecting:** restart both Studio and Claude Code, and check the binary path in
  step 4.
