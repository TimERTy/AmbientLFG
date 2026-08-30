# Changelog

## 0.4.0
**Rules are gone. You craft the search; the addon runs it for you.**

Set up the search you want in Blizzard's own Group Finder — category, filters, and the search box, including a keystone level or a range like `12-14` — and run it once. AmbientLFG replays exactly that search in the background and alerts you when a group appears with a seat you can fill. Saved rules are dropped on first login and your current spec's role is ticked for you.

The reason is that rule words could never do this job. Since 12.0 a listing's title reaches an addon as an opaque token — the game renders it on screen, but the characters an addon receives are an id, not words — and that is true even when the group typed the title themselves. A `+14` rule could not match a listing plainly titled `+14`. Blizzard's search box can: for keystones it is a key-*range* filter the server evaluates against the real key level, and it keeps applying to the addon's background searches after you close the window.

- Roles are now one setting rather than a property of each rule: tick the roles you can play, and a group alerts if any one of them has an open seat. None ticked means every group the search returns.
- The window names the search it is watching, so the filter that decides everything is never invisible state.
- Auto-search does nothing until you have run a search yourself, and says so, instead of quietly inventing one that approximated the panel's filters and could not carry the search box at all.
- `/alfg roles tank dps` (or `any`) replaces `/alfg add`, `del` and `clear`.
- The groups already listed when watching starts no longer alert. A login, a `/reload`, or changing your search used to fire on every listing the search returned at once; those are the board as you'd see it, not news, so alerting begins with the next group to appear. `/alfg reset` still makes them all alert again.
- Changing your search clears the matches list immediately instead of leaving the previous search's groups sitting in it until they aged out.
- The window is titled "AmbientLFG" rather than "Premade Alert".
- Fix: the roles on a rule were required all at once. Ticking Tank, Healer and DPS asked for a group with every role still open — an empty group — so it matched nothing and looked simply broken.
- Clicking a checkbox's label toggles it, instead of only the box itself.
- A queued background search now also fires on a keypress, not only on a click in the world. WoW requires a hardware event to run the search, and if you move with the keyboard you could go a long stretch without clicking anything while searches waited.
- New `/alfg diag` prints what the addon actually received for the listings on screen — the listing counts, whether each title and comment arrived as readable text or an unreadable token, and why each listing did or did not match.

## 0.3.4
- New: keystone levels can be filtered. A group's key level is in the title it typed, so `/alfg add +18 +tank` works. Numbers now match exactly, so a `+18` rule no longer fires on `+19` or `+188`, and a `+2` rule no longer catches every key from `+20` to `+29`.
- Fix: 0.3.3's release notes and README overstated the 12.0 text restrictions. Titles a group types itself are readable and are matched normally; only Blizzard's auto-generated titles arrive as unreadable tokens. Matching was never disabled for readable titles, but the docs said it was.

## 0.3.3
- Fix: rule words were being matched against listing titles and comments, which WoW 12.0 hands to addons as unreadable tokens rather than text. Their characters could produce false matches and never a real one, so they are now skipped — rules match the activity name, its difficulty, and the leader's name.
- The docs and the built-in examples no longer suggest matching on a boss name. Blizzard lists an activity per instance and difficulty ("Nerub-ar Palace (Mythic)"), never per boss, so a boss-name rule could never have fired. The README now spells out what a rule can and cannot match.

## 0.3.2
- Fix: a group you'd already been alerted about could alert again after you added, removed, or reordered rules — alert state is now tied to the rule itself rather than its position in the list
- Fix: replaced WoW API calls that were deprecated in 12.x
- The matching logic (rule parsing, seller filtering, role checks) is now covered by automated tests

## 0.3.1
- No more repeated failure messages when the Group Finder isn't usable (in a battleground, on an ineligible character, etc.) — retries slow down automatically and stop entirely after several failures, with a single message; searching resumes on its own once the Group Finder works again
- Background searches pause in battlegrounds and arenas
- Background searches now find the same listings the Group Finder window shows — previously they could miss more than half the groups (a search filter was too narrow)
- When you've searched manually at least once, background searches reuse your exact search settings for that section
- Groups no longer briefly disappear from the Current matches list and reappear — entries now only drop out when they're actually gone from newer search results
- Ready for WoW 12.1.0

## 0.3.0
Initial release.
- Watches the Premade Group Finder for groups matching your rules and alerts you with a raid-warning banner, sound, and a flashing taskbar icon so you can sign up before the group fills
- Rules combine words with requirements, e.g. "mythic lura +tank" alerts for Mythic Lura groups that still have a tank spot open — spelling variations like "Lurra" are matched automatically
- Optional auto-search keeps checking the Group Finder in the background while you play, so you don't have to sit in the browse window (pauses automatically while you browse the Group Finder yourself)
- Settings window (`/alfg`) with a live "Current matches" list showing each matching group's tank/healer/dps counts, the boss and difficulty it's listed for, and its title
- Boost/carry sellers are filtered out: repeat advertisers are recognized and hidden automatically, and you can permanently block any leader with one click on the X next to their group
- Rules can target Raids or Dungeons, a specific difficulty, and which roles must be open — all configurable in the UI or via slash commands (`/alfg` for the full list)
