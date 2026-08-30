# Changelog

## 0.3.5
- Fix: `/alfg add +18` was rejected as an unknown tag, so the keystone filtering 0.3.4 added could not actually be typed the way the docs described it. `+18` and `18` now mean the same thing, and a key matches whether or not the group typed the plus.
- Fix: a rule with no `+raid` or `+dungeon` searched raids only, so a keystone rule alerted on nothing while reporting listings scanned. Untagged rules now search both sections, which is what they already matched against.
- Section and difficulty are radio buttons now, since only one of each was ever selectable. Raids always has a difficulty selected — an unqualified raid rule matched Normal, Heroic and Mythic at once — and Dungeons hides the difficulty row entirely rather than offering M+ next to raid difficulties.
- A queued background search now also fires on a keypress, not only on a click in the world. WoW requires a hardware event to run the search, and if you move with the keyboard you could go a long stretch without clicking anything while searches waited.

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
