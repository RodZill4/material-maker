# GodotSteam for GDExtension | Community Edition
An ecosystem of tools for [Godot Engine](https://godotengine.org) and [Valve's Steam](https://store.steampowered.com). For the Windows, Linux, and Mac platforms.


Additional Flavors
---
Standard Module | Standard Plug-ins | Server Module | Server Plug-ins | Examples
--- | --- | --- | --- | ---
[Godot 2.x](https://codeberg.org/godotsteam/godotsteam/src/branch/godot2) | [GDNative](https://codeberg.org/godotsteam/godotsteam/src/branch/gdnative) | [Server 3.x](https://codeberg.org/godotsteam/godotsteam-server/src/branch/godot3) | [GDNative](https://codeberg.org/godotsteam/godotsteam-server/src/branch/gdnative) | [Skillet](https://codeberg.org/godotsteam/skillet)
[Godot 3.x](https://codeberg.org/godotsteam/godotsteam/src/branch/godot3) | [GDExtension](https://codeberg.org/godotsteam/godotsteam/src/branch/gdextension) | [Server 4.x](https://codeberg.org/godotsteam/godotsteam-server/src/branch/godot4) | [GDExtension](https://codeberg.org/godotsteam/godotsteam-server/src/branch/gdextension) | ---
[Godot 4.x](https://codeberg.org/godotsteam/godotsteam/src/branch/godot4) | --- | --- | --- | ---
[MultiplayerPeer](https://codeberg.org/godotsteam/multiplayerpeer)| --- | --- | --- | ---


Documentation
---
[Documentation is available here](https://godotsteam.com/).  You can also check out the Search Help section inside Godot Engine.  [To start, try checking out our tutorial on initializing Steam.](https://godotsteam.com/tutorials/initializing/)  There are additional tutorials, with more in the works.  You can also [check out additional Godot and Steam related videos, text, additional tools, plug-ins, etc. here.](https://godotsteam.com/resources/external/)

Feel free to chat with us about GodotSteam or ask for assistance on the [Discord server](https://discord.gg/SJRSq6K).


Donate
---
Pull-requests are the best way to help the project out but you can also donate through [Github Sponsors](https://github.com/sponsors/Gramps) or [LiberaPay](https://liberapay.com/godotsteam/donate)! [You can read more about donor perks here.](https://godotsteam.com/contribute/donations/)  [You can also view all our awesome donors here.](https://godotsteam.com/contribute/donors/)


Current Build
---
You can [download pre-compiled versions of this repo here](https://codeberg.org/godotsteam/godotsteam/releases).

**Version 4.17 Changes**
- Added: new enums to Result, HTTPStatusCode, RemotePlayScanCode, ActionOrigin per Steam SDK 1.63
- Added: `getDecompressedVoice()` as custom function to wrap up `getVoice()` and `decompressVoice()` in C++
- Added: missing HTMLMouseCursor enum binds
- Changed: converted functions entirely over to the Flat API system
- Changed: `activateGameOverlayInviteDialog()` changed argument name from steam_id to lobby_id for clarity
- Changed: renamed some minor parameters
- Changed: `getAPICallFailureReason()` now returns enum instead of string
- Changed: error messages if Steam is not initialized or classes are missing
- Fixed: `initFilterText()` now takes filter options
- Fixed: `sendMessages()` not compiling correctly
- Fixed: VOICE_RESULT_NO_DATA incorrectly named VOICE_RESULT_NO_DATE
- Removed: GameSearch and Music Remote classes, constants, enums per Steam SDK 1.63

[You can read more change-logs here](https://godotsteam.com/changelog/gdextension/).


Compatibility
---
While rare, sometimes Steamworks SDK updates will break compatilibity with older GodotSteam versions. Any compatability breaks are noted below.  Newer API files (dll, so, dylib) _should_ still work for older versions.

Steamworks SDK Version | GodotSteam Version
---|---
1.63 or newer | 4.17
1.62 | 4.14 or 4.16.2
1.61 | 4.12 to 4.13
1.60 | 4.6 to 4.11
1.59 | 4.6 to 4.8
1.58a or older | 4.5.4 or older

Versions of GodotSteam that have compatibility breaks introduced.

GodotSteam Version | Broken Compatibility
---|---
4.8 | Networking identity system removed, replaced with Steam IDs
4.9 | sendMessages returns an Array
4.11 | setLeaderboardDetailsMax removed
4.13 | getItemDefinitionProperty return a dictionary, html_needs_paint key 'bgra' changed to 'rbga'
4.14 | Removed first argument for stat request in steamInit and steamInitEx, steamInit returns intended bool value
4.16 | Variety of small break points, refer to [4.16 changelog for details](https://godotsteam.com/changelog/godot4/)


Known Issues
---
- GDExtension for 4.1 is **not** compatible with 4.0.3 or lower. Please check the versions you are using.
- Overlay will not work in the editor but will work in export projects when uploaded to Steam.  This seems to a limitation with Vulkan currently.


Quick How-To
---
For complete instructions on how to build the GDExtension version of GodotSteam, [please refer to our documentation's 'How-To GDExtension' section.](https://godotsteam.com/howto/gdextension/) It will have the most up-to-date information.

Alternatively, you can just [download the pre-compiled versions in our Releases section](https://codeberg.org/godotsteam/godotsteam/releases) or [from the Godot Asset Library](https://godotengine.org/asset-library/asset/2445) and skip compiling it yourself!


Usage
---
Do not use the GDExtension version of GodotSteam with any of the module versions whether it be our pre-compiled versions or ones you compile.  They are not compatible with each other.

When exporting with the GDExtension version, please use the normal Godot Engine templates instead of our GodotSteam templates or you will have a lot of issues.


License
---
MIT license
