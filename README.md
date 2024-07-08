# Commando Disassembly

## Introduction

This repository contains the disassembled code for Commando, an arcade game originally released in 1985. The project aims to preserve and study the technical aspects of classic games, providing valuable insights for educational and historical purposes.

## Disclaimer

The original code for Commando is the property of Capcom. This disassembled code is provided for educational purposes only. No commercial use or redistribution of the original game assets is intended or allowed. If you are the copyright holder and wish for this project to be removed or altered, please get in touch with us.

## Contributions

This project results from contributions from various enthusiasts in the retro gaming community. We aim to document and understand Commando's inner workings for the benefit of developers, historians, and fans.

## Usage

To disassemble your own legally obtained copy of Commando, follow these steps:

1. Obtain the original ROMs from a legitimate source
2. Disassemble using the appropriate tool
3. Use Mame (https://www.mamedev.org/) debugger to assist in the overall process

## Map Images
The Folder Photoshop contain the re-created Photoshop format Images for each of the 8 playing Areas within the game.
Each Photoshop file, PSD, is layered to show many elements that enabled the game to achieve the results.
There is a Background layer, which is the map of the scrolling background characters plotted from the original data maps; this is NOT a screen capture from Mame but a re-created version of the original data into an 8-bit colour format. Where the Arcade hardware had multiple palettes, the only option was to re-map these into standard 8-bit colour RGB data.
Please remember that the data shows how it was stored and that there are an additional 16 pixels on the left and right ( one character ), which is not displayed in the original Arcade but shown here for completeness.
The next layer (if the level had) is the trees and images of the top of the rocks. This layer shows you that hardware sprites were used in a table, which would be displayed (or animated like at the start of the game). This is generated from the same tables inside the ROM at the correct positions. I did notice there was a slight pixel overlay from the background layer. If you turn the layer on and off, you see it's slightly offset. This is correct, as comparing a snapshot in mame proved the positions to be 100% accurate. The bridges are also sprites, allowing the player to disappear behind objects and look like an excellent effect.
NOTE: I noticed a bug inside Mame when the screen captured the bridges, so they aligned with my generated layer. The palette data mame generated in the code from the original 444 RGB data of the commando roms does not yield the correct data; I was unable to create the same RGB values, so in the end, I screen captured the MAME palette from the screen and used an RGB screen reader to capture this to use. However, there are some decoding issues with MAME. The bridge has one colour that does not match.
For these maps, I have corrected this RGB colour so the bridge looks perfect. I am not 100% sure if the original would do the same thing, but I suspect it would display correctly, as my images show.
The event-sprites layer displays the location of some enemies, such as the bikes on bridges, the pickup locations, and some strategically placed enemies. These are a one-time event action set, so they would be set at a trigger point once. (unless you die and restart the area). Some sprites needed to be plotted as they provided little value. An example was Area 7; those doors had a sprite for the roof, so the open/close animation would hide the door moving. I found this trivial bug in the game; the original placed this roof 1 pixel incorrectly. With the sprite on/off inside Mame, you can see that the sprite is just off position. (this does not detract from the game. but just an observation. There are one or two other places where this happens also.
Lastly, the Tile layer is there to show you that the game uses a very small data set for the maps, and this is the master tile data, which is just 4 bytes across and ends up plotting a 4x4 tile, where each is 16 characters, which is 16 pixels. So, one tile is 64 x 64 pixels; hence, the width 256 is just 4 bytes. Characters in the system background have a palette and flip/hv bits, which are used to increase the range of displayed output significantly.
## Tiles maps
Because the original screen is only 256 wide, I created an alltiles.psd file. This shows you all the tiles available in the game and the character numbers used; there are two layers to this.
The background is just the tiles numbered from 0 to $d4 (ignore the last few; this is junk data). The pixels are expanded so you can read the small character number, which otherwise would be unreadable at a lower resolution. You can see a lot of tiles repeated with different palettes and reversed in direction. I also see a lot of the incomplete sides. I have noticed that the completed data for these missing ones are unavailable. It would be tempting to re-draw the missing parts, but this is not about changing; it's about the historical accuracy of the original data.

## Educational Value

This repository serves as a resource for those interested in learning about classic game development, reverse engineering, and the history of video games. By studying the code, we can gain insights into the era's programming techniques and hardware constraints.

## Acknowledgments

We want to thank the original developers of Commando for creating such an iconic game and the initial disassembly code from Scott Tunstall, Paisley, Scotland.

## Contact

For any inquiries or issues, please contact mkeybabes@gmail.com.
