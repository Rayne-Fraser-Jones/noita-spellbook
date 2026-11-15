# Spellbook

A Noita mod that gives you unlimited spell storage through the game's own spell row.

The spell row in the inventory screen (Tab) shows one page of the spellbook at a time. The pages
are made by the spellbook: every spell you have, sorted by type and in the game's own order. The
cards in the row are real cards, so you move spells between the spellbook and your wands with the
normal drag-and-drop.

Contents: [Install](#install) · [Quick start](#quick-start) · [How it works](#how-it-works) ·
[Moving spells](#moving-spells) · [The page list](#the-page-list) · [Store all](#store-all) ·
[Settings](#settings) · [Save data](#save-data) ·
[Status](#status-what-has-been-confirmed-in-play) · [Troubleshooting](#troubleshooting) ·
[Development](#development)

## Install

1. Copy the `spellbook` folder into Noita's `mods` folder (Steam: right-click Noita >
   Manage > Browse local files > `mods`). Replace any older copy.
2. Enable "Spellbook" in the Mods menu on the main screen. It does not need unsafe mods.
3. Turn off other spell-storage mods (such as Advanced Spell Inventory) to avoid conflicts.

The `tests` and `dev` folders are for development only; they do nothing in the game.

## Quick start

- Pick up spells as usual. They go into the spellbook.
- Open the inventory. The spell row shows one page of your spells. Drag a spell from it into
  a wand to take one copy; drag a spell from a wand into the row to store it.
- The pages are listed in the SPELLBOOK panel at the top right, like a table of contents: one
  line per spell type, with every spell in the game you have unlocked, faded where you have none.
  Rest the mouse on a name to look at that page; click it to select it. Drag the panel by its
  title bar to move it.
- Tick "Merge categories" (at the top of the panel) to put every spell on one line, "All";
  tick "Hide unowned" to see only the spells you have.
- Type in the search box (at the bottom of the page list) to see the spells whose name holds the text.
- Right-click a spell to see every copy of it, one per slot, by uses left.
- In a Holy Mountain, double-click a spell in a wand to store it, or use "Store all: Held
  wand / All wands" (beside the game's "SPELLS" label) to store a whole wand's spells.
- Beside "SPELLS", "Page: Projectiles 1" (for example) says which page the row shows.

## How it works

### Groups

The spellbook keeps copies in groups: every copy of one spell with one exact number of uses left.
"Black Hole, 3 uses" and "Black Hole, 0 uses" are two groups.

- On the spell type and search pages, each spell takes one slot, however many groups it has.
  The card shown is the copy with the most uses left (or the fewest, as set in the settings);
  the number in the bottom-right corner is how many copies of the spell you have in all (shown
  when there is more than one). The number in the top-left is the game's own uses count of the
  copy shown; the count is drawn the same way (the game's small numbers font and grey, no
  shadow), in the opposite corner.
- Dragging the card out takes that copy; the next one by uses left then shows in the slot.
  Once you drag it (the mouse moved a little with the button held: a press alone doesn't lift
  the card), the slot already shows that next copy, with the count one
  less, or stays empty for the last copy; the real card is put there when you let go.
- To pick an exact copy (for example a 0-use copy for Greek letter spells), right-click the card:
  its copies pages show every copy in a slot of its own (see [Pages](#pages)).
- When a spell's last copy leaves, the spells after it move up a slot.

### Pages

Each spell type (Projectiles, Static projectiles, Projectile modifiers, Multicasts, Materials,
Other, Utility, Passives: the game's own names for them, which it shortens to "Static proj." and
"Proj. modifier" in a spell's tooltip) has its own pages, one slot per spell, in the game's spell order: page 1
first, 16 slots to a page (one spell row).

With "Merge categories" ticked there is one line of pages instead, "All 1", "All 2", ...: every
spell, in the same order as the type pages put them one after another (all the projectiles, then
the static projectiles, and so on). Its card is the game's "All spells" spell. Everything else
below is the same, with All in place of the type pages.

- A type only has as many pages as it needs. With "Hide unowned" ticked, a type you have no
  spells of has no pages: with just two Spark Bolts, the only page is Projectiles 1.
- Every spell in the game you have unlocked has a slot, faded where you have none (spells not
  unlocked yet too, with the "Show locked spells" setting; one you own is always shown), so the
  pages are the same every time. With "Hide unowned" ticked, only the spells you have get slots,
  so the pages close up.
- Spells from a mod that is disabled stay in the spellbook, at the end of "Other", drawn as a faded
  placeholder; the tooltip gives the spell's ID and how many copies are kept. When the mod is
  enabled again, the cards come back.

Two more kinds of page are listed below the spell types while they exist:

- **Search** ("Search 'mana' 1", ...): the spells whose name holds the text in the search box
  (any case), grouped and ordered as on the type pages, the ones you have none of
  too, faded (unless "Hide unowned" is ticked). A search with no results has one empty page. Typing selects it; clearing the
  box (delete the text, or right-click the box) goes back to the type page you were on.
- **Copies** ("Copies of Black Hole 1", ...): right-click any card (also a spell with unlimited uses, for consistency,
  though then every copy is the same).
  Every copy of that spell gets a slot of its own (no grouping, no counts), ordered by uses left
  as in the settings, so you can take exactly the copy you want. The copies pages close when you
  select another page: by clicking it, or by typing a search (which selects the search page). If you take every copy out, the copies
  page stays, empty, so a copy put back shows on it again.
  Until you first do it, a hint at the bottom of the screen says "SPELLBOOK: Right-click a
  limited-uses spell in your inventory to see all its copies" while the mouse is on a spell
  with limited uses in the spell row (one of the spellbook's cards, which right-clicking works
  on) whose copies have at least two different numbers of uses, so there is a copy to choose; it
  hides again when the mouse moves off. It shows while the mod setting "Show right-click hint" is on (as it is to begin with); the first
  right-click on a card turns the setting off. It can be turned on or off there at any time.

When a spell is stored while a search or copies page is selected and that page shows it, the
page stays selected. These pages aren't saved: a run loads on the type page you were last on.

### The spell row

While the inventory is open, the spell row shows the selected page as real cards (or the page
whose name the mouse is resting on; see [The page list](#the-page-list)). While the inventory
is closed, the spellbook keeps the row empty, so picking up a spell always has room; the spell goes
straight into the spellbook.

The spellbook never changes the row while a mouse button is held, so it never interferes with a
drag in progress. It acts once you let go.

## Moving spells

Everything uses the game's normal controls. A card in the row stands for one copy.

| You do this | Result |
|---|---|
| Drag a card into a wand | One copy goes in. If the group has more, the next copy shows in the slot. |
| Drag a card onto a spell in a wand | The game swaps them: one copy goes into the wand, and the wand's spell is stored. |
| Drag a card out of the inventory | One copy is thrown. |
| Drag a card to another slot of the row | It goes back to its slot as soon as you let go: pages are always in order. |
| Drag a wand spell into the spell row | It is stored, wherever you drop it (onto a card too: the spellbook's card stays in the spellbook). |
| Double-click a spell in a wand | It is stored. Only two clicks count: a press dragged more than 3 pixels before it is let go is a drag, so a click and then a drag of the same spell moves it. |
| Press "Store all: Held wand" / "All wands" | Every spell in the wand you hold / in all your wands is stored; always-cast spells stay. |
| Pick up a spell | It is stored. With the inventory open, the game first puts it in an empty slot of the row. |
| Right-click a card | Its copies pages open (see [Pages](#pages)). Nothing moves. |
| Pick up a spell refresher | Limited-use spells in the spellbook are refilled, as the game refills the spells you carry (see below). |

The spell refresher refills every limited-use group to full uses; groups of a spell that end
up with the same uses combine. Groups with unlimited uses (for example after the Unlimited
Spells perk) stay unlimited. With the inventory open, the refill waits until no mouse button is
held. (This used to be a setting; it always happens now.)

When a spell is stored, the page it is on is selected, so it stays in view (except with Store
all, which stores many at once). A spell picked up with the inventory closed gives a message
saying which page it went to.

Moving spells into or out of wands only works where wands can be edited. For dragging, the game
itself refuses. The spellbook's own ways (double-click, Store all) check the same thing
as a level: a Holy Mountain counts 1, each "Tinker with Wands Everywhere" effect (the perk, its
potion effect, the meditation cube) adds 1, and each "No wand editing" effect (the perk, or its
potion effect) takes 1 away. Wands can be edited while the level is above 0, so the two perks
cancel out: editing only in a Holy Mountain. Picking up spells and throwing them work anywhere.

Double-clicking works on wands the spellbook knows the layout of in the inventory: wands without
always-cast spells, with at most 26 slots. The spellbook finds the spell under the mouse from that
layout, and for a wand it hasn't measured (and any wand below it in the inventory) it can't.

One of the spellbook's cards that turns up in a wand is a copy taken out, however it got there
(with the mouse, or a gamepad), unless a wand spell turned up in its slot of the row at the same
time: then the game swapped the two (a wand spell dropped onto the card), and the card is taken
back out of the wand.

## The page list

The page list is in a panel titled SPELLBOOK. Its usual place is at the top, below the gold
counter, with its right border at x 512: left of the game's own list of your perks, stains and
other effects, whose names reach about x 519. The game's first wands have only a few slots, so
their boxes stay well clear of it (a wand box reaches past it only from 20 slots).

The panel is drawn in front of everything else. Its title bar, an amber strip with SPELLBOOK
in it, gets lighter under the mouse: press on it and move the mouse to drag the panel. It stays
where it is let go, kept on the screen, and is in the same place in later runs (a hidden mod
setting); "Reset panel position" in the mod settings puts it back in its usual place.
Dragging it doesn't change the spell row or the page selected.

At the right end of the title bar is an arrow, grey, white under the mouse (drawn as a small
triangle, not a character of the font). While the panel is open it points up: click it to
collapse the panel to just its title bar, and it points down; click it again to expand the panel.
Their tooltips are "Collapse the panel" and "Expand the panel".
Pressing on the arrow doesn't drag the panel; the rest of the title bar still does, collapsed or
not. The spell row keeps showing the page selected. Collapsing gives back the search box's
keyboard (and your controls). The panel stays collapsed in later runs (a hidden mod setting).

Each line of the page list starts with a card, drawn as the inventory draws one: the type's
card background with the icon of a spell typical of the type, as a quick reference. They are
Spark bolt (Projectiles), Explosion (Static projectiles), Homing (Projectile modifiers), Double spell
(Multicasts), Water (Materials), Alpha (Other), Long-distance cast (Utility) and Energy shield
(Passives). The Copies line shows the spell whose copies are open. The Search line has a
magnifying glass (the mod's own `files/search_icon.png`, drawn in the game's style) on the
inventory's empty slot box. Beside the card is the line's name, and
under it its page numbers, from 1, so the two lines of text are about as tall as the card's
picture; a line with only one page has just its name, centred on the card. The lines are 20
apart (4 between the cards' pictures). The panel is as wide as the
longest name needs; the search box is as wide as the panel.

- "Merge categories", at the top, then "Hide unowned": see [Pages](#pages). Both are
  unticked to begin with. Each is drawn as "[x]" while ticked and "[ ]" while not, white while ticked, dark grey otherwise, and is the same as the
  mod setting of that name. The panel is wide enough for "[x] Merge categories".
- One line per spell type, then a "Copies" line and a "Search" line while those pages exist (see
  [Pages](#pages)). The numbers under a line's name (1, 2, 3, ...) are its pages; a line with
  only one page has no numbers. The card, the name and the "1" are one button for the first
  page: with the mouse on any of them (or anywhere else on the line, see below) all three light
  up, for the selected page all three are gold, the card shows the page's tooltip, and a click on
  any selects it. The names and numbers are dark grey, the game's hover yellow while the mouse is
  on one or in its area, and the selected page is gold.
  The name also stands for the whole line: it is gold while any of the line's pages is
  selected, and lights up while any of the line's page buttons is under the mouse (another
  number, or an arrow of "< 12/63 >"); the card and the "1" only for page 1. The page numbers
  are spaced the same on every line: the widest spacing at which every line fits. A line with more pages than fit (copies of a spell you have hundreds of, a big
  search) shows "< 12/63 >" under its name instead: white buttons for the previous and next page, dark grey (and not
  buttons) on the first and last page, and
  which page of how many: the page number gold when one of the line's pages is selected, the
  "/63" dark grey (the line's name is gold while any of its pages is selected). Resting the mouse on an arrow doesn't look at the page it leads to
  (the selected page stays shown), and the arrows have no tooltip (at the screen's edge the game
  would put it over them). The card has a tooltip naming the first page in full
  ("View page: Projectiles 1"); the names and page numbers have none, as it would cover most of
  the panel (the cards below a name, the numbers along) while the mouse moves over them.
- Rest the mouse on a line for a moment to look at its first page in the spell row, or on one
  of its other page numbers to look at that page. A whole line stands for its first page: the
  panel's full width and the line's full height, so the lines touch, apart from the areas of the
  numbers from 2 up (and the arrows of "< 12/63 >"). Each page number's area reaches halfway into
  the gaps beside it, so the areas touch too, and the last one reaches the panel's right edge, so
  moving on past it doesn't go back to the first page. The number areas take the lower part of
  the line, where the numbers are; right of the name above them is still the first page. Once a page is shown that way, moving to another
  line or number shows that page at once, so a sweep down the lines or along the numbers shows
  each page in turn, never the selected page in between; moving off the lines (the boxes, the
  title bar, the search box, or off the panel) shows the selected page again at once. A click
  anywhere on a line selects its first page, and anywhere in a number's area that page. Which
  area the mouse is in is worked out from its position, so exactly one is lit at a time, and a
  page's name or number lights up in the same hover yellow whether the mouse is on its text or
  elsewhere in its area.
  Beside SPELLS, "Page:" (the same grey as SPELLS) is followed by the page's name: gold for the
  selected page, and the game's hover yellow while you look at another (the same yellow as the
  name under the mouse). The cards can't be moved while
  looking, since the mouse is on the list.
- Click a name to select that page: it stays shown.
- If the selected page stops existing (its last spells left), the last page of that type is
  selected, or else the first page.
- The search box, at the bottom: click it to type (it says "Search..." while empty). It
  takes no typing until you click it, so running with the mouse over it types nothing. Once
  clicked, typing works with the mouse anywhere (letters, Shift for capitals, digits, space and
  - ' , .; keys are read by their position, so other keyboard layouts type what a QWERTY keyboard
  would), and holding Backspace keeps deleting. Its border
  lights up white while it has the keyboard. While it has
  the keyboard, your controls are switched off so typing doesn't also work the game's keys
  (switching wands with the number keys, for example); clicking again (anywhere, the box too), Enter or
  Escape gives the keyboard back, and so does closing the inventory. Right-click it to clear it;
  if it has the keyboard, it keeps it, so you can type a new search straight away. (With your
  controls off the game's GUI may not follow the mouse, so then whether the mouse is on the box
  comes from the mouse's position in the world, which does.)

## Store all

"Store all: Held wand / All wands" is on the line beside the game's "SPELLS" label, at the
right end of the spell row (further right if the page name is long). "Held wand" stores every
spell in the wand selected in the quickbar; "All wands" every spell in all the wands in the
quickbar. Always-cast spells stay in their wands. "Store all:" and "/" are the same grey as SPELLS.

The two buttons are white while they can be used; their tooltips say what they do in one line.
When they can't be used (wands can't be edited here, see [Moving spells](#moving-spells); no
wand selected; nothing to store, e.g. "Your held wand has no spells to store"), they are dark grey and don't light up under the mouse, and the
tooltip says why under what it does, briefly ("You cannot tinker with wands here"). The
message when one is used anyway, or a wand spell is double-clicked, says it in full (a Holy
Mountain or Tinker With Wands Everywhere needed; or blocked by No Wand Tinkering).

## Settings

Mod settings, in the game's Mods menu:

| Setting | Default | What it does |
|---|---|---|
| Merge categories | Off | Every spell on the pages of one line, "All", in the same order, instead of a line per spell type. The same as the "Merge categories" box in the page list. |
| Hide unowned spells | Off | No placeholders for spells you own no copies of. The same as the "Hide unowned" box in the page list. |
| Show locked spells | Off | With Hide unowned off, also placeholders for spells you haven't unlocked yet. |
| Show limited-uses spells with | Most uses on top | Which copy of a limited-uses spell its slot shows (Most uses on top or Least uses on top); copies pages, opened by right-clicking it, are ordered the same way. |
| Show right-click hint | On | The hint at the bottom of the screen about right-clicking a spell to see its copies, shown while the mouse is on a limited-uses spell in the spell row whose copies differ in uses. Turned off by itself the first time you right-click a card. |
| Reset panel position | (a button) | Puts the SPELLBOOK panel back in its usual place after it has been dragged; greyed out while it is there. |
| Debug log | Off | Records what the spellbook does. The last 400 lines are saved with the run (see [Troubleshooting](#troubleshooting)). |


## Save data

- The spellbook is saved with the run, in the world's global values. It survives save-and-quit and
  is reset by a new game.
- If the game is saved while the inventory is open, the cards shown in the row are not counted
  twice when the save is loaded.
- When the player entity is replaced (polymorph and back), the spellbook takes over the new spell
  row without counting its cards again.

## Status: what has been confirmed in play

The mod was written without access to the game and tested against a stand-in for the Noita API
(see [Development](#development)). Everything below has been confirmed by playing:

- The spell row shows a page as real cards; dragging them into and out of wands works. One copy
  per drag into a wand or out of the inventory, and the next copy appearing in the slot (drawn
  in the dragged card's slot as soon as the card is lifted, lined up with a real card).
- A card moved within the row (or two swapped) going back to its slot and staying there: it is
  replaced by a new card in its slot, as setting its slot back didn't stick (the game moved it
  back again every two frames).
- A wand spell dropped into the row being stored, and its page selected; one dropped onto one
  of the spellbook's cards: that card taken back out of the wand.
- Double-clicking a wand spell.
- "Store all: Held wand / All wands": placement beside SPELLS, greyed out when they can't be
  used, their tooltips.
- Pickups and their messages; the spell refresher waiting for the mouse button, unlimited groups
  staying unlimited.
- Group counts lining up with the game's inventory and looking the same as its uses count.
- The pages: filled in order, appearing and disappearing as spells come and go, placeholders
  for unowned spells, one line, All, in type order, the last page of a line being selected when
  the selected page goes, placeholders for spells from a disabled mod.
- The SPELLBOOK panel: its usual place, in front of everything else, the title bar, dragging
  it, kept on the screen and in the same place in later runs, "Reset panel position"; its two
  boxes (then "Categorize" and "Show unowned"; the mod settings menu not undoing a change made
  with them).
- The page list: the cards at the start of the lines, the names and page numbers beside them,
  the card, name and 1 lighting up together, page numbers spaced the same on every line,
  "< 12/63 >" for a line with too many pages; looking at a page by resting the mouse on its
  name, clicking to select it, a release over a name not counting as a click, the hover
  highlight staying on the button under the mouse when the row changes.
- Search and copies pages: right-clicking a card opens its copies pages, taking a copy from
  them; the search box (typing, the controls switched off while it has the keyboard and back on
  afterwards, right-click to clear, the white frame, only the box itself counting as under the
  mouse).
- The right-click hint and the "Show right-click hint" setting.
- Loading a save keeps the spells shown in the row.
- The debug log being saved with the run (in `world_state.xml`).

Not yet confirmed (new behaviour is listed here until it has been seen working in play):

- The arrow on the title bar collapsing the panel to its title bar, and expanding it again.
- The two boxes worded the other way round: "Merge categories" and "Hide unowned", both
  unticked to begin with, so the panel starts as a table of contents (a line per type, unowned
  spells shown). They are new settings, so a run's earlier "Categorize" and "Show unowned"
  choices aren't carried over.
- The code reorganised into smaller files (see [Files](#files)), with no change meant except
  one: mouse presses are read once a frame for every part of the mod, so a button already held
  when the inventory opens is never a press. The tests pass; it hasn't been played yet.
- Polymorph (the spellbook taking over the new player entity's row, with the inventory open or
  closed).
- The Holy Mountain detection for the Store all buttons and double-clicking, and the
  wand-editing level ("No Wand Tinkering" blocking the spellbook's own ways, and cancelling out
  "Tinker With Wands Everywhere").
- No tooltips on the page numbers or the lines' names.
- The right-click hint shown only while the mouse is on a limited-uses spell in the spell row
  whose copies have at least two different numbers of uses.
- Looking at pages: a whole line standing for its first page (the lines touching), each number's
  area reaching into the gaps beside it, a sweep down the lines or along the numbers showing each
  page at once, and the selected page again as soon as the mouse leaves the lines.
- "Page:", "Store all:" and the "/" between the Store all buttons in the same grey as SPELLS.
- A line's name gold while any of its pages is selected, and lit up with any of its page
  buttons under the mouse.
- Fixes from the review (each with a test, in `tests/edge_*.lua`): the Unlimited spells perk
  taken with the inventory closed leaving the row empty; the controls coming back after
  polymorph while typing in the search box; one of the spellbook's cards in a wand at a save or
  polymorph not counted twice; a click then a drag of a wand spell moving it (not a
  double-click); a card moved into a wand without its press being seen (or with a gamepad)
  kept there; a refresher still waiting at a save done after loading; storing a spell with
  copies open closing them, or selecting the page with the new copy; "<" dark grey on a line
  whose page isn't selected; a spell unlocked during the run getting its placeholder; the panel
  not jumping to the mouse after the inventory was closed mid-drag, and its place kept as whole
  pixels.
- The "Unlimited spells" perk. The game makes the spell cards the player has unlimited when the
  perk is taken (`GameRegenItemActionsInPlayer`), but the spellbook keeps its copies as counts.
  So once the perk is taken (`perk_infinite_spells` in the world state), every group with uses
  left of a spell the perk affects is combined into the spell's unlimited group, and so are
  limited copies stored later; spells the game marks `never_unlimited` keep their uses (and the
  spell refresher still refills them), and so do spells from a mod that isn't loaded. The row
  is refilled, not while a mouse button is held.

## Troubleshooting

- **Counts or buttons don't line up with the spell row**: the positions are fixed values for a
  640 × 360 UI (see `ROW_X`, `ROW_Y`, `PITCH` in `files/ui/widgets.lua`). Send a screenshot.
- **Clicking the SPELLBOOK panel picks up a card under it**: the game still sees clicks on what
  is under the panel (a mod can't stop that), so don't leave it over the spell row or a wand.
- **The SPELLBOOK panel is in the way**: drag it by its title bar somewhere else. "Reset panel
  position" in the mod settings puts it back in its usual place.
- **Double-clicking a wand spell does nothing, or the Store all buttons stay grey, in a Holy Mountain**: the mod looks for the game's workshop area by
  tag (`workshop_aabb`, then `workshop`); the tag may be wrong. Send a debug log.
- **Something went to the wrong place**: turn on "Debug log", repeat the action, then save and
  quit. The normal game (`noita.exe`) doesn't write a mod's log lines to `logger.txt`, so the
  spellbook keeps its last 400 lines in the run's saved values: in
  `%USERPROFILE%/AppData/LocalLow/Nolla_Games_Noita/save00/world_state.xml`, under the key
  `spellbank2_debug_log`. (`noita_dev.exe` also writes them to `logger.txt`, starting with
  `[spellbook]`.) The log records mouse presses and releases, double-clicks, every card the
  spellbook places, and every copy stored or taken out.

## Development

### Files

Each Lua file starts with a comment saying what it holds. They all share one global table, `SB`.
`init.lua` loads them in the order below; when it is loaded, a file only uses what the files
before it define (once running, any of them calls any other through `SB`).

| File | What it holds |
|---|---|
| `init.lua` | Entry point: loads the files below, and runs the spellbook every frame (also while the game is paused by the inventory). |
| `settings.lua` | The mod settings (the game's `mod_settings` format). The mod reads them with `SB.setting(id)`. |
| `mod.xml` | The mod's name and description. |
| `workshop.xml`, `workshop_preview_image.png` | For the Steam Workshop upload (`noita_dev.exe -workshop_upload`): the name, tags, the folders left out (`tests`, `dev`), and the preview picture. The description is set on the Workshop page itself. |
| `files/core.lua` | What every part shares: reading and changing settings (`SB.setting`, `SB.set_setting`, which also updates the mod settings menu), the debug log, messages, the mouse buttons (`SB.buttons`, `SB.button_held`). |
| `files/spells.lua` | The game's spell list (`SB.actions`, `SB.info`), locked spells, whether the Unlimited spells perk has been taken. |
| `files/groups.lua` | What the spellbook holds, as groups (`SB.add`, `SB.change_count`); the refresher and the Unlimited spells perk changing them; saving and loading. No entity code. |
| `files/pages.lua` | The pages, worked out from the groups (`SB.layout`, `SB.resolve`, `SB.page_sig`): spell types (or All), search results, copies. No entity code. |
| `files/cards.lua` | Entities: the player's inventory, reading a card, the mark on the spellbook's own cards, removing cards, telling the game to show changes. |
| `files/row.lua` | Keeping the spell row in line with the spellbook (`SB.reconcile`); emptying and refilling the row; pickups; taking over a new player entity's row. |
| `files/wands.lua` | Wands: their spells, where those are drawn in the inventory, the wand-editing level, Store all, storing a double-clicked wand spell. |
| `files/view.lua` | Which page is selected and which one the row shows: storing a spell selects its page; looking at a page by resting the mouse on its name; search and copies pages; the two boxes; the right-click hint. |
| `files/game.lua` | Each frame's order (`SB.tick`): mouse presses and double-clicks, the refresher, the Unlimited spells perk, the sync; loading, and the player entity being replaced. |
| `files/ui/widgets.lua` | What the drawing shares: the inventory's measured positions, colours, layers, every widget ID (`W.ID`), and helpers (text, images, buttons, `hit_area`). |
| `files/ui/spell_row.lua` | At the spell row: the page name and Store all beside SPELLS; over the row, counts, the next copy of a dragged card, faded placeholders. |
| `files/ui/search.lua` | The search box: typing, and the player's controls switched off while it has the keyboard. |
| `files/ui/panel.lua` | The SPELLBOOK panel: its place, the title bar and its collapse / expand arrow, the two boxes, the page list. |
| `files/ui/draw.lua` | Each frame's drawing in order (`SB.draw_ui`), the mouse position, the right-click hint. |
| `files/spell_refresh_append.lua` | Appended to the game's spell refresher script; signals a refresh through a global value. |
| `files/slot_hitbox.png` | An 18×18 transparent image placed over each card to tell where the mouse is. |
| `files/search_icon.png` | The magnifying glass at the start of the Search line in the page list (16×16, drawn in the game's style). |
| `tests/` | The stand-in Noita API and the tests (see below). |
| `dev/restart_game.ps1` | Restarts the game so it loads the mod's latest files, as the Mods menu's "Restart with enabled mods active" does: closes it the way its window's X does, then starts it with that button's options (`-no_logo_splashes -gamemode 4294967295 -save_slot 0`), which continue the run without the main menu. |
| `dev/workshop_description.txt` | The Steam Workshop page's description (Steam's BBCode), to paste into the page. |

### Data model (`files/groups.lua`, `files/pages.lua`)

- `SB.groups`: kind (`"ID#uses"`) → `{ kind, id, uses, count }`. `id` is the spell's action id;
  `uses` is -1 for unlimited spells. There is one group per kind. `SB.add` and
  `SB.change_count` are the only ways groups are made and removed; they raise `SB.version`.
- Pages aren't stored. `SB.layout()` works them out, and keeps the result until something it
  depends on changes (`layout_key`: `SB.version`, the settings, which spells are unlocked, the
  row's size, the search text, the spell whose copies are open and its counts). It returns
  `pages`, `by_key`, `by_type`, and `page_of[kind]`. A page is
  `{ key = "type:number", type, number, name, entries }`; an entry is `{ id, group, groups }`:
  one per spell, `groups` all its groups by uses left and `group` the first (the card shown;
  reps stand for that group); neither for a spell shown faded. The count drawn is worked out from
  `groups` when drawn (counts change without `SB.version` changing). With no pages, `by_key`
  holds one empty page, `"none"`.
- Page types 0 to 7 are the spell types; 10 (`SB.ALL`) is the All line, with "Merge categories" ticked.
  Search results (8, `SB.SEARCH`, while `SB.search_text` isn't empty) and copies (9,
  `SB.COPIES`, while `SB.copies_of` is a spell id) are in `by_type` and `by_key` but not in
  `pages` or `page_of` (`SB.is_special(key)`). Copies entries are marked `single` (no count
  drawn); one group fills as many slots as it has copies. `SB.LIST_ORDER` is the order of the
  page list's lines, and `SB.TYPE_NAMES` their names.
- `SB.selected` is the selected page's key; `SB.home` the last spell type page selected (what
  is saved, and what a search or copies page that has gone falls back to). `SB.resolve(key)`
  gives the nearest page that exists (the key itself, the last page of its type, `SB.home` for
  a search or copies page, the first page).
- `SB.page_sig(page)` is what a page holds, slot by slot, as one string. The row is refilled
  when it changes.
- Saved in global values: `spellbank2_stacks` (`ID#uses=count;...`) and
  `spellbank2_selected`. The keys keep the mod's old name, Spell Bank, so runs saved before the
  rename still load ("stacks" is an old name for groups). A save from the version with your own
  pages still loads (the `@page.slot` after each group is ignored, and groups of a kind
  combine); the first version's storage (`spellbank_stacks`) is no longer read.

### The sync (`files/row.lua`, `files/game.lua`)

- **Reps**: the cards the spellbook puts in the row. Each is created with `CreateItemActionEntity`
  and `GamePickUpInventoryItem`, given its slot, and marked with a `VariableStorageComponent`
  named `spellbank_rep` (so a save made with the inventory open can be cleaned up on load).
  `SB.reps` maps card entity → group kind; `SB.rep_slot` the slot it was placed in.
- **`SB.reconcile(snap)`** runs every frame while the inventory is open. It does nothing while
  a mouse button is held, or until every card in the row has reported the same slot two frames
  running ("settled"). Then, in order:
  1. reps no longer in the row: one copy taken off their group (into a wand, or thrown). A rep
     in a wand, not pressed on, with a wand spell now in its slot of the row, was swapped there by
     the game (a wand spell dropped onto it), so it is taken back out of the wand;
  2. reps still in the row: removed if their group has gone (its copies joined another group,
     which counts the rep's copy too); stored again if their uses changed; replaced (removed, and
     a new card placed in their slot in step 4) if they moved, as the game undoes a script
     setting a card's slot;
  3. cards in the row the spellbook didn't place (from a wand, or picked up): stored with
     `SB.store`, which also selects their page;
  4. if the page shown still holds what the row was filled with (`SB.row_sig`), empty slots
     that should show a card get one (worked out by slot, since a copies page shows one group in
     several slots); otherwise `SB.update_display` refills the whole row.
- **Emptying the row** (`SB.empty_row`): a last sync, then the reps are removed (their copies
  are already counted). Done when the inventory closes, when a refresher is picked up with it
  open, and before the row is refilled (`SB.relayout`).
- **Mouse buttons**: read once a frame, at its start (`SB.read_buttons` in `init.lua`), into
  `SB.buttons` (`left`, `right`, `pressed`, `released`, `right_pressed`), so every part sees the
  same press; a button already held when the inventory opens isn't a press. Whether a button is
  held right now is `SB.button_held()`.
- **Presses**: a left press on a rep (known from the hitbox under the mouse in the previous
  frame's drawing) goes in `SB.pressed`, kept through 3 syncs that ran to the end after the
  release (the game moves a released card within a few frames; frames waiting for a held
  button don't count). A press elsewhere that isn't on one of the mod's buttons may be on a wand
  spell, found with `SB.wand_card_at` from the measured wand panels. A click is a press let go
  within 3 pixels of where it was made; a second click on the same card within 30 frames is a
  double-click, acted on 2 frames after its release if the card is still in a wand.
- **Right presses**: a right press on a rep opens its spell's copies pages
  (`SB.show_copies`); the row changes once no button is held, like any page change.
- **Clicks on release**: the game reports letting go of a drag over a button as a click on it
  (seen in play), so the spellbook's buttons ignore clicks for 2 frames after a release that
  followed a press on a card or in the inventory.
- **What the row shows** (`SB.update_display`, `files/view.lua`): the selected page, or the page
  whose button (name, number or card) the mouse has rested on for 8 frames (`SB.hover_target`,
  set by the drawing; a whole line counts as its first page's button); once one is shown that
  way, another page's button shows its page at once, and none shows the selected page at once. It only changes
  the row when `SB.row_quiet()`: no button held, the last sync ran to the end, no press waiting.
- **The game changing the player's spells**: a refresher (`SB.refresh_uses`) or the Unlimited
  spells perk (`SB.make_unlimited`) changes the groups. The game changes the row's cards too, so
  they first get their group's uses back (`SB.reset_row_uses`) and are then replaced.
- **Player entity replaced** (`SB.player_changed`): the spellbook's record of its cards is
  dropped (their copies are counted in groups) and the new row is taken over as at load
  (`SB.take_over_row`).
- **Inventory closed** (`SB.inventory_closed`): the row is emptied, what was under the mouse and
  any press in progress are forgotten, and any card that appears in the row is a pickup and is
  stored immediately (`SB.store_pickups`).
- **Refreshing**: the game only shows cards the mod adds after `Inventory2Component.mForceRefresh`
  is set; wands are reloaded by also setting `mActualActiveItem` to 0. Both are only done
  outside drags.

### Assumptions about the game

Measured or confirmed:

- The inventory's wand panels (from two screenshots at 3840 × 2160): one panel per wand in
  the quickbar, in quickbar order, with no panel for an empty wand slot; every panel is the
  same height, since the full stats are only in the tooltip; the first panel's slot row
  starts at y ≈ 81 and each next one about 61 lower (up to 3 pixels more seen); slots start
  at x ≈ 26, 20 apart; a 26-slot wand fits on one line. Not seen: a wand with always-cast
  spells, or more than 26 slots.
- The UI is 640 × 360; the first spell slot's box starts at (191, 21), slots are 20 apart and
  18 wide (measured from screenshots). The SPELLBOOK panel's usual top is y = 58, below the
  gold counter.
- With the inventory open, the game lists stains, other effects and perks down the right edge,
  one per line, with their names to the left of the icons (reaching about x = 519 in the
  screenshots seen; a longer name may reach further). Many kinds of effects can be listed, so
  the panel doesn't try to stay below that list: it sits left of it, its border ending at
  x = 512 (the game's panel graphic draws its border about 2 outside the area it is given).
  A wand's box reaches x ≈ 26 + 20 × its slots (a 26-slot wand's reaches ≈ 552).
- The spell row is a single line. Changing `Inventory2Component.full_inventory_slots_x/y`
  makes it run off the screen (26 × 1) or hides the second row (13 × 2), so 16 × 1 is the
  only usable size.
- A dragged card stays in the spell row until the mouse is released.
- A card dropped into the row from a wand reports its old wand slot for a frame.
- Mod GUI widgets don't block the inventory's own mouse input.
- Letting go of a dragged card over a mod's GUI button counts as a click on the button.
- The game keys a GUI widget's hover highlight to its ID, so each widget's ID depends only on
  what it is (a slot, a page, a button).

Assumed, not confirmed:

- Wands can be edited while a level is above 0: a Holy Mountain counts 1, each
  `EDIT_WANDS_EVERYWHERE` game effect adds 1 and each `NO_WAND_EDITING` takes 1 away (both
  effects are in the game's data: perks, potion effects, the meditation cube; how the game
  combines them is the user's understanding, not seen in the data). The game refuses drags into
  or out of wands by itself where they can't be edited.
- With `ControlsComponent.enabled` false, the game's GUI may not follow the mouse (a click
  elsewhere wasn't seen as elsewhere, in play), so while the search box has the keyboard any
  left click gives it back. The debug log records each click on it with what the GUI saw.
- `ControlsComponent.enabled` set to false stops the game's keys (moving, switching wands,
  opening the inventory) while the search box has the keyboard. `GuiTextInput` takes typing
  whenever the mouse is over it, without a click (seen in play), and none when drawn with
  `GUI_OPTION.NonInteractive`. With the mouse off it, it takes none (seen in play). So the game's box
  only shows the text, drawn non-interactive, and the spellbook reads the keys itself with
  `InputIsKeyDown` (SDL scancodes, the same for every keyboard layout).
- Nothing in the game uses a right press on a card in the spell row.
- A card dropped onto an occupied slot swaps with the card there (in the row, and between the
  row and a wand).
- A card released outside the inventory loses its parent (lands in the world) within 3 frames.
- A wand spell pressed and let go without moving goes back into its wand slot.
- `deck_capacity` includes always-cast spells, which don't take a slot.
- The Holy Mountain's editing area is an entity tagged `workshop_aabb` with a
  `HitboxComponent`; the perk is the game effect `EDIT_WANDS_EVERYWHERE`.
- The spell refresher's script is `data/scripts/items/spell_refresh.lua` with an
  `item_pickup` function.
- `GuiText(gui, x, y, text, scale, font, is_pixel_font)` draws with another font; the card
  counts use `data/fonts/font_small_numbers.xml`, the font of the game's uses count.
- Lower GUI z values draw in front; negative values draw above the inventory.
- `GuiImageNinePiece` with no sprite given draws the game's own panel graphic
  (`data/ui_gfx/decorations/9piece0_gray.png`), used for the SPELLBOOK panel.
- The mouse position in UI pixels is the mouse's world position (`DEBUG_GetMouseWorld`)
  relative to the camera, scaled by `VIRTUAL_RESOLUTION_X/Y` to the UI, as Spell Lab Shugged
  works it out.
- A transparent `GuiImage` behind the page list reports the mouse over it without stopping
  the page names (buttons drawn in front of it) from being hovered and clicked.
- The game's report of the mouse over transparent images is unreliable for areas that touch or
  sit behind buttons (seen in play, sweeping along page numbers that each had such an area): two
  areas sharing an edge both counted as under the mouse there, and an area behind a number's
  text didn't count while the mouse was on the text, though one drawn earlier did. So the page
  list's line and number areas are worked out from the mouse's position (`W.mouse_in`), not from
  the game. The names and numbers are still the game's buttons (for their hover sound and
  clicks), and the game's own hover of a button's text reaches a pixel or so past the text, so at
  the edge between two numbers both can light up for a pixel (seen in play; left as it is: drawing
  them as buttons the game doesn't react to fixed it but lost the sound). A button lit by an area
  is drawn in the game's hover yellow (`W.button`); one the game has the mouse on is asked for in
  white, which the game draws in that yellow.
- `GamePickUpInventoryItem` puts the card in the row at once (one of the mod's cards found on the ground
  that was never seen in the row is taken as the game not showing it).
- `ModSettingSet` together with `ModSettingSetNextValue` changes a runtime setting so that
  the mod settings menu shows and keeps the new value.
- Polymorph replaces the player entity, and the new one's spell row holds copies of the old
  row's cards, with their components.
- The game counts an image as under the mouse within a square as wide as it is drawn, whatever
  its height scale (seen in play: a transparent image drawn 98 × 11 over the search box showed
  its tooltip and took clicks 85 below the box). So the transparent areas that tell where the
  mouse is (the search box, the title bar, the whole panel) are made of squares as big as the
  area's shorter side (`W.hit_area` in `files/ui/widgets.lua`); the tests' stand-in counts images the same
  way. (A height scale of 0 also means "the same as the width scale"; the height the game
  reports for the search box is only used if it looks right, 6 to 22, and is written to the
  debug log.)
- The game keeps its own record of where each card in the spell row is: setting the slot of a
  card already there (`ItemComponent.inventory_slot`) is undone (seen in play: a card moved
  within the row and put back that way went back to where it was dropped, every two frames).
  A new card takes the slot it is given. The tests' stand-in does the same.
- `EntityKill` removes an entity only at the end of the frame: until then `EntityGetWithTag`
  still lists it (seen in play: when a save was loaded, the row's cards, just killed, were taken
  for cards left on the cursor, and every spell shown lost a copy). The tests' stand-in does the
  same.

### Tests

The tests run the mod's own files against a stand-in for the Noita API (`tests/stubs.lua`),
with LuaJIT, the Lua that Noita uses (on Windows, MSYS2's `mingw-w64-ucrt-x86_64-luajit`
works):

```
cd spellbook
sh tests/run.sh
```

Each test sets up groups, acts out what the game would do (for example moving a card into a
wand with `set_parent`, or into a slot with `set_slot`), steps frames with
`OnWorldPostUpdate`, and checks the spellbook's state with `check(condition, message)`. GUI calls
are recorded in `gui_log`; tests click widgets with `click = { match = label_or_sprite }` and
hover with `hover_label` / `hover_xy`. `tests/helpers.lua` has the shared helpers: stepping,
reading the row and wand (`row_str()`), a page's contents (`page_str(key)`), and `where(id)`,
which counts a spell's copies everywhere (spellbook, wand, ground).

| Test | Covers |
|---|---|
| `layout.lua` | Pages worked out from groups: order, one slot per spell (the copy shown, the count of all copies, the next copy showing), uses order, page breaks, pages closing up, unowned spells shown, spells from a disabled mod. |
| `row_drags.lua` | One copy into a wand or thrown, the next copy showing, a card moved within the row (or two swapped) replaced in its slot, a quick second press. |
| `wand_to_spellbook.lua` | Wand spells dropped into the row; the two kinds of swap. |
| `double_click.lua` | Double-clicking a wand spell; clicks too far apart or on different spells; outside a Holy Mountain; the two perks cancelling out. |
| `store_all.lua` | Store all (Held wand, All wands): everything but always-cast spells, the wand-editing level, greyed out with the reason, empty wands, no wand selected. |
| `pickups.lua` | Pickups with the inventory closed and open; the page selected. |
| `page_numbers.lua` | A line's page numbers: their areas reaching into the gaps, a rest before the first page shows, a sweep showing each page at once, the selected page at once off the numbers, a click in a gap; the last number's area reaching the panel's right edge; the rest of a line (its whole width, the lines touching) standing for its first page, not over the 3's area, a click on it. |
| `page_list.lua` | Looking by hovering, selecting by clicking, a line's name lit up and gold with its other pages, a release over a name not being a click, Hide unowned, widget IDs, a selected page that goes. |
| `row_icons.lua` | The card at the start of each line of the page list: each type's spell and card background, the Copies line's spell, the Search symbol, the spacing, the page numbers under the name from 1, the card, name and 1 as one button (hover, gold, tooltip, click), the name gold with page 2 selected, the search box's width. |
| `panel_collapse.lua` | The title bar's arrow: up, then collapsing the panel to its title bar and pointing down, the tooltips, not dragging it, giving back the search box's keyboard, kept when the inventory is opened again, the collapsed panel still dragged by its title bar, expanding again, the hidden setting. |
| `panel_position.lua` | The SPELLBOOK panel: its usual place, the title bar, in front of everything, dragged by the title bar (following the mouse, kept where let go, not started by a press elsewhere), kept on the screen, the place kept for later runs and put back when the setting is cleared. |
| `full_spell_list.lua` | The page list with a spell list the size of the game's, unowned spells shown: it fits. |
| `saves.lua` | Loading, the selection saved, a save with the inventory open, spells shown in the row kept over two loads, the refresher. |
| `debug_log.lua` | The debug log kept in a saved value: capped at 400 lines, carried on from an earlier session. |
| `new_player.lua` | A replaced player entity. |
| `drag_view.lua` | The next copy drawn in a dragged card's slot: icon, card background, uses, count one less; nothing for a last copy or on a copies page. |
| `hint.lua` | The right-click hint: shown while the mouse is on a limited-uses card whose copies differ in uses (not one whose copies are all the same, not an unlimited one, not off the cards) and its setting is on, the first right-click on a card turning the setting off, the setting turning it on and off. |
| `grouping.lua` | Copies joining their group however they arrive (picked up, from a wand, back from the ground), a copy whose uses changed moving group, unlimited copies of a limited spell. |
| `merge_categories.lua` | The defaults: a line per type with unowned spells shown, both boxes unticked; Hide unowned ticked; Merge categories ticked: one line, All, every spell in type order, its card, a stored spell selecting it, a second page, Copies and Search as usual, unticking and ticking it, saving the selection; the boxes' order, colours and tooltips, and the settings' order and defaults. (The other tests have Hide unowned ticked.) |
| `edge_unlimited_closed.lua` | The Unlimited spells perk taken with the inventory closed: the row stays empty, a refresher then makes no extra copy. |
| `edge_player_change.lua` | Polymorph while typing in the search box: the controls come back; a card in a wand at a save not counted twice; a refresher waiting at a save done after loading. |
| `edge_wand_moves.lua` | A click then a drag of a wand spell (a move), a drag then a click (no double-click); a card moved into a wand without its press seen, or with no mouse button (a gamepad): kept there; a double-click released on a frame without a player entity. |
| `edge_pages.lua` | Storing with copies open: the page with the new copy, or its own page with the copies closed; "<" on a line whose page isn't selected; a spell unlocked during the run. |
| `edge_panel.lua` | The inventory closed mid-drag of the panel; a screen width with a fraction; a button already held when the inventory opens starting no drag. |
| `unlimited.lua` | The Unlimited spells perk: limited groups combined into unlimited ones (not while a button is held, once), never_unlimited spells and spells from a disabled mod left alone, later pickups made unlimited, the refresher, saving. |
| `copies.lua` | Right-click copies pages: one slot per copy, order, taking and returning copies, two pages, staying (empty) when every copy is taken, "< 1/25 >" for 25 pages (clicking > to the last page with the mouse resting on it shows that page), closing when another page is selected, not saved. |
| `search.lua` | The search page: matches, grouping, unowned spells, no results, clearing, the controls switched off while typing. |

The stand-in is a model, so a passing test shows the logic is consistent with the assumptions
above, not that the game behaves that way. When something misbehaves in play, reproduce it as
a test first (the debug log usually shows what the game did), then fix it.

### Ideas not built yet

- To wand: putting a saved wand layout back into a wand (removed with your own pages, which
  held the layouts).
- Undoing an accidental throw.
