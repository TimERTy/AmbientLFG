# AmbientLFG

Watches the WoW Premade Group Finder for groups matching your criteria and alerts you the moment one appears — so you can stop refreshing the browse window and just play.

## What it does

- **Rules**: "alert me for Mythic Nerub-ar Palace groups that still need a tank" is `/alfg add mythic nerub +tank` (or build it in the UI). Words match the activity — the instance and difficulty a group is listed for — plus the leader's name, and are spelling-tolerant ("Neroob" matches "nerub").
- **Alerts**: raid-warning banner, sound, and a flashing taskbar icon if you're alt-tabbed.
- **Background watching**: optional auto-search re-checks the Group Finder while you play. It pauses while you browse the Group Finder yourself and resumes when you close it.
- **Live matches list**: the `/alfg` window shows every currently-listed matching group with its tank/healer/dps counts, activity, difficulty, and title.

## Keystone levels

Key level lives in the listing's title, so match it there: `/alfg add +18 +tank`. Numbers are matched exactly — a `+18` rule will not fire on `+19` or `+188`, and a `+2` rule will not catch every key from `+20` to `+29`.

## What rules can't match

Rules see the listing's title and comment, the activity name and its difficulty, and the leader's name. Two limits are worth knowing:

- **Blizzard's auto-generated titles are unreadable.** When a group doesn't type its own title, the game sends addons an opaque token rather than words. Those listings can still be matched by activity, difficulty and leader, but not by title text.
- **There is no per-boss activity.** Blizzard lists one activity per instance per difficulty — "Nerub-ar Palace (Mythic)" — so a boss name only matches when the group happens to have typed it into their own title.
- **Seller filtering**: boost/carry advertisers are recognized and hidden automatically; block any leader forever with one click.

## Usage

1. `/alfg` to open the settings window
2. Add a rule (section, difficulty, words, roles that must be open)
3. Enable auto-search
4. When the alert fires, open the Group Finder and sign up

Signing up stays a manual click — Blizzard requires it — so pairing this with a one-click-apply addon like SmartLFG works well.
