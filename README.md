# AmbientLFG

Watches the WoW Premade Group Finder for groups matching your criteria and alerts you the moment one appears — so you can stop refreshing the browse window and just play.

## What it does

- **Rules**: "alert me for Mythic Nerub-ar Palace groups that still need a tank" is `/alfg add mythic nerub +tank` (or build it in the UI). Words match the activity — the instance and difficulty a group is listed for — plus the leader's name, and are spelling-tolerant ("Neroob" matches "nerub").
- **Alerts**: raid-warning banner, sound, and a flashing taskbar icon if you're alt-tabbed.
- **Background watching**: optional auto-search re-checks the Group Finder while you play. It pauses while you browse the Group Finder yourself and resumes when you close it.
- **Live matches list**: the `/alfg` window shows every currently-listed matching group with its tank/healer/dps counts, activity, difficulty, and title.

## What rules can't match

As of WoW 12.0 a listing's own title and comment reach addons as opaque tokens — the game renders them on screen, but nothing can read the words inside. Rules match what is still readable: the activity name, its difficulty, and the leader's name.

So a rule can say "Mythic Nerub-ar Palace", but it cannot say "the group whose title mentions Ulgrax" or "+18 keys only" — Blizzard exposes no per-boss or per-keystone-level activity, and the Group Finder's own search has no free-text filter. Rule words aimed at a boss name or a key level will simply never fire.
- **Seller filtering**: boost/carry advertisers are recognized and hidden automatically; block any leader forever with one click.

## Usage

1. `/alfg` to open the settings window
2. Add a rule (section, difficulty, words, roles that must be open)
3. Enable auto-search
4. When the alert fires, open the Group Finder and sign up

Signing up stays a manual click — Blizzard requires it — so pairing this with a one-click-apply addon like SmartLFG works well.
