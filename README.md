# SEGA Megadrive/Genesis for MiSTer.


## First commits for the 32x VDP by ElectronAsh
(I had to add this notice near the start of the README, as it's important)...

WARNING: Do NOT run this on a standard MiSTer setup that has an IO Board attached.
This is only a test build for devs who want to work on 32x, as it currently requires two real SH2 CPUs on a "hat" board.

This is NOT by any means a finished core for 32x, but quite a lot of testing has been done on the VDP logic.
(the framebuffer colour modes were tested a while ago, using a tweaked version of MAME to send raw images to the 32x framebuffer on the FPGA.)


(original README for the MD core continues here)...

This is the port of fpgagen core.

fpgagen - a SEGA Megadrive/Genesis clone in a FPGA.
Copyright (c) 2010-2013 Gregory Estrade (greg@torlus.com)
All rights reserved


## Installing
copy *.rbf to root of SD card. Put some ROMs (*.BIN/*.GEN/*.MD) into Genesis folder


## Hot Keys
* F1 - reset to JP(NTSC) region
* F2 - reset to US(NTSC) region
* F3 - reset to EU(PAL)  region


## Auto Region option
There are 2 versions of region detection:

1) File name extension:

* BIN -> JP
* GEN -> US
* MD  -> EU

2) Header. It may not always work as not all ROMs follow the rule, especially in European region.
The header may include several regions - the correct one will be selected depending on priority option.


## Additional features

* Multitaps: 4-way, Team player, J-Cart
* SVP chip (Virtua Racing)
* Audio Filters for Model 1, Model 2, Minimal, No Filter.
* Option to choose between YM2612 and YM3438 (changes Ladder Effect behavior).
* Composite Blending, smooth dithering patterns in games.
* Sprite Limit, enables more sprites.
* CPU Turbo, mitigates slowdowns.








