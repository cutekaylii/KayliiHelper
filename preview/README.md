# Kaylii Helper 2.0 alpha preview

This branch demonstrates the hub and a standalone Survival Helper. It is a
development preview. The other five modules and the combined profile transfer
are not included yet, so it must not replace the current 1.19.63 release.

The `KayliiHelper` addon retains the old `KayliiHelperDB` and
`KayliiHelperCharacterDB` tables without deleting or editing their module
settings. `KayliiSurvivalHelper` saves its own account and per-character data.
At load time, it copies missing `survival*` fields from the 1.x tables if the
hub is installed. An already saved 2.x field always wins. The original tables
remain available for the other modules' migrations.

The standalone module keeps `/khsurvival` and `/khsurv`. The hub keeps `/kh`,
`/kaylii`, and `/kayliihelper`. The standalone module runs without the hub,
though it cannot automatically read old 1.x saved data without the hub loading
those tables first.

The preview's settings pages are Trigger, Priority, Ready alerts, Death sound,
and Appearance. Action order, custom spells/items, and per-action TTS phrases
retain their character scope. This preview has not been validated inside WoW.
