# Kaylii Helper 2.0 alpha preview

This package contains the hub and six independently loadable addon folders:
KayliiTargetAuras, KayliiLustUp, KayliiStatsDisplay, KayliiTalentLoadout,
KayliiRaidFrameSpec, and KayliiSurvivalHelper. It is an alpha preview built
from the latest stable 1.19.63 runtime. It has not been tested inside WoW;
keep a backup of the original addon and WTF folder before trying it.

The hub saves its minimap preferences in `KayliiHelperHubDB` and loads old
1.x tables so each module can copy its settings. Each standalone module saves
in its own account table; Survival Helper also saves per-character values in
its own character table. An already saved 2.x value always wins. The Target
Auras copy runs initialization against its own table, never the old table.

The hub keeps `/kh`, `/kaylii`, and `/kayliihelper`. Module commands are
`/kaybuff`, `/kaylust`, `/kaystats`, `/kaytalent`, and `/kayraidspec`;
Survival Helper keeps `/khsurvival` and `/khsurv`. Modules work on their own,
but need the hub installed to read 1.x settings during migration.

The five new modules provide their own dark settings windows with tabs and
minimize buttons. Survival Helper includes Trigger, Priority, Ready alerts,
Death sound, and Appearance; its action order, custom actions, and per-action
TTS phrases retain character scope. The new windows cover the primary controls;
some advanced controls from 1.x and combined profile transfer are still to do.
