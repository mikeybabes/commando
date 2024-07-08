;
; Commando (C) 1985 CAPCOM.
;
; ORIGINAL Reverse engineering work by Scott Tunstall, Paisley, Scotland.
; Tools used: MAME debugger & Visual Studio Code text editor.
; Date: 23 Feb 2020. Keep checking for updates.
; Please send any questions, corrections and updates to scott.tunstall@ntlworld.com
;
; Be sure to check out my reverse engineering work for Robotron 2084, Galaxian and Scramble too,
; at http://seanriddle.com/robomame.asm, http://seanriddle.com/galaxian.asm and http://seanriddle.com/scramble.asm respectively.


; v2.0 Updated: 4th July 2024. by Michael J Archer
; Mame Debugger was mostly used, a zillion utilities to extract all data were all done in Python
; Kudos to ChatGPT used to make almost all the python code tools needed, it even understands Mame stuff pretty cool!
; A future for someone else to make a version which can be assembled.
; However, there is so many tables inside, and tables of tables, it's almost at a point where it's not worth doing.
; If you have any questions, you can email me mikeybabes@gmail.com
; And I don't know Z80 but I was close to writing a version of Commando on 8-bit systems, but someone ended up buying the license, and so was scrapped
; I always felt this was a cool playable intense game, maybe not a classic like Defender, but interesting to see how much hardware
; was in use during the early days, and if I'm honest how quite odd a lot of the logic and coding seems to be here.
; I can only assume several people were doing different parts, as it's quite jumpy in many places.
; Normally you would try keep things neat like tables in one place. You'll find if you tried to move stuff about it might break.
; Several key tables are in specific locations like $4000. Some unused locations referenced but unable to clarify the use.
; I created the tables inside via python scripts, and also references the original binary rom image (decoded)
; There are several PSD images I've created, which I produced again in Python. These are all the maps in the game.
; Additionally, I use photoshop layers to show the background character map including the unseen left-right sides, which look like it's broken.
; But these parts are trigger points for the enemies to spawn in the game. I did also find the image in Mame of the bridge seem to have incorrect RGBs
; I was unable to re-create the RGB colours Mame gives the game, as it should be a standard 444 RGB palette from the ROMS
; But Mame generates what looks like some random shit in some of the bits, which when you look at the same, the bridge part does not match up with the background
; So, I have a giant photoshop file, which shows all levels/Areas, and has the tree/rock layer, and the picks as a layer with bridges.
; I didn't see point show the map where the enemies come from, as this doesn't offer much to someone.
; 
; With so many hardware sprites (luxury in the day) they should used a better y sort allocation system, and put the sprites in a Y soft priority
; There are bags of RAM so plenty of space to do this with no complex coding would be needed.
; The sprite handler for the enemies is over complex, I have a feeling this was written for other titles, and just adapted for this title.
; The game status is also a bit of a weird way to handle events and triggers, but then if someone is taught a method, they tend to keep too it.
; Just working out how to the games flows is a nightmare, the game status stuff is really strange, no idea who would come up with such a strange method. But I guess it works.
; It's a bit strange they have a character plot for background, they could of equally been used for the trees and rocks sprites to be triggered with this data
; Plenty of unused tile slots could of used extra bits for events.
; The memory pointers are a bit weird, but maybe because they were using in a ROM, but I'm use to doing ROM coding so it's no big deal.

; The sound function is a strange system, I didn't even look at the sound code, as this is not my area I know much about.
; I used the demo mode to work out what most sounds were, and where inside the code. (if I bothered to comment them all)
; There is a lot from the original disassembly, so I have left most of it about, but I tried to rename some things because this is a better way of showing inside the code
; I didn't bother into some bits as it's already a lot of effort to work out this lot, and I want to look at other titles which are also close to my heart.


COORDINATES
===========

X,Y refer to the X and Y axis in a 2D coordinate system, where X is horizontal and Y is vertical.

*/

Memory map taken from https://github.com/mamedev/mame/blob/master/src/mame/drivers/commando.cpp

MAIN CPU
0000-bfff ROM
d000-d3ff Video RAM
d400-d7ff Color RAM
d800-dbff background video RAM
dc00-dfff background color RAM
e000-ffff RAM
fe00-ff7f Sprites
read:
c000      IN0
c001      IN1
c002      IN2
c003      DSW1
c004      DSW2
write:

c808-c809 background scroll x position
c80a-c80b background scroll y position

SOUND CPU
0000-3fff ROM
4000-47ff RAM
write:
8000      YM2203 #1 control
8001      YM2203 #1 write
8002      YM2203 #2 control
8003      YM2203 #2 write


CHARACTER_RAM	EQU	$D000
CHARACHER_COL	EQU	$D400
VIDEO_RAM		EQU	$D800
VIDEO_COLOUR	EQU	$DC00
HARDWARE_SPRITES	EQU $FE00				; Sprite base

; Port bits taken from https://github.com/RetroPie/mame4all-pi/blob/master/src/drivers/commando.cpp

PORT_START	/* IN0 */
PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_START1 )
PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_START2 )
PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_UNUSED )
PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_UNUSED )
PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_UNKNOWN )
PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_UNKNOWN )
PORT_BIT( 0x40, IP_ACTIVE_LOW, IPT_COIN1 )
PORT_BIT( 0x80, IP_ACTIVE_LOW, IPT_COIN2 )

PORT_START	/* IN1 */
PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_JOYSTICK_RIGHT | IPF_8WAY )
PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_JOYSTICK_LEFT | IPF_8WAY )
PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_JOYSTICK_DOWN | IPF_8WAY )
PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_JOYSTICK_UP | IPF_8WAY )
PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_BUTTON1 )
PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_BUTTON2 )
PORT_BIT( 0x40, IP_ACTIVE_LOW, IPT_UNUSED )
PORT_BIT( 0x80, IP_ACTIVE_LOW, IPT_UNUSED )

PORT_START	/* IN2 */
PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_JOYSTICK_RIGHT | IPF_8WAY | IPF_COCKTAIL )
PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_JOYSTICK_LEFT | IPF_8WAY | IPF_COCKTAIL )
PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_JOYSTICK_DOWN | IPF_8WAY | IPF_COCKTAIL )
PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_JOYSTICK_UP | IPF_8WAY | IPF_COCKTAIL )
PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_BUTTON1 | IPF_COCKTAIL )
PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_BUTTON2 | IPF_COCKTAIL )
PORT_BIT( 0x40, IP_ACTIVE_LOW, IPT_UNUSED )
PORT_BIT( 0x80, IP_ACTIVE_LOW, IPT_UNUSED )


; And these mappings are taken from https://github.com/mamedev/mame/blob/master/src/mame/drivers/commando.cpp

PORT_START("DSW1")
PORT_DIPNAME( 0x03, 0x03, "Starting Area" ) PORT_DIPLOCATION("SW1:8,7")
PORT_DIPSETTING(    0x03, "0 (Forest 1)" )
PORT_DIPSETTING(    0x01, "2 (Desert 1)" )
PORT_DIPSETTING(    0x02, "4 (Forest 2)" )
PORT_DIPSETTING(    0x00, "6 (Desert 2)" )
PORT_DIPNAME( 0x0c, 0x0c, DEF_STR( Lives ) ) PORT_DIPLOCATION("SW1:6,5")
PORT_DIPSETTING(    0x04, "2" )
PORT_DIPSETTING(    0x0c, "3" )
PORT_DIPSETTING(    0x08, "4" )
PORT_DIPSETTING(    0x00, "5" )
PORT_DIPNAME( 0x30, 0x30, DEF_STR( Coin_B ) ) PORT_DIPLOCATION("SW1:4,3")
PORT_DIPSETTING(    0x00, DEF_STR( 4C_1C ) )
PORT_DIPSETTING(    0x20, DEF_STR( 3C_1C ) )
PORT_DIPSETTING(    0x10, DEF_STR( 2C_1C ) )
PORT_DIPSETTING(    0x30, DEF_STR( 1C_1C ) )
PORT_DIPNAME( 0xc0, 0xc0, DEF_STR( Coin_A ) ) PORT_DIPLOCATION("SW1:1,2")
PORT_DIPSETTING(    0x00, DEF_STR( 2C_1C ) )
PORT_DIPSETTING(    0xc0, DEF_STR( 1C_1C ) )
PORT_DIPSETTING(    0x40, DEF_STR( 1C_2C ) )
PORT_DIPSETTING(    0x80, DEF_STR( 1C_3C ) )

PORT_START("DSW2")
PORT_DIPNAME( 0x07, 0x07, DEF_STR( Bonus_Life ) ) PORT_DIPLOCATION("SW2:8,7,6")
PORT_DIPSETTING(    0x07, "10K 50K+" )
PORT_DIPSETTING(    0x03, "10K 60K+" )
PORT_DIPSETTING(    0x05, "20K 60K+" )
PORT_DIPSETTING(    0x01, "20K 70K+" )
PORT_DIPSETTING(    0x06, "30K 70K+" )
PORT_DIPSETTING(    0x02, "30K 80K+" )
PORT_DIPSETTING(    0x04, "40K 100K+" )
PORT_DIPSETTING(    0x00, DEF_STR( None ) )
PORT_DIPNAME( 0x08, 0x08, DEF_STR( Demo_Sounds ) ) PORT_DIPLOCATION("SW2:5")
PORT_DIPSETTING(    0x00, DEF_STR( Off ) )
PORT_DIPSETTING(    0x08, DEF_STR( On ) )
PORT_DIPNAME( 0x10, 0x10, DEF_STR( Difficulty ) ) PORT_DIPLOCATION("SW2:4")
PORT_DIPSETTING(    0x10, DEF_STR( Normal ) )
PORT_DIPSETTING(    0x00, DEF_STR( Difficult ) )
PORT_DIPNAME( 0x20, 0x00, DEF_STR( Flip_Screen ) ) PORT_DIPLOCATION("SW2:3")
PORT_DIPSETTING(    0x00, DEF_STR( Off ) )
PORT_DIPSETTING(    0x20, DEF_STR( On ) )
PORT_DIPNAME( 0xc0, 0x00, DEF_STR( Cabinet ) ) PORT_DIPLOCATION("SW2:2,1")
PORT_DIPSETTING(    0x00, DEF_STR( Upright ) )
PORT_DIPSETTING(    0x40, "Upright Two Players" )
PORT_DIPSETTING(    0xc0, DEF_STR( Cocktail ) )

ROM_HI_SCORE_TABLE	EQU	$018F
VULGUS_HI_SCORE		EQU	ROM_HI_SCORE_TABLE
SON_SON_HI_SCORE	EQU	$019C
HIGEMARU_HI_SCORE	EQU	$01A9
CAPCOM_HI_SCORE		EQU	$01B6
EXED_EXES_HI_SCORE	EQU	$01C3
COMANDO_HI_SCORE	EQU	$01D0
EMPTY_HI_SCORE		EQU	$01DD

X-SCROLL		EQU	$C808	; $C809	Background scroll x position
X-SCROLL-HI		EQU	$C809
Y-SCROLL		EQU	$C80A	; $C80B Background scroll y position
Y-SCROLL-HI		EQU	$C80B	; High y position y scroll (technically X) is 0-1ff wraps around the memory map

GAME_STATUS1		EQU	$E000	; What the game is actually doing is set with two status values
GAME_STATUS2		EQU	$E001	;	STATUS1	STATUS2					
					;	00	00	Intro Copyright Notice Text displaying
					;	00	01	Controller and DIP screen with sound test
					;	01	01	Player sprite intro with Insert Coin
					;	01	02	Commando Graphic
					;	01	03	High Score Table display
					;	02	01	Credits ready to play game
					;	03	03	Intro Helicopter main game display
					;	03	04	Now playing the game
					;	03	06	Level complete having a smoke etc
					;	03	09	Enter initials into high-score table
					;	03	0A	Show your high score entry like a champion!
FRAME_SYNC		EQU	$E002	; This is just a counter which ticks over every frame sync, used for animations and timing
START_BUTTONS		EQU	$E003	; Bits %1 Player1,%10 Player2,%1000000 Coin1,%10000000 Coin2
CONTROLLER_1		EQU	$E004	; Bits %1 Right, %10 Left, %100(4) Down, %1000 Up , Bits %10000 Fire1, %100000 Fire2
CONTROLLER_2		EQU	$E005	; Bits %1 Right, %10 Left, %100(4) Down, %1000 Up , Bits %10000 Fire1, %100000 Fire2

PORT_STATE_C000_IN0	EQU	START_BUTTONS ; PORT_STATE_C001_IN1 holds the state of IN1 after a bit flip (2's complement) - see $0328
PORT_STATE_DSW1		EQU	$E006
PORT_STATE_DSW2		EQU	$E007
					; Represents  joystick 1 and 2 (if it's a dual cabinet)
					; When you press the values count, and get quickly to $ff if held down
					; JOYSTICK1_LEFT and $E010 MOVE LEFT $FF when HELD DOWN LEFT
					; $E009 $E011 $FF MOVE RIGHT
					; JOYSTICK1_LEFT $E012 MOVE DOWN $FF
					; JOYSTICK1_UP $E013 MOVE UP $FF
					; JOYSTICK1_FIRE1 $E014 $FF IF HOLD DOWN FIRE1
					; JOYSTICK1_FIRE2 $E015 $FF IF HOLD DOWN FIRE2

JOYSTICK1_RIGHT		EQU	$E008	; Joystick 1 Right with accumulator
JOYSTICK1_LEFT		EQU	$E009	; Joystick 1 left with accumulator
JOYSTICK1_DOWN		EQU	$E00A	; Joystick 1 Down with accumulator
JOYSTICK1_UP		EQU	$E00B	; Joystick 1 Up with accumulator
JOYSTICK1_FIRE1		EQU	$E00C	; Joystick 1 Fire 1 (gun) with accumulator
JOYSTICK1_FIRE2		EQU	$E00D	; Joystick 1 Fire 2 (grenade) with accumulator

JOYSTICK2_RIGHT		EQU	$E010	; Joystick 2 Right with accumulator
JOYSTICK2_LEFT		EQU	$E011	; Joystick 2 left with accumulator
JOYSTICK2_DOWN		EQU	$E012	; Joystick 2 Down with accumulator
JOYSTICK2_UP		EQU	$E013	; Joystick 2 Up with accumulator
JOYSTICK2_FIRE1		EQU	$E014	; Joystick 2 Fire 1 (gun) with accumulator
JOYSTICK2_FIRE2		EQU	$E015	; Joystick 2 Fire 2 (grenade) with accumulator

PLAYER_UP		EQU	$E019	; 0 if one player, otherwise just increased + 1 for each player turn
TWO_PLAYER_FLAG		EQU	$E01A	; 0 One player game or 1 if a 2player game
CREDITS_PER_COIN	EQU	$E020	; Coin A How many credits per coin
COINS_PER_CREDIT	EQU	$E022	; Coin A How many Coin(s) you need per game Credit(s)
COINS_PER_CREDIT_B	EQU	$E023	; Coin B How many Coin(s) you need per game Credit
CREDITS_PER_COIN_B	EQU	$E021	; Coin B How many credits for the Coins (only 1 ever)

NUM_LIVES		EQU	$E024	; dip Setting number of lives given 2 3 4 5
IS_CABINET_UPRIGHT	EQU	$E025   ; set to 1 if dip switches report an upright cabinet
DIFFICULTY_LEVEL	EQU	$E026	; value
STARTING_AREA		EQU	$E027	; 0 - 3 area starts stage in game

IS_BONUS_BITS		EQU	$E028	; bit 1 & bit 4 for Bonus point every 10000 and 50000
IS_SINGLE_STICK_SETUP	EQU	$E029	; set to 2 if dip switches report upright cabinet with one stick (see $012D)
IS_DEMO_SOUNDS_ON	EQU	$E02A	; set to 16 if dip switches report demo sounds should be OFF (see $0133)
IS_DIFFICULT		EQU	$E02C	; set to 8 if Difficult difficulty in dip switches, 0 = Normal (see $0139)
NUM_CREDITS		EQU	$E030	; number of credits inserted
IS_SCREEN_YFLIPPED	EQU	$E039	; set to 1 if screen is flipped on vertical axis
SOUND_CODE		EQU	$E03A	; Audio hardware Sound Code, poked to hardware via the IRQ handler
START_BUTTON_MIRROR	EQU	$E03B	; Copy of the start button key press bits pl1 pl2 and also screen flip
TEST_MODE_SFX_NUMBER	EQU 	$E044	; During Test mode this is the sound code SFX, or Tune.
					; The sounds are injected into to circular buffer which wraps around, and it's processes like the display text system.
				
	; Sound Codes which I could work out, it's same value poked into the SOUND_CODE byte
	; $02
	; $03 short blip
	; $04 Fire Gun
	; $05 $06 grenade (like firework)
	; $07
	; $0F like helicopter landing
	; $10 long helicopter sound fly repeating
	; $11 distance helicopter flying off into distance
	; $12 another helicopter same level repeating
	; $14 kill enemy
	; $15 alarm siren repeating
	; $16
	; $18 Some kind of screaming sound
	; $1A Coin Inserted
	; $1B Extra Life
	; $20 Starting level jingle
	; $21 Carry on from starting level jungle. (repeats)
	; $22 Seems like intro jingle with odd bits
	; $23 Final part of each stage to kill all enemies at gates
	; $24 Completed Level
	; $25 Completed Area
	; $26 Area 4 ride in helicopter
	; $27 End of Lives
	; $28
	; $2A completed game I think
	; $2B just been killed end a life
	; $2C like 22 repeats


COUNTDOWN_TIMER		EQU	$E047	; A general purpose countdown number which is use to trigger events
					; Example the attract mode counts down on zero will change the display
					; to the next attract mode, high score or the player sprite and so on.
ENEMY_SPRITE_COUNT	EQU	ENEMY_SPRITE_COUNT	; The sprite update table is processed with this set to 0, and each active item increased this count
					
MAP_OFFSET		EQU	$E05B	; & $EDA3 y position inside the map data
MAP_OFFSET_H		EQU	$E05C
TREE_ROCK_TABLE		EQU	$E05E	; The table from $4000 inside ROM for the trees & rock sprites scroll up.
					; These are fixed positions and just give the dimension look when behind
					; I expect if the hardware had more than one plane this entire table could of been replaced
	
SCREEN_SCROLLING	EQU	$E062	; 0 means screen is stationary, 1 if the display is scrolling
					; this is used in many routines for moving addition y offsets for sprites etc.
DO_EXPLOSION		EQU	$E080	; When explosion is gone bang, starts from $10 and counts down
					; Only one of these is actually possible at once.
BG_EVENT_POINTER	EQU	$E08F	; This points to the table inside ROM for background control items
					; As screen scrolls items like pickups, and timed events are triggered once
					; The table is process along each scroll of y to match any upcoming events
SPAWN_POSITION		EQU	$E096	; This points to the table which spawns enemies as you move throught the play area
AREA_END		EQU	$E09F	; Player has reached the end of Area/Level when = 1. Stop scrolling etc.
ENDING_ENEMIES		EQU	$E0A0	; Spawn all these enemies until exhaused then Area is completed.
COMPLETED_AREA_TIMER	EQU	$E0A1	; Countdown timer for the Area complete intermission screen.
MESSAGE_VIDEO_RAM	EQU	$E0B1	; Message display Pointer screen character memory stored
MESSAGE_TODISPLAY	EQU	$E0B3	; Message pointer in ROM what to display on screen


MAX_BULLETS		EQU	$E0F0	; Maximum of bullets which can be active. Dynamic
BULLET_TIMER_RESET	EQU	$E0F2	; Countdown timers reset for a new bullet spawn
BULLET_TIMER		EQU	$E0F3	; Countdown timer when reaches 0 can spawn another bullet
MAX_ENEMY		EQU	$F0F4	; Max amount of enemy -1 on screen at once
ENEMY_TIMER_RESET	EQU	$E0F5	; Countdown timer reset for new enemy spawn
ENEMY_TIMER		EQU	$E0F6	; Countdown timer for new enemy spawn

STANDING_TIMER		EQU	$E0F8	; Countdown when player stands still and doesn't scroll play area
					; When reaches 0 the system will auto-spawn more enemies from sides.
PLAYER_DATA		EQU	$E100	; FF for when player is on screen, 00 when not.

PLAYER_X		EQU	$E103	; Current player x position
PLAYER_Y		EQU	$E105	; Current player y position
	
GRENADE_LUNCHED		EQU	$E116	; Animation count of player befor grenade lunched

grenade_TABLE		EQU	$E140	; table+$14 0 not active, $ff is active and been thrown.

grenade_X_coordinate	EQU	$E143	; Screen X position
grenade_Y_coordinate	EQU	$E145	; Screen Y position

HELICOPTER_DATA		EQU	$E160	; Helicopter data table, it acts like normal object type but has just one table entry.

PLAYER_BULLETS		EQU	$E200	; Player has max of 6 Bullets on screen allocated is 32 bytes for each:
					; Byte 0 Value 0 for disabled, FF enabled or active, or a countdown until disabled
					; Byte 01 bullet direction. $00 Right $40 Up, $7F Left, $c0 Down
					; Now unusual directions have different values $20 Right Up,Left Up $60, Left down $A0, Right Down
					; There is an entire clock of directions for the bullets to travel, it's tricky to get the right value
					; 
					; Byte 02 unknown always zer0
					; Byte 03 sprite X position on screen
					; Byte 04
					; Byte 05 Sprite Y coordinate on screen
					; Bytes 7,8,9,$a always appear at 0
					; Bytes $0b value to add to X coordinate for each update
					; Bytes $0d value to add to Y coordinate for each update
					; Byte $12 set to $13 is distance counter by default (assume you not enabled the cheats!)
								
					; Byte $14 01 means been fired, 02 is slot available to fire if $00 is 0
					; Byte $15 a count down for bullet exploding or until starts to fire
					; When it reaches 0 the Byte 0 is set to $3f then 07,6,5,4,3,2,1,0
					; Seems bullet activating is $15 = 2, $14 = 0
					; $15 counts to 0, then sets $14 = 2 then enables sprite at byte 0 to $ff
								
					; sprites moves along until explodes. setting status $14 = 2 then $15 countdown to = 6
					; countdown of $15 to 0, then sets $00 to $3f
								
					; Sequence is as follows
					; byte0,	byte14,		byte15
					; 0,		01 or 02	00	; Free bullet to fire					
					; $ff,		00,		02	; Fired and counting down
					; $00,		00,		01	; counting down
					; $ff,		01,		00	; Fired and moving
					
					; $ff,		02,		06	; Bullet stopped and exploding
					; $ff,		02,		05	; Bullet counting down
					; $ff,		02,		04	; Bullet counting down
					; $ff,		02,		03	; Bullet counting down
					; $ff,		02,		02	; Bullet counting down
					; $ff,		02,		01	; Bullet counting down
					; $3f,		02,		00	; Bullet counting down
					; $07,		02,		00	; Bullet counting down
					; $06,		02,		00	; Bullet counting down
					; $05,		02,		00	; Bullet counting down
					; $04,		02,		00	; Bullet counting down
					; $03,		02,		00	; Bullet counting down
					; $02,		02,		00	; Bullet counting down
					; $01,		02,		00	; Bullet counting down
					; $00,		02,		00	; Bullet counting down

					; $35,7-1,1	02,		00	; exploding countdown

ENEMY_BULLETS		EQU	$E2C0	; The enemies have max of 8 Bullets on screen allocated is 32 bytes for each same as player data
					; Bullet data has a few data bytes / bullet
					; Byte 0 00 for disabled, FF enabled or active, other values are count down until disabled
					; Byte 1 bullet direction. $00 Right $40 Up, $7F Left, $c0 Down
					; Now unusual directions have different values $20 Right Up,Left Up $60, Left down $A0, Right Down
					; There is an entire clock of directions for the bullets to travel, it's tricky to get the right value
					; if you look close you can
					; Byte 2 unknown
					; Byte 3 sprite X position MSB
					; Byte 4 sprite X position fractional LSB
					; Byte 5 Sprite Y coordinate on screen MSB
					; Byte 6 Sprite Y position fractional LSB
					; Bytes $b,c value to add to X coordinate
					; So it's 34+bc in effect, but it's saved before updated to 34
					; Bytes $d,e value to add to Y coordinate
					; Again we have 56+de and again saved to 
								
					; Byte $14 01 means moving, 02 is in explosion state
					; Byte $15 a count down for bullet exploding starts at 6 and goes to 0
					; When it reaches 0 the Byte 0 is set to $3f then 07,6,5,4,3,2,1,0

BACKGROUND_ITEMS	EQU	$E500	; Items which scroll down with game 32 bytes / item
					; This is pickups, and also enemies behind sandbags
					; And also enemies in water and trenches timed sprites like the guards captured your friend
					; The bridge elements are also here (I would of suspected with other items but whatever.
					; Doors for small bunkers also here
					; Vehicles up down bikes left and right
					; concrete huts you can bomb
ENEMY_SPRITES		EQU	$E600	; Start of enemy tableset each with 32 bytes / enemy

TREE_ROCK_SPRITES	EQU	$E800	; The items which scroll in background which are only trees and the rocks
					; Data is 16 bytes / sprite. not this will be one or more physical sprites
					; Byte 0 = 0 for no sprite, and $FF if active
					; Byte 3 = Screen X coordinate
					; Byte 5 = Screen Y coordinate
					; Byte 7 & 8 This is the physical sprite data value
					; 	looking at screen it's bottom left +1 right
					;	Then top left -8 and top right is +1
					; Byte 9&10 are type
					; 9,10 = 04,$18 is palm trees with 10
					;	 0c,$25 twin rocks

TABLE_STATUS		EQU	$00	; Most tables first byte represents either 0 or -1 for it's active status, also can be other value as about to be removed from slot.
TABLE_X_cord		EQU	$03	; All data tables share same offset positions
TABLE_X_low		EQU	$04	; fractional add for X for movements 
TABLE_Y_cord		EQU	$05	; We create these variables to clearer elements in disassembly
TABLE_Y_low		EQU	$06
TABLE_new_X_high	EQU	$07	; When X is updated it uses a temp set of registers for new update to happen
TABLE_new_X_low		EQU	$08	; fractional add for X for movements new position
TABLE_new_Y_high	EQU	$09	; When X is updated it uses a temp set of registers for new update to happen
TABLE_new_Y_low		EQU	$0A	; fractional add for X for movements new position
TABLE_X_Add_low		EQU	$0B	; this is addition to the X coordinates it can be a fractional value with low byte being a division of a pixel
TABLE_X_Add_high	EQU	$0C	; The high whole pixel value addition or the msb of low byte addition if you like to call it that for the X
TABLE_Y_Add_low		EQU	$0D	; this is addition to the Y coordinates it can be a fractional value with low byte being a division of a pixel
TABLE_Y_Add_high	EQU	$0E	; The high whole pixel value addition or the msb of low byte addition if you like to call it that for the Y


ITEM_TYPE		EQU	$13	; This inside tables represent what type is
TABLE_COUNTDOWN		EQU	$15	; All tables use this as a generic countdown clock for events to trigger updates or animations
TABLE_SPRITE_QTY	EQU	$1A0	; How many sprites associated with this table entry


ACTION_NUMBER		EQU	$ED84


EVENT_BUFFER		EQU	$ED00	; Circular buffer for Events to handle, which are stacked up.
					; The buffer can have several entries which stack up, and each is activated
					; The buffer pointer is updated, until it find no more data $ff to indicate this

AUDIO_BUFFER		EQU	$ED40	; Seems a circular buffer area full of $ff but audio sounds get injected
					; And the buffer moves on one, but stays withing $ED40 - $ED5F
					; A large bunch of calls to the buffer fill with a sound effect.
					; One can only guess this is just a simple rotating list of sounds to blast off.
								
EVENT_HANDLER_NEXT	EQU	$ED80	; Next free slot inside the buffer
EVENT_NOW		EQU	$ED82	; Current Event location inside the buffer
AUDIO_POINTER_NEXT	EQU	$ED86	; Pointer to buffer for current
AUDIO_POINTER_NOW	EQU	$ED88	; Pointer to buffer for current

CURRENT_SCORE		EQU	$E0A6	; Pointer to the current player score, will change if P1 or P2
					; Score values increased reads from this pointer to change value
PLAYER_LIVES		EQU	$EDA0	; Current player lives

MAP_OFFSET_HIGH		EQU	$EDA3	; Copy pointer for high low loading into registers 
					; Stage 1 00 - 07
					; Stage 2 08 - 0F
					; Stage 3 10 - 16
					; Stage 4 18 - 18
					; Stage 4 19 - 1F After this stage is a fly in helicopter from 20 - 3f
					; Stage 5 48 - 4f
					; Stage 6 50 - 57
					; Stage 7 58 - 5f
					; Stage 8 60 - 6f
GAME_LEVEL		EQU	$EDA4	; Area level number 0 - 7 for basically all stages above (binary! 0 = 1 and 1=2 lol)
							
NUM_GRENADES		EQU	$EDA8
AREAS_COMPLETED 	EQU	$EDA9	; Numbers of areas/levels player has completed.


					; Player data is copied from here into the parameters as when players swap
					; this way the system is working on one set of values for positions lives etc.
			
PLAYER1_DATA		EQU	$EDC0	; First bytes is number of lives

PLAYER1_LIVES		EQU	$EDC0
PLAYER2_LIVES		EQU	$EDC1


PLAYER2_DATA		EQU	$EDE0


HI_SCORE_TABLE		EQU	$EE00
HI_SCORE_1ST		EQU	$EE00
HI_SCORE_2ND		EQU	$EE0D
HI_SCORE_3RD		EQU	$EE1A
HI_SCORE_4TH		EQU	$EE27
HI_SCORE_5TH		EQU	$EE34
HI_SCORE_6TH		EQU	$EE41
HI_SCORE_7TH		EQU	$EE4E

PLAYER1_SCORE		EQU	$EE91	; Score 00 00 00 ( decimal left to right )
PLAYER2_SCORE		EQU	$EE94	; each player has own kept value

HI_SCORE		EQU	$EE97	; the hi score seen on screen

TILE_POINTERS_RAM	EQU	$EF00	; Base memory for all pointers for decoding
TILE_DECODE_RAM		EQU	$F000	; This is the memory where the background character maps are decoded


					; Let's define the sprite offset so it makes for easier reading of some routines.
					; As the system uses single or dual and 2x2 sizes the most it looks better to show here as offsets
					; The tables which are used to point for each sprite are larger, so didn't use. 
					; sometimes they also use IX+ for working table sprite positions and data.
					; This offset is different for enemies / sprites / background sprite tables.

					; Mostly index via (IX+) inside the code
sprite_number		EQU	$00	; BYTE 0 is sprite number as per data layout in Mame F4 iy+$00 normally in code
sprite2_number		EQU	$04	; +4 define what's 2nd sprite when used in 2x1 and 2x2 sprites
sprite3_number		EQU	$08	; +4
sprite4_number		EQU	$0C	; +4 more

sprite_flags		EQU	$01	; iy+sprite_flags			
sprite2_flags		EQU	$05	; iy+sprite2_flags		; 4 bytes on
sprite3_flags		EQU	$09	; +4 for next
sprite4_flags		EQU	$0d	; +4 for last				
					; Bit 1: unused
					; Bit 0: if set, negative X coord (visually it's the Y) so -$ffff is this bit high
					; Bit 2: if set, flip sprite horizontally
					; Bit 3: if set, flip sprite vertically
					; Bits 4 & 5: sprite colour select (shift right 4 times to get real value) Palette values are $80 $90 $A0 $B0
					; Sprites are 4bit / colour so there is 16 colours, the colour 15 $f represents transparency.
					; Bits 6 & 7: sprite bank select ; this makes sprites like $1ff or $2ff
sprite_x		EQU	$02	; Technically Y but visually it is X position normally ix+$02
sprite2_x		EQU	$06	; This is offset always in form of ix+TABLE_Y_low  inside code
sprite3_x		EQU	$0a	; + 4
sprite4_x		EQU	$0e	; + 4 again
sprite_y		EQU	$03	; Again this is X position but visually it's Y on screen normally iy+$03
sprite2_y		EQU	$07	; This is offset always in form of ix+TABLE_new_X_high inside code for 2nd sprite inside a large size
sprite3_y		EQU	$0b
sprite4_y		EQU	$0f
					; Sprites x visually is actually Y from $08 left side & $df X is 8 for bottom of display $2f for scrolling

HW_SPRITE_1		EQU	$FE04	; Explosion 2 x 2 size
HW_SPRITE_2		EQU	$FE08	; Actually if you check there is only one explosion technically at same time
HW_SPRITE_3		EQU	$FE0C	; if you try and use cheat mode it's possible to get two to happen, but it actually glitches
HW_SPRITE_4		EQU	$FE10	; the explosion sprites are shared between your own Grenade and any others which are fired by enemies
HW_SPRITE_5		EQU	$FE14	; Grenades from enemies max of 5 can be thrown at same time E Grenade 1
ENEMY_GRENADES_SP	EQU	HW_SPRITE_5
HW_SPRITE_6		EQU	$FE18	; E Grenade 2
HW_SPRITE_7		EQU	$FE1C	; E Grenade 3
HW_SPRITE_8		EQU	$FE20	; E Grenade 4
HW_SPRITE_9		EQU	$FE24	; E Grenade 5
HW_SPRITE_10		EQU	$FE28	; In game pickup grenade box (single or double $267 or double $26E)
HW_SPRITE_11		EQU	$FE2C	; Grenade box double width box $26F
HW_SPRITE_12		EQU	$FE30	; Large sprite(1) 2x2 most are with background data
HW_SPRITE_13		EQU	$FE34
HW_SPRITE_14		EQU	$FE38
HW_SPRITE_15		EQU	$FE3C
HW_SPRITE_16		EQU	$FE40	; Large sprite(2) 2x2 also 2x1 for rocks on Area1
HW_SPRITE_17		EQU	$FE44
HW_SPRITE_18		EQU	$FE48	; seems as rocks 2 x 1
HW_SPRITE_19		EQU	$FE4C
HW_SPRITE_20		EQU	$FE50	; Large sprite(3) 2x2 and 2 x 1 for rocks
HW_SPRITE_21		EQU	$FE54
HW_SPRITE_22		EQU	$FE58	; rocks 2 x 1
HW_SPRITE_23		EQU	$FE5C
HW_SPRITE_24		EQU	$FE60	; Large sprite(4) 2 x 2 (example Palm tree 202) bottom left 
HW_SPRITE_25		EQU	$FE64	; bottom right
HW_SPRITE_26		EQU	$FE68	; top left
HW_SPRITE_27		EQU	$FE6C	; top tight
HW_SPRITE_28		EQU	$FE70	; Large sprite(5) 2 x 2
HW_SPRITE_29		EQU	$FE74
HW_SPRITE_30		EQU	$FE78
HW_SPRITE_31		EQU	$FE7C
HW_SPRITE_32		EQU	$FE80	; Large sprite(6) 2 x 2 
HW_SPRITE_33		EQU	$FE84
HW_SPRITE_34		EQU	$FE88
HW_SPRITE_35		EQU	$FE8C
HW_SPRITE_36		EQU	$FE90	; Large sprite(7) 2 x 2
HW_SPRITE_37		EQU	$FE94
HW_SPRITE_38		EQU	$FE98
HW_SPRITE_39		EQU	$FE9C
HW_SPRITE_40		EQU	$FEA0	; large sprite(8) 2 x 2 ( also 2 x 1 like part of bridge 
HW_SPRITE_41		EQU	$FEA4
HW_SPRITE_42		EQU	$FEA8
HW_SPRITE_43		EQU	$FEAC
HW_SPRITE_44		EQU	$FEB0	; Large sprite(9) 2 x 2
HW_SPRITE_45		EQU	$FEB4
HW_SPRITE_46		EQU	$FEB8
HW_SPRITE_47		EQU	$FEBC
HW_SPRITE_48		EQU	$FEC0
HW_SPRITE_49		EQU	$FEC4
HW_SPRITE_50		EQU	$FEC8	; Enemy rocket launcher on ground 
HW_SPRITE_51		EQU	$FECC
HW_SPRITE_52		EQU	$FED0	; Enemy (seems as single behind rocks)
HW_SPRITE_53		EQU	$FED4	; Enemy (seems as single behind rocks)
HW_SPRITE_54		EQU	$FED8	; Enemy 1 head 
HW_SPRITE_55		EQU	$FEDC	; Enemy 1 body
HW_SPRITE_56		EQU	$FEE0	; Enemy 1 wide body
HW_SPRITE_57		EQU	$FEE4	; Enemy 2 head
HW_SPRITE_58		EQU	$FEE8	; Enemy 2 Legs
HW_SPRITE_59		EQU	$FEEC	; Enemy 2 wide body
HW_SPRITE_60		EQU	$FEF0	; Enemy 3 head
HW_SPRITE_61		EQU	$FEF4	; Enemy 3 body
HW_SPRITE_62		EQU	$FEF8	; Enemy 3 wide body
HW_SPRITE_63		EQU	$FEFC	; Enemy 4 head
HW_SPRITE_64		EQU	$FF00	; Enemy 4 body
HW_SPRITE_65		EQU	$FF04	; Enemy 4 wide body
HW_SPRITE_66		EQU	$FF08	; Enemy 5 head
HW_SPRITE_67		EQU	$FF0C	; Enemy 5 body
HW_SPRITE_68		EQU	$FF10	; Enemy 5 wide body
HW_SPRITE_69		EQU	$FF14	; Enemy 6 head
HW_SPRITE_70		EQU	$FF18	; Enemy 7 body
HW_SPRITE_71		EQU	$FF1C	; Enemy 7 wide body
HW_SPRITE_72		EQU	$FF20	; Enemy 7 head
HW_SPRITE_73		EQU	$FF24	; Enemy 7 body
HW_SPRITE_74		EQU	$FF28	; Enemy 7 wide body
HW_SPRITE_75		EQU	$FF2C	; Enemy 8 head
HW_SPRITE_76		EQU	$FF30	; Enemy 8 body
HW_SPRITE_77		EQU	$FF34	; Enemy 8 wide body
HW_SPRITE_78		EQU	$FF38	; Player sprite 1
PLAYER_SPRITE		EQU	HW_SPRITE_78
HW_SPRITE_79		EQU	$FF3C	; Player sprite 2 (when move up and down only two sprites used)
HW_SPRITE_80		EQU	$FF40	; Player sprite 3 (left/right angles)
HW_SPRITE_81		EQU	$FF44	; Hand Grenade but not the explosion part, as that's 2 x 2 sprites
HW_SPRITE_82		EQU	$FF48	; Player bullet 1
BULLET_SPRITES		EQU	HW_SPRITE_82
HW_SPRITE_83		EQU	$FF4C	; Player bullet 2
HW_SPRITE_84		EQU	$FF50	; Player bullet 3
HW_SPRITE_85		EQU	$FF54	; Player bullet 4
HW_SPRITE_86		EQU	$FF58	; Player bullet 5
HW_SPRITE_87		EQU	$FF5C	; Player bullet 6
HW_SPRITE_88		EQU	$FF60	; Enemy bullet 1
ENEMY_BULLET_SPRITES	EQU	HW_SPRITES_88
HW_SPRITE_89		EQU	$FF64	; Enemy bullet 2
HW_SPRITE_90		EQU	$FF68	; Enemy bullet 3
HW_SPRITE_91		EQU	$FF6C	; Enemy bullet 4
HW_SPRITE_92		EQU	$FF70	; Enemy bullet 5
HW_SPRITE_93		EQU	$FF74	; Enemy bullet 6
HW_SPRITE_94		EQU	$FF78	; Enemy bullet 7
HW_SPRITE_95		EQU	$FF7C	; Enemy bullet 8


0000: 3E 40       ld   a,$04		; power on status, which don't last long.
0002: 32 00 0E    ld   (GAME_STATUS1),a
0005: C3 A4 00    jp   START_UP		; lets get going.
0008: C9          ret
0009: FF          rst  $38
000A: FF          rst  $38
000B: FF          rst  $38
000C: FF          rst  $38
000D: FF          rst  $38
000E: FF          rst  $38
000F: FF          rst  $38

; RST $10
; Vertical Blank interrupt according to commando.cpp from Mame
0010: F3          di			; disable anymore, prevents double calling into same request
0011: C3 7B 20    jp   IRQ_HANDLER	; jump to handler code.

0014: FF          rst  $38
0015: FF          rst  $38
0016: FF          rst  $38
0017: FF          rst  $38


; RST $18
; Add an 8-bit value to HL
; A = 8 bit value to add to HL
;
ADD_A_TO_HL:
0018: 85          add  a,l
0019: 6F          ld   l,a
001A: 30 01       jr   nc,$001D
001C: 24          inc  h
001D: C9          ret


001E: FF          rst  $38
001F: FF          rst  $38

; RST $20
; Return the byte at HL + A.
; i.e: in BASIC this would be akin to: result = PEEK (HL + A)
;
; expects:
; A = offset
; HL = pointer
;
; returns:
; A = the contents of (HL + A)
; HL = HL + A

INDEX_A_PLUS_HL:
0020: 85          add  a,l
0021: 6F          ld   l,a
0022: 30 01       jr   nc,$0025
0024: 24          inc  h
0025: 7E          ld   a,(hl)
0026: C9          ret

0027: FF          rst  $38

; RST $28
INDEX_ED_AT_2A_PLUS_HL:
0028: 87          add  a,a	 	; multiply a by 2
0029: DF          rst  ADD_A_TO_HL
002A: 5E          ld   e,(hl)
002B: 23          inc  hl
002C: 56          ld   d,(hl)
002D: 23          inc  hl
002E: C9          ret

002F: FF          rst  $38

; RST $30
JUMP_TABLE:
0030: E1          pop  hl
0031: EF          rst	INDEX_ED_AT_2A_PLUS_HL

0032: EB          ex   de,hl
0033: E9          jp   (hl)
0034: FF          rst  $0038
0035: FF          rst  $38
0036: FF          rst  $38
0037: FF          rst  $38

		; Save passed DE to the circular buffer area pointed to by EVENT_HANDLER_NEXT
; RST $38
ADD_DE_TO_EVENT:
0038: 2A 08 CF    ld   hl,(EVENT_HANDLER_NEXT)	; Circular buffer pointer
003B: 72          ld   (hl),d			; save passed d
003C: 2C          inc  l			; pointer +1
003D: 73          ld   (hl),e			; save e
003E: 2C          inc  l
003F: 7D          ld   a,l			; increase pointer
0040: FE 04       cp   $40			; circular from $ED00 - $ED3F
0042: 38 20       jr   c,$0046
0044: 2E 00       ld   l,$00			; Reset back
0046: 22 08 CF    ld   (EVENT_HANDLER_NEXT),hl	; update pointer
0049: C9          ret

		; The main start of the game code
START_UP:
004A: 31 00 1E    ld   sp,TILE_DECODE_RAM	; setup initial stack pointer
004D: F3          di
004E: 3E 10       ld   a,$10			; bit 4 for hardware initialize of the Sound CPU
0050: 32 40 8C    ld   ($C804),a
0053: AF          xor  a			; a=0 that old chestnut of la a,0 save a byte.
0054: 32 80 8C    ld   (X-SCROLL),a		; set background scroll X
0057: 32 A1 8C    ld   (Y-SCROLL-HI),a		; set background scroll Y
005A: 32 81 8C    ld   (X-SCROLL-HI),a		; set background scroll X
005D: 32 A0 8C    ld   (Y-SCROLL),a		; set background scroll Y
0060: 21 00 0E    ld   hl,$E000			; clear all RAM
0063: 11 01 0E    ld   de,$E001
0066: 36 00       ld   (hl),$00
0068: 01 FF F1    ld   bc,$1FFF
006B: ED B0       ldir
006D: 21 00 1C    ld   hl,CHARACTER_RAM		; clear Video RAM
0070: 11 01 1C    ld   de,CHARACTER_RAM+1
0073: 36 02       ld   (hl),$20			; Clear with Spaces 32chr
0075: 01 FF 21    ld   bc,$03FF
0078: ED B0       ldir
007A: 21 00 5C    ld   hl,CHARACHER_COL		; clear colour RAM
007D: 11 01 5C    ld   de,CHARACHER_COL+1
0080: 36 00       ld   (hl),$00
0082: 01 FF 21    ld   bc,$03FF
0085: ED B0       ldir
0087: 21 00 9C    ld   hl,VIDEO_RAM		; clear background video RAM
008A: 11 01 9C    ld   de,VIDEO_RAM+1
008D: 01 FF 21    ld   bc,$03FF
0090: 36 9E       ld   (hl),$F8
0092: ED B0       ldir
0094: 21 00 DC    ld   hl,VIDEO_COLOUR		; clear background colour RAM
0097: 11 01 DC    ld   de,VIDEO_COLOUR+1
009A: 01 FF 21    ld   bc,$03FF
009D: 36 00       ld   (hl),$00
009F: ED B0       ldir
00A1: 21 E9 01    ld   hl,ROM_HI_SCORE_TABLE	; Copy hi score to RAM 
00A4: E5          push hl			; load HL with address of ROM_HI_SCORE_TABLE
00A5: 11 79 EE    ld   de,HI_SCORE              ; load DE with address of HI_SCORE
00A8: ED A0       ldi				; copy top score from ROM...
00AA: ED A0       ldi
00AC: ED A0       ldi				; ..to current high score in RAM.
00AE: E1          pop  hl
00AF: 11 00 EE    ld   de,HI_SCORE_TABLE	; Copy high score table from ROM to RAM
00B2: 01 28 00    ld   bc,$0082
00B5: ED B0       ldir	
00B7: 21 00 CF    ld   hl,EVENT_BUFFER		; Set Print display buffer to defaults
00BA: 22 28 CF    ld   (EVENT_NOW),hl		; Now is current pointer, which has to activate and catch up with Next
00BD: 22 08 CF    ld   (EVENT_HANDLER_NEXT),hl	; Next is the next free slot.
00C0: 11 01 CF    ld   de,$ED01
00C3: 36 FF       ld   (hl),$FF			; clear as not active
00C5: 01 F3 00    ld   bc,$003F
00C8: ED B0       ldir
00CA: 21 04 CF    ld   hl,AUDIO_BUFFER		; $ED40 - $ED5F
00CD: 22 88 CF    ld   (AUDIO_POINTER_NOW),hl	; Current pointer
00D0: 22 68 CF    ld   (AUDIO_POINTER_NEXT),hl	; Next pointer
00D3: 11 05 CF    ld   de,AUDIO_BUFFER+1
00D6: 36 FF       ld   (hl),$FF			; clear as not active
00D8: 01 F1 00    ld   bc,$001F			; wipe all out
00DB: ED B0       ldir
00DD: CD 7B 21    call CLEAR_SPRITES
00E0: 3E 00       ld   a,$00
00E2: 32 93 0E    ld   (IS_SCREEN_YFLIPPED),a
00E5: CD 76 20    call READ_SW2_SETTINGS	; Get SW2 inverted and saved.

00E8: 3A 60 0E    ld   a,(PORT_STATE_DSW1)	; Get DIP Switches 1
00EB: 47          ld   b,a			; Save setting for all other setups
00EC: E6 21       and  $03			; first two bits
00EE: 21 67 01    ld   hl,COIN_A_TABLE		; Offset table
00F1: 87          add  a,a			; double the value
00F2: E7          rst	INDEX_A_PLUS_HL	    	; call RETURN_BYTE_AT_HL_PLUS_A
00F3: 32 22 0E    ld   (COINS_PER_CREDIT),a	; Coin A ( coins per credit )
00F6: 23          inc  hl			; Next byte also
00F7: 7E          ld   a,(hl)			; read table 2nd byte
00F8: 32 02 0E    ld   (CREDITS_PER_COIN),a	; Credits for the Coin(s)
00FB: 78          ld   a,b			; Get back original setting
00FC: 0F          rrca				; The number of lives in SW1 bits 2&3
00FD: 0F          rrca
00FE: E6 21       and  $03			; Mask out rest
0100: 21 E7 01    ld   hl,COIN_B_TABLE
0103: 87          add  a,a
0104: E7          rst	INDEX_A_PLUS_HL	 	; call RETURN_BYTE_AT_HL_PLUS_A
0105: 32 23 0E    ld   (COINS_PER_CREDIT_B),a	; Coin B ( Coins per Credit )
0108: 23          inc  hl
0109: 7E          ld   a,(hl)
010A: 32 03 0E    ld   (CREDITS_PER_COIN_B),a	; Credit for the Coins(s) in Slot B
010D: 78          ld   a,b			; get back SW1
010E: 07          rlca
010F: 07          rlca
0110: 07          rlca
0111: 07          rlca
0112: 21 77 01    ld   hl,LIVES_TABLE
0115: E6 21       and  $03			; Get lives lookup from bits 2&3
0117: E7          rst	INDEX_A_PLUS_HL	 	; call RETURN_BYTE_AT_HL_PLUS_A
0118: 32 42 0E    ld   (NUM_LIVES),a
011B: 78          ld   a,b
011C: 07          rlca
011D: 07          rlca
011E: E6 21       and  $03
0120: 32 63 0E    ld   (STARTING_AREA),a	; Save Area Start 0 1 2 3
0123: 3A 61 0E    ld   a,(PORT_STATE_DSW2)  	; read PORT_STATE_DSW2
0126: 47          ld   b,a
0127: E6 01       and  $01
0129: 32 43 0E    ld   (IS_CABINET_UPRIGHT),a	; set IS_CABINET_UPRIGHT
012C: 78          ld   a,b
012D: E6 20       and  $02
012F: 32 83 0E    ld   (IS_SINGLE_STICK_SETUP),a ; set IS_SINGLE_STICK_SETUP
0132: 78          ld   a,b
0133: E6 10       and  $10
0135: 32 A2 0E    ld   (IS_DEMO_SOUNDS_ON),a 	; set DEMO_SOUNDS_ON
0138: 78          ld   a,b
0139: E6 80       and  $08
013B: 32 C2 0E    ld   (IS_DIFFICULT),a		; set IS_NORMAL_DIFFICULTY
013E: 78          ld   a,b
013F: 07          rlca				; Shift down the difficulty bits
0140: 07          rlca
0141: 07          rlca
0142: E6 61       and  $07			; only count 0 - 7
0144: 87          add  a,a			; double is for two values / level
0145: 21 F7 01    ld   hl,LEVEL_TABLE		; Bonus table
0148: E7          rst	INDEX_A_PLUS_HL		; call RETURN_BYTE_AT_HL_PLUS_A
0149: 32 62 0E    ld   (DIFFICULTY_LEVEL),a
014C: 23          inc  hl
014D: 7E          ld   a,(hl)			; next table entry value
014E: 32 82 0E    ld   (IS_BONUS_BITS),a	; set if bonus is easy or hard
0151: 21 AE 01    ld   hl,VIOLATION_TEXT	; Startup export violation text
0154: 22 3B 0E    ld   (MESSAGE_TODISPLAY),hl
0157: 21 94 1C    ld   hl,$D058			; Screen RAM x=02, y=07
015A: 22 1B 0E    ld   (MESSAGE_VIDEO_RAM),hl
015D: 3E 0A       ld   a,$A0
015F: 32 65 0E    ld   (COUNTDOWN_TIMER),a
0162: 00          nop
0163: FB          ei
0164: C3 00 08    jp   EVENT_LOOP		; Endless loop for events handler

COIN_A_TABLE:	db	01,01			; 1 coin / 1 credit
		db	01,02			; 1 coin / 2 credits
		db	01,03			; 1 coin / 3 credits
		db	02,01			; 2 coins / 1 credit

COIN_B_TABLE:	db	01,01			; 1 coin / 1 credit
		db	02,01			; 2 coins / 1 credit
		db	03,01			; 3 coins / 1 credit
		db	04,01			; 4 coins / 1 credit

LIVES_TABLE:	db	3,2,4,5			; bits 2&3 in SW1 lookup for lives value.
						; The defaults they keep all off gives standard 3 lives

LEVEL_AREA_TABLE:	db	$00		; Start Area Desert 1 (default)
		db	$10			; Start Area Desert 2
		db	$80			; Start Area Forest 1
		db	$90			; Start Area Forest 2

LEVEL_TABLE:	db	01,05
		db	01,06
		db	02,06
		db	02,07
		db	03,07
		db	03,08
		db	04,10
		db	00,00 never used.

018F:		db	00,50,00,"VULGUS...."
		db	00,30,00,"SON.SON..."
		db	00,20,00,"HIGEMARU.."
		db	00,19,00,"CAPCOM...."
		db	00,19,00,"CAPCOM...."
		db	00,12,00,"EXED.EXES."
		db	00,10,00,"CAMANDO..."
		db	00,08,00,".........."

VIOLATION_TEXT:	db	"USE AND EXPORT OF THIS GAME#"
		dw	$d056			;  Screen RAM x=02, y=09
		db	"WITH IN THE #"
		dw	$d054			;  Screen RAM x=02, y=11
		db	"COUNTRY OF THE JAPAN#"
		dw	$d052			;  Screen RAM x=02, y=13
		db	"IS IN VIOLATION OF #"
		dw	$d050			;  Screen RAM x=02, y=15
		db	"COPYRIGHT LAW#"
		dw	$d04e			;  Screen RAM x=02, y=17
		db	"AND CONSTITUTES #"
		dw	$d04c			;  Screen RAM x=02, y=19
		db	"A CRIMINAL ACT@"

READ_SW2_SETTINGS:
0276: 3A 21 0C    ld   a,(DSW2)             	; read DSW1
0279: 2F          cpl
027A: 17          rla
027B: CB 18       rr   b
027D: 17          rla
027E: CB 18       rr   b
0280: 17          rla
0281: CB 18       rr   b
0283: 17          rla
0284: CB 18       rr   b
0286: 17          rla
0287: CB 18       rr   b
0289: 17          rla
028A: CB 18       rr   b
028C: 17          rla
028D: CB 18       rr   b
028F: 17          rla
0290: CB 18       rr   b
0292: 78          ld   a,b
0293: 32 60 0E    ld   (PORT_STATE_DSW1),a         ; write to PORT_STATE_DSW1
0296: 3A 40 0C    ld   a,(DSW2)             	; read DSW2
0299: 2F          cpl
029A: 17          rla
029B: CB 18       rr   b
029D: 17          rla
029E: CB 18       rr   b
02A0: 17          rla
02A1: CB 18       rr   b
02A3: 17          rla
02A4: CB 18       rr   b
02A6: 17          rla
02A7: CB 18       rr   b
02A9: 17          rla
02AA: CB 18       rr   b
02AC: 17          rla
02AD: CB 18       rr   b
02AF: 17          rla
02B0: CB 18       rr   b
02B2: 78          ld   a,b
02B3: 32 61 0E    ld   (PORT_STATE_DSW2),a      ; write to PORT_STATE_DSW2
02B6: C9          ret

						; Vertical Interupt handler
IRQ_HANDLER:
02B7: F5          push af			; Save every single register known to man
02B8: C5          push bc
02B9: D5          push de
02BA: E5          push hl
02BB: D9          exx
02BC: 08          ex   af,af'
02BD: F5          push af
02BE: C5          push bc
02BF: D5          push de
02C0: E5          push hl
02C1: DD E5       push ix
02C3: FD E5       push iy
02C5: CD 78 21    call HW_SCROLL_UPDATE		; hw scroll match game position pointers also audio stuff!
02C8: CD 63 69    call PROCESS_BUFFER_SFX	; Dispatch SFX to Audio hardware
02CB: CD BE 20    call UPDATE_BUTTONS		; Update all Inputs 
02CE: FD E1       pop  iy			; restore everything back
02D0: DD E1       pop  ix
02D2: E1          pop  hl
02D3: D1          pop  de
02D4: C1          pop  bc
02D5: F1          pop  af
02D6: 08          ex   af,af'
02D7: D9          exx
02D8: E1          pop  hl
02D9: D1          pop  de
02DA: C1          pop  bc
02DB: F1          pop  af
02DC: FB          ei				; re-enable interupts so this don't enter itself (ouch!)
02DD: C9          ret

02DE: 21 04 1C    ld   hl,$D040			; x=02, y=31
02E1: 06 D0       ld   b,$1C
02E3: 0E 11       ld   c,$11			; "C"
02E5: C3 3E 20    jp   $02F2			; x=02, y=31
02EB: 06 D0       ld   b,$1C
02ED: 0E 10       ld   c,$10			; "o"
02EF: C3 3E 20    jp   $02F2			; That's right ladies and gentleman it's the next bit of code!

02F2: 71          ld   (hl),c
02F3: 3E 02       ld   a,$20
02F5: DF          rst	ADD_A_TO_HL
02F6: 10 BE       djnz $02F2
02F8: C9          ret
02F9: C9          ret

UPDATE_BUTTONS:
02FA: 21 20 0E    ld   hl,FRAME_SYNC         	; load HL with address of TIMING_VARIABLE
02FD: 34          inc  (hl)			; increment TIMING_VARIABLE
02FE: 21 B3 0E    ld   hl,START_BUTTON_MIRROR
0301: 3A 40 0C    ld   a,(DSW2)             	; read DSW2
0304: 07          rlca
0305: 07          rlca
0306: E6 08       and  $80
0308: 4F          ld   c,a
0309: 3A 93 0E    ld   a,(IS_SCREEN_YFLIPPED)
030C: E6 01       and  $01
030E: 28 40       jr   z,$0314
0310: 79          ld   a,c
0311: C6 08       add  a,$80
0313: 4F          ld   c,a
0314: 3A B3 0E    ld   a,(START_BUTTON_MIRROR)
0317: E6 F7       and  $7F
0319: 81          add  a,c
031A: 32 B3 0E    ld   (START_BUTTON_MIRROR),a	; Flip screen, will do this on the fly! class
031D: 3A 00 0C    ld   a,($C000)             	; read IN0
0320: 2F          cpl
0321: 32 21 0E    ld   (START_BUTTONS),a	; save in PORT_STATE_C000_IN0
0324: 3A 01 0C    ld   a,($C001)		; read IN1
0327: 2F          cpl
0328: 32 40 0E    ld   (CONTROLLER_1),a		; save in PORT_STATE_C001_IN1
032B: 3A 20 0C    ld   a,($C002)		; read IN2
032E: 2F          cpl
032F: 32 41 0E    ld   (CONTROLLER_2),a		; save in PORT_STATE_C005

; Expand PORT_STATE_C001_IN1 bits to flags
0332: 11 40 0E    ld   de,CONTROLLER_1       	; load DE with address of PORT_STATE_C001_IN1
0335: 21 80 0E    ld   hl,JOYSTICK1_RIGHT
0338: 1A          ld   a,(de)                	; read PORT_STATE_C001_IN1
0339: 0F          rrca	     			; move IPT_JOYSTICK_RIGHT bit into carry
033A: CB 16       rl   (hl)			; shift into PORT_STATE_C001_BIT0_BITS
033C: 2C          inc  l
033D: 0F          rrca	    			 ; move IPT_JOYSTICK_LEFT bit into carry
033E: CB 16       rl   (hl)			; shift into PORT_STATE_C001_BIT1_BITS
0340: 2C          inc  l
0341: 0F          rrca	     			; move IPT_JOYSTICK_DOWN bit into carry
0342: CB 16       rl   (hl)			; shift into PORT_STATE_C001_BIT2_BITS
0344: 2C          inc  l
0345: 0F          rrca	     			; move IPT_JOYSTICK_UP bit into carry
0346: CB 16       rl   (hl)			; shift into PORT_STATE_C001_BIT3_BITS
0348: 2C          inc  l
0349: 0F          rrca	     			; move IPT_BUTTON1 (shoot) bit into carry
034A: CB 16       rl   (hl)			; shift into PORT_STATE_C001_BIT4_BITS
034C: 2C          inc  l
034D: 0F          rrca	     			; move IPT_BUTTON2 (grenade) bit into carry
034E: CB 16       rl   (hl)			; shift into PORT_STATE_C001_BIT5_BITS


0350: 11 40 0E    ld   de,CONTROLLER_1		; load DE with address of PORT_STATE_C001_IN1
0353: 3A 93 0E    ld   a,(IS_SCREEN_YFLIPPED)	; read IS_SCREEN_YFLIPPED flag
0356: E6 01       and  $01			; test if flag is set
0358: 20 60       jr   nz,$0360              	; if flag is set, goto $03600

035A: 3A 83 0E    ld   a,(IS_SINGLE_STICK_SETUP)
035D: A7          and  a
035E: 20 01       jr   nz,$0361
0360: 1C          inc  e	   		; bump DE to point to PORT_STATE_C002_IN2
0361: 21 10 0E    ld   hl,JOYSTICK2_RIGHT
0364: 1A          ld   a,(de)
0365: 0F          rrca
0366: CB 16       rl   (hl)
0368: 2C          inc  l
0369: 0F          rrca
036A: CB 16       rl   (hl)
036C: 2C          inc  l
036D: 0F          rrca
036E: CB 16       rl   (hl)
0370: 2C          inc  l
0371: 0F          rrca
0372: CB 16       rl   (hl)
0374: 2C          inc  l
0375: 0F          rrca
0376: CB 16       rl   (hl)
0378: 2C          inc  l
0379: 0F          rrca
037A: CB 16       rl   (hl)


037C: 3A 21 0E    ld   a,(START_BUTTONS)	; read PORT_STATE_C000_IN0 bits
037F: 21 96 0E    ld   hl,$E078			; Can't find any reference to this yet. Go Figure
0382: 0F          rrca
0383: CB 16       rl   (hl)			; Very unusual instruction to use here
0385: CD 73 F8    call $9E37

0388: 3A 00 0E    ld   a,(GAME_STATUS1)		; jump relative to this value
038B: E6 21       and  $03
038D: F7          rst  JUMP_TABLE		; Jump table from count a

		dw      JUMP_START0		;$03c9 Status Jump Table 0
		dw      JUMP_START1		;$0400 Status Jump Table 1
		dw      JUMP_START2   		;$0562 Status Jump Table 2
		dw      JUMP_START3		;$0621 Status Jump Table 3

		; put HW scroll registers from the offsets as needed.
HW_SCROLL_UPDATE:
0396: 3A B2 0E    ld   a,(SOUND_CODE)		; Read dispatched sound code
0399: 32 00 8C    ld   ($C800),a		; wack it into the audio hardware address
039C: 3A B5 0E    ld   a,(MAP_OFFSET)		; take high bit of scroll offset wrap to fit into $1ff
039F: E6 01       and  $01			; 0 or 1 for high bit
03A1: 32 81 8C    ld   (X-SCROLL+1),a
03A4: 3A D4 0E    ld   a,(MAP_OFFSET_H)
03A7: 32 80 8C    ld   (X-SCROLL),a
03AA: 3A B3 0E    ld   a,(START_BUTTON_MIRROR)	; reading this must be latch this side.
03AD: 32 40 8C    ld   ($C804),a		; I think must be audio latch trigger
03B0: 32 60 8C    ld   ($C806),a		; and another part for the audio? NO!
03B3: 00          nop				; Checking MAME debugger this generates a unmapped program memory log output!
03B4: 00          nop
03B5: 00          nop	
03B6: C9          ret

CLEAR_SPRITES:
03B7: DD 21 40 FE ld   ix,HW_SPRITE_1		; 1st Sprite data
03BB: 06 F5       ld   b,$5F			; 95 hardware sprites ( luxuary in 1985, compared to home computers)
03BD: 11 40 00    ld   de,$0004			; each sprite is 4 bytes of data
03C0: AF          xor  a			; zero a
03C1: DD 77 20    ld   (ix+sprite_x),a		; wipe all data X positions out makes them invisible from display.
03C4: DD 19       add  ix,de			; next sprite
03C6: 10 9F       djnz $03C1			; loop to wipe all
03C8: C9          ret

JUMP_START0:
03C9: 3A 01 0E    ld   a,(GAME_STATUS2)		; Sub call function
03CC: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	INTRO_MESSAGE  		; Intro Copyright Notice
		dw	$03fd   		; Game Jump 1
INTRO_MESSAGE:	
03D1: 3A C0 0E    ld   a,(JOYSTICK1_FIRE1)	; Press fire?
03D4: A7          and  a
03D5: C2 DE 41    jp   nz,ADVANCE_STATUS2	; yes
03D8: CD 06 E0    call MESSAGE_UPDATE
03DB: 3A 20 0E    ld   a,(FRAME_SYNC)		; So here we're using Frame Sync
03DE: E6 21       and  $03			; this 60Hz so every 4th sync
03E0: C0          ret  nz
03E1: 21 65 0E    ld   hl,COUNTDOWN_TIMER	; we will do a countdown timer
03E4: 35          dec  (hl)
03E5: C0          ret  nz			; and exit

03E6: 16 81       ld   d,$09
03E8: FF          rst  ADD_DE_TO_EVENT
03E9: 11 01 00    ld   de,$0001
03EC: FF          rst  ADD_DE_TO_EVENT
03ED: 11 21 00    ld   de,$0003
03F0: FF          rst  ADD_DE_TO_EVENT
03F1: 16 20       ld   d,$02
03F3: FF          rst  ADD_DE_TO_EVENT
03F4: 16 21       ld   d,$03
03F6: FF          rst  ADD_DE_TO_EVENT
03F7: 16 40       ld   d,$04
03F9: FF          rst  ADD_DE_TO_EVENT

03FA: C3 01 60    jp   END_STARTUP_SCREEN	; End of export text display.

03FD: C3 BA B2    jp   DIAGNOSTICS_MENU

JUMP_START1:
0400: 21 50 40    ld   hl,$0414			; return addres
0403: E5          push hl
0404: 3A 01 0E    ld   a,(GAME_STATUS2)
0407: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$0426   		; Game Status2 0
		dw	$045e   		; Game Status2 1
		dw	$048e   		; Game Status2 2
		dw	$04bb   		; Game Status2 3
		dw	$04d4   		; Game Status2 4
		dw	$04eb   		; Game Status2 5

0414: 3A 90 0E    ld   a,($E018)
0417: A7          and  a
0418: C2 16 41    jp   nz,$0570
041B: 3A 12 0E    ld   a,(NUM_CREDITS)
041E: A7          and  a
041F: C8          ret  z
0420: 16 81       ld   d,$09
0422: FF          rst  ADD_DE_TO_EVENT
0423: C3 01 60    jp   END_STARTUP_SCREEN


0426: 16 20       ld   d,$02
0428: FF          rst  ADD_DE_TO_EVENT
0429: 16 21       ld   d,$03
042B: FF          rst  ADD_DE_TO_EVENT
042C: 11 21 00    ld   de,$0003			; Display "TOP SCORE"
042F: FF          rst  ADD_DE_TO_EVENT
0430: 11 51 00    ld   de,$0015			; Display "
0433: FF          rst  ADD_DE_TO_EVENT
0434: 16 E0       ld   d,$0E
0436: FF          rst  ADD_DE_TO_EVENT
0437: CD 93 41    call COPYRIGHT_TEXT
043A: FD 21 92 FF ld   iy,PLAYER_SPRITE		; Intro screen with player sprite
043E: FD 36 20 94 ld   (iy+sprite_x),$58	; somewhere on screen
0442: FD 36 60 94 ld   (iy+sprite2_x),$58
0446: FD 36 21 1A ld   (iy+sprite_y),$B0	; sprites are 16 apart. (derrr the hight of them is 16 pixels!)
044A: FD 36 61 0A ld   (iy+sprite2_y),$A0	; 160 down for his head
044E: AF          xor  a
044F: 32 65 0E    ld   (COUNTDOWN_TIMER),a	; clear timer
0452: 21 00 80    ld   hl,$0800			; Demo display area
0455: 22 2A CF    ld   (MAP_OFFSET_HIGH),hl
0458: CD E8 4B    call UPDATE_OVERLAY_OBJECTS
045B: C3 DE 41    jp   ADVANCE_STATUS2


045E: CD D1 41    call $051D
0461: CD 9E 40    call ANIMATE_ATTRACT_PLAYER
0464: 21 65 0E    ld   hl,COUNTDOWN_TIMER
0467: 35          dec  (hl)
0468: C0          ret  nz

0469: FD 21 92 FF ld   iy,PLAYER_SPRITE
046D: FD 36 20 00 ld   (iy+sprite_x),$00
0471: FD 36 60 00 ld   (iy+sprite2_x),$00
0475: FD 36 A0 00 ld   (iy+sprite3_x),$00
0479: CD 81 60    call CLEAR_INFO_DISPLAY
047C: 16 80       ld   d,$08
047E: FF          rst  ADD_DE_TO_EVENT
047F: CD 93 41    call COPYRIGHT_TEXT
0482: 21 00 90    ld   hl,$1800
0485: 22 2A CF    ld   (MAP_OFFSET_HIGH),hl
0488: CD E8 4B    call UPDATE_OVERLAY_OBJECTS
048B: C3 DE 41    jp   ADVANCE_STATUS2

048E: 21 65 0E    ld   hl,COUNTDOWN_TIMER
0491: 35          dec  (hl)
0492: C0          ret  nz

0493: 21 00 84    ld   hl,$4800
0496: 22 2A CF    ld   (MAP_OFFSET_HIGH),hl
0499: CD E8 4B    call UPDATE_OVERLAY_OBJECTS
049C: CD 81 60    call CLEAR_INFO_DISPLAY
049F: CD DC 09    call TEXT_HIGH_SCORE_TABLE
04A2: 11 40 00    ld   de,$0004
04A5: FF          rst  ADD_DE_TO_EVENT
04A6: 16 61       ld   d,$07
04A8: FF          rst  ADD_DE_TO_EVENT
04A9: 16 80       ld   d,$08
04AB: FF          rst  ADD_DE_TO_EVENT
04AC: CD 93 41    call $0539
04AF: 21 00 F1    ld   hl,$1F00
04B2: 22 2A CF    ld   (MAP_OFFSET_HIGH),hl
04B5: CD E8 4B    call UPDATE_OVERLAY_OBJECTS
04B8: C3 DE 41    jp   ADVANCE_STATUS2
04BB: 21 65 0E    ld   hl,COUNTDOWN_TIMER
04BE: 35          dec  (hl)
04BF: C0          ret  nz
04C0: CD 81 60    call CLEAR_INFO_DISPLAY
04C3: AF          xor  a
04C4: 32 01 0E    ld   (GAME_STATUS2),a
04C7: C9          ret
04C8: 21 00 D0    ld   hl,$1C00
04CB: 22 2A CF    ld   (MAP_OFFSET_HIGH),hl
04CE: CD E8 4B    call UPDATE_OVERLAY_OBJECTS
04D1: C3 DE 41    jp   ADVANCE_STATUS2
04D4: CD 07 41    call $0561
04D7: 11 42 00    ld   de,$0024
04DA: FF          rst  ADD_DE_TO_EVENT
04DB: 1C          inc  e
04DC: FF          rst  ADD_DE_TO_EVENT
04DD: 11 F0 00    ld   de,$001E
04E0: FF          rst  ADD_DE_TO_EVENT
04E1: 1C          inc  e
04E2: FF          rst  ADD_DE_TO_EVENT
04E3: 3E 00       ld   a,$00
04E5: 32 65 0E    ld   (COUNTDOWN_TIMER),a
04E8: C3 DE 41    jp   ADVANCE_STATUS2
04EB: 21 65 0E    ld   hl,COUNTDOWN_TIMER
04EE: 35          dec  (hl)
04EF: C0          ret  nz
04F0: CD 81 60    call CLEAR_INFO_DISPLAY
04F3: AF          xor  a
04F4: 32 01 0E    ld   (GAME_STATUS2),a
04F7: C9          ret

ANIMATE_ATTRACT_PLAYER:
04F8: FD 21 92 FF ld   iy,PLAYER_SPRITE
04FC: 21 91 41    ld   hl,attract_sprite
04FF: 3A 20 0E    ld   a,(FRAME_SYNC)		; get system sync number that's counting down every refresh I assume 60Hz (NTSC sync)
0502: 0F          rrca
0503: 0F          rrca
0504: 0F          rrca				; / 8
0505: E6 21       and  $03			; 0 to 3
0507: E7          rst	INDEX_A_PLUS_HL		; call RETURN_BYTE_AT_HL_PLUS_A
0508: FD 77 00    ld   (sprite_number),a	; player head
050B: C6 80       add  a,$08			; and body
050D: FD 77 40    ld   (iy+sprite2_number),a
0510: FD 36 01 00 ld   (iy+sprite_flags),$00	; same palette and flip status for both
0514: FD 36 41 00 ld   (iy+sprite2_flags),$00
0518: C9          ret

attract_sprite:		db $20,$21,$22,$21	; little intro animation of player on attract screen

051D: 3A 20 0E    ld   a,(FRAME_SYNC)
0520: 47          ld   b,a
0521: E6 E1       and  $0F
0523: C0          ret  nz
0524: 11 60 00    ld   de,$0006
0527: 3A C2 0E    ld   a,(IS_DIFFICULT)
052A: A7          and  a
052B: 28 20       jr   z,$052F
052D: 1E 70       ld   e,$16			; display the bonus text
052F: CB 60       bit  4,b
0531: CA 92 00    jp   z,ADD_DE_TO_EVENT
0534: 14          inc  d			; change to the harder level text display
0535: C3 92 00    jp   ADD_DE_TO_EVENT
0538: C9          ret


COPYRIGHT_TEXT:
0539: 11 30 00    ld   de,$0012		; Display "CAPCOM"
053C: FF          rst  ADD_DE_TO_EVENT
053D: 11 31 00    ld   de,$0013		; Display "COPYRIGHT 1985"
0540: FF          rst  ADD_DE_TO_EVENT
0541: 11 50 00    ld   de,$0014		; Display "ALL RIGHTS RESERVED"
0544: FF          rst  ADD_DE_TO_EVENT
0545: C9          ret

0546: 3A 20 0E    ld   a,(FRAME_SYNC)
0549: 0F          rrca
054A: E6 21       and  $03
054C: 21 D5 41    ld   hl,$055D
054F: E7          rst	INDEX_A_PLUS_HL	; call RETURN_BYTE_AT_HL_PLUS_A
0550: 06 60       ld   b,$06		; 6 spaces
0552: 11 02 00    ld   de,$0020
0555: 21 2B 5D    ld   hl,$D5A3		; x=45, y=28 screen position
0558: 77          ld   (hl),a
0559: 19          add  hl,de		; next character along
055A: 10 DE       djnz $0558
055C: C9          ret

055D:		db $0c,$05,$0e,$05

0561: C9          ret

JUMP_START2:
0562: 21 29 41    ld   hl,$0583		; return address
0565: E5          push hl
0566: 3A 01 0E    ld   a,(GAME_STATUS2)
0569: F7          rst  JUMP_TABLE	; Jump table from count a

		dw      $05da   	; Game Status 0
		dw      $05f0   	; Game Status 1
		dw      $0600   	; Game Status 2	return!
			
0570: 3A 20 0E    ld   a,(FRAME_SYNC)
0573: 47          ld   b,a
0574: E6 F3       and  $3F
0576: 20 50       jr   nz,$058C
0578: 11 E0 00    ld   de,$000E
057B: CB 70       bit  6,b
057D: 28 01       jr   z,$0580
057F: 14          inc  d
0580: FF          rst  ADD_DE_TO_EVENT
0581: 18 81       jr   $058C

0583: 3A 20 0E    ld   a,(FRAME_SYNC)
0586: 47          ld   b,a
0587: E6 F1       and  $1F
0589: CC D8 41    call z,$059C
058C: 3A 21 0E    ld   a,(START_BUTTONS)
058F: CB 4F       bit  1,a			; Player 2 pressed?
0591: 20 43       jr   nz,TWO_PLAYER_GAME	; Cool you got a friend to play with how nice
0593: 3A 21 0E    ld   a,(START_BUTTONS)
0596: CB 47       bit  0,a			; Player one start
0598: C8          ret  z
0599: C3 8A 41    jp   ONE_PLAYER_GAME		; yes one player for billy no mates.

059C: 11 80 00    ld   de,$0008
059F: CB 68       bit  5,b
05A1: CA 92 00    jp   z,ADD_DE_TO_EVENT

05A4: 14          inc  d
05A5: C3 92 00    jp   ADD_DE_TO_EVENT

ONE_PLAYER_GAME:
05A8: 3A 12 0E    ld   a,(NUM_CREDITS)		; Reduce credits by one
05AB: D6 01       sub  $01
05AD: 27          daa
05AE: 32 12 0E    ld   (NUM_CREDITS),a		; save back (decimal only)
05B1: AF          xor  a
05B2: 32 B0 0E    ld   (TWO_PLAYER_FLAG),a	; Single player game
05B5: C3 8D 41    jp   PLAYER_GAME_ON

TWO_PLAYER_GAME:
05B8: 3A 12 0E    ld   a,(NUM_CREDITS)		; Check credits for two players
05BB: FE 01       cp   $01
05BD: C8          ret  z			; only one, sorry cheap skate pay more
05BE: D6 20       sub  $02			; two credits for two player mode
05C0: 27          daa
05C1: 32 12 0E    ld   (NUM_CREDITS),a		; save
05C4: 3E 01       ld   a,$01
05C6: 32 B0 0E    ld   (TWO_PLAYER_FLAG),a	; now we're 1 and 2UP oooo errr 

PLAYER_GAME_ON:
05C9: AF          xor  a	
05CA: 32 91 0E    ld   (PLAYER_UP),a		; first player first
05CD: 32 01 0E    ld   (GAME_STATUS2),a		; Status 2 clear
05D0: 3E 21       ld   a,$03
05D2: 32 00 0E    ld   (GAME_STATUS1),a		; Now set system for Playing game mode
05D5: 16 81       ld   d,$09
05D7: C3 92 00    jp   ADD_DE_TO_EVENT

05DA: CD 7B 21    call CLEAR_SPRITES
05DD: 16 81       ld   d,$09
05DF: FF          rst  ADD_DE_TO_EVENT
05E0: 16 40       ld   d,$04
05E2: FF          rst  ADD_DE_TO_EVENT
05E3: CD 93 41    call COPYRIGHT_TEXT
05E6: 16 80       ld   d,$08
05E8: FF          rst  ADD_DE_TO_EVENT
05E9: 11 A0 00    ld   de,$000A
05EC: FF          rst  ADD_DE_TO_EVENT
05ED: C3 DE 41    jp   ADVANCE_STATUS2

05F0: 3A 12 0E    ld   a,(NUM_CREDITS)
05F3: 3D          dec  a
05F4: C8          ret  z
05F5: 11 81 00    ld   de,$0009
05F8: FF          rst  ADD_DE_TO_EVENT
05F9: C3 DE 41    jp   ADVANCE_STATUS2

				  ; Used many times inside code to just advance the game status2
ADVANCE_STATUS2:
05FC: 21 01 0E    ld   hl,GAME_STATUS2		; This when you press fire at intro screen
05FF: 34          inc  (hl)			; put status to 1
0600: C9          ret

END_STARTUP_SCREEN:
0601: 21 00 0E    ld   hl,GAME_STATUS1		; Increase Staus1
0604: 34          inc  (hl)
0605: 2C          inc  l
0606: 36 00       ld   (hl),$00			; Zero out status2
0608: C9          ret

		; Clear Forground chraracter screen, but Leave alone the top two line
		; So 1UP TOP SCORE and the score numbers are left. (2UP if 2 players of course!)
CLEAR_INFO_DISPLAY:	
0609: 21 04 1C    ld   hl,$D040			; Start of the memory
060C: 0E D0       ld   c,$1C			; 28 characters this way
060E: 06 F0       ld   b,$1E			; and 30 this way
0610: 36 02       ld   (hl),$20			; Space or shall we call it Blank
0612: CB D4       set  2,h
0614: 36 00       ld   (hl),$00			; Zap the colour attributes also
0616: CB 94       res  2,h			; point back to RAM
0618: 2C          inc  l			; Add 1
0619: 10 5F       djnz $0610
061B: 23          inc  hl			; skip one line
061C: 23          inc  hl			; and skip another
061D: 0D          dec  c			; big loopy
061E: 20 EE       jr   nz,$060E
0620: C9          ret

0621: 3A 01 0E    ld   a,(GAME_STATUS2)
0624: F7          rst  JUMP_TABLE		; Jump table from count a

		dw      $0646   ; Game Status 0
		dw      $06dd   ; Game Status 1
		dw      $0769   ; Game Status 2
		dw      $07cd   ; Game Status 3
		dw      $07fc   ; Game Status 4
		dw      LEVEL_COMPLETED		;$094c Game Status 5
		dw      $0a6d   ; Game Status 6
		dw      $0ceb   ; Game Status 7
		dw      $0d1c   ; Game Status 8
		dw      $0d73   ; Game Status 9
		dw      $0df7   ; Game Status A

CLEAR_SCORE:
063B: 06 61       ld   b,$07			; Clear Player score values from display area
063D: 11 02 00    ld   de,$0020			; each position is 32 byte (screen rotated remember!)
0640: 36 02       ld   (hl),$20			; this is blank
0642: 19          add  hl,de			; next character
0643: 10 BF       djnz $0640			; max of 7 characters
0645: C9          ret

0646: 11 20 01    ld   de,$0102
0649: FF          rst  ADD_DE_TO_EVENT
064A: 21 19 EE    ld   hl,PLAYER1_SCORE		; Scores for player1 and player 2 3 bytes each cleared
064D: 06 60       ld   b,$06
064F: 36 00       ld   (hl),$00
0651: 2C          inc  l
0652: 10 BF       djnz $064F
0654: 21 F4 1C    ld   hl,$D05E			; x=02, y=01
0657: CD B3 60    call CLEAR_SCORE		; 1UP player score wipe
065A: 21 FE 3C    ld   hl,$D2FE			; x=23, y=01
065D: CD B3 60    call CLEAR_SCORE		; 2UP player score wipe
0660: 11 01 00    ld   de,$0001
0663: FF          rst  ADD_DE_TO_EVENT
0664: CD 3B D8    call SHOW_PLAYER_SCORE
0667: 3A 42 0E    ld   a,(NUM_LIVES)
066A: 32 0C CF    ld   (PLAYER1_DATA),a		; player 1 lives
066D: 32 0D CF    ld   (PLAYER1_DATA+1),a	; player 2 lives (set regardless of number of players
0670: 3E 60       ld   a,$06
0672: 32 8C CF    ld   ($EDC8),a		; No idea what's this for, no references found
0675: 3A 62 0E    ld   a,(DIFFICULTY_LEVEL)
0678: A7          and  a
0679: 28 54       jr   z,$06CF
067B: 6F          ld   l,a
067C: 26 00       ld   h,$00
067E: 29          add  hl,hl
067F: 29          add  hl,hl
0680: 29          add  hl,hl
0681: 29          add  hl,hl
0682: 7C          ld   a,h
0683: 32 4D CF    ld   ($EDC5),a
0686: 7D          ld   a,l
0687: 32 6C CF    ld   ($EDC6),a
068A: 3E 00       ld   a,$00
068C: 32 6D CF    ld   ($EDC7),a
068F: 3A 63 0E    ld   a,(STARTING_AREA)	; Get starting pointers for new game area
0692: 21 5D 60    ld   hl,LEVEL_START_TABLE
0695: EF          rst	INDEX_ED_AT_2A_PLUS_HL
0696: 63          ld   h,e			;
0697: 2E 00       ld   l,$00
0699: 22 2C CF    ld   ($EDC2),hl
069C: 7A          ld   a,d
069D: 32 8D CF    ld   ($EDC9),a
06A0: 32 4C CF    ld   ($EDC4),a
06A3: 3A B0 0E    ld   a,(TWO_PLAYER_FLAG)
06A6: A7          and  a
06A7: 28 30       jr   z,$06BB
06A9: CD 8C D8    call SHOW_PLAYER2_SCORE
06AC: 11 20 00    ld   de,$0002
06AF: FF          rst  ADD_DE_TO_EVENT
06B0: 21 0C CF    ld   hl,PLAYER1_DATA
06B3: 11 0E CF    ld   de,PLAYER2_DATA
06B6: 01 02 00    ld   bc,$0020
06B9: ED B0       ldir
06BB: CD 91 98    call $9819
06BE: 3E 06       ld   a,$60
06C0: 32 65 0E    ld   (COUNTDOWN_TIMER),a
06C3: CD 38 6B    call CLEAR_BACKGROUND
06C6: CD 7B 21    call CLEAR_SPRITES
06C9: CD 0C 68    call SFX_INTRO
06CC: C3 DE 41    jp   ADVANCE_STATUS2
06CF: 21 18 99    ld   hl,$9990
06D2: C3 28 60    jp   $0682

LEVEL_START_TABLE:	db	$00,$00
			db	$10,$20
			db	$04,$40
			db	$14,$60


06DD: CD 7B 21    call CLEAR_SPRITES
06E0: AF          xor  a
06E1: 32 F9 0E    ld   (AREA_END),a
06E4: CD 52 61    call CLEAR_SPRITE_TABLES
06E7: CD 2C 80    call SETUP_PLAYER_DATA
06EA: 11 0A CF    ld   de,PLAYER_LIVES
06ED: 01 02 00    ld   bc,$0020
06F0: ED B0       ldir
06F2: CD B9 61    call $079B
06F5: 16 81       ld   d,$09
06F7: FF          rst  ADD_DE_TO_EVENT
06F8: 16 A0       ld   d,$0A
06FA: FF          rst  ADD_DE_TO_EVENT
06FB: 16 C1       ld   d,$0D
06FD: FF          rst  ADD_DE_TO_EVENT
06FE: 3A 8A CF    ld   a,(NUM_GRENADES)		; read NUM_GRENADES
0701: FE 60       cp   $06
0703: 30 41       jr   nc,$070A
0705: 3E 60       ld   a,$06
0707: 32 8A CF    ld   (NUM_GRENADES),a		; update NUM_GRENADES
070A: 16 A1       ld   d,$0B
070C: FF          rst  ADD_DE_TO_EVENT
070D: CD E8 4B    call UPDATE_OVERLAY_OBJECTS
0710: 3A 0B CF    ld   a,($EDA1)		; seems always is a zero kind of pointless
0713: A7          and  a
0714: 20 A1       jr   nz,$0721
0716: 3E 0C       ld   a,$C0			; 3 second timer
0718: 32 65 0E    ld   (COUNTDOWN_TIMER),a
071B: CD 63 61    call $0727
071E: C3 DE 41    jp   ADVANCE_STATUS2

0721: CD 0C 68    call SFX_INTRO		; Intro Music
0724: C3 DE 41    jp   ADVANCE_STATUS2
0727: 3A 8B CF    ld   a,(AREAS_COMPLETED)
072A: E6 21       and  $03
072C: FE 21       cp   $03
072E: C2 AC 68    jp   nz,SFX_INTRO_ON
0731: C3 FC 68    jp   SFX_AREA4PLUS

CLEAR_SPRITE_TABLES:
0734: 21 00 6E    ld   hl,ENEMY_SPRITES
0737: 11 01 6E    ld   de,ENEMY_SPRITES+1
073A: 01 FF 00    ld   bc,$00FF
073D: 36 00       ld   (hl),$00
073F: ED B0       ldir
0741: 21 0C 2E    ld   hl,ENEMY_BULLETS
0744: 11 0D 2E    ld   de,ENEMY_BULLETS+1
0747: 01 FF 00    ld   bc,$00FF
074A: 36 00       ld   (hl),$00
074C: ED B0       ldir
074E: 21 00 4F    ld   hl,BACKGROUND_ITEMS
0751: 11 01 4F    ld   de,BACKGROUND_ITEMS+1
0754: 01 FF 00    ld   bc,$00FF
0757: 36 00       ld   (hl),$00
0759: ED B0       ldir
075B: 21 00 8E    ld   hl,TREE_ROCK_SPRITES
075E: 11 01 8E    ld   de,TREE_ROCK_SPRITES+1
0761: 01 E9 00    ld   bc,$008F
0764: 36 00       ld   (hl),$00
0766: ED B0       ldir
0768: C9          ret

0769: 3A 0B CF    ld   a,($EDA1)
076C: A7          and  a
076D: 20 D0       jr   nz,$078B
076F: 21 65 0E    ld   hl,COUNTDOWN_TIMER
0772: 35          dec  (hl)
0773: C2 8B 61    jp   nz,$07A9
0776: 16 81       ld   d,$09
0778: FF          rst  ADD_DE_TO_EVENT
0779: 16 A0       ld   d,$0A
077B: FF          rst  ADD_DE_TO_EVENT
077C: 16 A1       ld   d,$0B
077E: FF          rst  ADD_DE_TO_EVENT
077F: 16 C1       ld   d,$0D
0781: FF          rst  ADD_DE_TO_EVENT
0782: CD 60 89    call $8906
0785: 3E 40       ld   a,$04
0787: 32 01 0E    ld   (GAME_STATUS2),a
078A: C9          ret

078B: 21 0B CF    ld   hl,$EDA1
078E: 36 00       ld   (hl),$00
0790: 3E 06       ld   a,$60			; 1.6 Seconds timer!
0792: 32 65 0E    ld   (COUNTDOWN_TIMER),a
0795: CD DA 8B    call $A9BC
0798: C3 DE 41    jp   ADVANCE_STATUS2

079B: 3A 43 0E    ld   a,(IS_CABINET_UPRIGHT)
079E: A7          and  a
079F: C0          ret  nz
07A0: 3A 91 0E    ld   a,(PLAYER_UP)
07A3: E6 01       and  $01
07A5: 32 93 0E    ld   (IS_SCREEN_YFLIPPED),a
07A8: C9          ret

07A9: 11 C1 00    ld   de,$000D
07AC: FF          rst  ADD_DE_TO_EVENT
07AD: 3A 20 0E    ld   a,(FRAME_SYNC)
07B0: 47          ld   b,a
07B1: E6 E1       and  $0F
07B3: C0          ret  nz
07B4: 78          ld   a,b
07B5: 0F          rrca
07B6: 0F          rrca
07B7: 0F          rrca
07B8: 0F          rrca
07B9: E6 01       and  $01
07BB: 57          ld   d,a
07BC: 3A 91 0E    ld   a,(PLAYER_UP)
07BF: E6 01       and  $01
07C1: C6 A1       add  a,$0B
07C3: 5F          ld   e,a
07C4: FF          rst  ADD_DE_TO_EVENT
07C5: 16 C1       ld   d,$0D
07C7: FF          rst  ADD_DE_TO_EVENT
07C8: 16 A1       ld   d,$0B
07CA: C3 92 00    jp   ADD_DE_TO_EVENT
07CD: 3A 65 0E    ld   a,(COUNTDOWN_TIMER)
07D0: A7          and  a
07D1: 28 51       jr   z,$07E8
07D3: CD 8B 61    call $07A9
07D6: 21 65 0E    ld   hl,COUNTDOWN_TIMER
07D9: 35          dec  (hl)
07DA: 20 C0       jr   nz,$07E8
07DC: 16 81       ld   d,$09
07DE: FF          rst  ADD_DE_TO_EVENT
07DF: 16 A0       ld   d,$0A
07E1: FF          rst  ADD_DE_TO_EVENT
07E2: 16 A1       ld   d,$0B
07E4: FF          rst  ADD_DE_TO_EVENT
07E5: 16 C1       ld   d,$0D
07E7: FF          rst  ADD_DE_TO_EVENT
07E8: CD 21 AA    call $AA03
07EB: 3A 06 0F    ld   a,(HELICOPTER_DATA)
07EE: A7          and  a
07EF: C0          ret  nz
07F0: 32 02 4E    ld   ($E420),a
07F3: 32 DA 0E    ld   ($E0BC),a
07F6: CD 60 89    call $8906
07F9: C3 DE 41    jp   ADVANCE_STATUS2
07FC: CD 8B F9    call $9FA9
07FF: CD 81 F9    call $9F09
0802: CD 93 89    call $8939
0805: CD E3 63    call $272F
0808: CD EF 79    call $97EF
080B: CD F8 E1    call $0F9E
080E: CD D1 39    call $931D
0811: CD 39 E8    call $8E93
0814: CD 59 EA    call $AE95
0817: 3A 00 0F    ld   a,(PLAYER_DATA)
081A: A7          and  a
081B: 28 E5       jr   z,$086C
081D: 3A 0B 0E    ld   a,(COMPLETED_AREA_TIMER)
0820: A7          and  a
0821: C2 DE 41    jp   nz,ADVANCE_STATUS2
0824: 3A F9 0E    ld   a,(AREA_END)
0827: A7          and  a
0828: 20 42       jr   nz,$084E
082A: 3A D4 0E    ld   a,(MAP_OFFSET_H)
082D: A7          and  a
082E: C0          ret  nz
082F: 3A B5 0E    ld   a,(MAP_OFFSET)
0832: 3C          inc  a
0833: E6 F7       and  $7F
0835: C8          ret  z
0836: 47          ld   b,a
0837: E6 61       and  $07
0839: C0          ret  nz
083A: 3E 01       ld   a,$01			; Got to the ending of level
083C: 32 F9 0E    ld   (AREA_END),a
083F: 3D          dec  a
0840: 32 B0 0F    ld   ($E11A),a
0843: 3E 10       ld   a,$10			; now fight until this lot has depleted
0845: 32 0A 0E    ld   (ENDING_ENEMIES),a
0848: CD 2A 68    call SFX_STOP_SIREN		; Seem to just the siren when goto end of level ready to battle
084B: C3 9D 68    jp   SFX_RUMBLE
084E: 3A B0 0F    ld   a,($E11A)
0851: A7          and  a
0852: C0          ret  nz
0853: 3A 0A 0E    ld   a,(ENDING_ENEMIES)	; all out of the ending Area
0856: A7          and  a
0857: C0          ret  nz
0858: 3A 55 0E    ld   a,(ENEMY_SPRITE_COUNT)	; and check when all are out of tables
085B: A7          and  a
085C: C0          ret  nz
085D: 3C          inc  a			; make 1
085E: 32 B0 0F    ld   ($E11A),a		; now set close of the gates
0861: 3E 0C       ld   a,$C0
0863: 32 D0 0F    ld   ($E11C),a
0866: CD BB 68    call SFX_STOP
0869: C3 8E 68    jp   SFX_CLEARED
086C: 21 0A CF    ld   hl,PLAYER_LIVES
086F: 35          dec  (hl)
0870: 28 A2       jr   z,$089C
0872: CD ED 80    call $08CF
0875: CD 2C 80    call SETUP_PLAYER_DATA
0878: EB          ex   de,hl
0879: 21 0A CF    ld   hl,PLAYER_LIVES
087C: 01 02 00    ld   bc,$0020
087F: ED B0       ldir
0881: 3A B0 0E    ld   a,(TWO_PLAYER_FLAG)
0884: A7          and  a
0885: 28 E1       jr   z,$0896
0887: 21 91 0E    ld   hl,PLAYER_UP
088A: 34          inc  (hl)
088B: CD 2C 80    call SETUP_PLAYER_DATA
088E: 7E          ld   a,(hl)
088F: A7          and  a
0890: 20 40       jr   nz,$0896
0892: 21 91 0E    ld   hl,PLAYER_UP
0895: 34          inc  (hl)
0896: 3E 01       ld   a,$01
0898: 32 01 0E    ld   (GAME_STATUS2),a
089B: C9          ret

089C: 11 E0 00    ld   de,$000E
089F: FF          rst  ADD_DE_TO_EVENT
08A0: 3A 91 0E    ld   a,(PLAYER_UP)
08A3: E6 01       and  $01
08A5: C6 A1       add  a,$0B
08A7: 5F          ld   e,a
08A8: FF          rst  ADD_DE_TO_EVENT
08A9: CD 2C 80    call SETUP_PLAYER_DATA
08AC: 36 00       ld   (hl),$00
08AE: CD D3 68    call SFX_STOP_SFX
08B1: CD BB 68    call SFX_STOP
08B4: CD 3E 68    call SFX_GAMEOVER
08B7: 3E 5A       ld   a,$B4
08B9: 32 65 0E    ld   (COUNTDOWN_TIMER),a
08BC: 3E 80       ld   a,$08
08BE: 32 01 0E    ld   (GAME_STATUS2),a
08C1: C9          ret

SETUP_PLAYER_DATA:
08C2: 21 0C CF    ld   hl,PLAYER1_DATA		; Player 1 values
08C5: 3A 91 0E    ld   a,(PLAYER_UP)		; check is it's player 2 playing
08C8: E6 01       and  $01
08CA: C8          ret  z			; return if 0
08CB: 21 0E CF    ld   hl,PLAYER2_DATA		; otherwise point to player 2 values
08CE: C9          ret

		; This resets the map offsets to a pre-set location offset
		
08CF: DD 21 DE 80 ld   ix,START_TABLE		; level number start offsets
08D3: ED 5B 2A CF ld   de,(MAP_OFFSET_HIGH)
08D7: 01 20 00    ld   bc,$0002			; 2 bytes / entry
08DA: 21 00 00    ld   hl,$0000
08DD: 22 2A CF    ld   (MAP_OFFSET_HIGH),hl	; clear out
08E0: DD 66 01    ld   h,(ix+$01)		; hi
08E3: DD 6E 00    ld   l,(ix+$00)		; low
08E6: A7          and  a			; sec carry flag?
08E7: ED 52       sbc  hl,de			; subtract from offset table
08E9: 30 81       jr   nc,$08F4			; negative then reached where need go
08EB: 19          add  hl,de			; add back 
08EC: 22 2A CF    ld   (MAP_OFFSET_HIGH),hl	; save
08EF: DD 09       add  ix,bc			; advance on
08F1: C3 0E 80    jp   $08E0			; try another value
08F4: 7C          ld   a,h
08F5: B5          or   l
08F6: C0          ret  nz
08F7: 19          add  hl,de			; add back subtraction
08F8: 22 2A CF    ld   (MAP_OFFSET_HIGH),hl	; save it then.
08FB: C9          ret

START_TABLE:
		dw	$0000	; Level Start Offset Values 0
		dw	$0180	; Level Start Offset Values 1
		dw	$0300	; Level Start Offset Values 2
		dw	$0300	; Level Start Offset Values 3
		dw	$04c0	; Level Start Offset Values 4
		dw	$0640	; Level Start Offset Values 5
		dw	$0800	; Level Start Offset Values 6
		dw	$0980	; Level Start Offset Values 7
		dw	$0ac0	; Level Start Offset Values 8
		dw	$0c80	; Level Start Offset Values 9
		dw	$0e00	; Level Start Offset Values A
		dw	$1000	; Level Start Offset Values B
		dw	$11c0	; Level Start Offset Values C
		dw	$1480	; Level Start Offset Values D
		dw	$1600	; Level Start Offset Values E
		dw	$1800	; Level Start Offset Values F
		dw	$1980	; Level Start Offset Values 10
		dw	$1b40	; Level Start Offset Values 11
		dw	$1d40	; Level Start Offset Values 12
		dw	$1e40	; Level Start Offset Values 13
		dw	$4000	; Level Start Offset Values 14
		dw	$41c0	; Level Start Offset Values 15
		dw	$4300	; Level Start Offset Values 16
		dw	$4480	; Level Start Offset Values 17
		dw	$45c0	; Level Start Offset Values 18
		dw	$4800	; Level Start Offset Values 19
		dw	$4980	; Level Start Offset Values 1A
		dw	$4b00	; Level Start Offset Values 1B
		dw	$4c80	; Level Start Offset Values 1C
		dw	$4dc0	; Level Start Offset Values 1D
		dw	$5000	; Level Start Offset Values 1E
		dw	$51c0	; Level Start Offset Values 1F
		dw	$52c0	; Level Start Offset Values 20
		dw	$5480	; Level Start Offset Values 21
		dw	$5640	; Level Start Offset Values 22
		dw	$5800	; Level Start Offset Values 23
		dw	$5900	; Level Start Offset Values 24
		dw	$5ac0	; Level Start Offset Values 25
		dw	$5cc0	; Level Start Offset Values 26
		dw	$5e40	; Level Start Offset Values 27

		
LEVEL_COMPLETED:
094C: CD A7 81    call $096B
094F: CD 85 E0    call SHOW_AREA_COMPLETED
0952: AF          xor  a
0953: 32 F9 0E    ld   (AREA_END),a
0956: 3E 87       ld   a,$69			; Countdown for the splash screen
0958: 32 0B 0E    ld   (COMPLETED_AREA_TIMER),a
095B: 3A 8B CF    ld   a,(AREAS_COMPLETED)
095E: E6 21       and  $03
0960: FE 21       cp   $03
0962: C2 DE 41    jp   nz,ADVANCE_STATUS2
0965: CD CF 68    call SFX_HIGHSCORE
0968: C3 DE 41    jp   ADVANCE_STATUS2

096B: CD 7B 21    call CLEAR_SPRITES
096E: 3A 8B CF    ld   a,(AREAS_COMPLETED)
0971: E6 21       and  $03
0973: FE 21       cp   $03
0975: 28 A1       jr   z,$0982
0977: CD 38 6B    call CLEAR_BACKGROUND
097A: 3E 01       ld   a,$01
097C: 32 A1 8C    ld   (Y-SCROLL-HI),a
097F: C3 18 81    jp   $0990

0982: 21 08 20    ld   hl,$0280
0985: 22 5B 0E    ld   ($E0B5),hl
0988: 3E 00       ld   a,$00
098A: 32 7B 0E    ld   ($E0B7),a
098D: C3 67 8A    jp	HELICOPTER_RIDE		; $A867

0990: 3A 8B CF    ld   a,(AREAS_COMPLETED)
0993: E6 61       and  $07
0995: 21 5B 81    ld   hl,$09B5
0998: EF          rst  $28
0999: 21 78 BC    ld   hl,$DA96			; x=84, y=09
099C: 0E 21       ld   c,$03			; 3 across
099E: 06 40       ld   b,$04			; 4 down 24 bytes in total for each table entry
09A0: 1A          ld   a,(de)
09A1: 13          inc  de
09A2: 77          ld   (hl),a
09A3: 1A          ld   a,(de)
09A4: CB D4       set  2,h
09A6: 77          ld   (hl),a
09A7: CB 94       res  2,h
09A9: 23          inc  hl
09AA: 13          inc  de
09AB: 10 3F       djnz $09A0
09AD: 0D          dec  c
09AE: C8          ret  z

09AF: 3E D0       ld   a,$1C
09B1: DF          rst	ADD_A_TO_HL
09B2: C3 F8 81    jp   $099E

09B5: 		dw	$09c5	; Area Complete 0
		dw	$09dd	; Area Complete 1
		dw	$09f5	; Area Complete 2
		dw	$09f5	; Area Complete 3
		dw	$0a0d	; Area Complete 4
		dw	$0a25	; Area Complete 5
		dw	$0a3d	; Area Complete 6
		dw	$0a3d	; Area Complete 7
		
09c5:		db	70,c5,71,c5,72,c5,f8,00,f8,00,69,c5,6a,c5,f8,00,f8,00,f8,00,62,c5,63,c5
09dd:		db	f8,00,73,c5,74,c5,f8,00,f8,00,6b,c5,6c,c5,f8,00,f8,00,73,c5,64,c5,f8,00
09f5:		db	f8,00,6d,c5,6e,c5,f8,00,f8,00,65,c5,66,c5,f8,00,f8,00,f8,00,f8,00,f8,00
0a0d:		db	f8,00,d8,c5,d0,c5,f8,00,f8,00,f8,00,c8,c5,f8,00,f8,00,f8,00,c0,c5,f8,00
0a25:		db	c9,c5,d0,c5,d0,e5,c9,e5,c1,c5,f8,00,f8,00,c1,e5,f8,00,f8,00,c0,c5,f8,00
0a3d:		db	f8,00,6d,c5,6e,c5,f8,00,f8,00,f8,00,66,c5,f8,00,f8,00,f8,00,f8,00,f8,00
0a55:		db	f8,00,f8,00,f8,00,f8,00,f8,00,f8,00,f8,00,f8,00,f8,00,f8,00,f8,00,f8,00

0A6D: CD 06 E0    call MESSAGE_UPDATE
0A70: 3A 8B CF    ld   a,(AREAS_COMPLETED)
0A73: E6 21       and  $03
0A75: FE 21       cp   $03
0A77: C2 6E A0    jp   nz,$0AE6
0A7A: 3A 00 0F    ld   a,(PLAYER_DATA)
0A7D: A7          and  a
0A7E: C4 6A 88    call nz,$88A6
0A81: CD 8A 8A    call $A8A8
0A84: 3A 06 0F    ld   a,(HELICOPTER_DATA)
0A87: A7          and  a
0A88: CA 51 A1    jp   z,$0B15
0A8B: 3A 7B 0E    ld   a,($E0B7)
0A8E: 3D          dec  a
0A8F: C0          ret  nz
0A90: 2A 5B 0E    ld   hl,($E0B5)
0A93: 2B          dec  hl
0A94: 7C          ld   a,h
0A95: B5          or   l
0A96: 22 5B 0E    ld   ($E0B5),hl
0A99: 28 C2       jr   z,$0AC7
0A9B: CD AA A0    call $0AAA
0A9E: 21 00 01    ld   hl,$0100
0AA1: 22 75 0E    ld   ($E057),hl
0AA4: CD 81 F9    call $9F09
0AA7: C3 81 F9    jp   $9F09

0AAA: 3A 20 0E    ld   a,(FRAME_SYNC)
0AAD: 47          ld   b,a
0AAE: E6 F1       and  $1F
0AB0: C0          ret  nz
0AB1: 3A 8B CF    ld   a,(AREAS_COMPLETED)
0AB4: 0F          rrca
0AB5: E6 20       and  $02
0AB7: 1E 63       ld   e,$27
0AB9: 83          add  a,e
0ABA: 5F          ld   e,a
0ABB: 16 00       ld   d,$00
0ABD: CB 68       bit  5,b
0ABF: CA 2D A0    jp   z,$0AC3
0AC2: 14          inc  d
0AC3: FF          rst  ADD_DE_TO_EVENT

0AC4: 1C          inc  e
0AC5: FF          rst  ADD_DE_TO_EVENT
0AC6: C9          ret
0AC7: 3E 20       ld   a,$02
0AC9: 32 7B 0E    ld   ($E0B7),a
0ACC: AF          xor  a
0ACD: 32 65 0E    ld   (COUNTDOWN_TIMER),a
0AD0: 32 0B 0E    ld   (COMPLETED_AREA_TIMER),a
0AD3: 21 00 04    ld   hl,TREES_ROCKS_TABLE		; Trees and rocks
0AD6: 3A B5 0E    ld   a,(MAP_OFFSET)
0AD9: 84          add  a,h
0ADA: E6 04       and  $40
0ADC: 67          ld   h,a
0ADD: 22 2A CF    ld   (MAP_OFFSET_HIGH),hl
0AE0: CD 52 61    call CLEAR_SPRITE_TABLES
0AE3: C3 E8 4B    jp   UPDATE_OVERLAY_OBJECTS
0AE6: FD 21 92 FF ld   iy,PLAYER_SPRITE
0AEA: CD 82 A1    call $0B28
0AED: 3A 0B 0E    ld   a,(COMPLETED_AREA_TIMER)
0AF0: A7          and  a
0AF1: C0          ret  nz
0AF2: AF          xor  a
0AF3: 32 64 FF    ld   ($FF46),a
0AF6: 11 8D A1    ld   de,$0BC9
0AF9: CD 68 A1    call $0B86
0AFC: 11 55 A0    ld   de,$0A55
0AFF: CD 99 81    call $0999
0B02: CD 7B 21    call CLEAR_SPRITES
0B05: 2A 2A CF    ld   hl,(MAP_OFFSET_HIGH)
0B08: 11 00 01    ld   de,$0100				; Advance level map offset by $100 ie next Area
0B0B: 19          add  hl,de
0B0C: 22 2A CF    ld   (MAP_OFFSET_HIGH),hl		; save new pointer
0B0F: CD 52 61    call CLEAR_SPRITE_TABLES
0B12: CD E8 4B    call UPDATE_OVERLAY_OBJECTS
0B15: 21 8B CF    ld   hl,AREAS_COMPLETED		; How many we completed?
0B18: 34          inc  (hl)				; well looks like we done another one. Yah!
0B19: 16 81       ld   d,$09
0B1B: FF          rst  ADD_DE_TO_EVENT
0B1C: 16 C1       ld   d,$0D
0B1E: FF          rst  ADD_DE_TO_EVENT
0B1F: 16 A0       ld   d,$0A
0B21: FF          rst  ADD_DE_TO_EVENT
0B22: 16 A1       ld   d,$0B
0B24: FF          rst  ADD_DE_TO_EVENT
0B25: C3 DE 41    jp   ADVANCE_STATUS2
0B28: CD 72 A1    call $0B36
0B2B: 3A 20 0E    ld   a,(FRAME_SYNC)
0B2E: E6 21       and  $03
0B30: C0          ret  nz
0B31: 21 0B 0E    ld   hl,COMPLETED_AREA_TIMER
0B34: 35          dec  (hl)
0B35: C0          ret  nz
0B36: 3A 8B CF    ld   a,(AREAS_COMPLETED)
0B39: E6 61       and  $07
0B3B: 21 DD A1    ld   hl,$0BDD
0B3E: EF          rst  $28		  ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
0B3F: EB          ex   de,hl
0B40: 3A 20 0E    ld   a,(FRAME_SYNC)
0B43: 0F          rrca
0B44: 0F          rrca
0B45: 0F          rrca
0B46: 0F          rrca
0B47: E6 E1       and  $0F
0B49: 32 2A 0E    ld   ($E0A2),a
0B4C: 0F          rrca
0B4D: E6 61       and  $07
0B4F: DD 21 1D A1 ld   ix,$0BD1
0B53: EF          rst  $28	                 ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
0B54: CD 88 A3    call HW_SPRITE_UPDATER
0B57: 3A 8B CF    ld   a,(AREAS_COMPLETED)
0B5A: E6 61       and  $07
0B5C: 28 03       jr   z,$0B7F
0B5E: FE 40       cp   $04
0B60: 28 21       jr   z,$0B65
0B62: FE 41       cp   $05
0B64: C0          ret  nz
0B65: DD 21 7D A1 ld   ix,$0BD7
0B69: 3A 20 0E    ld   a,(FRAME_SYNC)
0B6C: 0F          rrca
0B6D: 0F          rrca
0B6E: E6 21       and  $03
0B70: 21 77 A1    ld   hl,$0B77
0B73: EF          rst	INDEX_ED_AT_2A_PLUS_HL

0B74: C3 9C D0    jp   SPRITE_UPDATE_DE


0B77: 		db	$73,$80,$74,$80,$7c,$80,$74,$88


0B7F: 21 0B A1    ld   hl,$0BA1
0B82: 3A 2A 0E    ld   a,($E0A2)
0B85: EF          rst	INDEX_ED_AT_2A_PLUS_HL
0B86: 21 ED 1D    ld   hl,$D1CF
0B89: 0E 20       ld   c,$02				;  display a 2x2 block
0B8B: 06 20       ld   b,$02
0B8D: 1A          ld   a,(de)
0B8E: 77          ld   (hl),a
0B8F: CB D4       set  2,h
0B91: 36 E1       ld   (hl),$0F
0B93: CB 94       res  2,h
0B95: 13          inc  de
0B96: 2B          dec  hl
0B97: 10 5E       djnz $0B8D
0B99: 0D          dec  c
0B9A: C8          ret  z
0B9B: 3E 22       ld   a,$22
0B9D: DF          rst	ADD_A_TO_HL
0B9E: C3 A9 A1    jp   $0B8B

0BA1:		dw	$0bc1,$0bc5	; Table 0
		dw	$0bc1,$0bc5	; Table 1
		dw	$0bc1,$0bc5	; Table 2	
		dw	$0bc1,$0bc5	; Table 3	
		dw	$0bc9,$0bc9	; Table 4
		dw	$0bc1,$0bc5	; Table 5
		dw	$0bc1,$0bc5	; Table 6
		dw	$0bc1,$0bcd	; Table 7

0bc1:		db	$a9, $b9
0bc3:		db	$af, $af
0bc5:		db	$aa, $ba
0bc7:		db	$af, $af
0bc9:		db	$af, $af
0bcb:		db	$af, $af
0bcd:		db	$af, $ab
0bcf:		db	$af, $ac

0BD1:		dw	$0bed	; Table 0
		dw	$0c0d	; Table 1
		dw	$0c3b	; Table 2
		dw	$0c3b	; Table 3
		dw	$0c73	; Table 4
		dw	$0c97	; Table 5	
		dw	$0cbf	; Table 6
		dw	$0cbf	; Table 7
		dw	$0bfd	; Table 8
		dw	$0bfd	; Table 9
		dw	$0bfd	; Table A
		dw	$0bfd	; Table B
		dw	$0c05	; Table C
		dw	$0bfd	; Table D
		dw	$0bfd	; Table E
		dw	$0bfd	; Table F
		
0bed:	dw	$0bfd
0bef:	dw	$0bfd
0bf1:	dw	$0bfd
0bf3:	dw	$0bfd
0bf5:	dw	$0c05
0bf7:	dw	$0bfd
0bf9:	dw	$0bfd
0bfb:	dw	$0bfd
0bfd:	db	$03, $80, $01, $94, $11, $95, $00, $9c
0bfd:	db	$03, $80, $01, $94, $11, $95, $00, $9c
0c05:	db	$03, $80, $01, $80, $11, $81, $00, $88


0c0d:	dw	$0c31
0c0f:	dw	$0c31
0c11:	dw	$0c31
0c13:	dw	$0c1d
0c15:	dw	$0c27
0c17:	dw	$0c1d
0c19:	dw	$0c27
0c1b:	dw	$0c1d
0c1d:	db	$04, $80, $01, $82, $11, $83, $f0, $89, $00, $8a
0c27:	db	$04, $80, $f1, $84, $01, $85, $11, $86, $00, $8d
0c31:	db	$04, $80, $01, $8e, $11, $8f, $00, $96, $00, $ff

0c3b:	dw	$0c4b
0c3d:	dw	$0c55
0c3f:	dw	$0c5f
0c41:	dw	$0c69
0c43:	dw	$0c5f
0c45:	dw	$0c69
0c47:	dw	$0c5f
0c49:	dw	$0c69
0c4b:	db	$04, $80, $01, $90, $11, $91, $00, $98, $10, $99
0c55:	db	$04, $80, $01, $92, $11, $93, $00, $9a, $10, $9b
0c5f:	db	$04, $80, $01, $90, $11, $91, $00, $98, $10, $99
0c69:	db	$04, $80, $01, $8b, $11, $8c, $00, $98, $10, $99

0c73:	dw	$0c83
0c75:	dw	$0c8d
0c77:	dw	$0c83
0c79:	dw	$0c8d
0c7b:	dw	$0c83
0c7d:	dw	$0c8d
0c7f:	dw	$0c83
0c81:	dw	$0c8d
0c83:	db	$04, $80, $01, $90, $11, $91, $00, $60, $0f, $68
0c8d:	db	$04, $80, $01, $90, $11, $91, $00, $61, $0f, $69

0c97:	dw	$0ca7
0c99:	dw	$0cb3
0c9b:	dw	$0ca7
0c9d:	dw	$0cb3
0c9f:	dw	$0ca7
0ca1:	dw	$0cb3
0ca3:	dw	$0ca7
0ca5:	dw	$0cb3
0ca7:	db	$05, $80, $01, $90, $11, $91, $00, $60, $0f, $78, $1f, $79
0cb3:	db	$05, $80, $01, $90, $11, $91, $00, $61, $0f, $7a, $1f, $7b
0cb3:	db	$05, $80, $01, $90, $11, $91, $00, $61, $0f, $7a, $1f, $7b

0cbf:	dw	$0ccf
0cc1:	dw	$0cdd
0cc3:	dw	$0ccf
0cc5:	dw	$0cdd
0cc7:	dw	$0ccf
0cc9:	dw	$0cdd
0ccb:	dw	$0ccf
0ccd:	dw	$0cdd
0ccf:	db	$06, $80, $01, $90, $11, $63, $21, $62, $00, $6a, $10, $6b, $0f, $72
0cdd:	db	$06, $80, $01, $90, $11, $63, $21, $62, $00, $70, $10, $71, $0f, $72


0CEB: 16 41       ld   d,$05
0CED: 1E 10       ld   e,$10
0CEF: FF          rst	ADD_DE_TO_EVENT

0CF0: 21 4A CF    ld   hl,GAME_LEVEL
0CF3: 34          inc  (hl)		; advance to next area level
0CF4: 7E          ld   a,(hl)
0CF5: E6 61       and  $07		; just repeat 0 - 7 all time even if you are a super player.
0CF7: 77          ld   (hl),a		; save
0CF8: CD 81 C1    call $0D09
0CFB: CD 60 89    call $8906
0CFE: 3E 40       ld   a,$04
0D00: 32 01 0E    ld   (GAME_STATUS2),a
0D03: 3E 00       ld   a,$00
0D05: 32 A1 8C    ld   (Y-SCROLL-HI),a
0D08: C9          ret

0D09: 3A 8B CF    ld   a,(AREAS_COMPLETED)
0D0C: E6 21       and  $03
0D0E: FE 21       cp   $03
0D10: C2 70 C1    jp   nz,$0D16
0D13: C3 2F 68    jp   SFX_MISSION2
0D16: CD BB 68    call SFX_STOP
0D19: C3 5C 68    jp   SFX_GAMELOOP		; Main game looping background playing music
0D1C: 3A 20 0E    ld   a,(FRAME_SYNC)
0D1F: CB 47       bit  0,a
0D21: C0          ret  nz
0D22: 21 65 0E    ld   hl,COUNTDOWN_TIMER
0D25: 35          dec  (hl)
0D26: C0          ret  nz
0D27: CD 81 60    call CLEAR_INFO_DISPLAY
0D2A: CD 7B 21    call CLEAR_SPRITES
0D2D: CD 41 E0    call $0E05
0D30: 3A 6A 0E    ld   a,(CURRENT_SCORE)
0D33: FE 80       cp   $08
0D35: 28 50       jr   z,$0D4B
0D37: 11 03 00    ld   de,$0021
0D3A: FF          rst  ADD_DE_TO_EVENT
0D3B: 11 22 00    ld   de,$0022
0D3E: FF          rst  ADD_DE_TO_EVENT
0D3F: CD F4 98    call $985E
0D42: CD F5 98    call $985F
0D45: CD 7F 68    call SFX_INTOHIGH
0D48: C3 DE 41    jp   ADVANCE_STATUS2
0D4B: 3A B0 0E    ld   a,(TWO_PLAYER_FLAG)
0D4E: A7          and  a
0D4F: 28 A1       jr   z,$0D5C
0D51: 21 91 0E    ld   hl,PLAYER_UP
0D54: 34          inc  (hl)
0D55: CD 2C 80    call SETUP_PLAYER_DATA
0D58: 7E          ld   a,(hl)
0D59: A7          and  a
0D5A: 20 11       jr   nz,$0D6D
0D5C: 16 81       ld   d,$09
0D5E: FF          rst  ADD_DE_TO_EVENT
0D5F: 3E 01       ld   a,$01
0D61: 32 00 0E    ld   (GAME_STATUS1),a
0D64: 3E 00       ld   a,$00
0D66: 32 01 0E    ld   (GAME_STATUS2),a
0D69: 32 93 0E    ld   (IS_SCREEN_YFLIPPED),a
0D6C: C9          ret

0D6D: 3E 01       ld   a,$01
0D6F: 32 01 0E    ld   (GAME_STATUS2),a
0D72: C9          ret

0D73: CD 43 99    call $9925
0D76: 3A 71 0E    ld   a,($E017)
0D79: A7          and  a
0D7A: C8          ret  z
0D7B: CD 7B 21    call CLEAR_SPRITES
0D7E: CD 4B C1    call $0DA5
0D81: 16 61       ld   d,$07
0D83: FF          rst  ADD_DE_TO_EVENT
0D84: CD A8 C1    call $0D8A
0D87: C3 DE 41    jp   ADVANCE_STATUS2

0D8A: CD D3 68    call SFX_STOP_SFX
0D8D: CD BB 68    call SFX_STOP_MUS
0D90: 3E 94       ld   a,$58
0D92: 32 65 0E    ld   (COUNTDOWN_TIMER),a
0D95: 3A 6A 0E    ld   a,(CURRENT_SCORE)
0D98: FE 01       cp   $01
0D9A: C2 01 69    jp   nz,SFX_AFTERHIGH
0D9D: 3E 98       ld   a,$98
0D9F: 32 65 0E    ld   (COUNTDOWN_TIMER),a
0DA2: C3 DE 68    jp   SFX_TOPSCORE
0DA5: 16 81       ld   d,$09
0DA7: FF          rst  ADD_DE_TO_EVENT
0DA8: 3A 6A 0E    ld   a,(CURRENT_SCORE)
0DAB: FE 61       cp   $07
0DAD: 28 10       jr   z,$0DBF
0DAF: 21 1F C1    ld   hl,$0DF1
0DB2: 3D          dec  a
0DB3: DF          rst	ADD_A_TO_HL
0DB4: 4E          ld   c,(hl)
0DB5: 06 00       ld   b,$00
0DB7: 11 B4 EE    ld   de,$EE5A
0DBA: 21 C5 EE    ld   hl,$EE4D
0DBD: ED B8       lddr
0DBF: 21 2F C1    ld   hl,$0DE3
0DC2: 3A 6A 0E    ld   a,(CURRENT_SCORE)
0DC5: 3D          dec  a
0DC6: EF          rst  $28		 ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
0DC7: 21 19 EE    ld   hl,PLAYER1_SCORE
0DCA: 3A 91 0E    ld   a,(PLAYER_UP)
0DCD: E6 01       and  $01
0DCF: 28 21       jr   z,$0DD4
0DD1: 21 58 EE    ld   hl,PLAYER2_SCORE
0DD4: ED A0       ldi
0DD6: ED A0       ldi
0DD8: ED A0       ldi
0DDA: 21 B8 EE    ld   hl,$EE9A
0DDD: 01 A0 00    ld   bc,$000A
0DE0: ED B0       ldir
0DE2: C9          ret

0DE3:	dw	$ee00	; High Score Table Entry 0
	dw	$ee0d	; High Score Table Entry 1
	dw	$ee1a	; High Score Table Entry 2
	dw	$ee27	; High Score Table Entry 3
	dw	$ee34	; High Score Table Entry 4
	dw	$ee41	; High Score Table Entry 5
	dw	$ee4e	; High Score Table Entry 6
	
0DF1:	db	$e4	; seems an unused byte?

0DF2: 05          dec  b
0DF3: 52          ld   d,d
0DF4: 63          ld   h,e
0DF5: B0          or   b
0DF6: C1          pop  bc
0DF7: 3A 20 0E    ld   a,(FRAME_SYNC)
0DFA: E6 21       and  $03
0DFC: C0          ret  nz
0DFD: 21 65 0E    ld   hl,COUNTDOWN_TIMER
0E00: 35          dec  (hl)
0E01: C0          ret  nz
0E02: C3 A5 C1    jp   $0D4B

0E05: 3E 80       ld   a,$08
0E07: 32 6A 0E    ld   (CURRENT_SCORE),a
0E0A: 11 19 EE    ld   de,PLAYER1_SCORE
0E0D: 3A 91 0E    ld   a,(PLAYER_UP)
0E10: E6 01       and  $01
0E12: 28 21       jr   z,$0E17
0E14: 11 58 EE    ld   de,PLAYER2_SCORE
0E17: 21 E4 EE    ld   hl,$EE4E
0E1A: 0E 61       ld   c,$07
0E1C: 22 CA 0E    ld   ($E0AC),hl
0E1F: ED 53 AA 0E ld   ($E0AA),de
0E23: 06 21       ld   b,$03
0E25: 1A          ld   a,(de)
0E26: BE          cp   (hl)
0E27: 28 40       jr   z,$0E2D
0E29: 38 D1       jr   c,$0E48
0E2B: 18 40       jr   $0E31
0E2D: 13          inc  de
0E2E: 23          inc  hl
0E2F: 10 5E       djnz $0E25
0E31: 3A 6A 0E    ld   a,(CURRENT_SCORE)
0E34: 3D          dec  a
0E35: 32 6A 0E    ld   (CURRENT_SCORE),a
0E38: 2A CA 0E    ld   hl,($E0AC)
0E3B: ED 5B AA 0E ld   de,($E0AA)
0E3F: 7D          ld   a,l
0E40: D6 C1       sub  $0D
0E42: 6F          ld   l,a
0E43: 0D          dec  c
0E44: C2 D0 E0    jp   nz,$0E1C
0E47: C9          ret
0E48: C9          ret

SHOW_AREA_COMPLETED:
0E49: 21 8B CF    ld   hl,AREAS_COMPLETED	; Area completed message number
0E4C: 7E          ld   a,(hl)			; Get number
0E4D: E6 61       and  $07			; only 8 entries needed
0E4F: 21 59 E0    ld   hl,MESSAGE_LOOKUP	; End of level message table
0E52: EF          rst	INDEX_ED_AT_2A_PLUS_HL
0E53: EB          ex   de,hl
0E54: 5E          ld   e,(hl)
0E55: 23          inc  hl
0E56: 56          ld   d,(hl)
0E57: 23          inc  hl
0E58: ED 53 1B 0E ld   (MESSAGE_VIDEO_RAM),de
0E5C: 22 3B 0E    ld   (MESSAGE_TODISPLAY),hl
0E5F: C9          ret


;
; MESSAGE_VIDEO_RAM = pointer to video RAM
; MESSAGE_TODISPLAY = pointer to text to print
;
MESSAGE_UPDATE:
0E60: 3A 20 0E    ld   a,(FRAME_SYNC)	; slow message print only print on 4th sync
0E63: E6 21       and  $03
0E65: C0          ret  nz
0E66: ED 5B 1B 0E ld   de,(MESSAGE_VIDEO_RAM)
0E6A: 2A 3B 0E    ld   hl,(MESSAGE_TODISPLAY)
0E6D: 7E          ld   a,(hl)
0E6E: FE 04       cp   $40			; "@" end of message display
0E70: C8          ret  z			; Yes ok let's get out of dodge.
0E71: FE 23       cp   $23
0E73: 28 31       jr   z,$0E88
0E75: 12          ld   (de),a			; blast that video character memory
0E76: 23          inc  hl
0E77: 22 3B 0E    ld   (MESSAGE_TODISPLAY),hl
0E7A: 21 02 00    ld   hl,$0020			; next character along is 32 bytes as we know
0E7D: 19          add  hl,de			; update pointer
0E7E: 22 1B 0E    ld   (MESSAGE_VIDEO_RAM),hl
0E81: FE 02       cp   $20
0E83: C8          ret  z
0E84: C3 65 68    jp   SFX_BLEEP
0E87: C9          ret

0E88: 23          inc  hl			; Advance message pointer
0E89: 5E          ld   e,(hl)
0E8A: 23          inc  hl
0E8B: 56          ld   d,(hl)		; 
0E8C: ED 53 1B 0E ld   (MESSAGE_VIDEO_RAM),de	; save back to display source
0E90: 23          inc  hl
0E91: 22 3B 0E    ld   (MESSAGE_TODISPLAY),hl	
0E94: C9          ret


MESSAGE_LOOKUP:	dw	BROKE_MESS1,BROKE_MESS2,BROKE_MESS3,BROKE_MESS5
		dw	BROKE_MESS1,BROKE_MESS2,BROKE_MESS3,BROKE_MESS7

BROKE_MESS1:	dw	$D094
		db	"BROKE THE 1ST AREA#NOW RUSH TO THE 2ND AREA@"
BROKE_MESS2:	dw	$D094
		db	"BROKE THE 2ND AREA#NOW RUSH TO THE 3RD AREA@"
BROKE_MESS3:	dw	$D0B4
		db	"BROKE THE 3RD AREA#NOW RUSH TO THE LAST AREA@"
BROKE_MESS4:	dw	CHARACTER_RAM
		db	"@"
BROKE_MESS5:	dw	$D096
		db	"     CONGRATULATION#YOUR FIRST DUTY FINISHED@"
BROKE_MESS6:	dw	CHARACTER_RAM
		db	"@"
BROKE_MESS7:	dw	$D096
		db	"     CONGRATULATION#YOUR EVERY DUTY FINISHED@"

0E95:	dw	$0ea5	; Fred 0
	dw	$0ed5	; Fred 1
	dw	$0f05	; Fred 2
	dw	$0f36	; Fred 3
	dw	$0ea5	; Fred 4
	dw	$0ed5	; Fred 5
	dw	$0f05	; Fred 6
	dw	$0f6a	; Fred 7

0ea5:	db	$94, $d0, $42, $52, $4f, $4b, $45, $20, $54, $48, $45, $20, $31, $53, $54, $20, $41, $52, $45, $41, $23, $92, $d0, $4e
	db	$4f, $57, $20, $52, $55, $53, $48, $20, $54, $4f, $20, $54, $48, $45, $20, $32, $4e, $44, $20, $41, $52, $45, $41, $40

0ed5:	db	$94, $d0, $42, $52, $4f, $4b, $45, $20, $54, $48, $45, $20, $32, $4e, $44, $20, $41, $52, $45, $41, $23, $92, $d0, $4e
	db	$4f, $57, $20, $52, $55, $53, $48, $20, $54, $4f, $20, $54, $48, $45, $20, $33, $52, $44, $20, $41, $52, $45, $41, $40

0f05:   db      $b4, $d0, $42, $52, $4f, $4b, $45, $20, $54, $48, $45, $20, $33, $52, $44, $20, $41, $52, $45, $41, $23, $b2, $d0, $4e
	db      $4f, $57, $20, $52, $55, $53, $48, $20, $54, $4f, $20, $54, $48, $45, $20, $4c, $41, $53, $54, $20, $41, $52, $45, $41,$40

0f36:	db	$00, $d0, $40, $96, $d0, $20, $20, $20, $20, $20, $43, $4f, $4e, $47, $52, $41, $54, $55, $4c, $41, $54, $49, $4f, $4e, $23, $94, $d0, $59
	db	$4f, $55, $52, $20, $46, $49, $52, $53, $54, $20, $44, $55, $54, $59, $20, $46, $49, $4e, $49, $53, $48, $45, $44, $40

0f6a:   db      $00, $d0, $40, $96, $d0, $20, $20, $20, $20, $20, $43, $4f, $4e, $47, $52, $41, $54, $55, $4c, $41, $54, $49, $4f, $4e, $23, $94, $d0, $59
	db      $4f, $55, $52, $20, $45, $56, $45, $52, $59, $20, $44, $55, $54, $59, $20, $46, $49, $4e, $49, $53, $48, $45, $44, $40


		; Enemy Sprites update routine
0F9E: AF          xor  a
0F9F: 32 55 0E    ld   (ENEMY_SPRITE_COUNT),a
0FA2: DD 21 00 6E ld   ix,ENEMY_SPRITES
0FA6: FD 21 9C FE ld   iy,HW_SPRITE_54
0FAA: 06 80       ld   b,$08
0FAC: C5          push bc
0FAD: DD 7E 00    ld   a,(ix+TABLE_STATUS)
0FB0: A7          and  a
0FB1: 28 E1       jr   z,$0FC2
0FB3: 21 55 0E    ld   hl,ENEMY_SPRITE_COUNT
0FB6: 34          inc  (hl)
0FB7: 21 2C E1    ld   hl,$0FC2
0FBA: E5          push hl
0FBB: 3C          inc  a
0FBC: CA 1C E1    jp   z,$0FD0
0FBF: C3 68 71    jp   $1786

0FC2: C1          pop  bc
0FC3: 11 02 00    ld   de,$0020
0FC6: DD 19       add  ix,de
0FC8: 11 C0 00    ld   de,$000C
0FCB: FD 19       add  iy,de
0FCD: 10 DD       djnz $0FAC
0FCF: C9          ret

0FD0: DD 7E 21    ld   a,(ix+TABLE_X_coord)
0FD3: C6 C0       add  a,$0C
0FD5: FE 80       cp   $08
0FD7: DA DD 71    jp   c,$17DD
0FDA: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
0FDD: FE 21       cp   $03
0FDF: DA DD 71    jp   c,$17DD
0FE2: DD CB 30 6A res  4,(ix+$12)
0FE6: CD 43 10    call $1025
0FE9: CD 88 31    call $1388
0FEC: CD 75 70    call $1657
0FEF: C9          ret

0FF0: DD 7E 11    ld   a,(ix+$11)
0FF3: 3C          inc  a
0FF4: 28 B1       jr   z,$1011
0FF6: DD 7E 01    ld   a,(ix+$01)
0FF9: C6 80       add  a,$08
0FFB: 0F          rrca
0FFC: 0F          rrca
0FFD: 0F          rrca
0FFE: 0F          rrca
0FFF: E6 E1       and  $0F
1001: 21 51 10    ld   hl,$1015
1004: E7          rst	INDEX_A_PLUS_HL
1005: DD 77 01    ld   (ix+$01),a
1008: DD 77 20    ld   (ix+$02),a
100B: CD 9B 51    call $15B9
100E: C3 94 31    jp   ENEMY_BULLET_XY_UPDATE
1011: E1          pop  hl
1012: C3 DD 71    jp   $17DD
1015: 0A          ld   a,(bc)
1016: 14          inc  d
1017: 06 1C       ld   b,$D0
1019: 0E 1A       ld   c,$B0
101B: 1E 0C       ld   e,$C0
101D: 10 16       djnz $108F
101F: 04          inc  b
1020: 12          ld   (de),a
1021: 02          ld   (bc),a
1022: 08          ex   af,af'
1023: 18 1A       jr   $0FD5
1025: DD 7E 11    ld   a,(ix+$11)
1028: E6 01       and  $01
102A: 20 4C       jr   nz,$0FF0
102C: DD 7E 31    ld   a,(ix+ITEM_TYPE)
102F: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$142e	; Jump Table 0
		dw	$142e	; Jump Table 1
		dw	$1260	; Jump Table 2
		dw	$108c	; Jump Table 3
		dw	$10e3	; Jump Table 4
		dw	$1123	; Jump Table 5
		dw	$12a7	; Jump Table 6
		dw	$1260	; Jump Table 7
		dw	$142e	; Jump Table 8
		dw	$126e	; Jump Table 9
		dw	$1046	; Jump Table A

1046: CD 94 31    call $1358
1049: DD CB 30    set  4,(ix+$12)
104D: 3A 20 0E    ld   a,(FRAME_SYNC)
1050: 0F          rrca
1051: 0F          rrca
1052: E6 21       and  $03
1054: 21 E6 10    ld   hl,$106E
1057: 0E 16       ld   c,$70
1059: DD CB 91 64 bit  0,(ix+$19)
105D: 28 41       jr   z,$1064
105F: 21 76 10    ld   hl,$1076
1062: 0E 96       ld   c,$78
1064: EF          rst	INDEX_ED_AT_2A_PLUS_HL
1065: EB          ex   de,hl
1066: 7E          ld   a,(hl)
1067: DD 77 F0    ld   (ix+$1e),a
106A: 23          inc  hl
106B: C3 2C C9    jp   $8DC2

106E:		dw	$107e	; Table 0
		dw	$1086	; Table 1
		dw	$1089	; Table 2
		dw	$1086	; Table 3
 
1076:		dw	$1082	; Table 0
		dw	$1086	; Table 1
		dw	$1089	; Table 2
		dw	$1086	; Table 3


107e:		db	$01, $05, $0d, $0e
1082:		db	$01, $05, $0e, $0d
1086:		db	$00, $36, $3e
1089:		db	$00, $37, $3f

108C: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
108F: A7          and  a
1090: CC D9 10    call z,$109D
1093: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
1096: CD 95 90    call $1859
1099: CD 94 31    call ENEMY_BULLET_XY_UPDATE
109C: C9          ret

109D: DD 7E 50    ld   a,(ix+$14)
10A0: FE 02       cp   $20
10A2: D0          ret  nc
10A3: DD 34 50    inc  (ix+$14)
10A6: E6 21       and  $03
10A8: 28 F0       jr   z,$10C8
10AA: CD 2E C6    call $6CE2
10AD: DD 77 01    ld   (ix+$01),a
10B0: CD E3 98    call $982F
10B3: 3C          inc  a
10B4: E6 F3       and  $3F
10B6: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a
10B9: D6 02       sub  $20
10BB: DD 86 01    add  a,(ix+$01)
10BE: DD 77 01    ld   (ix+$01),a
10C1: DD 36 E1 00 ld   (ix+$0f),$00
10C5: C3 9B 51    jp   $15B9
10C8: DD 7E F1    ld   a,(ix+$1f)
10CB: E6 61       and  $07
10CD: 07          rlca
10CE: 07          rlca
10CF: 07          rlca
10D0: 47          ld   b,a
10D1: 3A 20 0E    ld   a,(FRAME_SYNC)
10D4: 80          add  a,b
10D5: DD 77 01    ld   (ix+$01),a
10D8: DD 77 20    ld   (ix+$02),a
10DB: E6 F7       and  $7F
10DD: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a
10E0: C3 9B 51    jp   $15B9

10E3: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
10E6: A7          and  a
10E7: CC 40 11    call z,$1104
10EA: DD 7E 71    ld   a,(ix+$17)
10ED: A7          and  a
10EE: 20 A0       jr   nz,$10FA
10F0: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
10F3: CD 95 90    call $1859
10F6: CD 94 31    call ENEMY_BULLET_XY_UPDATE
10F9: C9          ret
10FA: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
10FD: DD CB 30 6E set  4,(ix+$12)
1101: C3 55 50    jp   $1455
1104: CD E3 98    call $982F
1107: E6 F1       and  $1F
1109: C6 12       add  a,$30
110B: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a
110E: DD 34 50    inc  (ix+$14)
1111: DD CB 50 64 bit  0,(ix+$14)
1115: DD 36 71 00 ld   (ix+$17),$00
1119: C0          ret  nz
111A: DD 36 51 90 ld   (iy+TABLE_COUNTDOWN),$18
111E: DD 36 71 01 ld   (ix+$17),$01
1122: C9          ret

1123: DD CB 30 6E set  4,(ix+$12)
1127: CD A6 11    call $116A
112A: DD 7E 50    ld   a,(ix+$14)
112D: E6 21       and  $03
112F: 28 31       jr   z,$1144
1131: FE 20       cp   $02
1133: 20 A0       jr   nz,$113F
1135: DD 7E 70    ld   a,(ix+$16)
1138: 87          add  a,a
1139: 21 46 11    ld   hl,$1164
113C: DF          rst	ADD_A_TO_HL
113D: 18 30       jr   $1151
113F: 21 26 11    ld   hl,$1162
1142: 18 C1       jr   $1151
1144: 3A 20 0E    ld   a,(FRAME_SYNC)
1147: 21 B4 11    ld   hl,$115A
114A: CB 5F       bit  3,a
114C: 28 21       jr   z,$1151
114E: 21 D4 11    ld   hl,$115C
1151: 0E 04       ld   c,$40
1153: DD 36 F0 00 ld   (ix+$1e),$00
1157: C3 2C C9    jp   $8DC2

115A:		dw	$1810  
115C:		dw	$1911   
115E:		dw	$1810
1160:		dw	$1a11
1162:		dw	$1213
1164:		dw	$1c14
1166:		dw	$1b13
1168:		dw	$7b74

116A: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
116D: A7          and  a
116E: 28 E0       jr   z,$117E
1170: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
1173: DD 7E 50    ld   a,(ix+$14)
1176: E6 21       and  $03
1178: C2 19 51	  jp   nz,$1591
117B: C3 94 31    jp   ENEMY_BULLET_XY_UPDATE
117E: DD 7E 50    ld   a,(ix+$14)
1181: FE 21       cp   $03
1183: 28 33       jr   z,$11B8
1185: FE 01       cp   $01
1187: 38 C0       jr   c,$1195
1189: CA 0D 11    jp   z,$11C1
118C: DD 36 50 21 ld   (ix+$14),$03
1190: DD 36 51 80 ld   (iy+TABLE_COUNTDOWN),$08
1194: C9          ret
1195: CD 2E C6    call $6CE2
1198: DD 77 20    ld   (ix+$02),a
119B: C6 94       add  a,$58
119D: FE 12       cp   $30
119F: 38 60       jr   c,$11A7
11A1: E6 F1       and  $1F
11A3: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a
11A6: C9          ret
11A7: 0F          rrca
11A8: 0F          rrca
11A9: 0F          rrca
11AA: 0F          rrca
11AB: E6 21       and  $03
11AD: DD 77 70    ld   (ix+$16),a
11B0: DD 36 51 00 ld   (iy+TABLE_COUNTDOWN),$00
11B4: DD 34 50    inc  (ix+$14)
11B7: C9          ret

11B8: DD 36 50 00 ld   (ix+$14),$00
11BC: DD 36 51 A0 ld   (iy+TABLE_COUNTDOWN),$0A
11C0: C9          ret

11C1: 3A 3F 0E    ld   a,(BULLET_TIMER)
11C4: A7          and  a
11C5: 20 F2       jr   nz,$1205
11C7: 3A 1F 0E    ld   a,($E0F1)		; Table entry
11CA: 57          ld   d,a
11CB: 87          add  a,a			; * 2
11CC: 3C          inc  a			; +1
11CD: 5F          ld   e,a			; save for compare
11CE: DD 66 21    ld   h,(ix+TABLE_X_coord)
11D1: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
11D4: 3A 21 0F    ld   a,(PLAYER_X)
11D7: 94          sub  h
11D8: 82          add  a,d
11D9: BB          cp   e
11DA: 30 80       jr   nc,$11E4
11DC: 3A 41 0F    ld   a,(PLAYER_Y)
11DF: 95          sub  l
11E0: 82          add  a,d
11E1: BB          cp   e
11E2: 38 03       jr   c,$1205
11E4: DD E5       push ix
11E6: E5          push hl
11E7: DD 6E 70    ld   l,(ix+$16)
11EA: DD 4E 20    ld   c,(ix+$02)
11ED: 3A 1E 0E    ld   a,(MAX_BULLETS)			; 
11F0: 47          ld   b,a
11F1: DD 21 0C 2E ld   ix,ENEMY_BULLETS
11F5: 11 02 00    ld   de,$0020
11F8: DD 7E 00    ld   a,(ix+TABLE_STATUS)
11FB: A7          and  a
11FC: 28 10       jr   z,$120E
11FE: DD 19       add  ix,de
1200: 10 7E       djnz $11F8
1202: E1          pop  hl
1203: DD E1       pop  ix
1205: DD 36 51 A0 ld   (iy+TABLE_COUNTDOWN),$0A
1209: DD 36 50 00 ld   (ix+$14),$00
120D: C9          ret

120E: DD 35 00    dec  (ix+TABLE_STATUS)
1211: DD 71 01    ld   (ix+$01),c
1214: DD 36 31 01 ld   (ix+ITEM_TYPE),$01
1218: DD 75 91    ld   (ix+$19),l
121B: 7D          ld   a,l
121C: 21 B4 30    ld   hl,$125A
121F: EF          rst	INDEX_ED_AT_2A_PLUS_HL
1220: E1          pop  hl
1221: 7B          ld   a,e
1222: 84          add  a,h
1223: DD 77 21    ld   (ix+TABLE_X_coord),a
1226: 7A          ld   a,d
1227: 85          add  a,l
1228: DD 77 41    ld   (ix+TABLE_Y_coord),a
122B: DD 36 E1 60 ld   (ix+$0f),$06
122F: DD 7E 01    ld   a,(ix+$01)
1232: CD 46 C6    call $6C64
1235: DD 72 A1    ld   (ix+TABLE_X_Add_low),d
1238: DD 73 C0    ld   (ix+TABLE_X_Add_high),e
123B: DD 70 C1    ld   (ix+$0d),b
123E: DD 71 E0    ld   (ix+$0e),c
1241: DD 36 30 84 ld   (ix+$12),$48
1245: DD 36 50 00 ld   (ix+$14),$00
1249: DD 36 51 80 ld   (iy+TABLE_COUNTDOWN),$08
124D: DD E1       pop  ix
124F: DD 34 50    inc  (ix+$14)
1252: DD 36 51 80 ld   (iy+TABLE_COUNTDOWN),$08
1256: CD 24 68    call SFX_MORTAR
1259: C9          ret

125A:		dw	$f8f6   ; table 0
125C:		dw	$f6fb   ; table 1
125E:		dw	$f402   ; table 2

1260: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
1263: A7          and  a
1264: C2 90 31    jp   nz,$1318
1267: CD 95 90    call $1859
126A: CD 94 31    call ENEMY_BULLET_XY_UPDATE
126D: C9          ret

126E: DD 7E 50    ld   a,(ix+$14)
1271: A7          and  a
1272: CA 9D 30    jp   z,$12D9
1275: DD 7E 71    ld   a,(ix+$17)
1278: A7          and  a
1279: 20 C1       jr   nz,$1288
127B: CD 95 90    call $1859
127E: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
1281: CC 58 30    call z,$1294
1284: CD 94 31    call ENEMY_BULLET_XY_UPDATE
1287: C9          ret

1288: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
128B: 28 61       jr   z,$1294
128D: DD CB 30 6E set  4,(ix+$12)
1291: C3 55 50    jp   $1455
1294: DD 34 50    inc  (ix+$14)
1297: E6 20       and  $02
1299: 0F          rrca
129A: DD 77 71    ld   (ix+$17),a
129D: 20 21       jr   nz,$12A2
129F: C3 4C 30    jp   $12C4
12A2: DD 36 51 90 ld   (iy+TABLE_COUNTDOWN),$18
12A6: C9          ret

12A7: DD 7E 50    ld   a,(ix+$14)
12AA: A7          and  a
12AB: 28 C2       jr   z,$12D9
12AD: CD 95 90    call $1859
12B0: CD 7B 30    call $12B7
12B3: CD 94 31    call ENEMY_BULLET_XY_UPDATE
12B6: C9          ret

12B7: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
12BA: C0          ret  nz
12BB: DD 7E 50    ld   a,(ix+$14)
12BE: FE 80       cp   $08
12C0: D0          ret  nc
12C1: DD 34 50    inc  (ix+$14)
12C4: CD 2E C6    call $6CE2
12C7: DD 77 20    ld   (ix+$02),a
12CA: DD 77 01    ld   (ix+$01),a
12CD: 0F          rrca
12CE: 0F          rrca
12CF: E6 F1       and  $1F
12D1: C6 02       add  a,$20
12D3: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a
12D6: C3 9B 51    jp   $15B9

12D9: DD 7E 31    ld   a,(ix+ITEM_TYPE)
12DC: 21 CB 70    ld   hl,$16AD
12DF: DF          rst	ADD_A_TO_HL
12E0: 4E          ld   c,(hl)
12E1: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
12E4: 28 50       jr   z,$12FA
12E6: DD CB 30 6E set  4,(ix+$12)
12EA: CD 19 51    call $1591
12ED: 1E E7       ld   e,$6F
12EF: DD 7E 71    ld   a,(ix+$17)
12F2: E6 01       and  $01
12F4: 20 B1       jr   nz,$1311
12F6: 51          ld   d,c
12F7: C3 9C D0    jp   SPRITE_UPDATE_DE
12FA: DD 36 01 0C ld   (ix+$01),$C0
12FE: DD 36 20 0C ld   (ix+$02),$C0
1302: DD 36 50 01 ld   (ix+$14),$01
1306: DD 36 51 10 ld   (iy+TABLE_COUNTDOWN),$10
130A: DD 36 71 00 ld   (ix+$17),$00
130E: C3 9B 51    jp   $15B9
1311: 79          ld   a,c
1312: C6 80       add  a,$08
1314: 57          ld   d,a
1315: C3 9C D0    jp   SPRITE_UPDATE_DE
1318: DD 7E 31    ld   a,(ix+ITEM_TYPE)
131B: 21 CB 70    ld   hl,$16AD
131E: DF          rst	ADD_A_TO_HL
131F: 56          ld   d,(hl)
1320: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
1323: DD CB 30 6E set  4,(ix+$12)
1327: CD 19 51    call $1591
132A: 3A 20 0E    ld   a,(FRAME_SYNC)
132D: E6 21       and  $03
132F: CC 25 31    call z,$1343
1332: 1E 4A       ld   e,$A4
1334: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
1337: FE 61       cp   $07
1339: D2 9C D0    jp   nc,SPRITE_UPDATE_DE
133C: 1E AB       ld   e,$AB
133E: C3 9C D0    jp   SPRITE_UPDATE_DE
1341: AB          xor  e
1342: 4A          ld   c,d
1343: DD 7E 21    ld   a,(ix+TABLE_X_coord)
1346: FE 08       cp   $80
1348: 30 61       jr   nc,$1351
134A: DD 34 21    inc  (ix+TABLE_X_coord)
134D: DD 34 61    inc  (ix+TABLE_new_X_high)
1350: C9          ret
1351: DD 35 21    dec  (ix+TABLE_X_coord)
1354: DD 35 61    dec  (ix+TABLE_new_X_high)
1357: C9          ret

		; So update bullet from ix X: 78=34+BC & Y: 9A=56+DE-(scroll) (numbers are index)
ENEMY_BULLET_XY_UPDATE:
1358: DD 66 21    ld   h,(ix+TABLE_X_coord)	; Sprite X MSB 
135B: DD 6E 40    ld   l,(ix+TABLE_X_low)		; Sprite X lsb
135E: DD 56 A1    ld   d,(ix+TABLE_X_Add_low)
1361: DD 5E C0    ld   e,(ix+TABLE_X_Add_high)
1364: 19          add  hl,de			; Add position
1365: DD 74 61    ld   (ix+TABLE_new_X_high),h		; save to new X coordinate
1368: DD 75 80    ld   (ix+TABLE_new_X_low),l
136B: 3A 26 0E    ld   a,(SCREEN_SCROLLING)	; The screen scroll is 0 or 1
136E: A7          and  a
136F: 28 21       jr   z,$1374 
1371: DD 35 41    dec  (ix+TABLE_Y_coord)	; minus one pixel when screen is on the move.
1374: DD 66 41    ld   h,(ix+TABLE_Y_coord)	; now we update the Y with the Add fraction
1377: DD 6E 60    ld   l,(ix+TABLE_Y_low)
137A: DD 56 C1    ld   d,(ix+$0d)
137D: DD 5E E0    ld   e,(ix+$0e)
1380: 19          add  hl,de			; use a 16 bit Add for movement
1381: DD 74 81    ld   (ix+TABLE_new_Y_high),h		; save as new positions
1384: DD 75 A0    ld   (ix+TABLE_new_Y_low),l
1387: C9          ret

1388: DD 7E 31    ld   a,(ix+ITEM_TYPE)
138B: E6 E1       and  $0F
138D: 28 17       jr   z,$1400
138F: DD CB 31 F6 bit  7,(ix+ITEM_TYPE)
1393: C0          ret  nz
1394: DD 7E 90    ld   a,(ix+$18)
1397: A7          and  a
1398: 28 60       jr   z,$13A0
139A: DD 35 90    dec  (ix+$18)
139D: C3 00 50    jp   $1400
13A0: CD 39 A9    call $8B93
13A3: A7          and  a
13A4: C2 D1 50    jp   nz,$141D
13A7: DD 7E 81    ld   a,(ix+TABLE_new_Y_high)
13AA: 47          ld   b,a
13AB: 3A 30 EF    ld   a,($EF12)
13AE: E6 E1       and  $0F
13B0: 80          add  a,b
13B1: 47          ld   b,a
13B2: DD 7E 61    ld   a,(ix+TABLE_new_X_high)
13B5: C6 61       add  a,$07
13B7: 4F          ld   c,a
13B8: 3A 10 EF    ld   a,($EF10)
13BB: 57          ld   d,a
13BC: 3A 11 EF    ld   a,($EF11)
13BF: 5F          ld   e,a
13C0: 78          ld   a,b
13C1: E6 1E       and  $F0
13C3: 6F          ld   l,a
13C4: 26 00       ld   h,$00
13C6: 29          add  hl,hl
13C7: 19          add  hl,de
13C8: 79          ld   a,c
13C9: CB 3F       srl  a
13CB: 4F          ld   c,a
13CC: CB 3F       srl  a
13CE: CB 3F       srl  a
13D0: E6 F0       and  $1E
13D2: DF          rst	ADD_A_TO_HL
13D3: 7C          ld   a,h
13D4: E6 BF       and  $FB
13D6: 67          ld   h,a
13D7: 7E          ld   a,(hl)
13D8: A7          and  a
13D9: 28 43       jr   z,$1400
13DB: 5F          ld   e,a
13DC: 23          inc  hl
13DD: 7E          ld   a,(hl)
13DE: A7          and  a
13DF: 28 21       jr   z,$13E4
13E1: 79          ld   a,c
13E2: 2F          cpl
13E3: 4F          ld   c,a
13E4: 6B          ld   l,e
13E5: 26 00       ld   h,$00
13E7: 29          add  hl,hl
13E8: 29          add  hl,hl
13E9: 29          add  hl,hl
13EA: 78          ld   a,b
13EB: 0F          rrca
13EC: 2F          cpl
13ED: E6 61       and  $07
13EF: DF          rst	ADD_A_TO_HL
13F0: 11 46 46    ld   de,$6464
13F3: 19          add  hl,de
13F4: 56          ld   d,(hl)
13F5: 79          ld   a,c
13F6: E6 61       and  $07
13F8: 21 62 50    ld   hl,STRAIGHT_BIT_TABLE
13FB: DF          rst	ADD_A_TO_HL
13FC: 7E          ld   a,(hl)
13FD: A2          and  d
13FE: 20 D1       jr   nz,$141D

1400: DD 36 11 00 ld   (ix+$11),$00
1404: DD 66 61    ld   h,(ix+TABLE_new_X_high)
1407: DD 6E 80    ld   l,(ix+TABLE_new_X_low)
140A: DD 56 81    ld   d,(ix+TABLE_new_Y_high)
140D: DD 5E A0    ld   e,(ix+TABLE_new_Y_low)
1410: DD 74 21    ld   (ix+TABLE_X_coord),h
1413: DD 75 40    ld   (ix+TABLE_X_low),l
1416: DD 72 41    ld   (ix+TABLE_Y_coord),d
1419: DD 73 60    ld   (ix+TABLE_Y_low),e
141C: C9          ret
141D: DD CB 11 70 rl   (ix+$11)
1421: DD CB 11 6C set  0,(ix+$11)
1425: C9          ret

STRAIGHT_BIT_TABLE:
1426:		db $80,$40,$20,$10,$08,$04,$02,$01

142E: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
1431: A7          and  a
1432: CC D9 51    call z,$159D
1435: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
1438: DD 7E 50    ld   a,(ix+$14)
143B: A7          and  a
143C: 20 60       jr   nz,$1444

143E: CD 94 31    call ENEMY_BULLET_XY_UPDATE
1441: C3 95 90    jp   $1859

1444: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$143e	; Table 0
		dw	$143e	; Table 1
		dw	$143e	; Table 2
		dw	$143e	; Table 3
		dw	$1455	; Table 4
		dw	$14c3	; Table 5
		dw	$1556	; Table 6
		dw	$143e	; Table 7

1455: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
1458: FE 80       cp   $08
145A: CC 96 50    call z,$1478
145D: CD 19 51    call $1591
1460: 0E 00       ld   c,$00
1462: 21 86 50    ld   hl,$1468
1465: C3 D4 51    jp   $155C

1468:		dw	$146e   ; table 0
146A:		dw	$1471   ; table 1
146C:		dw	$1475   ; table 2

146e:		db	$10, $c6, $d5
1471:		db	$12, $d6, $d7,$df
1475:		db	$10, $c7, $cf

1478: DD E5       push ix
147A: 21 0C 50    ld   hl,$14C0
147D: E5          push hl
147E: DD 66 21    ld   h,(ix+TABLE_X_coord)
1481: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
1484: D9          exx
1485: DD 21 0E 4F ld   ix,$E5E0
1489: 21 50 FE    ld   hl,ENEMY_GRENADES_SP
148C: 3E 41       ld   a,$05
148E: 08          ex   af,af'
148F: 01 40 00    ld   bc,$0004
1492: 11 0E FF    ld   de,$FFE0
1495: DD 7E 00    ld   a,(ix+TABLE_STATUS)
1498: A7          and  a
1499: 28 81       jr   z,$14A4
149B: 09          add  hl,bc
149C: DD 19       add  ix,de
149E: 08          ex   af,af'
149F: 3D          dec  a
14A0: C8          ret  z

14A1: 08          ex   af,af'
14A2: 18 1F       jr   $1495
14A4: DD 74 B1    ld   (ix+$1b),h
14A7: DD 75 D0    ld   (ix+$1c),l
14AA: D9          exx
14AB: DD 74 21    ld   (ix+TABLE_X_coord),h
14AE: DD 75 41    ld   (ix+TABLE_Y_coord),l
14B1: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
14B5: DD 36 31 C1 ld   (ix+ITEM_TYPE),$0D
14B9: DD 36 B0 01 ld   (ix+TABLE_SPRITE_QTY),$01
14BD: C3 06 02    jp   $2060
14C0: DD E1       pop  i
14C2: C9          ret

14C3: CD 19 51    call $1591
14C6: 21 E0 51    ld   hl,$150E
14C9: CD B6 51    call $157A
14CC: DD 66 21    ld   h,(ix+TABLE_X_coord)
14CF: DD 6E 40    ld   l,(ix+TABLE_X_low)
14D2: DD 7E 01    ld   a,(ix+$01)
14D5: C6 04       add  a,$40
14D7: FE 08       cp   $80
14D9: 30 90       jr   nc,$14F3
14DB: 11 08 00    ld   de,$0080
14DE: 19          add  hl,de
14DF: DD 74 61    ld   (ix+TABLE_new_X_high),h
14E2: DD 75 80    ld   (ix+TABLE_new_X_low),l
14E5: DD 7E 31    ld   a,(ix+ITEM_TYPE)
14E8: 21 CB 70    ld   hl,$16AD
14EB: DF          rst	ADD_A_TO_HL
14EC: 4E          ld   c,(hl)
14ED: 21 F0 51    ld   hl,$151E
14F0: C3 D4 51    jp   $155C
14F3: 11 08 FF    ld   de,$FF80
14F6: 19          add  hl,de
14F7: DD 74 61    ld   (ix+TABLE_new_X_high),h
14FA: DD 75 80    ld   (ix+TABLE_new_X_low),l
14FD: DD 7E 31    ld   a,(ix+ITEM_TYPE)
1500: 21 CB 70    ld   hl,$16AD
1503: DF          rst	ADD_A_TO_HL
1504: 7E          ld   a,(hl)
1505: C6 80       add  a,$08
1507: 4F          ld   c,a
1508: 21 F2 51    ld   hl,$153E
150B: C3 D4 51    jp   $155C
150E: 00          nop
150F: 00          nop
1510: 16 FE       ld   d,$FE
1512: 02          ld   (bc),a
1513: FF          rst  $38
1514: 16 FF       ld   d,$FF
1516: 1A          ld   a,(de)
1517: FF          rst  $38

1518: 04          inc  b
1519: 00          nop
151A: 08          ex   af,af'
151B: 00          nop
151C: 00          nop
151D: 00          nop
151E: E2 51 B2    jp   po,$3A15
1521: 51          ld   d,c
1522: B2          or   d
1523: 51          ld   d,c
1524: B2          or   d
1525: 51          ld   d,c
1526: B2          or   d
1527: 51          ld   d,c
1528: 72          ld   (hl),d
1529: 51          ld   d,c
152A: 32 51 E2    ld   ($2E15),a
152D: 51          ld   d,c

152e:		db	$00, $90, $98, $00
1532:		db	$00, $94, $9c, $00
1536:		db	$02, $92, $93, $91
153a:		db	$02, $9a, $9b, $99

153E:		dw	$152e	; table 0
1540:		dw	$1552	; table 1
1542:		dw	$1552	; table 2
1544:		dw	$1552	; table 3
1546:		dw	$1552	; table 4
1548:		dw	$154e	; table 5
154A:		dw	$1532	; table 6
154C:		dw	$152e	; table 7

154e:		db	$02, $93, $92, $91
1552:		db	$02, $9b, $9a, $99

1556: CD 19 51    call $1591
1559: C3 95 90    jp   $1859
155C: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
155F: 0F          rrca
1560: 0F          rrca
1561: 0F          rrca
1562: E6 F1       and  $1F
1564: EF          rst	INDEX_ED_AT_2A_PLUS_HL
1565: EB          ex   de,hl
1566: 7E          ld   a,(hl)
1567: 47          ld   b,a
1568: E6 DE       and  $FC
156A: 81          add  a,c
156B: 4F          ld   c,a
156C: 78          ld   a,b
156D: E6 21       and  $03
156F: DD 77 F0    ld   (ix+$1e),a
1572: 23          inc  hl
1573: DD CB 30 6E set  4,(ix+$12)
1577: C3 2C C9    jp   $8DC2
157A: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
157D: 0F          rrca
157E: 0F          rrca
157F: 0F          rrca
1580: E6 F1       and  $1F
1582: EF          rst  $28	 ; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_H
1583: DD 66 41    ld   h,(ix+TABLE_Y_coord)
1586: DD 6E 60    ld   l,(ix+TABLE_Y_low)
1589: 19          add  hl,de
158A: DD 74 81    ld   (ix+TABLE_new_Y_high),h
158D: DD 75 A0    ld   (ix+TABLE_new_Y_low),l
1590: C9          ret
1591: 3A 26 0E    ld   a,(SCREEN_SCROLLING)
1594: A7          and  a
1595: C8          ret  z
1596: DD 35 41    dec  (ix+TABLE_Y_coord)
1599: DD 35 81    dec  (ix+TABLE_new_Y_high)
159C: C9          ret
159D: CD 8D 51    call $15C9
15A0: 47          ld   b,a
15A1: E6 F1       and  $1F
15A3: FE F1       cp   $1F
15A5: 28 13       jr   z,$15D8
15A7: DD 36 50 00 ld   (ix+$14),$00
15AB: DD 70 01    ld   (ix+$01),b
15AE: DD 70 20    ld   (ix+$02),b
15B1: 7E          ld   a,(hl)
15B2: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a
15B5: 23          inc  hl
15B6: CD 1D 51    call $15D1

15B9: CD 46 C6    call $6C64
15BC: DD 72 A1    ld   (ix+TABLE_X_Add_low),d
15BF: DD 73 C0    ld   (ix+TABLE_X_Add_high),e
15C2: DD 70 C1    ld   (ix+$0d),b
15C5: DD 71 E0    ld   (ix+$0e),c
15C8: C9          ret
15C9: DD 66 70    ld   h,(ix+$16)
15CC: DD 6E 71    ld   l,(ix+$17)
15CF: 7E          ld   a,(hl)
15D0: 23          inc  hl
15D1: DD 74 70    ld   (ix+$16),h
15D4: DD 75 71    ld   (ix+$17),l
15D7: C9          ret
15D8: 78          ld   a,b
15D9: 07          rlca
15DA: 07          rlca
15DB: 07          rlca
15DC: E6 61       and  $07
15DE: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$15ef	; Table 0
		dw	$15f9	; Table 1
		dw	$1600	; Table 2
		dw	$160a	; Table 3
		dw	$1621	; Table 4
		dw	$162a	; Table 5
		dw	$1633	; Table 6
		dw	$163e	; Table 7

15EF: 3E 01	  ld   a,$01
15F1: 32 58 0E    ld   ($e094),a
15F4: DD 36 51 01 ld   (iy+TABLE_COUNTDOWN),$01
15F8: C9          ret

15F9: CD 8d 51    call $15c9
15FC: DD 77 E1    ld   (ix+$0f),a
15FF: C9          ret

1600: DD 36 31 01 ld   (ix+ITEM_TYPE),$01
1604: DD 36 51 00 ld   (iy+TABLE_COUNTDOWN),$00
1608: E1          pop  hl
1609: C9          ret

160A: CD 2E C6    call $6CE2
160D: DD 77 01    ld   (ix+$01),a
1610: DD 77 20    ld   (ix+$02),a
1613: CD 8D 51    call $15C9
1616: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a
1619: CD 9B 51    call $15B9
161C: DD 36 50 21 ld   (ix+$14),$03
1620: C9          ret

1621: DD 36 50 40 ld   (ix+$14),$04
1625: DD 36 51 90 ld   (iy+TABLE_COUNTDOWN),$18
1629: C9          ret

162A: DD 36 50 41 ld   (ix+$14),$05
162E: DD 36 51 04 ld   (iy+TABLE_COUNTDOWN),$40
1632: C9          ret

1633: DD 36 50 60 ld   (ix+$14),$06
1637: CD 8D 51    call $15C9
163A: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a
163D: C9          ret

163E: CD 9B 51    call $15B9
1641: DD 36 50 00 ld   (ix+$14),$00
1645: DD 36 51 FF ld   (iy+TABLE_COUNTDOWN),$FF
1649: DD 66 70    ld   h,(ix+$16)
164C: DD 6E 71    ld   l,(ix+$17)
164F: 2B          dec  hl
1650: DD 74 70    ld   (ix+$16),h
1653: DD 75 71    ld   (ix+$17),l
1656: C9          ret


1657: DD CB 30 66 bit  4,(ix+$12)
165B: C0          ret  nz
165C: CB 6F       bit  5,a
165E: 20 11       jr   nz,$1671
1660: 3A 20 0E    ld   a,(FRAME_SYNC)
1663: E6 21       and  $03
1665: 47          ld   b,a
1666: DD 7E F1    ld   a,(ix+$1f)
1669: E6 21       and  $03
166B: B8          cp   b
166C: 20 21       jr   nz,$1671
166E: DD 34 10    inc  (ix+$10)
1671: DD 7E 31    ld   a,(ix+ITEM_TYPE)
1674: 21 CB 70    ld   hl,$16AD
1677: E7          rst	INDEX_A_PLUS_HL
1678: 08          ex   af,af'
1679: DD 7E 20    ld   a,(ix+$02)
167C: C6 61       add  a,$07
167E: 0F          rrca
167F: 0F          rrca
1680: 0F          rrca
1681: 0F          rrca
1682: E6 E1       and  $0F
1684: 47          ld   b,a
1685: 21 7A 70    ld   hl,$16B6
1688: DF          rst	ADD_A_TO_HL
1689: 4E          ld   c,(hl)
168A: 08          ex   af,af'
168B: 81          add  a,c
168C: 4F          ld   c,a
168D: 78          ld   a,b
168E: 87          add  a,a
168F: 87          add  a,a
1690: 47          ld   b,a
1691: 87          add  a,a
1692: 80          add  a,b
1693: 47          ld   b,a
1694: DD 7E 10    ld   a,(ix+$10)
1697: E6 21       and  $03
1699: FE 21       cp   $03
169B: 20 20       jr   nz,$169F
169D: 3E 01       ld   a,$01
169F: 87          add  a,a
16A0: 87          add  a,a
16A1: 80          add  a,b
16A2: 21 6C 70    ld   hl,$16C6
16A5: E7          rst	INDEX_A_PLUS_HL
16A6: DD 77 F0    ld   (ix+$1e),a
16A9: 23          inc  hl
16AA: C3 2C C9    jp   $8DC2

16ad:		db	$00, $00, $10, $00, $10, $00, $10, $20, $30
16b6:		db	$00, $00, $00, $00, $00, $08, $08, $08, $08, $08, $08, $08, $00, $00, $00, $00

16c6:		db	$01, $40, $48, $49, $00
16cb:		db	$42, $4a, $00, $00, $40
16d0:		db	$41, $00, $00, $43, $4b
16d5:		db	$00, $00, $44, $4c, $00

16DA: 00     call nz,$0000
16DB: 44          ld   b,h
16DC: 45          ld   b,l
16DD: 00          nop
16DE: 00          nop
16DF: 64          ld   h,h
16E0: E4 00 00    call po,$0000
16E3: 65          ld   h,l
16E4: E5          push hl
16E5: 00          nop
16E6: 00          nop
16E7: 64          ld   h,h
16E8: C5          push bc
16E9: 00          nop
16EA: 00          nop
16EB: 14          inc  d
16EC: 94          sub  h
16ED: 00          nop
16EE: 00          nop
16EF: 15          dec  d
16F0: 95          sub  l
16F1: 00          nop
16F2: 00          nop
16F3: 15          dec  d
16F4: 34          inc  (hl)
16F5: 00          nop
16F6: 00          nop
16F7: 35          dec  (hl)
16F8: B5          or   l
16F9: 00          nop
16FA: 00          nop
16FB: 54          ld   d,h
16FC: D4 00 00    call nc,$0000
16FF: 35          dec  (hl)
1700: B4          or   h
1701: 00          nop
1702: 00          nop
1703: 14          inc  d
1704: 94          sub  h
1705: 00          nop
1706: 00          nop
1707: 15          dec  d
1708: 95          sub  l
1709: 00          nop
170A: 00          nop
170B: 15          dec  d
170C: 34          inc  (hl)
170D: 00          nop
170E: 00          nop
170F: 64          ld   h,h
1710: E4 00 00    call po,$0000
1713: 65          ld   h,l
1714: E5          push hl
1715: 00          nop
1716: 00          nop
1717: 64          ld   h,h
1718: C5          push bc
1719: 00          nop
171A: 00          nop
171B: 25          dec  h
171C: A5          and  l
171D: 00          nop
171E: 00          nop
171F: 44          ld   b,h
1720: C4 00 00    call nz,$0000
1723: 44          ld   b,h
1724: 45          ld   b,l
1725: 00          nop
1726: 01 04 85    ld   bc,$4940
1729: 84          add  a,h
172A: 00          nop
172B: 24          inc  h
172C: A4          and  h
172D: 00          nop
172E: 00          nop
172F: 04          inc  b
1730: 05          dec  b
1731: 00          nop
1732: 00          nop
1733: 47          ld   b,a
1734: C7          rst  $00
1735: 00          nop
1736: 00          nop
1737: 66          ld   h,(hl)
1738: E6 00       and  $00
173A: 00          nop
173B: 66          ld   h,(hl)
173C: 67          ld   h,a
173D: 00          nop
173E: 00          nop
173F: 27          daa
1740: A7          and  a
1741: 00          nop
1742: 00          nop
1743: 46          ld   b,(hl)
1744: C6 00       add  a,$00
1746: 00          nop
1747: 27          daa
1748: A6          and  (hl)
1749: 00          nop
174A: 00          nop
174B: 06 86       ld   b,$68
174D: B5          or   l
174E: 00          nop
174F: 07          rlca
1750: 87          add  a,a
1751: B5          or   l
1752: 00          nop
1753: 06 26       ld   b,$62
1755: B5          or   l
1756: 00          nop
1757: 55          ld   d,l
1758: D5          push de
1759: 00          nop
175A: 00          nop
175B: 74          ld   (hl),h
175C: F4 00 00    call p,$0000
175F: 55          ld   d,l
1760: 75          ld   (hl),l
1761: 00          nop
1762: 00          nop
1763: 06 86       ld   b,$68
1765: B5          or   l
1766: 00          nop
1767: 07          rlca
1768: 87          add  a,a
1769: B5          or   l
176A: 00          nop
176B: 06 26       ld   b,$62
176D: B5          or   l
176E: 00          nop
176F: 27          daa
1770: A7          and  a
1771: 00          nop
1772: 00          nop
1773: 46          ld   b,(hl)
1774: C6 00       add  a,$00
1776: 00          nop
1777: 27          daa
1778: A6          and  (hl)
1779: 00          nop
177A: 00          nop
177B: 47          ld   b,a
177C: C7          rst  $00
177D: 00          nop
177E: 00          nop

177F: 66          ld   h,(hl)
1780: E6 00       and  $00
1782: 00          nop
1783: 66          ld   h,(hl)
1784: 67          ld   h,a
1785: 00          nop

1786: CD 19 51    call $1591
1789: DD 7E 00    ld   a,(ix+TABLE_STATUS)
178C: FE F3       cp   $3F
178E: D2 EE 71    jp   nc,$17EE
1791: 47          ld   b,a
1792: DD 35 00    dec  (ix+TABLE_STATUS)
1795: CA DD 71    jp   z,$17DD
1798: DD 7E 31    ld   a,(ix+ITEM_TYPE)
179B: FE A0       cp   $0A
179D: C8          ret  z
179E: 78          ld   a,b
179F: CB 47       bit  0,a
17A1: 28 B1       jr   z,$17BE
17A3: 21 7A 71    ld   hl,$17B6
17A6: CB 5F       bit  3,a
17A8: 28 21       jr   z,$17AD
17AA: 21 BA 71    ld   hl,$17BA
17AD: 4E          ld   c,(hl)
17AE: 23          inc  hl
17AF: DD 36 F0 20 ld   (ix+$1e),$02
17B3: C3 2C C9    jp   $8DC2

17B6: 80          add  a,b
17B7: 17          rla
17B8: 16 96       ld   d,$78
17BA: 00          nop
17BB: 16 17       ld   d,$71
17BD: 96          sub  (hl)
17BE: DD 7E 21    ld   a,(ix+TABLE_X_coord)
17C1: FD 77 20    ld   (iy+sprite_x),a
17C4: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
17C7: C6 80       add  a,$08
17C9: FD 77 21    ld   (iy+sprite_y),a
17CC: FD 36 00 97 ld   (iy+$00),$79
17D0: FD 36 01 00 ld   (iy+sprite_flags),$00
17D4: FD 36 60 00 ld   (iy+sprite2_x),$00
17D8: FD 36 A0 00 ld   (iy+sprite3_x),$00
17DC: C9          ret

17DD: AF          xor  a
17DE: DD 77 00    ld   (ix+TABLE_STATUS),a
17E1: DD 77 21    ld   (ix+TABLE_X_coord),a
17E4: FD 77 20    ld   (iy+sprite_x),a
17E7: FD 77 60    ld   (iy+sprite2_x),a
17EA: FD 77 A0    ld   (iy+sprite3_x),a
17ED: C9          ret
17EE: DD 36 00 02 ld   (ix+TABLE_STATUS),$20
17F2: CD 98 68    call SFX_KILL
17F5: DD 7E 31    ld   a,(ix+ITEM_TYPE)
17F8: E6 E1       and  $0F
17FA: 21 63 90    ld   hl,$1827
17FD: DF          rst	ADD_A_TO_HL
17FE: 16 41       ld   d,$05
1800: 5E          ld   e,(hl)
1801: FF          rst  ADD_DE_TO_EVENT
1802: DD 7E 31    ld   a,(ix+ITEM_TYPE)
1805: FE A0       cp   $0A
1807: C0          ret  nz
1808: DD 36 40 00 ld   (ix+TABLE_X_low),$00
180C: 11 71 90    ld   de,$1817
180F: FD E5       push iy
1811: CD 88 A3    call HW_SPRITE_UPDATER
1814: FD E1       pop  iy
1816: C9          ret

1817:		db	$03, $60, $00, $55, $10, $57, $00, $ff, $02, $70, $71, $78, $02, $79, $7a, $72
1827:		db	$03, $03, $05, $02, $03, $04, $03, $05, $05, $05, $0a, $02, $02, $02, $02, $02

1837: 20 3A       ld   a,($E062)
183A:		  and  a
183B: 28 21       jr   z,$1840
183D: DD 35 41    dec  (ix+TABLE_Y_coord)
1840: DD 66 21    ld   h,(ix+TABLE_X_coord)
1843: DD 6E 40    ld   l,(ix+TABLE_X_low)
1846: DD 56 41    ld   d,(ix+TABLE_Y_coord)
1849: DD 5E 60    ld   e,(ix+TABLE_Y_low)
184C: DD 74 61    ld   (ix+TABLE_new_X_high),h
184F: DD 75 80    ld   (ix+TABLE_new_X_low),l
1852: DD 72 81    ld   (ix+TABLE_new_Y_high),d
1855: DD 73 A0    ld   (ix+TABLE_new_Y_low),e
1858: C9          ret

1859: DD 7E F1    ld   a,(ix+$1f)
185C: E6 E1       and  $0F
185E: 47          ld   b,a
185F: 3A 20 0E    ld   a,(FRAME_SYNC)
1862: E6 E1       and  $0F
1864: B8          cp   b
1865: C0          ret  nz
1866: C3 11 58    jp   $9411


UPDATE_GUNNER_SANDBAG:
1869: 21 55 0E    ld   hl,ENEMY_SPRITE_COUNT
186C: 34          inc  (hl)
186D: CD C9 B2    call ADJUST_Y_POSITION
1870: 3A D8 0E    ld   a,($E09C)
1873: A7          and  a
1874: 28 81       jr   z,$187F
1876: 21 03 10    ld   hl,$1021
1879: 11 03 10    ld   de,$1021
187C: CD 0F B0    call $1AE1
187F: DD 7E 41    ld   a,(ix+TABLE_Y_coord)			; Y coordinate
1882: A7          and  a				; compare with 0 (z80 short cut)
1883: CA 6B B2    jp   z,REMOVE_SPRITES			; check if 0
1886: FE 56       cp   $74				; check if $74 (strange position!) for Y coordinate
1888: DA 71 D0    jp   c,$1C17
188B: CD 0F B1    call $1BE1				; some animation countdown timer
188E: DD 7E 80    ld   a,(ix+TABLE_new_X_low)			; Get frame number
1891: 21 7D 90    ld   hl,$18D7
1894: EF          rst  $28	 			; Get e then d from ( a*2 + hl)
1895: C3 9C D0    jp   SPRITE_UPDATE_DE			; Get
1898: 21 55 0E    ld   hl,ENEMY_SPRITE_COUNT
189B: 34          inc  (hl)
189C: CD F1 91    call $191F
189F: 3A 00 0F    ld   a,(PLAYER_DATA)
18A2: 3C          inc  a
18A3: 20 43       jr   nz,$18CA
18A5: 06 10       ld   b,$10
18A7: DD CB 50 E4 bit  1,(ix+$14)
18AB: 28 20       jr   z,$18AF
18AD: 06 80       ld   b,$08
18AF: 3A 41 0F    ld   a,(PLAYER_Y)
18B2: DD 96 41    sub  (ix+TABLE_Y_coord)
18B5: FE 80       cp   $08
18B7: 30 11       jr   nc,$18CA
18B9: 3A 21 0F    ld   a,(PLAYER_X)
18BC: DD 96 21    sub  (ix+TABLE_X_coord)
18BF: C6 10       add  a,$10
18C1: FE 04       cp   $40
18C3: 30 41       jr   nc,$18CA
18C5: 3E F3       ld   a,$3F			; You've just been killed 
18C7: 32 00 0F    ld   (PLAYER_DATA),a
18CA: 11 EF 90    ld   de,$18EF
18CD: DD 7E 50    ld   a,(ix+$14)
18D0: 21 6F 90    ld   hl,$18E7
18D3: EF          rst	INDEX_ED_AT_2A_PLUS_HL
18D4: C3 88 A3    jp   HW_SPRITE_UPDATER

18D7:		db	$ef, $18		; reversed sprites first
18D9:		db	$ef, $18
18DB:		db	$f7, $18
18DD:		dw	$f6, $18
18DF:   	db	$f5, $10		; will sprite be sprite $f5 palette 1 
18E1:		db	$f6, $10		; and so on for animation code.
18E3:		db	$f7, $10
18E5:		db	$ef, $10

18E7:		dw	$18EF
18E9:		dw	$18FD
18EB:		dw	$190B
18ED:		dw	$1915

18EF:		db	$06, $50, $00, $59, $10, $5a, $20 $5b, $01, $51, $11, $52, $21, $53
18FD:		db	$06, $58, $20, $59, $10, $5a, $00, $5b, $21, $51, $11, $52, $01, $53
190B:		db	$04, $70, $00, $68, $10, $69, $20, $6a, $11, $60
1915:		db	$04, $78, $20, $68, $10, $69, $00, $6a, $11, $60

191F: CD          call $3A8D
1922: 3A 20 0E    ld   a,(FRAME_SYNC)
1925: E6 61       and  $07
1927: 20 11       jr   nz,$193A
1929: DD 46 41    ld   b,(ix+TABLE_Y_coord)
192C: 3A 41 0F    ld   a,(PLAYER_Y)
192F: 90          sub  b
1930: 30 41       jr   nc,$1937
1932: DD 35 41    dec  (ix+TABLE_Y_coord)
1935: 18 21       jr   $193A
1937: DD 34 41    inc  (ix+TABLE_Y_coord)
193A: 3A 00 0F    ld   a,(PLAYER_DATA)
193D: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
1940: FE 20       cp   $02
1942: 30 40       jr   nc,$1948
1944: E1          pop  hl
1945: C3 6B B2    jp   REMOVE_SPRITES
1948: DD CB 50 64 bit  0,(ix+$14)
194C: 28 90       jr   z,$1966
194E: DD 34 21    inc  (ix+TABLE_X_coord)
1951: 3A 20 0E    ld   a,(FRAME_SYNC)
1954: E6 01       and  $01
1956: C8          ret  z
1957: DD 34 21    inc  (ix+TABLE_X_coord)
195A: DD 7E 21    ld   a,(ix+TABLE_X_coord)
195D: C6 02       add  a,$20
195F: FE 21       cp   $03
1961: D0          ret  nc
1962: E1          pop  hl
1963: C3 6B B2    jp   REMOVE_SPRITES
1966: DD 35 21    dec  (ix+TABLE_X_coord)
1969: 3A 20 0E    ld   a,(FRAME_SYNC)
196C: E6 01       and  $01
196E: C8          ret  z
196F: DD 35 21    dec  (ix+TABLE_X_coord)
1972: DD 7E 21    ld   a,(ix+TABLE_X_coord)
1975: C6 10       add  a,$10
1977: FE 21       cp   $03
1979: D0          ret  nc
197A: E1          pop  hl
197B: C3 6B B2    jp   REMOVE_SPRITES
197E: CD C9 B2    call ADJUST_Y_POSITION
1981: DD 66 40    ld   h,(ix+TABLE_X_low)
1984: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
1987: 11 FE FF    ld   de,$FFFE
198A: 19          add  hl,de
198B: DD 74 40    ld   (ix+TABLE_X_low),h
198E: DD 75 41    ld   (ix+TABLE_Y_coord),l
1991: 7C          ld   a,h
1992: A7          and  a
1993: C8          ret  z
1994: 7D          ld   a,l
1995: FE 1C       cp   $D0
1997: D0          ret  nc
1998: E1          pop  hl
1999: C3 6B B2    jp   REMOVE_SPRITES
199C: CD F6 91    call $197E
199F: CD 8A 91    call $19A8
19A2: 11 6D 91    ld   de,$19C7
19A5: C3 88 A3    jp   HW_SPRITE_UPDATER
19A8: 3A 00 0F    ld   a,(PLAYER_DATA)
19AB: 3C          inc  a
19AC: C0          ret  nz
19AD: 3A 41 0F    ld   a,(PLAYER_Y)
19B0: DD 96 41    sub  (ix+TABLE_Y_coord)
19B3: FE 02       cp   $20
19B5: D0          ret  nc
19B6: 3A 21 0F    ld   a,(PLAYER_X)
19B9: DD 96 21    sub  (ix+TABLE_X_coord)
19BC: C6 C0       add  a,$0C
19BE: FE 83       cp   $29
19C0: D0          ret  nc
19C1: 3E F3       ld   a,$3F
19C3: 32 00 0F    ld   (PLAYER_DATA),a
19C6: C9          ret

19c7:		db	$04, $50, $00, $f8, $10, $f9, $01, $f0, $11, $f1

19D1: CD F6 91    call $197E
19D4: CD 8A 91    call $19A8
19D7: 11 0E 91    ld   de,$19E0
19DA: CD 88 A3    call HW_SPRITE_UPDATER
19DD: C3 88 A3    jp   HW_SPRITE_UPDATER

19e0:		db	$03, $50, $00, $f5, $01, $ed, $02, $e5
19e8:		db	$03, $58, $10, $f5, $11, $ed, $12, $e5

UPDATE_BARRACK_DOOR:
19F0: CD C9 B2    call ADJUST_Y_POSITION
19F3: CD 55 B0    call $1A55
19F6: CD 22 B0    call $1A22
19F9: 11 85 B0    ld   de,$1A49
19FC: CD 88 A3    call HW_SPRITE_UPDATER
19FF: DD 46 21    ld   b,(ix+TABLE_X_coord)
1A02: DD 4E 41    ld   c,(ix+TABLE_Y_coord)
1A05: C5          push bc
1A06: DD 7E 70    ld   a,(ix+$16)
1A09: 67          ld   h,a
1A0A: 80          add  a,b
1A0B: C6 FE       add  a,$FE
1A0D: DD 77 21    ld   (ix+TABLE_X_coord),a
1A10: 7C          ld   a,h
1A11: 81          add  a,c
1A12: C6 C0       add  a,$0C
1A14: DD 77 41    ld   (ix+TABLE_Y_coord),a
1A17: D4 88 A3    call nc,HW_SPRITE_UPDATER
1A1A: C1          pop  bc
1A1B: DD 70 21    ld   (ix+TABLE_X_coord),b
1A1E: DD 71 41    ld   (ix+TABLE_Y_coord),c
1A21: C9          ret
1A22: 3A 20 0E    ld   a,(FRAME_SYNC)
1A25: E6 21       and  $03
1A27: C0          ret  nz
1A28: DD 7E 50    ld   a,(ix+$14)
1A2B: E6 21       and  $03
1A2D: C8          ret  z
1A2E: 3D          dec  a
1A2F: 28 20       jr   z,$1A33
1A31: 18 C1       jr   $1A40
1A33: DD 35 70    dec  (ix+$16)
1A36: DD 7E 70    ld   a,(ix+$16)
1A39: FE 5E       cp   $F4
1A3B: D0          ret  nc
1A3C: DD 34 50    inc  (ix+$14)
1A3F: C9          ret
1A40: DD 34 70    inc  (ix+$16)
1A43: C0          ret  nz
1A44: DD 36 50 00 ld   (ix+$14),$00
1A48: C9          ret

1A49:   db      $02, $90, $01, $55, $00, $5d
1A4F:   db      $02, $90, $11, $54, $10, $5c

1A55: DD 7E 50    ld   a,(ix+$14)
1A58: A7          and  a
1A59: C0          ret  nz
1A5A: DD 7E 40    ld   a,(ix+TABLE_X_low)
1A5D: A7          and  a
1A5E: C0          ret  nz
1A5F: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
1A62: FE 02       cp   $20
1A64: D8          ret  c
1A65: 3A 7E 0E    ld   a,(ENEMY_TIMER)
1A68: A7          and  a
1A69: C0          ret  nz
1A6A: DD 7E 21    ld   a,(ix+TABLE_X_coord)
1A6D: C6 C1       add  a,$0D
1A6F: 67          ld   h,a
1A70: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
1A73: C6 C1       add  a,$0D
1A75: 6F          ld   l,a
1A76: DD E5       push ix
1A78: DD 21 00 6E ld   ix,ENEMY_SPRITES
1A7C: 3A 5E 0E    ld   a,(MAX_ENEMY)
1A7F: 47          ld   b,a
1A80: 11 02 00    ld   de,$0020
1A83: DD 7E 00    ld   a,(ix+TABLE_STATUS)
1A86: A7          and  a
1A87: 28 61       jr   z,$1A90
1A89: DD 19       add  ix,de
1A8B: 10 7E       djnz $1A83
1A8D: DD E1       pop  ix
1A8F: C9          ret

1A90: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
1A94: DD 36 01 0C ld   (ix+$01),$C0
1A98: DD 36 20 0C ld   (ix+$02),$C0
1A9C: DD 74 21    ld   (ix+TABLE_X_coord),h
1A9F: DD 74 61    ld   (ix+TABLE_new_X_high),h
1AA2: DD 75 41    ld   (ix+TABLE_Y_coord),l
1AA5: DD 75 81    ld   (ix+TABLE_new_Y_high),l
1AA8: DD 36 31 81 ld   (ix+ITEM_TYPE),$09
1AAC: DD 36 50 00 ld   (ix+$14),$00
1AB0: DD 36 51 C0 ld   (iy+TABLE_COUNTDOWN),$0C
1AB4: DD 36 90 90 ld   (ix+$18),$18
1AB8: DD 71 71    ld   (ix+$17),c
1ABB: DD 70 F1    ld   (ix+$1f),b
1ABE: DD 36 A1 00 ld   (ix+TABLE_X_Add_low),$00
1AC2: DD 36 C0 00 ld   (ix+TABLE_X_Add_high),$00
1AC6: DD 36 C1 FF ld   (ix+$0d),$FF
1ACA: DD 36 E0 00 ld   (ix+$0e),$00
1ACE: DD 36 E1 00 ld   (ix+$0f),$00
1AD2: CD 4C 59    call $95C4
1AD5: 3A 5F 0E    ld   a,(ENEMY_TIMER_RESET)
1AD8: 32 7E 0E    ld   (ENEMY_TIMER),a
1ADB: DD E1       pop  ix
1ADD: DD 34 50    inc  (ix+$14)
1AE0: C9          ret

1AE1: 3A D9 0E    ld   a,($E09D)
1AE4: DD 96 21    sub  (ix+TABLE_X_coord)
1AE7: 84          add  a,h
1AE8: BD          cp   l
1AE9: D0          ret  nc
1AEA: 3A F8 0E    ld   a,($E09E)
1AED: DD 96 41    sub  (ix+TABLE_Y_coord)
1AF0: 82          add  a,d
1AF1: BB          cp   e
1AF2: D0          ret  nc
1AF3: DD 36 00 F3 ld   (ix+TABLE_STATUS),$3F
1AF7: C9          ret
1AF8: CD C9 B2    call ADJUST_Y_POSITION
1AFB: CD 78 B1    call $1B96
1AFE: CD 84 B1    call $1B48
1B01: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
1B04: FE 0E       cp   $E0
1B06: D0          ret  nc
1B07: F5          push af
1B08: DD 46 51    ld   b,(iy+TABLE_COUNTDOWN)
1B0B: 80          add  a,b
1B0C: C6 61       add  a,$07
1B0E: DD 77 41    ld   (ix+TABLE_Y_coord),a
1B11: 78          ld   a,b
1B12: FE 81       cp   $09
1B14: 30 A1       jr   nc,$1B21
1B16: 11 C2 B1    ld   de,$1B2C
1B19: CD 88 A3    call HW_SPRITE_UPDATER
1B1C: F1          pop  af
1B1D: DD 77 41    ld   (ix+TABLE_Y_coord),a
1B20: C9          ret
1B21: 11 F2 B1    ld   de,$1B3E
1B24: CD 88 A3    call HW_SPRITE_UPDATER
1B27: F1          pop  af
1B28: DD 77 41    ld   (ix+TABLE_Y_coord),a
1B2B: C9          ret

1B2C:		db	$08, $50, $00, $af, $10, $af, $20, $af, $30, $af, $01, $af, $11, $af, $21, $af, $31, $af
1B3E:		db	$04, $50, $00, $af, $10, $af, $20, $af, $30, $af

1B48: 3A 58 0E    ld   a,($E094)
1B4B: A7          and  a
1B4C: 28 81       jr   z,$1B57
1B4E: DD 36 50 01 ld   (ix+$14),$01
1B52: 3E 00       ld   a,$00
1B54: 32 58 0E    ld   ($E094),a
1B57: DD 7E 50    ld   a,(ix+$14)
1B5A: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$1b63	; Table 0
		dw	$1b64	; Table 1
		dw	$1b78	; Table 2
		dw	$1b87	; Table 3

1B63: C9          ret

1B64: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
1B67: FE 91       cp   $19
1B69: 30 40       jr   nc,$1B6F
1B6B: DD 34 51    inc  (iy+TABLE_COUNTDOWN)
1B6E: C9          ret
1B6F: DD 36 70 F0 ld   (ix+$16),$1E
1B73: DD 36 50 20 ld   (ix+$14),$02
1B77: C9          ret

1B78: DD 7E 70    ld   a,(ix+$16)
1B7B: A7          and  a
1B7C: 28 40       jr   z,$1B82
1B7E: DD 35 70    dec  (ix+$16)
1B81: C9          ret
1B82: DD 36 50 21 ld   (ix+$14),$03
1B86: C9          ret

1B87: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
1B8A: A7          and  a
1B8B: 28 40       jr   z,$1B91
1B8D: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
1B90: C9          ret
1B91: DD 36 50 00 ld   (ix+$14),$00
1B95: C9          ret
1B96: 11 F9 B1    ld   de,$1B9F
1B99: CD 88 A3    call HW_SPRITE_UPDATER
1B9C: C3 88 A3    jp   HW_SPRITE_UPDATER

1b9f:		db	$04, $50, $00, $b6, $01, $ae, $02, $a6, $12, $a7
1ba9:		db	$04, $58, $30, $b6, $31, $ae, $32, $a6, $22, $a7

UPDATE_SANDBAG:
1BB3: 55          ld   hl,ENEMY_SPRITE_COUNT
1BB5: 0E 34       inc  (hl)
1BB7: CD C9 B2    call ADJUST_Y_POSITION
1BBA: 3A D8 0E    ld   a,($E09C)
1BBD: A7          and  a
1BBE: 28 81       jr   z,$1BC9
1BC0: 21 03 10    ld   hl,$1021
1BC3: 11 03 10    ld   de,$1021
1BC6: CD 0F B0    call $1AE1
1BC9: DD 7E 41    ld   a,(ix+TABLE_Y_coord)		; Get y cord
1BCC: A7          and  a
1BCD: CA 6B B2    jp   z,REMOVE_SPRITES
1BD0: FE 56       cp   $74			; position down screen
1BD2: 38 25       jr   c,$1C17
1BD4: CD 0F B1    call $1BE1
1BD7: DD 7E 80    ld   a,(ix+TABLE_new_X_low)
1BDA: 21 04 D0    ld   hl,$1C40
1BDD: EF          rst	INDEX_ED_AT_2A_PLUS_HL
1BDE: C3 9C D0    jp   SPRITE_UPDATE_DE		; update hardware sprite and exit


1BE1: DD 35 51    dec  (iy+TABLE_COUNTDOWN)			; countdown timer
1BE4: 28 44       jr   z,$1C2A
1BE6: DD CB 50 64 bit  0,(ix+$14)
1BEA: C8          ret  z
1BEB: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
1BEE: 47          ld   b,a
1BEF: E6 E1       and  $0F
1BF1: C0          ret  nz
1BF2: CD 2E C6    call $6CE2
1BF5: 47          ld   b,a
1BF6: FE D8       cp   $9C
1BF8: 38 D0       jr   c,$1C16
1BFA: FE 4E       cp   $E4
1BFC: 30 90       jr   nc,$1C16
1BFE: DD 70 20    ld   (ix+$02),b
1C01: C6 80       add  a,$08
1C03: 0F          rrca
1C04: 0F          rrca
1C05: 0F          rrca
1C06: 0F          rrca
1C07: E6 61       and  $07
1C09: DD 77 80    ld   (ix+TABLE_new_X_low),a
1C0C: 21 B0 D0    ld   hl,$1C1A
1C0F: EF          rst	INDEX_ED_AT_2A_PLUS_HL
1C10: 63          ld   h,e
1C11: 6A          ld   l,d
1C12: CD DF 39    call $93FD
1C15: C9          ret
1C16: E1          pop  hl
1C17: C3 14 D0    jp   $1C50

1C1A:		db	$f2, $f4
1C1C:		db	$f2, $f4
1C1E:		db	$f4, $f4
1C20:		db	$fc, $f4
1C22:		db	$01, $f4
1C24:		db	$04, $f4
1C26:		db	$0c, $f4
1C28:		db	$0e, $f4

1C29: 5E          ld   e,(hl)
1C2A: DD 7E 50    ld   a,(ix+$14)		; timer restart
1C2D: 3C          inc  a
1C2E: E6 01       and  $01			; 0 or 1 only
1C30: DD 77 50    ld   (ix+$14),a
1C33: A7          and  a
1C34: 28 41       jr   z,$1C3B			; alternate between two countdowns
1C36: DD 36 51 08 ld   (iy+TABLE_COUNTDOWN),$80		; $80 value here
1C3A: C9          ret
1C3B: DD 36 51 D2 ld   (iy+TABLE_COUNTDOWN),$3C		; and $3c this value here first countdown is this one
1C3F: C9          ret

1c40:		db	$a3, $18
1c42:		db	$a3, $18
1c44:		db 	$a2, $18
1c46:		db 	$a1, $18
1c48:		db	$a0, $10		; Man with gun with palette 1
1c4a:		db	$a1, $10
1c4c:		db	$a2, $10
1c4e:		db	$a3, $10

1C50: D0 E5       push IX
1C52: DD 66 21    ld   h,(ix+TABLE_X_coord)
1C55: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
1C58: C6 61       add  a,$07
1C5A: 6F          ld   l,a
1C5B: DD 4E F1    ld   c,(ix+$1f)
1C5E: DD 21 00 6E ld   ix,ENEMY_SPRITES
1C62: 11 02 00    ld   de,$0020
1C65: 06 80       ld   b,$08
1C67: DD 7E 00    ld   a,(ix+TABLE_STATUS)
1C6A: A7          and  a
1C6B: 28 61       jr   z,$1C74
1C6D: DD 19       add  ix,de
1C6F: 10 7E       djnz $1C67
1C71: DD E1       pop  ix
1C73: C9          ret

1C74: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
1C78: DD 36 01 04 ld   ((TABLE_COUNTDOWN),$40
1C7C: DD 36 20 04 ld   (ix+$02),$40
1C80: DD 74 21    ld   (ix+TABLE_X_coord),h
1C83: DD 74 61    ld   (ix+TABLE_new_X_high),h
1C86: DD 75 41    ld   (ix+TABLE_Y_coord),l
1C89: DD 75 81    ld   (ix+TABLE_new_Y_high),l
1C8C: DD 36 31 20 ld   (ix+ITEM_TYPE),$02
1C90: DD 36 50 00 ld   (ix+$14),$00
1C94: DD 36 90 00 ld   (ix+$18),$00
1C98: DD 36 51 10 ld   (iy+TABLE_COUNTDOWN),$10
1C9C: DD 70 F1    ld   (ix+$1f),b
1C9F: 79          ld   a,c
1CA0: E6 21       and  $03
1CA2: 21 0D D0    ld   hl,$1CC1
1CA5: 87          add  a,a
1CA6: EF          rst	INDEX_ED_AT_2A_PLUS_HL
1CA7: DD 72 A1    ld   (ix+TABLE_X_Add_low),d
1CAA: DD 73 C0    ld   (ix+TABLE_X_Add_high),e
1CAD: 4E          ld   c,(hl)
1CAE: 23          inc  hl
1CAF: 46          ld   b,(hl)
1CB0: DD 70 C1    ld   (ix+$0d),b
1CB3: DD 71 E0    ld   (ix+$0e),c
1CB6: DD E1       pop  ix
1CB8: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
1CBC: FD 36 20 00 ld   (iy+sprite_x),$00
1CC0: C9          ret

1cc1:		db	$a0, $ff
1cc3:		db	$b8, $00
1cc5:		db	$60, $00
1cc7:		db	$b8, $00

1CC9: 1C          inc  e
1CCA: FF          rst  $38
1CCB: 8C          adc  a,h
1CCC: 00          nop
1CCD: 12          ld   (de),a
1CCE: 00          nop
1CCF: 8C          adc  a,h
1CD0: 00          nop
1CD1: 0F          rrca
1CD2: 0F          rrca
1CD3: 0F          rrca
1CD4: 0F          rrca
1CD5: E6 E1       and  $0F
1CD7: EF          rst	INDEX_ED_AT_2A_PLUS_HL


		; e sprite number, d is flags, x and y as per table entries.
SPRITE_UPDATE_DE:
1CD8: FD 73 00    ld   (iy+sprite_number),e	; sprite number passed from e
1CDB: FD 72 01    ld   (iy+sprite_flags),d	; flags from d
1CDE: DD 7E 21    ld   a,(ix+TABLE_X_coord)		; x cord in table
1CE1: FD 77 20    ld   (iy+sprite_x),a		; as x
1CE4: DD 7E 41    ld   a,(ix+TABLE_Y_coord)		; and table in y as the y
1CE7: FD 77 21    ld   (iy+sprite_y),a		; save to hardware sprite
1CEA: C9          ret

1CEB: DD 36 00 F3 ld   (ix+TABLE_STATUS),$3F
1CEF: DD 36 40 00 ld   (ix+TABLE_X_low),$00
1CF3: C9          ret

UPDATE_PRISONER:
1CF4: 21 55 0E    ld   hl,ENEMY_SPRITE_COUNT
1CF7: 34          inc  (hl)
1CF8: 3A DA 0E    ld   a,($E0BC)
1CFB: A7          and  a
1CFC: 28 CF       jr   z,$1CEB
1CFE: CD 10 D1    call $1D10
1D01: 21 0B F0    ld   hl,PRISONER_ANIMATION
1D04: 3A 20 0E    ld   a,(FRAME_SYNC)		; three frame animations
1D07: 0F          rrca
1D08: 0F          rrca
1D09: 0F          rrca
1D0A: E6 21       and  $03			; yes we ask for just 4, but actually only three in the data table
1D0C: EF          rst  $28	 		; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
1D0D: C3 88 A3    jp   HW_SPRITE_UPDATER

1D10: 3A 26 0E    ld   a,(SCREEN_SCROLLING)
1D13: A7          and  a
1D14: 28 21       jr   z,$1D19
1D16: DD 35 41    dec  (ix+TABLE_Y_coord)
1D19: DD 7E 50    ld   a,(ix+$14)
1D1C: E6 01       and  $01
1D1E: 28 93       jr   z,$1D59
1D20: DD 66 21    ld   h,(ix+TABLE_X_coord)
1D23: DD 6E 40    ld   l,(ix+TABLE_X_low)
1D26: DD 56 A1    ld   d,(ix+TABLE_X_Add_low)
1D29: DD 5E C0    ld   e,(ix+TABLE_X_Add_high)
1D2C: 19          add  hl,de
1D2D: DD 74 21    ld   (ix+TABLE_X_coord),h
1D30: DD 75 40    ld   (ix+TABLE_X_low),l
1D33: 7C          ld   a,h
1D34: FE 9E       cp   $F8
1D36: 38 40       jr   c,$1D3C
1D38: E1          pop  hl
1D39: C3 6B B2    jp   REMOVE_SPRITES
1D3C: DD 66 41    ld   h,(ix+TABLE_Y_coord)
1D3F: DD 6E 60    ld   l,(ix+TABLE_Y_low)
1D42: DD 56 C1    ld   d,(ix+$0d)
1D45: DD 5E E0    ld   e,(ix+$0e)
1D48: 19          add  hl,de
1D49: DD 74 41    ld   (ix+TABLE_Y_coord),h
1D4C: DD 75 60    ld   (ix+TABLE_Y_low),l
1D4F: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
1D52: FE 9E       cp   $F8
1D54: D8          ret  c
1D55: E1          pop  hl
1D56: C3 6B B2    jp   REMOVE_SPRITES
1D59: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
1D5C: FE 0A       cp   $A0
1D5E: D0          ret  nc
1D5F: DD 34 50    inc  (ix+$14)
1D62: C9          ret

		; Guards which are matching the prison only used a few times in game.
UPDATE_GUARDS:
1D63: CD 10 D1    call $1D10
1D66: CD 96 D1    call $1D78
1D69: 21 BB F0    ld   hl,GUARDS_MARCHING
1D6C: 3A 20 0E    ld   a,(FRAME_SYNC)
1D6F: 0F          rrca
1D70: 0F          rrca
1D71: 0F          rrca
1D72: E6 21       and  $03
1D74: EF          rst	INDEX_ED_AT_2A_PLUS_HL
1D75: C3 88 A3    jp   HW_SPRITE_UPDATER

			; IX = pointer to ???
			; Looks like player bullet to enemy collision detection here.

1D78: DD 66 21    ld   h,(ix+TABLE_X_coord)
1D7B: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
1D7E: DD E5       push ix
1D80: DD 21 00 2E ld   ix,BULLET_SPRITES
1D84: 11 02 00    ld   de,$0020
1D87: 06 60       ld   b,$06
1D89: DD 7E 00    ld   a,(ix+TABLE_STATUS)
1D8C: 3C          inc  a
1D8D: 20 03       jr   nz,$1DB0
1D8F: 7D          ld   a,l
1D90: DD 96 41    sub  (ix+TABLE_Y_coord)
1D93: FE 10       cp   $10
1D95: 30 91       jr   nc,$1DB0
1D97: DD 7E 21    ld   a,(ix+TABLE_X_coord)
1D9A: 94          sub  h
1D9B: C6 80       add  a,$08
1D9D: FE 11       cp   $11
1D9F: 30 E1       jr   nc,$1DB0
1DA1: DD 36 00 F3 ld   (ix+TABLE_STATUS),$3F
1DA5: DD E1       pop  ix
1DA7: DD 36 00 F3 ld   (ix+TABLE_STATUS),$3F
1DAB: DD 36 40 00 ld   (ix+TABLE_X_low),$00
1DAF: C9          ret

1DB0: DD 19       add  ix,de
1DB2: 10 5D       djnz $1D89
1DB4: DD E1       pop  ix
1DB6: C9          ret

UPDATE_LAUNCHER:
1DB7: DD 7E 70    ld   a,(ix+$16)
1DBA: A7          and  a
1DBB: 20 52       jr   nz,$1DF1

1DBD: 21 55 0E    ld   hl,ENEMY_SPRITE_COUNT
1DC0: 34          inc  (hl)
1DC1: 3A D8 0E    ld   a,($E09C)
1DC4: A7          and  a
1DC5: 28 81       jr   z,$1DD0
1DC7: 21 03 10    ld   hl,$1021
1DCA: 11 83 10    ld   de,$1029
1DCD: CD 0F B0    call $1AE1
1DD0: CD B7 F0    call $1E7B
1DD3: DD 7E 80    ld   a,(ix+TABLE_new_X_low)
1DD6: 21 92 F1    ld   hl,$1F38		; this is the mortan gun as this need higher priority to be in front of the man.
1DD9: EF          rst	INDEX_ED_AT_2A_PLUS_HL
1DDA: CD 9C D0    call SPRITE_UPDATE_DE
1DDD: DD 7E 70    ld   a,(ix+$16)
1DE0: A7          and  a
1DE1: C0          ret  nz
1DE2: 11 40 00    ld   de,$0004
1DE5: FD 19       add  iy,de		; add another sprite
1DE7: DD 7E 50    ld   a,(ix+$14)
1DEA: 21 D0 F1    ld   hl,$1F1C		; this is the guy two halfs, head and body
1DED: EF          rst	INDEX_ED_AT_2A_PLUS_HL
1DEE: C3 88 A3    jp   HW_SPRITE_UPDATER

1DF1: CD C9 B2    call ADJUST_Y_POSITION
1DF4: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
1DF7: A7          and  a
1DF8: CA 6B B2    jp   z,REMOVE_SPRITES
1DFB: DD 7E 80    ld   a,(ix+TABLE_new_X_low)
1DFE: 21 92 F1    ld   hl,$1F38
1E01: EF          rst	INDEX_ED_AT_2A_PLUS_HL
1E02: C3 9C D0    jp   SPRITE_UPDATE_DE

1E05: DD E5       push ix
1E07: DD 66 21    ld   h,(ix+TABLE_X_coord)
1E0A: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
1E0D: C6 61       add  a,$07
1E0F: 6F          ld   l,a
1E10: DD 4E F1    ld   c,(ix+$1f)
1E13: DD 21 00 6E ld   ix,ENEMY_SPRITES
1E17: 11 02 00    ld   de,$0020
1E1A: 06 80       ld   b,$08
1E1C: DD 7E 00    ld   a,(ix+TABLE_STATUS)
1E1F: A7          and  a
1E20: 28 61       jr   z,$1E29
1E22: DD 19       add  ix,de
1E24: 10 7E       djnz $1E1C
1E26: DD E1       pop  ix
1E28: C9          ret

1E29: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
1E2D: DD 36 01 04 ld   (ix+$01),$40
1E31: DD 36 20 04 ld   (ix+$02),$40
1E35: DD 74 21    ld   (ix+TABLE_X_coord),h
1E38: DD 74 61    ld   (ix+TABLE_new_X_high),h
1E3B: DD 75 41    ld   (ix+TABLE_Y_coord),l
1E3E: DD 75 81    ld   (ix+TABLE_new_Y_high),l
1E41: DD 36 31 61 ld   (ix+ITEM_TYPE),$07
1E45: DD 36 50 00 ld   (ix+$14),$00
1E49: DD 36 90 00 ld   (ix+$18),$00
1E4D: DD 36 51 10 ld   (iy+TABLE_COUNTDOWN),$10
1E51: DD 70 F1    ld   (ix+$1f),b
1E54: 79          ld   a,c
1E55: E6 21       and  $03
1E57: 21 0D D0    ld   hl,$1CC1
1E5A: 87          add  a,a
1E5B: EF          rst	INDEX_ED_AT_2A_PLUS_HL
1E5C: DD 72 A1    ld   (ix+TABLE_X_Add_low),d
1E5F: DD 73 C0    ld   (ix+TABLE_X_Add_high),e
1E62: 4E          ld   c,(hl)
1E63: 23          inc  hl
1E64: 46          ld   b,(hl)
1E65: DD 70 C1    ld   (ix+$0d),b
1E68: DD 71 E0    ld   (ix+$0e),c
1E6B: DD E1       pop  ix
1E6D: DD 36 70 01 ld   (ix+$16),$01
1E71: FD 36 60 00 ld   (iy+sprite2_x),$00
1E75: FD 36 A0 00 ld   (iy+sprite3_x),$00
1E79: E1          pop  hl
1E7A: C9          ret

1E7B: CD C9 B2    call ADJUST_Y_POSITION
1E7E: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
1E81: FE 96       cp   $78
1E83: DC 41 F0    call c,$1E05
1E86: DD 7E 50    ld   a,(ix+$14)
1E89: A7          and  a
1E8A: 28 34       jr   z,$1EDE
1E8C: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
1E8F: C0          ret  nz
1E90: DD 7E 50    ld   a,(ix+$14)
1E93: DD 34 50    inc  (ix+$14)
1E96: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$1eee	; Table 0
		dw	$1f0b	; Table 1
		dw	$1f17	; Table 2
		dw	$1f17	; Table 3
		dw	$1ed5	; Table 4

PRISONER_ANIMATION:
		dw	$1ea9	; Prisoner 0
		dw	$1eaf	; Prisoner 1
		dw	$1eb5	; Prisoner 2
		dw	$1eaf	; Prisoner 3

1ea9:		db	$02, $00, $01, $e0, $00, $e8		; Simple two sprites ontop of eachother
1eaf:		db	$02, $00, $01, $e1, $00, $e9
1eb5:		db	$02, $00, $01, $e2, $00, $ea

GUARDS_MARCHING:
		dw      $1ec3	; Prisioner Save Me 0
		dw	$1ec9	; Prisioner Save Me 1
		dw	$1ecf	; Prisioner Save Me 2
		dw	$1ec9	; Prisioner Save Me 3
1ec3:		db	$02, $00, $01, $f0, $00, $f8		; Again just two sprites ontop of eachother
1ec9:		db      $02, $00, $01, $f1, $00, $f9
1ecf:		db	$02, $00, $01, $f2, $00, $fa

1ED5: DD 36 50 00 ld   (ix+$14),$00
1ED9: DD 36 51 10 ld   (iy+TABLE_COUNTDOWN),$10
1EDD: C9          ret

1EDE: 3A 20 0E    ld   a,(FRAME_SYNC)
1EE1: E6 F3       and  $3F
1EE3: 47          ld   b,a
1EE4: DD 7E F1    ld   a,(ix+$1f)
1EE7: E6 61       and  $07
1EE9: 87          add  a,a
1EEA: 87          add  a,a
1EEB: 87          add  a,a
1EEC: B8          cp   b
1EED: C0          ret  nz

1EEE: DD 34 50    inc  (ix+$14)
1EF1: DD 36 51 80 ld   (iy+TABLE_COUNTDOWN),$08
1EF5: CD 2E C6    call $6CE2
1EF8: CB 7F       bit  7,a
1EFA: 28 9D       jr   z,$1ED5
1EFC: DD 77 20    ld   (ix+$02),a
1EFF: C6 80       add  a,$08
1F01: 0F          rrca
1F02: 0F          rrca
1F03: 0F          rrca
1F04: 0F          rrca
1F05: E6 61       and  $07
1F07: DD 77 80    ld   (ix+TABLE_new_X_low),a
1F0A: C9          ret

1F0B: DD 36 51 80 ld   (iy+TABLE_COUNTDOWN),$08
1F0F: DD E5       push ix
1F11: CD 84 F1    call $1F48
1F14: DD E1       pop  ix
1F16: C9          ret

1F17: DD 36 51 10 ld   (iy+TABLE_COUNTDOWN),$10
1F1B: C9          ret

1f1c:		dw	$1f26
1f1e:		dw	$1f2c
1f20:		dw	$1f32
1f22:		dw	$1f2c
1f24:		dw	$1f26
1f26:		db	$02, $20, $01, $d0, $00, $d8
1f2c:		db	$02, $20, $01, $d1, $00, $d9
1f32:		db	$02, $20, $01, $d2, $00, $da

1f38:		db	$de, $18		; this is the mortar luncher as different pisitions
1f3a:		db	$de, $18
1f3c:		db	$dd, $18
1f3e:		db	$dc, $18
1f40:		db	$db, $10		; including above is the flip to go left to right in movement.
1f42:		db	$dc, $10
1f44:		db	$dd, $10
1f46:		db	$de, $10

1F48: DD 4E 80    ld   c,(ix+TABLE_new_X_low)
1F4B: DD 66 21    ld   h,(ix+TABLE_X_coord)
1F4E: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
1F51: 11 50 FE    ld   de,ENEMY_GRENADES_SP
1F54: DD 21 0E 4F ld   ix,$E5E0
1F58: DD 7E 00    ld   a,(ix+TABLE_STATUS)
1F5B: A7          and  a
1F5C: 28 B1       jr   z,$1F79
1F5E: 11 90 FE    ld   de,$FE18
1F61: DD 21 0C 4F ld   ix,$E5C0
1F65: DD 7E 00    ld   a,(ix+TABLE_STATUS)
1F68: A7          and  a
1F69: 28 E0       jr   z,$1F79
1F6B: 11 D0 FE    ld   de,$FE1C
1F6E: DD 21 0A 4F ld   ix,$E5A0
1F72: DD 7E 00    ld   a,(ix+TABLE_STATUS)
1F75: A7          and  a
1F76: 28 01       jr   z,$1F79
1F78: C9          ret
sa
1F79: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
1F7D: DD 36 31 40 ld   (ix+ITEM_TYPE),$04
1F81: DD 36 50 00 ld   (ix+$14),$00
1F85: DD 36 51 40 ld   (iy+TABLE_COUNTDOWN),$04
1F89: DD 36 B0 01 ld   (ix+TABLE_SPRITE_QTY),$01
1F8D: DD 72 B1    ld   (ix+$1b),d
1F90: DD 73 D0    ld   (ix+$1c),e
1F93: DD 71 20    ld   (ix+$02),c
1F96: DD 74 21    ld   (ix+TABLE_X_coord),h
1F99: DD 75 41    ld   (ix+TABLE_Y_coord),l
1F9C: DD 7E 20    ld   a,(ix+$02)
1F9F: 21 5B F1    ld   hl,$1FB5
1FA2: EF          rst	INDEX_ED_AT_2A_PLUS_HL
1FA3: DD 7E 21    ld   a,(ix+TABLE_X_coord)
1FA6: 83          add  a,e
1FA7: DD 77 21    ld   (ix+TABLE_X_coord),a
1FAA: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
1FAD: 82          add  a,d
1FAE: DD 77 41    ld   (ix+TABLE_Y_coord),a
1FB1: CD 24 68    call SFX_MORTAR
1FB4: C9          ret
1FB5: BE          cp   (hl)
1FB6: 81          add  a,c
1FB7: BE          cp   (hl)
1FB8: 80          add  a,b
1FB9: BE          cp   (hl)
1FBA: 61          ld   h,c
1FBB: DE 60       sbc  a,$06
1FBD: 40          ld   b,b
1FBE: 60          ld   h,b
1FBF: 60          ld   h,b
1FC0: 61          ld   h,c
1FC1: 60          ld   h,b
1FC2: 80          add  a,b
1FC3: 60          ld   h,b
1FC4: 81          add  a,c
1FC5: CD 01 02    call $2001
1FC8: 0E 80       ld   c,$08
1FCA: DD 7E 20    ld   a,(ix+$02)
1FCD: FE 40       cp   $04
1FCF: 38 20       jr   c,$1FD3
1FD1: 0E 00       ld   c,$00
1FD3: FD 71 01    ld   (iy+sprite_flags),c
1FD6: DD 7E 50    ld   a,(ix+$14)
1FD9: FE 20       cp   $02
1FDB: 28 30       jr   z,$1FEF
1FDD: C6 3D       add  a,$D3
1FDF: FD 77 00    ld   (iy+sprite_number),a
1FE2: DD 7E 21    ld   a,(ix+TABLE_X_coord)
1FE5: FD 77 20    ld   (iy+sprite_x),a
1FE8: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
1FEB: FD 77 21    ld   (iy+sprite_y),a
1FEE: C9          ret
1FEF: 16 00       ld   d,$00
1FF1: 1E 1B       ld   e,$B1
1FF3: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
1FF6: D6 02       sub  $20
1FF8: FE 04       cp   $40
1FFA: D2 9C D0    jp   nc,SPRITE_UPDATE_DE
1FFD: 1D          dec  e
1FFE: C3 9C D0    jp   SPRITE_UPDATE_DE
2001: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
2004: CA B3 02    jp   z,$203B
2007: DD 7E 50    ld   a,(ix+$14)
200A: FE 20       cp   $02
200C: DA C9 B2    jp   c,ADJUST_Y_POSITION
200F: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
2012: 0F          rrca
2013: 0F          rrca
2014: 0F          rrca
2015: 0F          rrca
2016: E6 61       and  $07
2018: 87          add  a,a
2019: 21 A3 02    ld   hl,$202B
201C: DF          rst	ADD_A_TO_HL
201D: 4E          ld   c,(hl)
201E: 23          inc  hl
201F: 46          ld   b,(hl)
2020: CD 5C E9    call $8FD4
2023: 09          add  hl,bc
2024: DD 74 41    ld   (ix+TABLE_Y_coord),h
2027: DD 75 60    ld   (ix+TABLE_Y_low),l
202A: C9          ret

202B:		dw	$fe80	; Table 0
		dw	$fee0	; Table 1
		dw	$ff40	; Table 2
		dw	$ffc0	; Table 3
		dw	$0040	; Table 4
		dw	$00c0	; Table 5
		dw	$0120	; Table 6
		dw	$0180	; Table 7

203B: DD 7E 50    ld   a,(ix+$14)
203E: DD 34 50    inc  (ix+$14)
2041: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$205b	; Table 0
		dw	$2060	; Table 1
		dw	$2048	; Table 2

2048: E1          pop  hl
2049: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
204D: DD 66 21    ld   h,(ix+TABLE_X_coord)
2050: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
2053: FD 36 20 00 ld   (iy+sprite_x),$00
2057: CD C1 38    call MAKE_EXPLOSION
205A: C9          ret

205B: DD 36 51 40 ld   (iy+TABLE_COUNTDOWN),$04
205F: C9          ret

2060: DD 36 51 08 ld   (iy+TABLE_COUNTDOWN),$80
2064: 3A 41 0F    ld   a,(PLAYER_Y)
2067: 67          ld   h,a
2068: 2E 00       ld   l,$00
206A: DD 56 41    ld   d,(ix+TABLE_Y_coord)
206D: 1E 00       ld   e,$00
206F: A7          and  a
2070: ED 52       sbc  hl,de
2072: CB 1C       rr   h
2074: CB 1D       rr   l
2076: CB 2C       sra  h
2078: CB 1D       rr   l
207A: CB 2C       sra  h
207C: CB 1D       rr   l
207E: CB 2C       sra  h
2080: CB 1D       rr   l
2082: CB 2C       sra  h
2084: CB 1D       rr   l
2086: CB 2C       sra  h
2088: CB 1D       rr   l
208A: CB 2C       sra  h
208C: CB 1D       rr   l
208E: DD 74 C1    ld   (ix+$0d),h
2091: DD 75 E0    ld   (ix+$0e),l
2094: DD 36 60 00 ld   (ix+TABLE_Y_low),$00
2098: 3A 21 0F    ld   a,(PLAYER_X)
209B: 67          ld   h,a
209C: 2E 00       ld   l,$00
209E: DD 56 21    ld   d,(ix+TABLE_X_coord)
20A1: 1E 00       ld   e,$00
20A3: A7          and  a
20A4: ED 52       sbc  hl,de
20A6: CB 1C       rr   h
20A8: CB 1D       rr   l
20AA: CB 2C       sra  h
20AC: CB 1D       rr   l
20AE: CB 2C       sra  h
20B0: CB 1D       rr   l
20B2: CB 2C       sra  h
20B4: CB 1D       rr   l
20B6: CB 2C       sra  h
20B8: CB 1D       rr   l
20BA: CB 2C       sra  h
20BC: CB 1D       rr   l
20BE: CB 2C       sra  h
20C0: CB 1D       rr   l
20C2: DD 74 A1    ld   (ix+TABLE_X_Add_low),h
20C5: DD 75 C0    ld   (ix+TABLE_X_Add_high),l
20C8: DD 36 40 00 ld   (ix+TABLE_X_low),$00
20CC: C9          ret

20CD: C6 61       add  a,$07
20CF: 0F          rrca
20D0: 0F          rrca
20D1: 0F          rrca
20D2: 0F          rrca
20D3: E6 E1       and  $0F
20D5: EF          rst	INDEX_ED_AT_2A_PLUS_HL
20D6: C9          ret

UPDATE_BUILDING_TURRET:
20D7: 21 55 0E    ld   hl,ENEMY_SPRITE_COUNT
20DA: 34          inc  (hl)
20DB: 3E 01       ld   a,$01
20DD: 32 4A 0E    ld   ($E0A4),a
20E0: 3A D8 0E    ld   a,($E09C)
20E3: A7          and  a
20E4: 28 81       jr   z,$20EF
20E6: 21 03 10    ld   hl,$1021
20E9: 11 03 10    ld   de,$1021
20EC: CD 0F B0    call $1AE1
20EF: CD C9 B2    call ADJUST_Y_POSITION
20F2: DD 7E 40    ld   a,(ix+TABLE_X_low)
20F5: A7          and  a
20F6: 28 A0       jr   z,$2102
20F8: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
20FB: FE 0E       cp   $E0
20FD: 30 21       jr   nc,$2102
20FF: C3 6B B2    jp   REMOVE_SPRITES
2102: DD 7E 21    ld   a,(ix+TABLE_X_coord)
2105: FE 08       cp   $80
2107: 30 02       jr   nc,$2129
2109: CD A8 03    call $218A
210C: 11 B2 03    ld   de,$213A
210F: DD 7E 90    ld   a,(ix+$18)
2112: A7          and  a
2113: 28 21       jr   z,$2118
2115: 11 C4 03    ld   de,$214C
2118: CD 88 A3    call HW_SPRITE_UPDATER
211B: DD 7E 70    ld   a,(ix+$16)
211E: 21 F4 03    ld   hl,$215E
2121: DF          rst	ADD_A_TO_HL
2122: 5E          ld   e,(hl)
2123: FD 56 CF    ld   d,(iy-$13)
2126: C3 9C D0    jp   SPRITE_UPDATE_DE

2129: CD 4D 03	  call $21c5
212C: 11 66 03    ld   de,$2166
212E: 03	  inc  bc
212F: DD 7E 90    ld   a,(ix+$18)
2132: A7          and  a
2133: 28 2F       jr   z,$2118
2135: 11 96 03    ld   de,$2178
2138: 18 FC       jr   $2118
213A: 80          add  a,b
213B: 18 1F       jr   $212E
213D: 0B          dec  bc
213E: 01 2A 0E    ld   bc,$E0A2
2141: 8A          adc  a,d
2142: 1E 8B       ld   e,$A9
2144: EF          rst	INDEX_ED_AT_2A_PLUS_HL
2145: 1A          ld   a,(de)
2146: FF          rst  ADD_DE_TO_EVENT
2147: 1B          dec  de
2148: E1          pop  hl
2149: 3A FE 9B    ld   a,($B9FE)

214c:   db      $08, $90, $f1, $a4, $01, $a5, $e0, $ab, $f0
2155:   db      $ac, $ef, $b3, $ff, $b4, $0f, $b5, $fe, $bc

215e:   db      $a3, $aa, $aa, $ad, $ad, $a0, $a0, $a0
2166:   db      $08, $98, $11, $a1, $01, $a2, $20, $a8

216e:   db      $10, $a9, $2f, $b0, $1f, $b1, $0f, $b2,$1e, $b9 
2178:	db	$08, $98, $11, $a4, $01, $a5
217e:   db      $20, $ab, $10, $ac, $2f, $b3, $1f, $b4
2186:   db      $0f, $b5, $1e, $bc

218A: DD 7E 40    ld   a,(ix+TABLE_X_low)
218D: A7          and  a
218E: C0          ret  nz
218F: 3A 20 0E    ld   a,(FRAME_SYNC)
2192: 47          ld   b,a
2193: E6 61       and  $07
2195: C0          ret  nz
2196: 78          ld   a,b
2197: 0F          rrca
2198: 0F          rrca
2199: 0F          rrca
219A: E6 61       and  $07
219C: 47          ld   b,a
219D: DD 7E F1    ld   a,(ix+$1f)
21A0: E6 61       and  $07
21A2: B8          cp   b
21A3: C0          ret  nz
21A4: CD 2E C6    call $6CE2
21A7: 47          ld   b,a
21A8: C6 80       add  a,$08
21AA: D6 8C       sub  $C8
21AC: FE 86       cp   $68
21AE: D0          ret  nc
21AF: DD 70 20    ld   (ix+$02),b
21B2: 0F          rrca
21B3: 0F          rrca
21B4: 0F          rrca
21B5: 0F          rrca
21B6: E6 E1       and  $0F
21B8: DD 77 70    ld   (ix+$16),a
21BB: DD 36 71 00 ld   (ix+$17),$00
21BF: 21 BF 03    ld   hl,$21FB
21C2: C3 43 22    jp   $2225

21C5: DD 7E F1    ld   a,(ix+$1f)
21C8: 87          add  a,a
21C9: 87          add  a,a
21CA: 87          add  a,a
21CB: 87          add  a,a
21CC: E6 F3       and  $3F
21CE: 47          ld   b,a
21CF: 3A 20 0E    ld   a,(FRAME_SYNC)
21D2: E6 F3       and  $3F
21D4: B8          cp   b
21D5: C0          ret  nz
21D6: CD 2E C6    call $6CE2
21D9: 47          ld   b,a
21DA: C6 80       add  a,$08
21DC: D6 14       sub  $50
21DE: FE 86       cp   $68
21E0: D0          ret  nc
21E1: DD 70 20    ld   (ix+$02),b
21E4: 0F          rrca
21E5: 0F          rrca
21E6: 0F          rrca
21E7: 0F          rrca
21E8: E6 E1       and  $0F
21EA: 47          ld   b,a
21EB: 3E 60       ld   a,$06
21ED: 90          sub  b
21EE: DD 77 70    ld   (ix+$16),a
21F1: DD 36 71 80 ld   (ix+$17),$08
21F5: 21 10 22    ld   hl,$2210			; Ofset table set for position
21F8: C3 43 22    jp   $2225


21FB:		db	$06, $f6, $bb, $09, $f6, $bb, $09, $f6, $bb, $0c, $fb, $ba, $0c, $fb, $ba, $0a, $05, $b8, $0a, $05, $b8
2210:		db	$fa, $f6, $bb, $f7, $f6, $bb, $f7, $f6, $bb, $f4, $fb, $ba, $f4, $fb, $ba, $f6, $05, $b8, $f6, $05, $b8

2225: DD E5       push ix
2227: 11 6A 22    ld   de,$22A6
222A: D5          push de
222B: DD 7E 70    ld   a,(ix+$16)
222E: 47          ld   b,a
222F: 87          add  a,a
2230: 80          add  a,b
2231: E7          rst	INDEX_A_PLUS_HL
2232: DD 86 21    add  a,(ix+TABLE_X_coord)
2235: 57          ld   d,a
2236: 23          inc  hl
2237: 7E          ld   a,(hl)
2238: DD 86 41    add  a,(ix+TABLE_Y_coord)
223B: 5F          ld   e,a
223C: 23          inc  hl
223D: 4E          ld   c,(hl)
223E: DD 46 20    ld   b,(ix+$02)
2241: DD 21 0E 4F ld   ix,$E5E0
2245: 21 50 FE    ld   hl,ENEMY_GRENADES_SP
2248: DD 7E 00    ld   a,(ix+TABLE_STATUS)
224B: A7          and  a
224C: 28 B1       jr   z,$2269
224E: DD 21 0C 4F ld   ix,$E5C0
2252: 21 90 FE    ld   hl,HW_SPRITE_6		; 2nd Grenade
2255: DD 7E 00    ld   a,(ix+TABLE_STATUS)
2258: A7          and  a
2259: 28 E0       jr   z,$2269
225B: DD 21 0A 4F ld   ix,$E5A0
225F: 21 D0 FE    ld   hl,HW_SPRITE_7		; 3rd Grenade
2262: DD 7E 00    ld   a,(ix+TABLE_STATUS)
2265: A7          and  a
2266: 28 01       jr   z,$2269
2268: C9          ret

2269: DD 36 B0 01 ld   (ix+TABLE_SPRITE_QTY),$01
226D: DD 74 B1    ld   (ix+$1b),h
2270: DD 75 D0    ld   (ix+$1c),l
2273: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
2277: DD 70 01    ld   (ix+$01),b
227A: DD 70 20    ld   (ix+$02),b
227D: DD 71 30    ld   (ix+$12),c
2280: DD 72 21    ld   (ix+TABLE_X_coord),d
2283: DD 73 41    ld   (ix+TABLE_Y_coord),e
2286: DD 36 E1 40 ld   (ix+$0f),$04
228A: CD 46 C6    call $6C64
228D: DD 72 A1    ld   (ix+TABLE_X_Add_low),d
2290: DD 73 C0    ld   (ix+TABLE_X_Add_high),e
2293: DD 70 C1    ld   (ix+$0d),b
2296: DD 71 E0    ld   (ix+$0e),c
2299: DD 36 31 60 ld   (ix+ITEM_TYPE),$06
229D: DD 36 50 00 ld   (ix+$14),$00
22A1: DD 36 51 40 ld   (iy+TABLE_COUNTDOWN),$04
22A5: C9          ret

22A6: DD E1       pop  ix
22A8: C9          ret

22A9: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
22AC: 28 45       jr   z,$22F3
22AE: DD 7E 50    ld   a,(ix+$14)
22B1: A7          and  a
22B2: 28 C3       jr   z,$22E1
22B4: CD 5C E9    call $8FD4
22B7: 3A 00 0F    ld   a,(PLAYER_DATA)
22BA: 3C          inc  a
22BB: 20 D1       jr   nz,$22DA
22BD: 3A 21 0F    ld   a,(PLAYER_X)
22C0: DD 96 21    sub  (ix+TABLE_X_coord)
22C3: C6 C0       add  a,$0C
22C5: FE 91       cp   $19
22C7: 30 11       jr   nc,$22DA
22C9: 3A 41 0F    ld   a,(PLAYER_Y)
22CC: DD 96 41    sub  (ix+TABLE_Y_coord)
22CF: C6 C0       add  a,$0C
22D1: FE 91       cp   $19
22D3: 30 41       jr   nc,$22DA
22D5: 3E F3       ld   a,$3F
22D7: 32 00 0F    ld   (PLAYER_DATA),a
22DA: 1E 1B       ld   e,$B1
22DC: 16 12       ld   d,$30
22DE: C3 9C D0    jp   SPRITE_UPDATE_DE
22E1: 16 08       ld   d,$80
22E3: DD 5E 30    ld   e,(ix+$12)
22E6: DD 7E 21    ld   a,(ix+TABLE_X_coord)
22E9: FE 08       cp   $80
22EB: DA 9C D0    jp   c,SPRITE_UPDATE_DE
22EE: 16 88       ld   d,$88
22F0: C3 9C D0    jp   SPRITE_UPDATE_DE
22F3: DD 7E 50    ld   a,(ix+$14)
22F6: DD 34 50    inc  (ix+$14)
22F9: A7          and  a
22FA: 28 11       jr   z,$230D
22FC: DD 66 21    ld   h,(ix+TABLE_X_coord)
22FF: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
2302: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
2306: FD 36 20 00 ld   (iy+sprite_x),$00
230A: C3 C1 38    jp   MAKE_EXPLOSION
230D: DD 36 51 14 ld   (iy+TABLE_COUNTDOWN),$50
2311: C9          ret
2312: C9          ret
2313: C9          ret

UPDATE_LARGE_TRUCK:
2314: 21 55 0E    ld   hl,ENEMY_SPRITE_COUNT		; Increase bad guys.
2317: 34          inc  (hl)
2318: 3A D8 0E    ld   a,($E09C)
231B: A7          and  a
231C: 28 81       jr   z,$2327
231E: 21 13 00    ld   hl,$0031
2321: 11 03 10    ld   de,$1021
2324: CD 0F B0    call $1AE1

2327: CD C9 B2    call ADJUST_Y_POSITION
232A: CD 13 23    call $2331
232D: CD 10 42    call $2410
2330: C9          ret
2331: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
2334: FE 8E       cp   $E8
2336: D0          ret  nc
2337: DD 7E 50    ld   a,(ix+$14)
233A: E6 01       and  $01
233C: 20 51       jr   nz,$2353
233E: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
2341: C0          ret  nz
2342: DD 34 50    inc  (ix+$14)
2345: DD 36 51 71 ld   (iy+TABLE_COUNTDOWN),$17
2349: CD B6 68    call SFX_BIKER_OFF
234C: C9          ret
234D: CD F7 68    call SFX_FLUSH
2350: C3 6B B2    jp   REMOVE_SPRITES
2353: 3A 20 0E    ld   a,(FRAME_SYNC)
2356: E6 01       and  $01
2358: C0          ret  nz
2359: DD 35 21    dec  (ix+TABLE_X_coord)
235C: DD 7E 21    ld   a,(ix+TABLE_X_coord)
235F: FE EF       cp   $EF
2361: CA C5 23    jp   z,$234D
2364: DD 7E 70    ld   a,(ix+$16)
2367: FE 41       cp   $05
2369: D0          ret  nc
236A: DD 7E 40    ld   a,(ix+TABLE_X_low)
236D: A7          and  a
236E: C0          ret  nz
236F: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
2372: C0          ret  nz
2373: DD 34 50    inc  (ix+$14)
2376: DD 36 51 02 ld   (iy+TABLE_COUNTDOWN),$20
237A: CD 56 68    call SFX_RETURN
237D: DD 4E 70    ld   c,(ix+$16)
2380: DD 34 70    inc  (ix+$16)
2383: DD E5       push ix
2385: 21 C1 42    ld   hl,$240D
2388: E5          push hl
2389: DD 7E 21    ld   a,(ix+TABLE_X_coord)
238C: C6 12       add  a,$30
238E: 67          ld   h,a
238F: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
2392: C6 80       add  a,$08
2394: 6F          ld   l,a
2395: DD 21 00 6E ld   ix,ENEMY_SPRITES
2399: 06 80       ld   b,$08
239B: 11 02 00    ld   de,$0020
239E: DD 7E 00    ld   a,(ix+TABLE_STATUS)
23A1: A7          and  a
23A2: 28 41       jr   z,$23A9
23A4: DD 19       add  ix,de
23A6: 10 7E       djnz $239E
23A8: C9          ret
23A9: DD 35 00    dec  (ix+TABLE_STATUS)
23AC: DD 74 21    ld   (ix+TABLE_X_coord),h
23AF: DD 74 61    ld   (ix+TABLE_new_X_high),h
23B2: DD 75 41    ld   (ix+TABLE_Y_coord),l
23B5: DD 75 81    ld   (ix+TABLE_new_Y_high),l
23B8: DD 36 E1 00 ld   (ix+$0f),$00
23BC: DD 36 11 00 ld   (ix+$11),$00
23C0: DD 36 31 80 ld   (ix+ITEM_TYPE),$08
23C4: DD 36 50 00 ld   (ix+$14),$00
23C8: DD 36 51 00 ld   (iy+TABLE_COUNTDOWN),$00
23CC: 79          ld   a,c
23CD: 21 BD 23    ld   hl,$23DB
23D0: EF          rst	INDEX_ED_AT_2A_PLUS_HL
23D1: DD 72 70    ld   (ix+$16),d
23D4: DD 73 71    ld   (ix+$17),e
23D7: CD 4C 59    call $95C4
23DA: C9          ret

23db:		dw	$23e5
23dd:		dw	$23ed
23df:		dw	$23f5
23e1:		dw	$23fd
23e3:		dw	$2405

23e5:		db	$bf, $c0, $40, $e0, $40, $f0, $80, $ff
23ed:		db	$bf, $c0, $40, $e0, $40, $f0, $80, $ff
23f5:		db	$bf, $c0, $40, $e0, $40, $f0, $80, $ff
23fd:		db	$bf, $c0, $40, $e0, $40, $f0, $80, $ff
2405:		db	$bf, $c0, $40, $e0, $40, $f0, $80, $ff

240F: C9          ret
2410: 11 70 42    ld   de,$2416
2413: C3 88 A3    jp   HW_SPRITE_UPDATER

2416:		db	$08, $50, $01, $e0, $11, $e1, $21, $e2, $31, $e3, $00, $e8, $10, $e9, $20, $ea, $30, $eb

UPDATE_GUNNER_TRENCH:
2428: 21 55 0E    ld   hl,ENEMY_SPRITE_COUNT
242B: 34          inc  (hl)
242C: 3A D8 0E    ld   a,($E09C)
242F: A7          and  a
2430: 28 81       jr   z,$243B
2432: 21 03 10    ld   hl,$1021
2435: 11 03 10    ld   de,$1021
2438: CD 0F B0    call $1AE1
243B: 3A 26 0E    ld   a,(SCREEN_SCROLLING)		; scrolling screen?
243E: A7          and  a
243F: 28 60       jr   z,$2447
2441: DD 35 41    dec  (ix+TABLE_Y_coord)				; Y position move with scroll
2444: CA AC 42    jp   z,KILL_OFF_ENEMY1		; off screen kill this enemy from table
2447: CD E4 42    call $244E
244A: CD 3D 42    call $24D3
244D: C9          ret

244E: DD 35 51    dec  (iy+TABLE_COUNTDOWN)				; it's the final countdown (der der der der)
2451: 20 55       jr   nz,$24A8
2453: DD 7E 41    ld   a,(ix+TABLE_Y_coord)			; Get position y coordinate
2456: 47          ld   b,a
2457: 3A 41 0F    ld   a,(PLAYER_Y)
245A: B8          cp   b
245B: 30 82       jr   nc,RETURN_BACK_KILL_ENEMY1	; If position is as players Y then dissapear off

245D: DD 34 50    inc  (ix+$14)
2460: DD 7E 50    ld   a,(ix+$14)
2463: FE 20       cp   $02
2465: 28 22       jr   z,$2489
2467: FE 41       cp   $05
2469: 28 A1       jr   z,$2476
246B: CD E3 98    call $982F
246E: E6 61       and  $07
2470: C6 61       add  a,$07
2472: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a
2475: C9          ret
2476: CD E3 98    call $982F
2479: E6 F3       and  $3F
247B: C6 02       add  a,$20
247D: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a
2480: DD 36 50 00 ld   (ix+$14),$00
2484: C9          ret

RETURN_BACK_KILL_ENEMY1:
2485: E1          pop  hl
2486: C3 AC 42    jp   KILL_OFF_ENEMY1
2489: CD 2E C6    call $6CE2
248C: 47          ld   b,a
248D: D6 18       sub  $90
248F: FE 06       cp   $60
2491: 38 10       jr   c,$24A3
2493: DD 36 50 00 ld   (ix+$14),$00
2497: CD E3 98    call $982F
249A: E6 F1       and  $1F
249C: 87          add  a,a
249D: C6 02       add  a,$20
249F: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a
24A2: C9          ret
24A3: DD 36 51 04 ld   (iy+TABLE_COUNTDOWN),$40
24A7: C9          ret

24A8: DD 7E 50    ld   a,(ix+$14)
24AB: FE 20       cp   $02
24AD: C0          ret  nz
24AE: 3A 20 0E    ld   a,(FRAME_SYNC)
24B1: E6 E1       and  $0F
24B3: 47          ld   b,a
24B4: DD 7E F1    ld   a,(ix+$1f)
24B7: E6 E1       and  $0F
24B9: B8          cp   b
24BA: C0          ret  nz
24BB: CD 2E C6    call $6CE2
24BE: 47          ld   b,a
24BF: D6 0A       sub  $A0
24C1: FE 04       cp   $40
24C3: D0          ret  nc
24C4: DD 70 20    ld   (ix+$02),b
24C7: C3 11 58    jp   $9411

KILL_OFF_ENEMY1:
24CA: DD 36 00 00 ld   (ix+TABLE_STATUS),$00		; zap sprite
24CE: FD 36 20 00 ld   (iy+sprite_x),$00		; zap the x coordinate
24D2: C9          ret

24D3: DD 7E 50    ld   a,(ix+$14)			; Animation frame
24D6: FE 20       cp   $02				; is = too it (see what I did there!)
24D8: 28 71       jr   z,$24F1
24DA: 47          ld   b,a				; save to b
24DB: DD 7E 71    ld   a,(ix+$17)
24DE: 21 91 43    ld   hl,$2519
24E1: 16 10       ld   d,$10
24E3: A7          and  a
24E4: 28 41       jr   z,$24EB
24E6: 21 62 43    ld   hl,$2526
24E9: 16 00       ld   d,$00
24EB: 78          ld   a,b
24EC: E7          rst	INDEX_A_PLUS_HL
24ED: 5F          ld   e,a
24EE: C3 9C D0    jp   SPRITE_UPDATE_DE
24F1: 16 10       ld   d,$10				; sprite attributes color palette here combat colour set
24F3: 21 11 43    ld   hl,$2511
24F6: DD 7E 71    ld   a,(ix+$17)
24F9: A7          and  a
24FA: 28 41       jr   z,$2501
24FC: 21 F0 43    ld   hl,$251E				; Same enemy type but this is guy in the croc infested swamp water
24FF: 16 00       ld   d,$00				; the palette is base 0 this is blue set very aquaman style.
2501: DD 7E 20    ld   a,(ix+$02)
2504: C6 61       add  a,$07
2506: 0F          rrca
2507: 0F          rrca
2508: 0F          rrca
2509: 0F          rrca
250A: E6 61       and  $07
250C: E7          rst	INDEX_A_PLUS_HL
250D: 5F          ld   e,a						; sprite number
250E: C3 9C D0    jp   SPRITE_UPDATE_DE

2511:		db	$97, $97, $97, $97, $82, $9f, $9f, $9f		; gun position 97 left 82 down and 9f right
2519:		db	$80, $81, $82, $81, $80				; boob up and down
251E:		db	$fe, $fe, $fe, $fe, $8a, $fd, $fd, $fd		; man in water positions
2526:		db	$88, $89, $8a, $89, $88				; Man in water same as boob above

252B: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
252E: 28 F0       jr   z,$254E
2530: CD F5 43    call $255F
2533: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
2536: 21 64 43    ld   hl,$2546
2539: 0F          rrca
253A: 0F          rrca
253B: 0F          rrca
253C: 0F          rrca
253D: E6 E1       and  $0F
253F: E7          rst	INDEX_A_PLUS_HL
2540: 5F          ld   e,a
2541: 16 10       ld   d,$10
2543: C3 9C D0    jp   SPRITE_UPDATE_DE
2546: 5A          ld   e,d
2547: 3B          dec  sp
2548: 3B          dec  sp
2549: 3A 3A 3B    ld   a,($B3B2)
254C: 3B          dec  sp
254D: 5A          ld   e,d
254E: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
2552: DD 66 21    ld   h,(ix+TABLE_X_coord)
2555: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
2558: FD 36 20 00 ld   (iy+sprite_x),$00
255C: C3 C1 38    jp   MAKE_EXPLOSION
255F: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)	; Countdown
2562: 0F          rrca
2563: 0F          rrca
2564: 0F          rrca
2565: 0F          rrca			; / 16
2566: E6 61       and  $07		; 0 - 7
2568: 87          add  a,a		; Double for lookup value
2569: 21 88 43    ld   hl,$2588		; Addition able
256C: DF          rst	ADD_A_TO_HL
256D: 4E          ld   c,(hl)		; low add
256E: 23          inc  hl
256F: 46          ld   b,(hl)		; high add
2570: CD 5C E9    call $8FD4
2573: 09          add  hl,bc
2574: DD 74 41    ld   (ix+TABLE_Y_coord),h
2577: DD 75 60    ld   (ix+TABLE_Y_low),l
257A: 7C          ld   a,h
257B: FE 9E       cp   $F8		; off screen?
257D: D8          ret  c
257E: E1          pop  hl		; yes so kill of this item
257F: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
2583: FD 36 20 00 ld   (iy+sprite_x),$00
2587: C9          ret

		; add low and add high
2588:	        db	$80, $fe		; this will be -2.5 pixels
		db      $e0, $fe	
		db      $40, $ff
		db	$c0, $ff
		db	$40, $00
		db	$c0, $00
		db	$20, $01		; 1.125 pixels ( that.s $100/$20
		db	$80, $01		; 1.5 pixels add

2598: DD 7E 00    ld   a,(ix+TABLE_STATUS)
259B: FE FE       cp   $FE
259D: C8          ret  z
259E: CD 5C E9    call $8FD4
25A1: 1E 7E       ld   e,$F6
25A3: 16 16       ld   d,$70
25A5: CD 9C D0    call SPRITE_UPDATE_DE
25A8: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
25AB: C0          ret  nz
25AC: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
25B0: FD 36 20 00 ld   (iy+sprite_x),$00
25B4: DD 66 21    ld   h,(ix+TABLE_X_coord)
25B7: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
25BA: C3 C1 38    jp   MAKE_EXPLOSION
25BD: C9          ret
25BE: 21 55 0E    ld   hl,ENEMY_SPRITE_COUNT
25C1: 34          inc  (hl)
25C2: 3A D8 0E    ld   a,($E09C)
25C5: A7          and  a
25C6: 28 81       jr   z,$25D1
25C8: 21 03 10    ld   hl,$1021
25CB: 11 13 80    ld   de,$0831
25CE: CD 0F B0    call $1AE1
25D1: CD C9 B2    call ADJUST_Y_POSITION
25D4: CD 20 62    call $2602
25D7: CD C6 62    call $266C
25DA: DD 7E 50    ld   a,(ix+$14)
25DD: 21 B1 63    ld   hl,$271B
25E0: E7          rst	INDEX_A_PLUS_HL
25E1: 5F          ld   e,a
25E2: 16 14       ld   d,$50
25E4: DD 7E 21    ld   a,(ix+TABLE_X_coord)
25E7: F5          push af
25E8: C6 80       add  a,$08
25EA: DD 77 21    ld   (ix+TABLE_X_coord),a
25ED: CD 9C D0    call SPRITE_UPDATE_DE
25F0: F1          pop  af
25F1: DD 77 21    ld   (ix+TABLE_X_coord),a
25F4: 11 40 00    ld   de,$0004
25F7: FD 19       add  iy,de
25F9: 11 F1 63    ld   de,$271F
25FC: CD 88 A3    call HW_SPRITE_UPDATER
25FF: C3 88 A3    jp   HW_SPRITE_UPDATER
2602: CD 15 62    call $2651
2605: DD 7E 71    ld   a,(ix+$17)
2608: A7          and  a
2609: 28 92       jr   z,$2643
260B: 11 06 01    ld   de,$0160
260E: DD 7E 40    ld   a,(ix+TABLE_X_low)
2611: DD 66 41    ld   h,(ix+TABLE_Y_coord)
2614: DD 6E 60    ld   l,(ix+TABLE_Y_low)
2617: 19          add  hl,de
2618: DD 74 41    ld   (ix+TABLE_Y_coord),h
261B: DD 75 60    ld   (ix+TABLE_Y_low),l
261E: CE 00       adc  a,$00
2620: DD 77 40    ld   (ix+TABLE_X_low),a
2623: A7          and  a
2624: 28 C0       jr   z,$2632
2626: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
2629: FE 10       cp   $10
262B: D2 32 62    jp   nc,$2632
262E: E1          pop  hl
262F: C3 6B B2    jp   REMOVE_SPRITES
2632: DD 7E 90    ld   a,(ix+$18)
2635: A7          and  a
2636: C0          ret  nz
2637: 7C          ld   a,h
2638: FE 1E       cp   $F0
263A: D8          ret  c
263B: DD 36 71 00 ld   (ix+$17),$00
263F: CD 56 68    call SFX_RETURN
2642: C9          ret
2643: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
2646: FE 18       cp   $90
2648: D0          ret  nc
2649: CD B6 68    call SFX_BIKER_OFF
264C: DD 36 71 01 ld   (ix+$17),$01
2650: C9          ret
2651: DD 7E 90    ld   a,(ix+$18)
2654: A7          and  a
2655: C0          ret  nz
2656: 3A 20 0E    ld   a,(FRAME_SYNC)
2659: CB 4F       bit  1,a
265B: C8          ret  z
265C: DD 35 70    dec  (ix+$16)
265F: C0          ret  nz
2660: DD 36 90 01 ld   (ix+$18),$01
2664: DD 36 71 01 ld   (ix+$17),$01
2668: CD B6 68    call SFX_BIKER_OFF
266B: C9          ret
266C: DD 7E 50    ld   a,(ix+$14)
266F: A7          and  a
2670: 28 A7       jr   z,$26DD
2672: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
2675: C0          ret  nz
2676: DD 34 50    inc  (ix+$14)
2679: DD 7E 50    ld   a,(ix+$14)
267C: FE 21       cp   $03
267E: 28 81       jr   z,$2689
2680: FE 40       cp   $04
2682: 28 54       jr   z,$26D8
2684: DD 36 51 80 ld   (iy+TABLE_COUNTDOWN),$08
2688: C9          ret
2689: DD 36 51 80 ld   (iy+TABLE_COUNTDOWN),$08
268D: DD E5       push ix
268F: DD 66 E1    ld   h,(ix+$0f)
2692: DD 6E 10    ld   l,(ix+$10)
2695: DD 56 21    ld   d,(ix+TABLE_X_coord)
2698: DD 5E 41    ld   e,(ix+TABLE_Y_coord)
269B: DD 46 11    ld   b,(ix+$11)
269E: DD 4E 30    ld   c,(ix+$12)
26A1: E5          push hl
26A2: DD E1       pop  ix
26A4: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
26A8: DD 36 31 C0 ld   (ix+ITEM_TYPE),$0C
26AC: DD 72 21    ld   (ix+TABLE_X_coord),d
26AF: DD 73 41    ld   (ix+TABLE_Y_coord),e
26B2: DD 70 B1    ld   (ix+$1b),b
26B5: DD 71 D0    ld   (ix+$1c),c
26B8: CD 2E C6    call $6CE2
26BB: DD 77 01    ld   (ix+$01),a
26BE: DD 36 E1 01 ld   (ix+$0f),$01
26C2: CD 46 C6    call $6C64
26C5: DD 72 A1    ld   (ix+TABLE_X_Add_low),d
26C8: DD 73 C0    ld   (ix+TABLE_X_Add_high),e
26CB: DD 70 C1    ld   (ix+$0d),b
26CE: DD 71 E0    ld   (ix+$0e),c
26D1: DD 36 51 12 ld   (iy+TABLE_COUNTDOWN),$30
26D5: DD E1       pop  ix
26D7: C9          ret
26D8: DD 36 50 00 ld   (ix+$14),$00
26DC: C9          ret
26DD: DD 7E 40    ld   a,(ix+TABLE_X_low)
26E0: A7          and  a
26E1: C0          ret  nz
26E2: 3A 20 0E    ld   a,(FRAME_SYNC)
26E5: E6 F3       and  $3F
26E7: C0          ret  nz
26E8: 21 0E 4F    ld   hl,$E5E0
26EB: 11 50 FE    ld   de,ENEMY_GRENADES_SP
26EE: 7E          ld   a,(hl)
26EF: A7          and  a
26F0: 28 31       jr   z,$2705
26F2: 21 0C 4F    ld   hl,$E5C0
26F5: 11 90 FE    ld   de,$FE18
26F8: 7E          ld   a,(hl)
26F9: A7          and  a
26FA: 28 81       jr   z,$2705
26FC: 21 0A 4F    ld   hl,$E5A0
26FF: 11 D0 FE    ld   de,$FE1C
2702: 7E          ld   a,(hl)
2703: A7          and  a
2704: C0          ret  nz
2705: 36 FE       ld   (hl),$FE
2707: DD 74 E1    ld   (ix+$0f),h
270A: DD 75 10    ld   (ix+$10),l
270D: DD 72 11    ld   (ix+$11),d
2710: DD 73 30    ld   (ix+$12),e
2713: DD 34 50    inc  (ix+$14)
2716: DD 36 51 80 ld   (iy+TABLE_COUNTDOWN),$08
271A: C9          ret

271B: 6E          ld   l,(hl)
271C: 6F          ld   l,a
271D: EE EF       xor  $EF
271F: 21 14 20    ld   hl,$0250
2722: 4E          ld   c,(hl)
2723: 01 CE 00    ld   bc,$00EC
2726: 5E          ld   e,(hl)
2727: 21 94 30    ld   hl,$1258
272A: 4E          ld   c,(hl)
272B: 11 CE 10    ld   de,$10EC
272E: 5E          ld   e,(hl)
272F: CD 65 63    call CHECK_EVENT_TABLE	; Check for new trigger event/items etc
2732: 3A 4A 0E    ld   a,($E0A4)
2735: 32 4B 0E    ld   ($E0A5),a
2738: AF          xor  a
2739: 32 4A 0E    ld   ($E0A4),a
273C: CD F2 A2    call UPDATE_CURRENT_EVENTS; Process current table list including just created ones
273F: C9          ret

2740: 21 EA 17    ld   hl,BG_EVENT_TABLE; Starting position in ROM
2743: 22 E9 0E    ld   (BG_EVENT_POINTER),hl; Save this 
2746: C9          ret

		; So here we check the event pointer, which just move along the compare table
		; when a matching y position is reached then insert the action type into the next free slot
		; call an initial setup for this type, such as setup cords or other paramaters etc.
		; Each event has 32 bytes of data a lot is common, but many variarions of some offsets are unique for this type.

CHECK_EVENT_TABLE:
2747: FD 2A E9 0E ld   iy,(BG_EVENT_POINTER) ; Read current for master index
274B: FD 6E 00    ld   l,(iy+$00)	; First byte is y low
274E: FD 7E 01    ld   a,(iy+$01)	; 2nd is y high
2751: 67          ld   h,a		; save to h
2752: FE FF       cp   $FF		; if y is high (then just say no to drugs)
2754: C8          ret  z		; then end of data table is reached so exit
2755: ED 5B B5 0E ld   de,(MAP_OFFSET)	; Current Y position
2759: 7A          ld   a,d
275A: 53          ld   d,e
275B: 5F          ld   e,a
275C: A7          and  a
275D: ED 52       sbc  hl,de		; Subtract TABLE_Y - MAP_OFFSET
275F: 7C          ld   a,h
2760: A7          and  a
2761: 28 A0       jr   z,$276D		; Triggered event
2763: CB 7F       bit  7,a
2765: C8          ret  z		; not close yet so just exit
2766: 11 60 00    ld   de,$0006		; Advance table 6 bytes / entry
2769: FD 19       add  iy,de		; update pointer index
276B: 18 FC       jr   $274B		; try next one

276D: FD 66 20    ld   h,(iy+$02)	; Now read the event type, see table for list of function
2770: FD 4E 21    ld   c,(iy+$03)	; Read the table X position
2773: FD 5E 40    ld   e,(iy+$04)	; Hardware sprite address low address
2776: FD 56 41    ld   d,(iy+$05)	; Hardware sprite address high address
2779: DD 21 00 4F ld   ix,BACKGROUND_ITEMS	; Ram address for the table start
277D: D9          exx			; get back other register set
277E: 11 02 00    ld   de,$0020		; Tableset is 32 bytes / entry (very high really)
2781: 06 80       ld   b,$08		; 8 table entries for these max amount
2783: DD 7E 00    ld   a,(ix+TABLE_STATUS)	; So now we'll find a free slot for this bad boy
2786: A7          and  a		; 0 is free
2787: 28 81       jr   z,$2792		; if its -1 well'll check the next one
2789: DD 19       add  ix,de		; advance pointer
278B: 10 7E       djnz $2783		; check the rest. if none left, keep the pointer
278D: FD 22 E9 0E ld   (BG_EVENT_POINTER),iy; This means actually if more than one item remains
2791: C9          ret			; it would appear by magic once a free slot appears (maybe)

2792: DD 70 F1    ld   (ix+$1f),b	; Save slot number b into last part of table
2795: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF	; Now make this slot active
2799: D9          exx			; get back our table data
279A: DD 72 B1    ld   (ix+$1b),d	; save sprite address here high byte
279D: DD 73 D0    ld   (ix+$1c),e	; save sprite address low bytw
27A0: DD 74 31    ld   (ix+ITEM_TYPE),h	; the item type
27A3: DD 71 21    ld   (ix+TABLE_X_coord),c	; x coordinate
27A6: DD 75 41    ld   (ix+TABLE_Y_coord),l	; y coordinate loe mostly starts at ff but it might not be if during helicopter ride.
27A9: DD 36 40 00 ld   (ix+TABLE_X_low),$00	; y coordinate high starts at 0
27AD: 11 60 00    ld   de,$0006		; Table entry 6 bytes / entry
27B0: FD 19       add  iy,de		; advance on the pointer
27B2: FD 22 E9 0E ld   (BG_EVENT_POINTER),iy; and save for the next read cycle
27B6: DD 7E 31    ld   a,(ix+ITEM_TYPE)	; Lets get the control value for an initial setup
27B9: 47          ld   b,a		; now this is multipler for rst call
27BA: 21 E0 A2    ld   hl,ITEM_SPRITES_USED_TABLE	; This is the table of values
27BD: E7          rst	INDEX_A_PLUS_HL		; get value at (hl+a)
27BE: DD 77 B0    ld   (ix+TABLE_SPRITE_QTY),a	; save to master table how many sprites for this item is to use
27C1: 78          ld   a,b		; get back original control value
27C2: F7          rst  JUMP_TABLE		; Jump table from count a

		; Jump table depending on the control value the initial setup for each action sprite(s) / animation
		dw	SET_GUNNER_BEHIND_SANDBAG	; Control Number 0 same as $2f
		dw	SET_PRISONER_NEEDS_HELP		; Control Number 1
		dw	SET_PRISONER_GUARD		; Control Number 2
		dw	SET_MAN_WITH_MORTAR		; Control Number 3
		dw	$1f48				; Control Number 4
		dw	SET_LARGE_BLOCK_BUILDING_TURRET	; Control Number 5
		dw	$2225				; Control Number 6
		dw	SET_NOTHING			; Control Number 7
		dw	$29dd				; Control Number 8
		dw	SET_GUNNER_IN_WINDOW		; Control Number 9
		dw	SET_LARGE_TRUCK			; Control Number A
		dw	$29fa				; Control Number B
		dw	SET_NOTHING			; Control Number C
		dw	SET_NOTHING			; Control Number D
		dw	SET_GUNNER_TRENCH		; Control Number E
		dw	$295c				; Control Number F
		dw	SET_NOTHING			; Control Number 10
		dw	SET_NOTHING			; Control Number 11
		dw	SET_BARRACK_DOOR_OPEN_CLOSE_ENEMY	; Control Number 12
		dw	SET_NOTHING			; Control Number 13
		dw	SET_LARGE_DOORS_BRICK_WALL	; Control Number 14
		dw	$2944				; Control Number 15
		dw	SET_BIG_EXPLOSION		; Control Number 16 (Return)
		dw	SET_DOUBLE_BARREL_TURRET_FLOOR	; Control Number 17
		dw	SET_DOUBLE_BARREL_TURRET_FLOOR	; Control Number 18 ( same as above)
		dw	SET_MAN_ON_MOTORBIKE		; Control Number 19
		dw	SET_NOTHING			; Control Number 1A
		dw	SET_NOTHING			; Control Number 1B
		dw	SET_NOTHING			; Control Number 1C
		dw	SET_NOTHING			; Control Number 1D
		dw	$3627				; Control Number 1E
		dw	$28dc				; Control Number 1F
		dw	SET_NOTHING			; Control Number 20
		dw	SET_SLIM_SINGLE_DOORS		; Control Number 21
		dw	SET_NOTHING			; Control Number 22
		dw	SET_AMMO_PICKUP_SINGLE_MULTI	; Control Number 23
		dw	SET_DOUBLE_AMMO_NOT_ANIMATED	; Control Number 24
		dw	SET_NOTHING			; Control Number 25
		dw	SET_GUNNER_BEHIND_SANDBAG	; Control Number 26
		dw	SET_GUNNER_IN_TOWER		; Control Number 27
		dw	SET_AREA_BIG_DOOR_END		; Control Number 28
		dw	SET_SLIDE_UP_DOWN_DOORS		; Control Number 29
		dw	SET_MAN_ON_MOTORBIKE		; Control Number 2A (same as 19)
		dw	SET_SLIM_MOTOR_BIKE_CAR		; Control Number 2B
		dw	SET_VEHICLE_COMING_DOWN		; Control Number 2C
		dw	SET_VEHICLE_COMING_DOWN		; Control Number 2D
		dw	SET_ENEMY_IN_WATER		; Control Number 2E
		dw	SET_GUNNER_BEHIND_SANDBAG	; Control Number 2F

SET_VEHICLE_COMING_DOWN:
2823: CD E7 68    call SFX_VEHICLE
2826: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
2829: FE 1E       cp   $F0
282B: D2 33 82    jp   nc,$2833
282E: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
2832: C9          ret
2833: 3A 21 0F    ld   a,(PLAYER_X)
2836: 47          ld   b,a
2837: 3A 20 0E    ld   a,(FRAME_SYNC)
283A: E6 F1       and  $1F
283C: 2F          cpl
283D: 80          add  a,b
283E: DD 77 21    ld   (ix+TABLE_X_coord),a
2841: C9          ret

SET_SLIM_MOTOR_BIKE_CAR:
2842: CD E7 68    call SFX_VEHICLE
2845: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
2848: FE 1E       cp   $F0
284A: D2 34 82    jp   nc,$2852
284D: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
2851: C9          ret
2852: DD 36 41 14 ld   (ix+TABLE_Y_coord),$50
2856: DD 7E 21    ld   a,(ix+TABLE_X_coord)
2859: E6 21       and  $03
285B: DD 77 50    ld   (ix+$14),a
285E: CB 47       bit  0,a
2860: 28 41       jr   z,$2867
2862: DD 36 21 1E ld   (ix+TABLE_X_coord),$F0
2866: C9          ret
2867: DD 36 21 0E ld   (ix+TABLE_X_coord),$E0
286B: C9          ret

SET_AREA_BIG_DOOR_END:
286C: DD 36 50 00 ld   (ix+$14),$00
2870: DD 36 51 00 ld   (iy+TABLE_COUNTDOWN),$00
2874: DD 36 70 00 ld   (ix+$16),$00
2878: C9          ret

		; 23 Ammo Pickup single and double
SET_AMMO_PICKUP_SINGLE_MULTI:
2879: DD 7E 21    ld   a,(ix+TABLE_X_coord)	; X position
287C: 47          ld   b,a		; save to b
287D: E6 21       and  $03		; take the lower 2 bits
287F: DD 77 50    ld   (ix+$14),a	; save this value
2882: 78          ld   a,b		; get back a ie the X
2883: E6 DE       and  $FC		; now mask off the bottom 2 bits
2885: DD 77 21    ld   (ix+TABLE_X_coord),a	; now save this as the x coordinate
2888: C9          ret

SET_GUNNER_IN_TOWER:
2889: DD 7E 21    ld   a,(ix+TABLE_X_coord)
288C: DD CB 21 68 res  0,(ix+TABLE_X_coord)
2890: E6 01       and  $01
2892: DD 77 71    ld   (ix+$17),a
2895: DD 36 A0 0C ld   (ix+TABLE_new_Y_low),$C0
2899: CD D9 68    call SFX_SIREN
289C: C9          ret

SET_NOTHING:
289D: C9          ret

SET_DOUBLE_AMMO_NOT_ANIMATED:
289E: DD 36 50 00 ld   (ix+$14),$00
28A2: DD 36 51 00 ld   (iy+TABLE_COUNTDOWN),$00
28A6: C9          ret

SET_SLIM_SINGLE_DOORS:
28A7: DD 7E 21    ld   a,(ix+TABLE_X_coord)
28AA: E6 01       and  $01
28AC: DD CB 21 68 res  0,(ix+TABLE_X_coord)
28B0: DD 77 71    ld   (ix+$17),a
28B3: DD 36 50 00 ld   (ix+$14),$00
28B7: DD 36 51 00 ld   (iy+TABLE_COUNTDOWN),$00
28BB: DD 36 70 00 ld   (ix+$16),$00
28BF: C9          ret

SET_SLIDE_UP_DOWN_DOORS:
28C0: DD 7E 21    ld   a,(ix+TABLE_X_coord)		; get x
28C3: 47          ld   b,a
28C4: E6 21       and  $03			; lower bits for which direction
28C6: DD 77 71    ld   (ix+$17),a		; save this value
28C9: 78          ld   a,b			; get back original X
28CA: E6 DE       and  $FC			; ignore lower 2 bits
28CC: DD 77 21    ld   (ix+TABLE_X_coord),a		; save as new x
28CF: DD 36 50 00 ld   (ix+$14),$00
28D3: DD 36 51 00 ld   (iy+TABLE_COUNTDOWN),$00
28D7: DD 36 70 00 ld   (ix+$16),$00
28DB: C9          ret

28DC: 3A 20 0E    ld   a,(FRAME_SYNC)
28DF: E6 08       and  $80
28E1: D6 04       sub  $40
28E3: 47          ld   b,a
28E4: 3A 21 0F    ld   a,(PLAYER_X)
28E7: 80          add  a,b
28E8: DD 77 21    ld   (ix+TABLE_X_coord),a
28EB: DD 36 20 0C ld   (ix+$02),$C0
28EF: DD 36 41 00 ld   (ix+TABLE_Y_coord),$00
28F3: DD 36 50 00 ld   (ix+$14),$00
28F7: DD 36 51 00 ld   (iy+TABLE_COUNTDOWN),$00
28FB: DD 36 71 00 ld   (ix+$17),$00
28FF: CD E7 68    call SFX_VEHICLE
2902: C9          ret

2903: 25          dec  h
2904: E5          push hl
2905: 14          inc  d
2906: 95          sub  l
2907: 34          inc  (hl)
2908: 85          add  a,l
2909: 65          ld   h,l
290A: 84          add  a,h
290B: 54          ld   d,h
290C: 02          ld   (bc),a
290D: 25          dec  h
290E: 05          dec  b
290F: 14          inc  d
2910: 25          dec  h
2911: E5          push hl
2912: C5          push bc
2913: 02          ld   (bc),a
2914: 13          inc  de
2915: 93          sub  e
2916: 92          sub  d
2917: 53          ld   d,e

SET_MAN_ON_MOTORBIKE:
2918: 11 0C FE    ld   de,$FEC0			; set a specific HW sprite number for bike.
291B: DD 72 A1    ld   (ix+TABLE_X_Add_low),d		; however there is another bike so two can be on screen at same time.
291E: DD 73 C0    ld   (ix+TABLE_X_Add_high),e
2921: 11 00 00    ld   de,$0000
2924: DD 36 C1 00 ld   (ix+$0d),$00
2928: DD 36 E0 00 ld   (ix+$0e),$00
292C: DD 36 E1 00 ld   (ix+$0f),$00
2930: DD 36 10 00 ld   (ix+$10),$00
2934: DD 36 50 00 ld   (ix+$14),$00
2938: DD 36 51 82 ld   (iy+TABLE_COUNTDOWN),$28
293C: C3 E7 68    jp   SFX_VEHICLE

SET_DOUBLE_BARREL_TURRET_FLOOR:
293F: DD 36 50 00 ld   (ix+$14),$00
2943: C9          ret

2944: DD 36 50 00 ld   (ix+$14),$00
2948: DD 36 51 06 ld   (iy+TABLE_COUNTDOWN),$60
294C: C9          ret

SET_BIG_EXPLOSION:
294D: C9          ret

SET_LARGE_DOORS_BRICK_WALL:
294E: DD 36 50 00 ld   (ix+$14),$00
2952: C9          ret

SET_BARRACK_DOOR_OPEN_CLOSE_ENEMY:
2953: DD 36 50 00 ld   (ix+$14),$00
2957: DD 36 70 00 ld   (ix+$16),$00
295B: C9          ret

295C: DD 36 20 0C ld   (ix+$02),$C0
2960: DD 36 50 00 ld   (ix+$14),$00
2964: DD 36 51 04 ld   (iy+TABLE_COUNTDOWN),$40
2968: DD 7E 21    ld   a,(ix+TABLE_X_coord)
296B: C6 9E       add  a,$F8
296D: DD 77 61    ld   (ix+TABLE_new_X_high),a
2970: C9          ret

SET_ENEMY_IN_WATER:
2971: DD 36 50 01 ld   (ix+$14),$01
2975: DD 36 51 A0 ld   (iy+TABLE_COUNTDOWN),$0A
2979: DD 36 71 01 ld   (ix+$17),$01
297D: C9          ret

SET_GUNNER_TRENCH:
297E: DD 36 50 01 ld   (ix+$14),$01		; Animation frame
2982: DD 36 51 A0 ld   (iy+TABLE_COUNTDOWN),$0A		; countdown timer for change of animation.
2986: DD 36 71 00 ld   (ix+$17),$00
298A: C9          ret


SET_GUNNER_BEHIND_SANDBAG:
29b8: DD 36 20 0C ld   (ix+$02),$C0		; 
298F: DD 36 50 01 ld   (ix+$14),$0
2993: DD 36 51 01 ld   (iy+TABLE_COUNTDOWN),$01		; countdown trigger in setup
2997: DD 36 80 40 ld   (ix+TABLE_new_X_low),$04		; initial animation position index
299B: C9          ret

SET_PRISONER_GUARD:
299C: 21 DA 0E    ld   hl,$E0BC
299F: 34          inc  (hl)

SET_PRISONER_NEEDS_HELP:
29A0: DD 7E 21    ld   a,(ix+TABLE_X_coord)		; X-cord & $f0 so in 16 pixels chunks
29A3: 47          ld   b,a
29A4: E6 1E       and  $F0
29A6: DD 77 21    ld   (ix+TABLE_X_coord),a
29A9: 78          ld   a,b
29AA: E6 E1       and  $0F
29AC: 87          add  a,a
29AD: 87          add  a,a
29AE: 87          add  a,a
29AF: 87          add  a,a
29B0: DD 77 01    ld   (ix+$01),a		; using the low bits as 
29B3: DD 36 E1 00 ld   (ix+$0f),$00
29B7: CD 9B 51    call $15B9
29BA: DD 36 50 00 ld   (ix+$14),$00
29BE: C9          ret

SET_SET_MAN_WITH_MORTAR:
29BF: DD 36 20 0C ld   (ix+$02),$C0		; Palette %1100 0000 so this is palette 3
29C3: DD 36 50 00 ld   (ix+$14),$00
29C7: DD 36 70 00 ld   (ix+$16),$00
29CB: C9          ret

SET_LARGE_BLOCK_BUILDING_TURRET:
29CC: DD 36 20 00 ld   (ix+$02),$00
29D0: DD 36 50 00 ld   (ix+$14),$00
29D4: DD 36 70 21 ld   (ix+$16),$03
29D8: DD 36 90 00 ld   (ix+$18),$00
29DC: C9          ret

29DD: DD 36 50 00 ld   (ix+$14),$00
29E1: C9          ret

SET_GUNNER_IN_WINDOW:
29E2: DD 36 50 00 ld   (ix+$14),$00
29E6: CD E7 68    call SFX_VEHICLE
29E9: C9          ret

SET_LARGE_TRUCK:
29EA: DD 36 50 01 ld   (ix+$14),$01
29EE: DD 36 51 04 ld   (iy+TABLE_COUNTDOWN),$40
29F2: DD 36 70 00 ld   (ix+$16),$00
29F6: CD E7 68    call SFX_VEHICLE
29F9: C9          ret

29FA: DD 36 50 00 ld   (ix+$14),$00
29FE: DD 36 70 1E ld   (ix+$16),$F0
2A02: DD 36 71 00 ld   (ix+$17),$00
2A06: DD 36 90 00 ld   (ix+$18),$00
2A0A: CD E7 68    call SFX_VEHICLE
2A0D: C9          ret

		; Data table for each of the control objects, and how many sprites in total used.
ITEM_SPRITES_USED_TABLE:
		db	$01	;	Action 00
		db	$02	;	Action 01
		db	$02	;	Action 02
		db	$03	;	Action 03
		db	$01	;	Action 04
		db	$09	;	Action 05
		db	$01	;	Action 06
		db	$14	;	Action 07
		db	$12	;	Action 08
		db	$05	;	Action 09
		db	$08	;	Action 0a
		db	$07	;	Action 0b
		db	$01	;	Action 0c
		db	$01	;	Action 0d
		db	$01	;	Action 0e
		db	$05	;	Action 0f
		db	$01	;	Action 10
		db	$09	;	Action 11
		db	$04	;	Action 12
		db	$14	;	Action 13
		db	$12	;	Action 14		; 18 with the double doors, that's a big ass sprite
		db	$03	;	Action 15
		db	$01	;	Action 16
		db	$04	;	Action 17
		db	$01	;	Action 18
		db	$05	;	Action 19
		db	$0e	;	Action 1a
		db	$0e	;	Action 1b
		db	$06	;	Action 1c
		db	$0d	;	Action 1d
		db	$10	;	Action 1e
		db	$05	;	Action 1f
		db	$01	;	Action 20
		db	$04	;	Action 21
		db	$14	;	Action 22
		db	$02	;	Action 23
		db	$09	;	Action 24
		db	$08	;	Action 25
		db	$01	;	Action 26
		db	$0e	;	Action 27
		db	$10	;	Action 28
		db	$03	;	Action 29
		db	$05	;	Action 2a
		db	$06	;	Action 2b
		db	$04	;	Action 2c
		db	$06	;	Action 2d
		db	$01	;	Action 2e
		db	$01	;	Action 2f

			; Process all background items
UPDATE_CURRENT_EVENTS:
2A3E: DD 21 00 4F ld   ix,BACKGROUND_ITEMS	; Inital table start
2A42: 06 80       ld   b,$08			; Max of 8 seperate items (but this can be big sprites!)
2A44: C5          push bc			; save count
2A45: DD 7E 00    ld   a,(ix+TABLE_STATUS)		; get master control value
2A48: A7          and  a			;
2A49: 28 10       jr   z,$2A5B
2A4B: DD 66 B1    ld   h,(ix+$1b)		; Get the hardware sprite base address high
2A4E: DD 6E D0    ld   l,(ix+$1c)		; and the low address
2A51: E5          push hl			; save to stack
2A52: FD E1       pop  iy			; now value is in iy registers
2A54: FE FF       cp   $FF
2A56: 38 C0       jr   c,$2A64
2A58: CD E7 A2    call $2A6F			; Now run the code for this control item number
2A5B: 11 02 00    ld   de,$0020			; Add $20 which will index to next table entry
2A5E: DD 19       add  ix,de			; advance on ix pointer
2A60: C1          pop  bc			; return counter
2A61: 10 0F       djnz $2A44			; minus 1 and do the rest
2A63: C9          ret

2A64: FE FE       cp   $FE
2A66: CA B5 A2    jp   z,$2A5B
2A69: CD 3D A2    call $2AD3
2A6C: C3 B5 A2    jp   $2A5B

2A6F: DD 7E 31    ld   a,(ix+ITEM_TYPE)		; The object type lots from 1 - $2f 
2A72: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	UPDATE_SANDBAG	; Gunman behind a sandbag 0
		dw	UPDATE_PRISONER	; Save our little friend earn some points. 1
		dw	UPDATE_GUARDS	; Guads matching the prisioner 2
		dw	UPDATE_LAUNCHER	; Guy with motar launcher $1db7 3
		dw	$1fc5		; Level Start Offset Values 4
		dw	UPDATE_BUILDING_TURRET	;$20d7  5
		dw	$22a9		; Level Start Offset Values 6
		dw	$2313		; Level Start Offset Values 7
		dw	$2313		; Level Start Offset Values 8
		dw	$2312		; Level Start Offset Values 9
		dw	UPDATE_LARGE_TRUCK	;$2314		; Level Start Offset Values A
		dw	$25be		; Level Start Offset Values B
		dw	$2598		; Level Start Offset Values C
		dw	$252b		; Level Start Offset Values D
		dw	UPDATE_GUNNER_TRENCH	;$2428	
		dw	$3a8c		; Level Start Offset Values F
		dw	$3a8c		; Level Start Offset Values 10
		dw	$3a8c		; Level Start Offset Values 11
		dw	UPDATE_BARRACK_DOOR	; $19f0		; Level Start Offset Values 12
		dw	$39ac		; Level Start Offset Values 13
		dw	UPDATE_DOORS	; Doors end of Area 1 $39ad
		dw	$3898		; Level Start Offset Values 15
		dw	$3899		; Level Start Offset Values 16
		dw	$3823		; Level Start Offset Values 17
		dw	$37c0		; Level Start Offset Values 18
		dw	$36a7		; Level Start Offset Values 19
		dw	UPDATE_BRIDGE	; Level Start Offset Values 1A Bridge
		dw	$3646		; Level Start Offset Values 1B
		dw	$3643		; Level Start Offset Values 1C
		dw	$3625		; Level Start Offset Values 1D
		dw	$3627		; Level Start Offset Values 1E
		dw	$34ca		; Level Start Offset Values 1F
		dw	$34c9		; Level Start Offset Values 20
		dw	UPDATE_SLIM_SINGLE_DOORS	;	$3178 Values 21
		dw	$313b		; Level Start Offset Values 22
		dw	UPDATE_AMMO_PICKUP		; Level Start Offset Values 23
		dw	$3091		; Level Start Offset Values 24
		dw	$3004		; Level Start Offset Values 25
		dw	$3024		; Level Start Offset Values 26
		dw	$2ea7		; Level Start Offset Values 27
		dw	$1af8		; Level Start Offset Values 28
		dw	UPDATE_SLIDE_DOORS	;$32c3 Level Start Offset Values 29 area 7 doors
		dw	$2d28		; Level Start Offset Values 2A
		dw	$1898		; Level Start Offset Values 2B
		dw	$199c		; Level Start Offset Values 2C
		dw	$19d1		; Level Start Offset Values 2D
		dw	UPDATE_GUNNER_TRENCH	;$2428 Offset Values 2E
		dw	UPDATE_GUNNER_SANDBAG	; Gunman hiding behind sandbags 2F

2AD3: CD C9 B2    call ADJUST_Y_POSITION
2AD6: DD 7E 31    ld   a,(ix+ITEM_TYPE)	; get the control action number/
2AD9: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$2b3a	; Sprite Offset 0
		dw	$2bc9	; Sprite Offset 1
		dw	$2bf0	; Sprite Offset 2
		dw	$2c13	; Sprite Offset 3
		dw	$2c64	; Sprite Offset 4
		dw	$2c64	; Sprite Offset 5
		dw	$2c8c	; Sprite Offset 6
		dw	$2313	; Sprite Offset 7
		dw	$2313	; Sprite Offset 8
		dw	$2c8d	; Sprite Offset 9
		dw	$2c94	; Sprite Offset A
		dw	$2cb9	; Sprite Offset B
		dw	$2cde	; Sprite Offset C
		dw	$2cde	; Sprite Offset D
		dw	$2cde	; Sprite Offset E
		dw	$2d1d	; Sprite Offset F
		dw	$2d1d	; Sprite Offset 10
		dw	$2d1d	; Sprite Offset 11
		dw	$2d1d	; Sprite Offset 12
		dw	$2d1d	; Sprite Offset 13
		dw	$2d1d	; Sprite Offset 14
		dw	$2d1d	; Sprite Offset 15
		dw	$2d1d	; Sprite Offset 16
		dw	$2d1d	; Sprite Offset 17
		dw	$2d1d	; Sprite Offset 18
		dw	$2d1e	; Sprite Offset 19
		dw	$2d25	; Sprite Offset 1A
		dw	$2d25	; Sprite Offset 1B
		dw	$2d25	; Sprite Offset 1C
		dw	$2d25	; Sprite Offset 1D
		dw	$2c64	; Sprite Offset 1E
		dw	$2b3a	; Sprite Offset 1F
		dw	$2b3a	; Sprite Offset 20
		dw	$2b3a	; Sprite Offset 21
		dw	$2b3a	; Sprite Offset 22
		dw	$2b3a	; Sprite Offset 23
		dw	$2b3a	; Sprite Offset 24
		dw	$2b3a	; Sprite Offset 25
		dw	$2b3a	; Sprite Offset 26
		dw	$2b3a	; Sprite Offset 27
		dw	$2b3a	; Sprite Offset 28
		dw	$2b3a	; Sprite Offset 29
		dw	$2d1e	; Sprite Offset 2A
		dw	$2b3a	; Sprite Offset 2B
		dw	$2b3a	; Sprite Offset 2C
		dw	$2b3a	; Sprite Offset 2D
		dw	$2cde	; Sprite Offset 2E
		dw	$2b3a	; Sprite Offset 2F

2B3A: DD 7E 00    ld   a,(ix+TABLE_STATUS)
2B3D: FE F3       cp   $3F
2B3F: CC 74 A3    call z,$2B56
2B42: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
2B45: CA 6B B2    jp   z,REMOVE_SPRITES
2B48: 21 E7 A3    ld   hl,$2B6F
2B4B: 0F          rrca
2B4C: 0F          rrca
2B4D: E6 21       and  $03
2B4F: DF          rst	ADD_A_TO_HL
2B50: 5E          ld   e,(hl)
2B51: 16 00       ld   d,$00
2B53: C3 9C D0    jp   SPRITE_UPDATE_DE
2B56: CD 98 68    call SFX_KILL
2B59: DD 36 00 01 ld   (ix+TABLE_STATUS),$01
2B5D: DD 36 51 10 ld   (iy+TABLE_COUNTDOWN),$10
2B61: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
2B64: C6 21       add  a,$03
2B66: DD 77 41    ld   (ix+TABLE_Y_coord),a
2B69: 16 41       ld   d,$05
2B6B: 1E 41       ld   e,$05
2B6D: FF          rst  ADD_DE_TO_EVENT
2B6E: C9          ret

2b6f:		db      $84, $8c, $83, $79

2B73: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
2B76: 0F          rrca
2B77: 0F          rrca
2B78: 0F          rrca
2B79: E6 F1       and  $1F
2B7B: C3 69 A3    jp   $2B87
2B7E: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
2B81: 0F          rrca
2B82: 0F          rrca
2B83: 0F          rrca
2B84: 0F          rrca
2B85: E6 E1       and  $0F
2B87: EF          rst	INDEX_ED_AT_2A_PLUS_HL


HW_SPRITE_UPDATER:			; Hardware Sprites updater or just basically just we can say a poke direct to the hardware registers 
					; IX for table position
					; DE is the sprite number pointer in ROM
					; IY is Hardware Sprite pointer.
					
					; Data table is 4 or bytes
					; 1st is number of sprites to use with each entry of 2 bytes an x add, and sprite number
					; 2nd is Flags which will have the negative y added for the y position
					; 3rd top $f0 is added to Y position, and lower is high byte for y
					; 4th is sprite number for hardware number	
2B88: DD 46 40    ld   b,(ix+TABLE_X_low)	; Y coordinate high byte
2B8B: DD 4E 41    ld   c,(ix+TABLE_Y_coord)	; Y coordinate low byte
2B8E: 1A          ld   a,(de)		; Get data 1st byte this will be how many sprites to use
2B8F: 13          inc  de		; advance
2B90: 08          ex   af,af'		; save out
2B91: 1A          ld   a,(de)		; get 2nd byte
2B92: 13          inc  de		; advance source
2B93: D9          exx			; save out all pointers
2B94: 4F          ld   c,a		; put 2nd byte into c
2B95: 08          ex   af,af'		; get back 1st byte
2B96: 47          ld   b,a		; save into b this is how many sprites in count
2B97: 11 40 00    ld   de,$0004		; hw sprite data size 4 bytes / entry

2B9A: D9          exx			; save pointers and count
2B9B: 1A          ld   a,(de)		; get 3rd byte offset or next in table if multi-sprite
2B9C: E6 1E       and  $F0		; only in negative region
2B9E: DD 86 21    add  a,(ix+TABLE_X_coord)	; add X or subtract depending on value really
2BA1: FD 77 20    ld   (iy+sprite_x),a	; save the x position
2BA4: 1A          ld   a,(de)		; get back 3rd byte the offset again
2BA5: 13          inc  de		; now advance pointer
2BA6: 87          add  a,a		; * 16 for this value
2BA7: 87          add  a,a
2BA8: 87          add  a,a
2BA9: 87          add  a,a
2BAA: 6F          ld   l,a		; put to l
2BAB: 26 00       ld   h,$00
2BAD: 07          rlca
2BAE: CB 14       rl   h
2BB0: 09          add  hl,bc		; so the lower 
2BB1: FD 75 21    ld   (iy+sprite_y),l	; now the y coordinate
2BB4: 7C          ld   a,h		; get high byte
2BB5: E6 01       and  $01		; > 0 ie -1 -2 etc high will be ff really but we use 1 bit
2BB7: D9          exx
2BB8: 81          add  a,c		; 2nd bytes + y high bit for flags value
2BB9: FD 77 01    ld   (iy+sprite_flags),a	; save hw sprite data flags palette and bank and x/y flip
2BBC: D9          exx
2BBD: 1A          ld   a,(de)		; read last byte or just next in table
2BBE: 13          inc  de		; next value
2BBF: FD 77 00    ld   (iy+sprite_number),a	; sprite number
2BC2: D9          exx			; get back pointers
2BC3: FD 19       add  iy,de		; advance hw sprite destination number
2BC5: 10 3D       djnz $2B9A		; now do rest
2BC7: D9          exx			; put back pointers
2BC8: C9          ret			; all done, let's get out of dodge.

2BC9: DD 7E 00    ld   a,(ix+TABLE_STATUS)
2BCC: FE F3       cp   $3F
2BCE: 28 51       jr   z,$2BE5
2BD0: DD 35 00    dec  (ix+TABLE_STATUS)
2BD3: CA 6B B2    jp   z,REMOVE_SPRITES
2BD6: DD 7E 00    ld   a,(ix+TABLE_STATUS)
2BD9: 21 82 C2    ld   hl,$2C28
2BDC: 0F          rrca
2BDD: 0F          rrca
2BDE: 0F          rrca
2BDF: E6 21       and  $03
2BE1: EF          rst	INDEX_ED_AT_2A_PLUS_HL
2BE2: C3 88 A3    jp   HW_SPRITE_UPDATER
2BE5: DD 35 00    dec  (ix+TABLE_STATUS)
2BE8: 16 41       ld   d,$05
2BEA: 1E 80       ld   e,$08
2BEC: FF          rst  ADD_DE_TO_EVENT
2BED: C3 CA 68    jp   SFX_FLUSH1
2BF0: DD 7E 00    ld   a,(ix+TABLE_STATUS)
2BF3: FE F3       cp   $3F
2BF5: 28 C0       jr   z,$2C03
2BF7: DD 35 00    dec  (ix+TABLE_STATUS)
2BFA: CA 6B B2    jp   z,REMOVE_SPRITES
2BFD: 11 24 C2    ld   de,$2C42
2C00: C3 88 A3    jp   HW_SPRITE_UPDATER
2C03: DD 35 00    dec  (ix+TABLE_STATUS)
2C06: 21 DA 0E    ld   hl,$E0BC
2C09: 35          dec  (hl)
2C0A: CD 98 68    call SFX_KILL
2C0D: 16 41       ld   d,$05
2C0F: 1E 80       ld   e,$08
2C11: FF          rst  ADD_DE_TO_EVENT

2C12: C9          ret
2C13: DD 7E 00    ld   a,(ix+TABLE_STATUS)
2C16: FE F3       cp   $3F
2C18: 28 B2       jr   z,$2C54
2C1A: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
2C1D: CA 6B B2    jp   z,REMOVE_SPRITES
2C20: 21 84 C2    ld   hl,$2C48
2C23: 0E 02       ld   c,$20
2C25: C3 D4 51    jp   $155C

2c28:		dw	$2c30
2c2a:		dw	$2c3c
2c2c:		dw	$2c36
2c2e:		dw	$2c3c
2c30:		db	$02, $00, $01, $e3, $00, $eb
2c3c:		db	$02, $00, $01, $e5, $00, $ed
2c36:		db	$02, $00, $01, $e4, $00, $ec
2c3c:		db	$02, $00, $01, $e5, $00, $ed

2c42:   	db      $02, $40, $f0, $56, $00, $57

2c48:		dw	$2c50
2c4a:		dw	$2c50
2c4c:		dw	$2c50
2c4e:		dw	$2c50

2c50:		db	$02, $70, $71, $78

2C54: CD 98 68	  call SFX_KILL
2C57: DD 35 00    dec  (ix+TABLE_STATUS)
2C5A: DD 36 51 02 ld   (iy+TABLE_COUNTDOWN),$20
2C5E: 16 41       ld   d,$05
2C60: 1E 41       ld   e,$05
2C62: FF          rst  ADD_DE_TO_EVENT
2C63: C9          ret
2C64: DD 7E 90    ld   a,(ix+$18)
2C67: A7          and  a
2C68: 28 30       jr   z,$2C7C
2C6A: CD 47 68    call SFX_EXPLODE_HUT
2C6D: 16 41       ld   d,$05
2C6F: 1E 80       ld   e,$08
2C71: FF          rst  ADD_DE_TO_EVENT
2C72: CD 6B B2    call REMOVE_SPRITES
2C75: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
2C79: C3 83 72    jp   $3629
2C7C: CD 47 68    call SFX_EXPLODE_HUT
2C7F: DD 34 90    inc  (ix+$18)
2C82: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
2C86: 16 41       ld   d,$05
2C88: 1E 41       ld   e,$05
2C8A: FF          rst  ADD_DE_TO_EVENT
2C8B: C9          ret
2C8C: C9          ret
2C8D: CD 06 68    call SFX_EXPLODE_VEHICLE
2C90: CD F7 68    call SFX_FLUSH
2C93: C9          ret
2C94: CD 06 68    call SFX_EXPLODE_VEHICLE
2C97: CD F7 68    call SFX_FLUSH
2C9A: 16 41       ld   d,$05
2C9C: 1E 41       ld   e,$05
2C9E: FF          rst  ADD_DE_TO_EVENT
2C9F: DD 7E 21    ld   a,(ix+TABLE_X_coord)
2CA2: C6 90       add  a,$18
2CA4: DD 77 21    ld   (ix+TABLE_X_coord),a
2CA7: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
2CAA: C6 80       add  a,$08
2CAC: DD 77 41    ld   (ix+TABLE_Y_coord),a
2CAF: CD 6B B2    call REMOVE_SPRITES
2CB2: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
2CB6: C3 83 72    jp   $3629
2CB9: CD 06 68    call SFX_EXPLODE_VEHICLE
2CBC: CD F7 68    call SFX_FLUSH
2CBF: DD 7E 21    ld   a,(ix+TABLE_X_coord)
2CC2: C6 80       add  a,$08
2CC4: DD 77 21    ld   (ix+TABLE_X_coord),a
2CC7: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
2CCA: C6 10       add  a,$10
2CCC: DD 77 41    ld   (ix+TABLE_Y_coord),a
2CCF: CD 6B B2    call REMOVE_SPRITES
2CD2: 16 41       ld   d,$05
2CD4: 1E 80       ld   e,$08
2CD6: FF          rst  ADD_DE_TO_EVENT
2CD7: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
2CDB: C3 83 72    jp   $3629
2CDE: DD 7E 00    ld   a,(ix+TABLE_STATUS)
2CE1: FE F3       cp   $3F
2CE3: 28 82       jr   z,$2D0D
2CE5: 21 DF C2    ld   hl,$2CFD
2CE8: DD 7E B0    ld   a,(ix+TABLE_SPRITE_QTY)
2CEB: A7          and  a
2CEC: 28 21       jr   z,$2CF1
2CEE: 21 41 C3    ld   hl,$2D05
2CF1: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
2CF4: CA 6B B2    jp   z,REMOVE_SPRITES
2CF7: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
2CFA: C3 3C D0    jp   $1CD2

2cfd:		db	$83, $00, $8c, $00, $84, $00, $79, $00
2d05:		db	$74, $10, $3f, $10, $7b, $10, $79, $10

2D0D: CD 98 68    call SFX_KILL
2D10: 16 41       ld   d,$05
2D12: 1E 20       ld   e,$02
2D14: FF          rst  ADD_DE_TO_EVENT
2D15: DD 35 00    dec  (ix+TABLE_STATUS)
2D18: DD 36 51 02 ld   (iy+TABLE_COUNTDOWN),$20
2D1C: C9          ret
2D1D: C9          ret
2D1E: CD F7 68    call SFX_FLUSH
2D21: CD 06 68    call SFX_EXPLODE_VEHICLE
2D24: C9          ret
2D25: C3 6B B2    jp   REMOVE_SPRITES
2D28: CD F8 72    call $369E
2D2B: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
2D2E: A7          and  a
2D2F: CA 6B B2    jp   z,REMOVE_SPRITES
2D32: CD 96 C3    call $2D78
2D35: DD 7E 50    ld   a,(ix+$14)
2D38: 47          ld   b,a
2D39: E6 21       and  $03
2D3B: FE 20       cp   $02
2D3D: 28 70       jr   z,$2D55
2D3F: 21 C6 73    ld   hl,$376C
2D42: CB 50       bit  2,b
2D44: 28 21       jr   z,$2D49
2D46: 21 F5 E2    ld   hl,$2E5F
2D49: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
2D4C: 0F          rrca
2D4D: 0F          rrca
2D4E: 0F          rrca
2D4F: E6 01       and  $01
2D51: EF          rst	INDEX_ED_AT_2A_PLUS_HL
2D52: C3 86 C3    jp   $2D68
2D55: 21 88 73    ld   hl,$3788
2D58: CB 50       bit  2,b
2D5A: 28 21       jr   z,$2D5F
2D5C: 21 B7 E2    ld   hl,$2E7B
2D5F: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
2D62: 0F          rrca
2D63: 0F          rrca
2D64: 0F          rrca
2D65: E6 21       and  $03
2D67: EF          rst	INDEX_ED_AT_2A_PLUS_HL
2D68: DD 7E 40    ld   a,(ix+TABLE_X_low)
2D6B: F5          push af
2D6C: DD CB 40 68 res  0,(ix+TABLE_X_low)
2D70: CD 88 A3    call HW_SPRITE_UPDATER
2D73: F1          pop  af
2D74: DD 77 40    ld   (ix+TABLE_X_low),a
2D77: C9          ret
2D78: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
2D7B: CA DC C3    jp   z,$2DDC
2D7E: DD 7E 50    ld   a,(ix+$14)
2D81: E6 21       and  $03
2D83: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$2d8c	; Table 0
		dw	$2d8c	; Table 1
		dw	$2dad	; Table 2
		dw	$2d8c	; Table 3

2D8C: DD 56 E1    ld   d,(ix+$0f)
2D8F: DD 5E 10    ld   e,(ix+$10)
2D92: DD 66 A1    ld   h,(ix+TABLE_X_Add_low)
2D95: DD 6E C0    ld   l,(ix+TABLE_X_Add_high)
2D98: 19          add  hl,de
2D99: DD 74 A1    ld   (ix+TABLE_X_Add_low),h
2D9C: DD 75 C0    ld   (ix+TABLE_X_Add_high),l
2D9F: DD 56 21    ld   d,(ix+TABLE_X_coord)
2DA2: DD 5E 40    ld   e,(ix+TABLE_X_low)
2DA5: 19          add  hl,de
2DA6: DD 74 21    ld   (ix+TABLE_X_coord),h
2DA9: DD 75 40    ld   (ix+TABLE_X_low),l
2DAC: C9          ret

2DAD: DD CB 50 74 bit  2,(ix+$14)
2DB1: 28 E0       jr   z,$2DC1
2DB3: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
2DB6: FE 01       cp   $01
2DB8: C0          ret  nz
2DB9: CD 96 50    call $1478
2DBC: DD 36 51 02 ld   (iy+TABLE_COUNTDOWN),$20
2DC0: C9          ret
2DC1: 3A 41 0F    ld   a,(PLAYER_Y)
2DC4: 47          ld   b,a
2DC5: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
2DC8: 90          sub  b
2DC9: FE 12       cp   $30
2DCB: DA 22 E2    jp   c,$2E22
2DCE: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
2DD1: FE 01       cp   $01
2DD3: C0          ret  nz
2DD4: CD 96 50    call $1478
2DD7: DD 36 51 02 ld   (iy+TABLE_COUNTDOWN),$20
2DDB: C9          ret
2DDC: DD 7E 50    ld   a,(ix+$14)
2DDF: 47          ld   b,a
2DE0: E6 21       and  $03
2DE2: FE 20       cp   $02
2DE4: C8          ret  z
2DE5: DD 34 50    inc  (ix+$14)
2DE8: 78          ld   a,b
2DE9: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$2e34	; Table 0
		dw	$2e14	; Table 1
		dw	$2e22	; Table 2
		dw	$2df8	; Table 3
		dw	$2e39	; Table 4
		dw	$2e14	; Table 5
		dw	$2e3b	; Table 6

2DF8: DD 36 21 00 ld   (ix+TABLE_X_coord),$00
2DFC: 21 04 01    ld   hl,$0140
2DFF: DD 74 A1    ld   (ix+TABLE_X_Add_low),h
2E02: DD 75 C0    ld   (ix+TABLE_X_Add_high),l
2E05: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
2E08: C6 10       add  a,$10
2E0A: DD 77 41    ld   (ix+TABLE_Y_coord),a
2E0D: CD E7 68    call SFX_VEHICLE
2E10: 3E 21       ld   a,$03
2E12: 18 63       jr   $2E3B

2E14: 21 00 00    ld   hl,$0000
2E17: DD 74 A1    ld   (ix+TABLE_X_Add_low),h
2E1A: DD 75 C0    ld   (ix+TABLE_X_Add_high),l
2E1D: DD 36 51 02 ld   (iy+TABLE_COUNTDOWN),$20
2E21: C9          ret

2E22: 21 00 00    ld   hl,$0000
2E25: DD 74 A1    ld   (ix+TABLE_X_Add_low),h
2E28: DD 75 C0    ld   (ix+TABLE_X_Add_high),l
2E2B: DD 36 50 21 ld   (ix+$14),$03
2E2F: 3E 20       ld   a,$02
2E31: C3 B3 E2    jp   $2E3B

2E34: 3E 00       ld   a,$00
2E36: C3 B3 E2    jp   $2E3B

2E39: 3E 40       ld   a,$04

2E3B: 21 14 E2    ld   hl,$2E50			; index *
2E3E: 47          ld   b,a			; a * 3 for 3/bytes each table entry.
2E3F: 87          add  a,a
2E40: 80          add  a,b
2E41: E7          rst	INDEX_A_PLUS_HL
2E42: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a
2E45: 23          inc  hl
2E46: 5E          ld   e,(hl)
2E47: 23          inc  hl
2E48: 56          ld   d,(hl)
2E49: DD 72 E1    ld   (ix+$0f),d
2E4C: DD 73 10    ld   (ix+$10),e
2E4F: C9          ret

2e50:		db	$38, $05, $00		; 0
2e53:		db	$20, $00, $00		; 1
2e56:		db	$6c, $fa, $ff		; 2
2e59:		db	$4c, $00, $00		; 3
2e5c:		db	$20, $f6, $ff		; 4

2E5F:		dw	$2e63	; Table 0
		dw	$2e6f	; Table 1

2e63:		db	$05, $58, $01, $60, $f1, $ff, $10, $68, $00, $69, $f0, $6a
2e6f:		db	$05, $58, $01, $6b, $f1, $ff, $10, $61, $00, $62, $f0, $63

2E7B: 		dw	$2e83	; Table 0
		dw	$2e8f	; Table 1
		dw	$2e9b	; Table 2
		dw	$2e83	; Table 3

2e83:		db	$05, $58, $01, $70, $f1, $71, $10, $68, $00, $78, $f0, $79
2e8f:		db	$05, $58, $01, $72, $f1, $73, $10, $68, $00, $7a, $f0, $79
2e9b:		db	$05, $58, $01, $64, $f1, $65, $10, $68, $00, $6c, $f0, $79
 
2EA7: 21 55 0E    ld   hl,ENEMY_SPRITE_COUNT
2EAA: 34          inc  (hl)
2EAB: CD C9 B2    call ADJUST_Y_POSITION
2EAE: CD 49 E3    call $2F85
2EB1: CD 4C E2    call $2EC4
2EB4: 11 4E E3    ld   de,$2FE4			; index*
2EB7: DD 7E 71    ld   a,(ix+$17)
2EBA: A7          and  a
2EBB: CA 88 A3    jp   z,HW_SPRITE_UPDATER
2EBE: 11 5E E3    ld   de,$2FF4			; index* 
2EC1: C3 88 A3    jp   HW_SPRITE_UPDATER
2EC4: DD 7E 40    ld   a,(ix+TABLE_X_low)
2EC7: A7          and  a
2EC8: 20 95       jr   nz,$2F23
2ECA: 21 75 E3    ld   hl,$2F57			; index *
2ECD: DD 7E 71    ld   a,(ix+$17)
2ED0: A7          and  a
2ED1: 28 21       jr   z,$2ED6
2ED3: 21 37 E3    ld   hl,$2F73			; index *
2ED6: DD 7E 80    ld   a,(ix+TABLE_new_X_low)
2ED9: EF          rst	INDEX_ED_AT_2A_PLUS_HL
2EDA: CD 9C D0    call SPRITE_UPDATE_DE
2EDD: 11 40 00    ld   de,$0004
2EE0: FD 19       add  iy,de
2EE2: DD 46 21    ld   b,(ix+TABLE_X_coord)
2EE5: DD 4E 41    ld   c,(ix+TABLE_Y_coord)
2EE8: C5          push bc
2EE9: 21 13 E3    ld   hl,$2F31			; index	*
2EEC: DD 7E 71    ld   a,(ix+$17)
2EEF: A7          and  a
2EF0: 28 21       jr   z,$2EF5
2EF2: 21 B3 E3    ld   hl,$2F3B			; index *
2EF5: DD 7E 80    ld   a,(ix+TABLE_new_X_low)
2EF8: EF          rst	INDEX_ED_AT_2A_PLUS_HL
2EF9: 78          ld   a,b
2EFA: 83          add  a,e
2EFB: DD 77 21    ld   (ix+TABLE_X_coord),a
2EFE: 79          ld   a,c
2EFF: 82          add  a,d
2F00: DD 77 41    ld   (ix+TABLE_Y_coord),a
2F03: 21 C5 E3    ld   hl,$2F4D			; index *
2F06: DD 7E 71    ld   a,(ix+$17)
2F09: A7          and  a
2F0A: 28 21       jr   z,$2F0F
2F0C: 21 07 E3    ld   hl,$2F61			; index *
2F0F: DD 7E 80    ld   a,(ix+TABLE_new_X_low)
2F12: EF          rst	INDEX_ED_AT_2A_PLUS_HL
2F13: CD 9C D0    call SPRITE_UPDATE_DE
2F16: 11 40 00    ld   de,$0004
2F19: FD 19       add  iy,de
2F1B: C1          pop  bc
2F1C: DD 70 21    ld   (ix+TABLE_X_coord),b
2F1F: DD 71 41    ld   (ix+TABLE_Y_coord),c
2F22: C9          ret
2F23: FD 36 20 00 ld   (iy+sprite_x),$00
2F27: FD 36 60 00 ld   (iy+sprite2_x),$00
2F2B: 11 80 00    ld   de,$0008
2F2E: FD 19       add  iy,de
2F30: C9          ret

2f31:   	db      $fa, $fa, $fa, $fa, $fa, $fa, $fc, $fa, $fc, $fa	; *
2f3b:   	db      $06, $fa, $06, $fa, $06, $fa, $04, $fa, $04, $fa	; *
2f45:		db      $04, $fa, $06, $fa, $06, $fa, $06, $fa

2f4d:		db	$76, $80, $76, $80, $75, $80, $7d, $80, $7d, $80	; *
2f57:		db	$4f, $90, $4f, $90, $53, $90, $5b, $90, $5b, $90	; *
2f61:		db	$76, $88, $76, $88, $75, $88, $7d, $88, $7d, $88	; *

2f6b:		db	$7d, $88, $75, $88, $76, $88, $76, $88
2f73:		db	$4f, $98, $4f, $98, $53, $98, $5b, $98			; *
2f7b:		db	$5b, $98, $5b, $98, $53, $98, $4f, $98,$4f, $98

2F85: DD 7E 40    ld   a,(ix+TABLE_X_low)
2F88: A7          and  a
2F89: 20 98       jr   nz,$2F23
2F8B: 3A 20 0E    ld   a,(FRAME_SYNC)
2F8E: E6 61       and  $07
2F90: C0          ret  nz
2F91: CD 2E C6    call $6CE2
2F94: CB 7F       bit  7,a
2F96: C8          ret  z
2F97: DD 77 20    ld   (ix+$02),a
2F9A: C6 80       add  a,$08
2F9C: 0F          rrca
2F9D: 0F          rrca
2F9E: 0F          rrca
2F9F: 0F          rrca
2FA0: E6 61       and  $07
2FA2: 47          ld   b,a
2FA3: DD 7E 71    ld   a,(ix+$17)
2FA6: A7          and  a
2FA7: 28 81       jr   z,$2FB2
2FA9: 78          ld   a,b
2FAA: FE 40       cp   $04
2FAC: D8          ret  c
2FAD: 21 5C E3    ld   hl,$2FD4			; index *
2FB0: 18 61       jr   $2FB9
2FB2: 78          ld   a,b
2FB3: FE 41       cp   $05
2FB5: D0          ret  nc
2FB6: 21 2C E3    ld   hl,$2FC2			; index *
2FB9: DD 77 80    ld   (ix+TABLE_new_X_low),a
2FBC: EF          rst	INDEX_ED_AT_2A_PLUS_HL
2FBD: 63          ld   h,e
2FBE: 6A          ld   l,d
2FBF: C3 DF 39    jp   $93FD

2fc2:		db	$f0, $f6, $f0, $f6, $f4, $f3, $f8, $f2, $f8, $f2
		db	$0a, $0e, $0a, $0e, $0a, $0e, $0a, $0e
2fd4:		db	$0a, $0e, $0a, $0e, $0a, $0e, $0a, $0e, $08, $f2, $08, $f2, $0c, $f3, $10, $f6

2fe4:		db	$07, $90, $f0, $4e, $f1, $4c, $01, $4d, $f2, $44, $02, $45, $03, $46, $13, $47
2ff4:		db	$07, $98, $10, $4e, $11, $4c, $01, $4d, $12, $44, $02, $45, $03, $46, $f3, $47

3004: CD C9 B2    call ADJUST_Y_POSITION
3007: 11 10 12    ld   de,$3010
300A: CD 88 A3    call HW_SPRITE_UPDATER
300D: C3 88 A3    jp   HW_SPRITE_UPDATER

3010:		db	$04, $60, $11, $43, $21, $44, $10, $45, $20, $4e
301a:		db	$04, $68, $e1, $43, $d1, $44, $e0, $45, $d0, $4e

3024: 3A B0 0f    ld   a,($E11A)
3027: A7          and  a
3028: C2 6B B2    jp   nz,REMOVE_SPRITES
302B: 3A D8 0E    ld   a,($E09C)
302E: A7          and  a
302F: 28 81       jr   z,$303A
3031: 21 03 10    ld   hl,$1021
3034: 11 03 10    ld   de,$1021
3037: CD 0F B0    call $1AE1
303A: CD C9 B2    call ADJUST_Y_POSITION
303D: CD B4 12    call $305A
3040: DD 7E 80    ld   a,(ix+TABLE_new_X_low)
3043: 21 A4 12    ld   hl,$304A
3046: EF          rst	INDEX_ED_AT_2A_PLUS_HL
3047: C3 9C D0    jp   SPRITE_UPDATE_DE

304a:		db	$a3, $08, $a3, $08, $a2, $08, $a1, $08
3052:		db	$a0, $00, $a1, $00, $a2, $00, $a3, $00

305A: 3A 20 0E    ld   a,(FRAME_SYNC)
305D: E6 61       and  $07
305F: 47          ld   b,a
3060: DD 7E F1    ld   a,(ix+$1f)
3063: E6 61       and  $07
3065: B8          cp   b
3066: C0          ret  nz
3067: CD 2E C6    call $6CE2
306A: DD 77 20    ld   (ix+$02),a
306D: C6 61       add  a,$07
306F: 0F          rrca
3070: 0F          rrca
3071: 0F          rrca
3072: 0F          rrca
3073: E6 61       and  $07
3075: DD 77 80    ld   (ix+TABLE_new_X_low),a
3078: 21 09 12    ld   hl,$3081
307B: EF          rst	INDEX_ED_AT_2A_PLUS_HL
307C: 63          ld   h,e
307D: 6A          ld   l,d
307E: C3 DF 39    jp   $93FD

3081:	dw	$f4f2	; Table 0
	dw	$f4f2	; Table 1
	dw	$f4f4	; Table 2
	dw	$f4fc	; Table 3	; loads up l as $f4 and h as $fc
	dw	$f401	; Table 4
	dw	$f404	; Table 5
	dw	$f40c	; Table 6
	dw	$f40e	; Table 7


UPDATE_AMMO_PICKUP:
3092: CD BC 12    call AMMO_MOVE_AND_PICKUP
3095: 3A 20 0E    ld   a,(FRAME_SYNC)		; countdown value
3098: 0F          rrca
3099: 0F          rrca
309A: 0F          rrca
309B: E6 01       and  $01		; Get some kind of random number 0,1 only!
309D: 47          ld   b,a		; save a
309E: DD 7E 50    ld   a,(ix+$14)	; Get the pick up amount we saved
30A1: 87          add  a,a		; double it so now 0 2 4 6
30A2: 80          add  a,b		; add the the random 0 or 1
30A3: 21 AA 12    ld   hl,$30AA		; now get us a table entry (0 - 7) * 2
30A6: EF          rst  $28		; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
30A7: C3 88 A3    jp   HW_SPRITE_UPDATER

30AA:		dw	$30ba   ; Table Entry 0	- 1 wide
		dw	$30ca   ; Table Entry 1 - 1 wide
		dw	$30be   ; Table Entry 2 - 2 wide
		dw	$30ce   ; Table Entry 3 - 2 wide
		dw	$30c4   ; Table Entry 4 - 2 wide
		dw	$30d4   ; Table Entry 5 - 2 wide
		dw	$30ca   ; Table Entry 6 - 1 wide
		dw	$30d4   ; Table Entry 7 - 2 wide

			; Sprite table updater uses same data sets like this
			; 1st byte is how many sprites to use
			; 2nd byte is Sprite data flags
			; 3rd is y-offset
			; 4th is hw sprite number
			; multi entry sprites additional is next sprite x offset and next sprite number to use.
			; the same palette bits are always for additional sprites. makes sence really would be a waste.

30ba:		db	$01, $80, $00, $67
30be: 		db	$02, $80, $f0, $6e, $00, $6f
30c4: 		db	$02, $80, $f0, $7e, $00, $7f
30ca:		db	$01, $b0, $00, $67
30ce: 		db	$02, $b0, $f0, $6e, $00, $6f 
30d4:		db	$02, $b0, $f0, $7e, $00, $7f

AMMO_MOVE_AND_PICKUP: 
30DA: C9 B2       call ADJUST_Y_POSITION; update Y position based on scroll
30DD: DD 7E 41    ld   a,(ix+TABLE_Y_coord)	; Get Y
30E0: A7          and  a
30E1: 28 92       jr   z,REMOVE_EVENT_ITEM	; if zero then scrolled off bottom
30E3: 3A 00 0F    ld   a,(PLAYER_DATA)	; Get player is player is active 
30E6: 3C          inc  a		; Advance pointer which actually is $e101
30E7: C0          ret  nz		; if zero then just return back
30E8: 3A 21 0F    ld   a,(PLAYER_X)	; Get player X
30EB: DD 96 21    sub  (ix+TABLE_X_coord)		; - Pickup X
30EE: C6 10       add  a,$10		; + 16
30F0: FE 03       cp   $21		; in range?
30F2: D0          ret  nc		; nope so exit
30F3: 3A 41 0F    ld   a,(PLAYER_Y)	; Get Player Y
30F6: DD 96 41    sub  (ix+TABLE_Y_coord)		; - Pickup Y
30F9: C6 10       add  a,$10		; + 16
30FB: FE 03       cp   $21		; 21 pixels away?
30FD: D0          ret  nc		; nope so exit
30FE: CD 6B 68    call SFX_AMMO		; If we got a pickup then let's get some benefit
3101: DD 7E 50    ld   a,(ix+$14)	; The original data lower bits used for the pickup quantity only 0,1,2 values used
3104: 21 53 13    ld   hl,AMMO_PICKUP_TABLE
3107: EF          rst  $28		; call MULTIPLY_A_BY_2_ADD_TO_HL_LOAD_DE_FROM_HL
3108: 3A 8A CF    ld   a,(NUM_GRENADES)	; read NUM_GRENADES
310B: BA          cp   d		; check for max can collect
310C: 30 70       jr   nc,$3124		; if going to wrap then just max out to 99
310E: 83          add  a,e		; add pickup amount
310F: 27          daa			; decimal only addition
3110: 32 8A CF    ld   (NUM_GRENADES),a	; update NUM_GRENADES
3113: 16 A1       ld   d,$0B
3115: FF          rst  ADD_DE_TO_EVENT
3116: 16 41       ld   d,$05
3118: 1E 80       ld   e,$08
311A: FF          rst  ADD_DE_TO_EVENT

REMOVE_EVENT_ITEM:
311B: DD 36 00 00 ld   (ix+TABLE_STATUS),$00	; zap active
311F: DD 36 21 00 ld   (ix+TABLE_X_coord),$00	; zero out x coordinate also
3123: C9          ret

MAX_PICKUPS_GRENADES:
3124: DD 36 00 00 ld   (ix+TABLE_STATUS),$00	; kill off the item in list
3128: DD 36 21 00 ld   (ix+TABLE_X_coord),$00	; and it's x coordinate
312C: 3E 99       ld   a,$99		; now we got lots of little bombs
312E: 32 8A CF    ld   (NUM_GRENADES),a	; set NUM_GRENADES
3131: 16 A1       ld   d,$0B
3133: FF          rst  ADD_DE_TO_EVENT
3134: C9          ret

				; Pickup reward, quantity, and current max, so you don't wrap over 99 in game. (assume you're that good a player, or in cheat mode)
AMMO_PICKUP_TABLE:
		db	$01,$98
		db	$03,$96
		db	$05,$94
				
313B: CD C9 B2    call ADJUST_Y_POSITION
313E: 3A 4B 0E    ld   a,($E0A5)
3141: A7          and  a
3142: C0          ret  nz
3143: 11 C4 13    ld   de,$314C
3146: CD 88 A3    call HW_SPRITE_UPDATER
3149: C3 88 A3    jp   HW_SPRITE_UPDATER

314c:		db	$0c, $68, $11, $43, $01, $44, $10, $45, $00, $4e, $15, $43, $05, $44, $14, $45, $04, $4e, $1d, $43, $0d, $44, $1c, $45, $0c, $4e
3166:		db	$08, $60, $41, $43, $51, $44, $40, $45, $50, $4e, $45, $43, $55, $44, $44, $45, $54, $4e

UPDATE_SLIM_SINGLE_DOORS:
3178: 21 55 0E    ld   hl,$E055
317A: 0E 34       inc  (hl)
317C: CD C9 B2    call ADJUST_Y_POSITION
317F: CD 5E 13    call $31F4
3182: 11 6B 32    ld   de,$32A7
3185: DD 7E 71    ld   a,(ix+$17)
3188: E6 01       and  $01
318A: 28 21       jr   z,$318F
318C: 11 5B 32    ld   de,$32B5
318F: DD 46 40    ld   b,(ix+TABLE_X_low)
3192: DD 4E 41    ld   c,(ix+TABLE_Y_coord)
3195: 21 31 00    ld   hl,$0013
3198: 09          add  hl,bc
3199: DD 74 40    ld   (ix+TABLE_X_low),h
319C: DD 75 41    ld   (ix+TABLE_Y_coord),l
319F: C5          push bc
31A0: CD 88 A3    call HW_SPRITE_UPDATER
31A3: C1          pop  bc
31A4: DD 70 40    ld   (ix+TABLE_X_low),b
31A7: DD 71 41    ld   (ix+TABLE_Y_coord),c
31AA: DD 7E 50    ld   a,(ix+$14)
31AD: A7          and  a
31AE: CA 88 A3    jp   z,HW_SPRITE_UPDATER
31B1: DD 7E 70    ld   a,(ix+$16)
31B4: FE 50       cp   $14
31B6: 30 33       jr   nc,$31EB
31B8: FE A0       cp   $0A
31BA: 30 10       jr   nc,$31CC
31BC: 6F          ld   l,a
31BD: 26 00       ld   h,$00
31BF: 09          add  hl,bc
31C0: C5          push bc
31C1: DD 74 40    ld   (ix+TABLE_X_low),h
31C4: DD 75 41    ld   (ix+TABLE_Y_coord),l
31C7: CD 88 A3    call HW_SPRITE_UPDATER
31CA: 18 71       jr   $31E3
31CC: 21 60 00    ld   hl,$0006
31CF: 19          add  hl,de
31D0: EB          ex   de,hl
31D1: 6F          ld   l,a
31D2: 26 00       ld   h,$00
31D4: 09          add  hl,bc
31D5: C5          push bc
31D6: DD 74 40    ld   (ix+TABLE_X_low),h
31D9: DD 75 41    ld   (ix+TABLE_Y_coord),l
31DC: CD 88 A3    call HW_SPRITE_UPDATER
31DF: FD 36 20 00 ld   (iy+sprite_x),$00
31E3: C1          pop  bc
31E4: DD 70 40    ld   (ix+TABLE_X_low),b
31E7: DD 71 41    ld   (ix+TABLE_Y_coord),c
31EA: C9          ret
31EB: FD 36 20 00 ld   (iy+sprite_x),$00
31EF: FD 36 60 00 ld   (iy+sprite2_x),$00
31F3: C9          ret

31F4: DD 7E 40    ld   a,(ix+TABLE_X_low)
31F7: A7          and  a
31F8: C0          ret  nz
31F9: DD 7E 50    ld   a,(ix+$14)
31FC: A7          and  a
31FD: C2 C9 32    jp   nz,$328D
3200: 3A 20 0E    ld   a,(FRAME_SYNC)
3203: 0F          rrca
3204: 0F          rrca
3205: E6 61       and  $07
3207: 47          ld   b,a
3208: DD 7E F1    ld   a,(ix+$1f)
320B: B8          cp   b
320C: C0          ret  nz
320D: 3A 7E 0E    ld   a,(ENEMY_TIMER)
3210: A7          and  a
3211: C0          ret  nz
3212: DD E5       push ix
3214: DD 4E 71    ld   c,(ix+$17)
3217: DD 66 21    ld   h,(ix+TABLE_X_coord)
321A: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
321D: C6 40       add  a,$04
321F: 6F          ld   l,a
3220: DD 21 00 6E ld   ix,ENEMY_SPRITES
3224: 11 02 00    ld   de,$0020
3227: 3A 5E 0E    ld   a,(MAX_ENEMY)
322A: 47          ld   b,a
322B: DD 7E 00    ld   a,(ix+TABLE_STATUS)
322E: A7          and  a
322F: 28 61       jr   z,$3238
3231: DD 19       add  ix,de
3233: 10 7E       djnz $322B
3235: DD E1       pop  ix
3237: C9          ret

3238: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
323C: DD 36 01 0C ld   (ix+$01),$C0
3240: DD 36 20 0C ld   (ix+$02),$C0
3244: DD 74 21    ld   (ix+TABLE_X_coord),h
3247: DD 74 61    ld   (ix+TABLE_new_X_high),h
324A: DD 75 41    ld   (ix+TABLE_Y_coord),l
324D: DD 75 81    ld   (ix+TABLE_new_Y_high),l
3250: DD 36 31 60 ld   (ix+ITEM_TYPE),$06
3254: DD 36 50 00 ld   (ix+$14),$00
3258: DD 36 51 C0 ld   (iy+TABLE_COUNTDOWN),$0C
325C: DD 36 90 90 ld   (ix+$18),$18
3260: DD 71 71    ld   (ix+$17),c
3263: DD 70 F1    ld   (ix+$1f),b
3266: DD 36 A1 00 ld   (ix+TABLE_X_Add_low),$00
326A: DD 36 C0 00 ld   (ix+TABLE_X_Add_high),$00
326E: DD 36 C1 FF ld   (ix+$0d),$FF
3272: DD 36 E0 00 ld   (ix+$0e),$00
3276: DD 36 E1 00 ld   (ix+$0f),$00
327A: 3A 5F 0E    ld   a,(ENEMY_TIMER_RESET)
327D: 32 7E 0E    ld   (ENEMY_TIMER),a
3280: CD 4C 59    call $95C4
3283: DD E1       pop  ix
3285: DD 34 50    inc  (ix+$14)
3288: DD 36 51 02 ld   (iy+TABLE_COUNTDOWN),$20
328C: C9          ret
328D: DD 7E 50    ld   a,(ix+$14)
3290: 3D          dec  a
3291: 28 81       jr   z,$329C
3293: DD 35 70    dec  (ix+$16)
3296: C0          ret  nz
3297: DD 36 50 00 ld   (ix+$14),$00
329B: C9          ret
329C: DD 34 70    inc  (ix+$16)
329F: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
32A2: C0          ret  nz
32A3: DD 34 50    inc  (ix+$14)
32A6: C9          ret

32a7:		db	$01, $98, $00, $57
32ab:		db	$02, $98, $01, $56, $00, $5e
32b1:		db	$01, $98, $00, $5e

32b5:		db	$01, $90, $00, $57
32b9:		db	$02, $90, $01, $56, $00, $5e
32bf:   	db	$01, $90, $00, $5e

UPDATE_SLIDE_DOORS:
32C3: 21 55 0E    ld   hl,$E055
32C5: 0E 34       inc  (hl)
32C7: CD C9 B2    call ADJUST_Y_POSITION
32CA: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
32CD: A7          and  a
32CE: CA 6B B2    jp   z,REMOVE_SPRITES
32D1: CD 80 52    call $3408
32D4: CD 9C 32    call $32D8
32D7: C9          ret

32D8: DD 46 21    ld   b,(ix+TABLE_X_coord)
32DB: DD 4E 41    ld   c,(ix+TABLE_Y_coord)
32DE: C5          push bc
32DF: 79          ld   a,c
32E0: C6 51       add  a,$15
32E2: FE 31       cp   $13
32E4: 38 31       jr   c,$32F9
32E6: DD 77 41    ld   (ix+TABLE_Y_coord),a
32E9: 16 18       ld   d,$90			; roof sprite (hard coded sprite numbers!)
32EB: 1E 05       ld   e,$41			; roof of the door to hide the sprite priority higher
32ED: DD 7E 71    ld   a,(ix+$17)		; this is the type of door. from table x cord lower 2 bits 0 - 3
32F0: FE 20       cp   $02			; a 2 represents it's flipped in the x direction
32F2: 20 20       jr   nz,$32F6
32F4: 16 98       ld   d,$98			; this is flags for flip
32F6: CD 9C D0    call SPRITE_UPDATE_DE
32F9: 11 40 00    ld   de,$0004
32FC: FD 19       add  iy,de
32FE: C1          pop  bc
32FF: DD 7E 70    ld   a,(ix+$16)
3302: C5          push bc
3303: 81          add  a,c
3304: C6 BF       add  a,$FB
3306: DD 77 41    ld   (ix+TABLE_Y_coord),a
3309: 21 5E 33    ld   hl,$33F4
330C: E5          push hl
330D: DD 7E 71    ld   a,(ix+$17)		; now check is the type is = 1
3310: FE 01       cp   $01
3312: 28 87       jr   z,$337D
3314: 38 77       jr   c,$338D
3316: DD 7E 70    ld   a,(ix+$16)
3319: FE 81       cp   $09
331B: 30 C3       jr   nc,$334A
331D: 21 47 33    ld   hl,$3365
3320: E7          rst	INDEX_A_PLUS_HL
3321: DD 86 21    add  a,(ix+TABLE_X_coord)
3324: DD 77 21    ld   (ix+TABLE_X_coord),a
3327: 1E A4       ld   e,$4A
3329: 16 18       ld   d,$90
332B: CD 9C D0    call SPRITE_UPDATE_DE
332E: 11 40 00    ld   de,$0004
3331: FD 19       add  iy,de
3333: 3E 21       ld   a,$03
3335: DD 86 21    add  a,(ix+TABLE_X_coord)
3338: DD 77 21    ld   (ix+TABLE_X_coord),a
333B: 3E 10       ld   a,$10
333D: DD 86 41    add  a,(ix+TABLE_Y_coord)
3340: DD 77 41    ld   (ix+TABLE_Y_coord),a
3343: 1E 24       ld   e,$42
3345: 16 18       ld   d,$90
3347: C3 9C D0    jp   SPRITE_UPDATE_DE
334A: 21 47 33    ld   hl,$3365
334D: E7          rst	INDEX_A_PLUS_HL
334E: DD 86 21    add  a,(ix+TABLE_X_coord)
3351: DD 77 21    ld   (ix+TABLE_X_coord),a
3354: 1E 24       ld   e,$42
3356: 16 18       ld   d,$90
3358: CD 9C D0    call SPRITE_UPDATE_DE
335B: 11 40 00    ld   de,$0004
335E: FD 19       add  iy,de
3360: FD 36 20 00 ld   (iy+sprite_x),$00
3364: C9          ret

3365:		db	$f9, $f9, $f9, $fb, $fb, $fb, $fa, $fa, $fa, $fc, $fc, $fc
3371:		db	$fd, $fd, $fd, $fe, $fe, $fe, $ff, $ff, $ff, $00, $00, $00

337D: 11 20 52    ld   de,$3402
3380: DD 7E 70    ld   a,(ix+$16)
3383: FE 80       cp   $08
3385: 38 21       jr   c,$338A
3387: 11 DE 33    ld   de,$33FC
338A: C3 88 A3    jp   HW_SPRITE_UPDATER
338D: DD 7E 70    ld   a,(ix+$16)
3390: FE 41       cp   $05
3392: 30 C3       jr   nc,$33C1
3394: 21 DC 33    ld   hl,$33DC
3397: E7          rst	INDEX_A_PLUS_HL
3398: DD 86 21    add  a,(ix+TABLE_X_coord)
339B: DD 77 21    ld   (ix+TABLE_X_coord),a
339E: 16 98       ld   d,$98
33A0: 1E A4       ld   e,$4A
33A2: CD 9C D0    call SPRITE_UPDATE_DE
33A5: 11 40 00    ld   de,$0004
33A8: FD 19       add  iy,de
33AA: 3E DF       ld   a,$FD
33AC: DD 86 21    add  a,(ix+TABLE_X_coord)
33AF: DD 77 21    ld   (ix+TABLE_X_coord),a
33B2: 3E 10       ld   a,$10
33B4: DD 86 41    add  a,(ix+TABLE_Y_coord)
33B7: DD 77 41    ld   (ix+TABLE_Y_coord),a
33BA: 16 98       ld   d,$98
33BC: 1E 24       ld   e,$42			; sprite slope left top
33BE: C3 9C D0    jp   SPRITE_UPDATE_DE

33C1: 21 DC 33    ld   hl,$33DC
33C4: E7          rst	INDEX_A_PLUS_HL
33C5: DD 86 21    add  a,(ix+TABLE_X_coord)
33C8: DD 77 21    ld   (ix+TABLE_X_coord),a
33CB: 16 98       ld   d,$98
33CD: 1E A4       ld   e,$4A			; sprite slop left bottom
33CF: CD 9C D0    call SPRITE_UPDATE_DE
33D2: 11 40 00    ld   de,$0004
33D5: FD 19       add  iy,de
33D7: FD 36 20 00 ld   (iy+sprite_x),$00
33DB: C9          ret

33dc:		db	$07, $07, $07, $05, $05, $05, $06, $06, $06, $04, $04, $04
33e8:		db	$03, $03, $03, $02, $02, $02, $01, $01, $01, $00, $00, $00

33F4: C1          pop  bc
33F5: DD 70 21    ld   (ix+TABLE_X_coord),b
33F8: DD 71 41    ld   (ix+TABLE_Y_coord),c
33FB: C9          ret

33fc:		db	$02, $90, $00, $51, $00, $ff, $02, $90, $00, $51, $01, $49

3408: 85          add  a,l
340A: DD 7E 40    ld   a,(ix+TABLE_X_low)
340B: A7          and  a
340C: C0          ret  nz
340D: DD 7E 50    ld   a,(ix+$14)
3410: F7          rst  JUMP_TABLE		; Jump table from count a

		dw      $3419   ; Control Number 0
		dw      $34a8   ; Control Number 1
		dw      $34b9   ; Control Number 2
		dw      $34c1   ; Control Number 3
				
3419: 3A 20 0E    ld   a,(FRAME_SYNC)
341C: 0F          rrca
341D: 0F          rrca
341E: E6 61       and  $07
3420: 47          ld   b,a
3421: DD 7E F1    ld   a,(ix+$1f)
3424: E6 61       and  $07
3426: B8          cp   b
3427: C0          ret  nz
3428: 3A 7E 0E    ld   a,(ENEMY_TIMER)
342B: A7          and  a
342C: C0          ret  nz
342D: DD E5       push ix
342F: DD 4E 71    ld   c,(ix+$17)
3432: DD 66 21    ld   h,(ix+TABLE_X_coord)
3435: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
3438: C6 00       add  a,$00
343A: 6F          ld   l,a
343B: DD 21 00 6E ld   ix,ENEMY_SPRITES
343F: 11 02 00    ld   de,$0020
3442: 3A 5E 0E    ld   a,(MAX_ENEMY)
3445: 47          ld   b,a
3446: DD 7E 00    ld   a,(ix+TABLE_STATUS)
3449: A7          and  a
344A: 28 61       jr   z,$3453
344C: DD 19       add  ix,de
344E: 10 7E       djnz $3446
3450: DD E1       pop  ix
3452: C9          ret

3453: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
3457: DD 36 01 0C ld   (ix+$01),$C0
345B: DD 36 20 0C ld   (ix+$02),$C0
345F: DD 74 21    ld   (ix+TABLE_X_coord),h
3462: DD 74 61    ld   (ix+TABLE_new_X_high),h
3465: DD 75 41    ld   (ix+TABLE_Y_coord),l
3468: DD 75 81    ld   (ix+TABLE_new_Y_high),l
346B: DD 36 31 81 ld   (ix+ITEM_TYPE),$09
346F: DD 36 50 00 ld   (ix+$14),$00
3473: DD 36 51 C0 ld   (iy+TABLE_COUNTDOWN),$0C
3477: DD 36 90 90 ld   (ix+$18),$18
347B: DD 71 71    ld   (ix+$17),c
347E: DD 70 F1    ld   (ix+$1f),b
3481: DD 36 A1 00 ld   (ix+TABLE_X_Add_low),$00
3485: DD 36 C0 00 ld   (ix+TABLE_X_Add_high),$00
3489: DD 36 C1 FF ld   (ix+$0d),$FF
348D: DD 36 E0 00 ld   (ix+$0e),$00
3491: DD 36 E1 00 ld   (ix+$0f),$00
3495: 3A 5F 0E    ld   a,(ENEMY_TIMER_RESET)
3498: 32 7E 0E    ld   (ENEMY_TIMER),a
349B: CD 4C 59    call $95C4
349E: DD E1       pop  ix
34A0: DD 34 50    inc  (ix+$14)
34A3: DD 36 70 00 ld   (ix+$16),$00
34A7: C9          ret

34A8: DD 34 70    inc  (ix+$16)
34AB: DD 7E 70    ld   a,(ix+$16)
34AE: FE 70       cp   $16
34B0: D8          ret  c
34B1: DD 34 50    inc  (ix+$14)
34B4: DD 36 51 F0 ld   (iy+TABLE_COUNTDOWN),$1E
34B8: C9          ret

34B9: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
34BC: C0          ret  nz
34BD: DD 34 50    inc  (ix+$14)
34C0: C9          ret

34C1: DD 35 70    dec  (ix+$16)
34C4: C0          ret  nz
34C5: DD 36 50 00 ld   (ix+$14),$00
34C9: C9          ret

34CA: CD 5C 53    call $35D4
34CD: CD B0 53    call $351A
34D0: CD 6B 53    call $35A7
34D3: CD 5F 52    call $34F5
34D6: 3A 00 0F    ld   a,(PLAYER_DATA)
34D9: 3C          inc  a
34DA: C0          ret  nz
34DB: 3A 21 0F    ld   a,(PLAYER_X)
34DE: DD 96 21    sub  (ix+TABLE_X_coord)
34E1: C6 C0       add  a,$0C
34E3: FE 91       cp   $19
34E5: D0          ret  nc
34E6: 3A 41 0F    ld   a,(PLAYER_Y)
34E9: DD 96 41    sub  (ix+TABLE_Y_coord)
34EC: FE 91       cp   $19
34EE: D0          ret  nc
34EF: 3E F3       ld   a,$3F
34F1: 32 00 0F    ld   (PLAYER_DATA),a
34F4: C9          ret
34F5: DD 7E 70    ld   a,(ix+$16)
34F8: 21 77 53    ld   hl,$3577
34FB: EF          rst	INDEX_ED_AT_2A_PLUS_HL
34FC: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
34FF: C6 41       add  a,$05
3501: DD 77 41    ld   (ix+TABLE_Y_coord),a
3504: CD 9C D0    call SPRITE_UPDATE_DE
3507: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
350A: C6 BF       add  a,$FB
350C: DD 77 41    ld   (ix+TABLE_Y_coord),a
350F: 11 40 00    ld   de,$0004
3512: FD 19       add  iy,de
3514: 11 79 53    ld   de,$3597
3517: C3 88 A3    jp   HW_SPRITE_UPDATER
351A: 3A 20 0E    ld   a,(FRAME_SYNC)
351D: E6 01       and  $01
351F: C8          ret  z
3520: FD E5       push iy
3522: FD 21 00 2E ld   iy,BULLET_SPRITES
3526: 11 02 00    ld   de,$0020              ; size of (PLAYER_BULLET)
3529: 06 60       ld   b,$06
352B: DD 66 21    ld   h,(ix+TABLE_X_coord)
352E: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
3531: FD 7E 00    ld   a,(iy+sprite_number)
3534: 3C          inc  a
3535: 20 93       jr   nz,$3570
3537: FD 7E 21    ld   a,(iy+sprite_y)
353A: 94          sub  h
353B: C6 90       add  a,$18
353D: FE 03       cp   $21
353F: 30 E3       jr   nc,$3570
3541: FD 7E 41    ld   a,(iy+sprite2_flags)
3544: 95          sub  l
3545: C6 80       add  a,$08
3547: FE 03       cp   $21
3549: 30 43       jr   nc,$3570
354B: FD 36 00 F3 ld   (iy+$00),$3F
354F: FD E1       pop  iy
3551: CD 15 68    call SFX_BULLET_HIT
3554: 16 41       ld   d,$05
3556: 1E 20       ld   e,$02
3558: FF          rst  ADD_DE_TO_EVENT
3559: DD 34 71    inc  (ix+$17)
355C: DD 7E 71    ld   a,(ix+$17)
355F: FE 61       cp   $07
3561: 38 11       jr   c,$3574
3563: E1          pop  hl
3564: DD 66 21    ld   h,(ix+TABLE_X_coord)
3567: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
356A: CD 6B B2    call REMOVE_SPRITES
356D: C3 C1 38    jp   MAKE_EXPLOSION
3570: FD 19       add  iy,de
3572: 10 DB       djnz $3531
3574: FD E1       pop  iy
3576: C9          ret

3577: 2B          dec  hl
3578: 80          add  a,b
3579: 2B          dec  hl
357A: 80          add  a,b
357B: 2A 80 0B    ld   hl,($A108)
357E: 80          add  a,b
357F: 0A          ld   a,(bc)
3580: 00          nop
3581: 0B          dec  bc
3582: 00          nop
3583: 2A 00 2B    ld   hl,($A300)
3586: 00          nop
3587: 3E BF       ld   a,$FB
3589: 3E BF       ld   a,$FB
358B: 5E          ld   e,(hl)
358C: BE          cp   (hl)
358D: DE 9F       sbc  a,$F9
358F: 01 9E 40    ld   bc,$04F8
3592: 9F          sbc  a,a
3593: 30 BE       jr   nc,$358F
3595: 50          ld   d,b
3596: BF          cp   a
3597: 40          ld   b,b
3598: 14          inc  d
3599: 1F          rra
359A: 3E 01       ld   a,$01
359C: 3F          ccf
359D: 1E BE       ld   e,$FA
359F: 00          nop
35A0: BF          cp   a
35A1: 18 01       jr   $35A4
35A3: 08          ex   af,af'
35A4: 00          nop
35A5: 16 01       ld   d,$01
35A7: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
35AA: FE 12       cp   $30
35AC: D8          ret  c
35AD: FE 1E       cp   $F0
35AF: D0          ret  nc
35B0: 3A 20 0E    ld   a,(FRAME_SYNC)
35B3: E6 E1       and  $0F
35B5: C0          ret  nz
35B6: CD 2E C6    call $6CE2
35B9: 47          ld   b,a
35BA: C6 61       add  a,$07
35BC: CB 7F       bit  7,a
35BE: C8          ret  z
35BF: DD 70 20    ld   (ix+$02),b
35C2: 0F          rrca
35C3: 0F          rrca
35C4: 0F          rrca
35C5: 0F          rrca
35C6: E6 61       and  $07
35C8: DD 77 70    ld   (ix+$16),a
35CB: 21 69 53    ld   hl,$3587
35CE: EF          rst	INDEX_ED_AT_2A_PLUS_HL
35CF: 63          ld   h,e
35D0: 6A          ld   l,d
35D1: C3 DF 39    jp   $93FD
35D4: CD C9 B2    call ADJUST_Y_POSITION
35D7: DD 7E 50    ld   a,(ix+$14)
35DA: 21 0B 53    ld   hl,$35A1
35DD: EF          rst	INDEX_ED_AT_2A_PLUS_HL
35DE: DD 7E 40    ld   a,(ix+TABLE_X_low)
35E1: DD 66 41    ld   h,(ix+TABLE_Y_coord)
35E4: DD 6E 60    ld   l,(ix+TABLE_Y_low)
35E7: 19          add  hl,de
35E8: DD 74 41    ld   (ix+TABLE_Y_coord),h
35EB: DD 75 60    ld   (ix+TABLE_Y_low),l
35EE: CE 00       adc  a,$00
35F0: DD 77 40    ld   (ix+TABLE_X_low),a
35F3: A7          and  a
35F4: 28 81       jr   z,$35FF
35F6: 7C          ld   a,h
35F7: FE 0E       cp   $E0
35F9: 30 40       jr   nc,$35FF
35FB: E1          pop  hl
35FC: C3 6B B2    jp   REMOVE_SPRITES
35FF: DD 7E 50    ld   a,(ix+$14)
3602: FE 01       cp   $01
3604: 28 E0       jr   z,$3614
3606: D0          ret  nc
3607: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
360A: FE 0A       cp   $A0
360C: D8          ret  c
360D: DD 34 50    inc  (ix+$14)
3610: CD 56 68    call SFX_RETURN
3613: C9          ret
3614: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
3617: 28 60       jr   z,$361F
3619: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
361C: FE 08       cp   $80
361E: D0          ret  nc
361F: DD 34 50    inc  (ix+$14)
3622: CD B6 68    call SFX_BIKER_OFF
3625: C9          ret
3626: 00          nop
3627: C9          ret
3628: 63          ld   h,e
3629: DD 36 31 70 ld   (ix+ITEM_TYPE),$16
362D: DD 36 50 01 ld   (ix+$14),$01
3631: DD 36 51 02 ld   (iy+TABLE_COUNTDOWN),$20
3635: DD 36 B0 10 ld   (ix+TABLE_SPRITE_QTY),$10
3639: 21 02 FE    ld   hl,$FE20
363C: DD 74 B1    ld   (ix+$1b),h
363F: DD 75 D0    ld   (ix+$1c),l
3642: C9          ret
3643: C9          ret
3644: 02          ld   (bc),a
3645: FB          ei

UPDATE_1E:
3646: CD C9 B2    call ADJUST_Y_POSITION
3649: 11 34 72    ld   de,$3652
364C: CD 88 A3    call HW_SPRITE_UPDATER
364F: C3 88 A3    jp   HW_SPRITE_UPDATER

3652:		db	$07, $a0, $03, $04, $13, $05, $02, $0c, $12, $0d, $01, $1e, $11, $1f, $00, $16
3662:		db	$07, $a8, $33, $04, $23, $05, $32, $0c, $22, $0d, $31, $1e, $21, $1f, $30, $16

UPDATE_BRIDGE:
3672: CD C9 B2    call ADJUST_Y_POSITION
3675: 11 F6 72    ld   de,BRIDGE_DATA
3678: CD 88 A3    call HW_SPRITE_UPDATER	; Do top half first
367B: C3 88 A3    jp   HW_SPRITE_UPDATER	; then carry on with the rest so all table is processed

	; Two bridges halves top half and bottom half
BRIDGE_DATA:
	db      $07, $b0	
	db	$03, $0f
	db	$13, $0f
	db	$02, $17
	db	$12, $17
	db	$01, $06
	db	$11, $07
	db	$00, $0e
	
        db      $07, $b8
	db	$33, $0f
	db	$23, $0f
	db	$32, $17
	db	$22, $17
	db	$31, $06
	db	$21, $07
	db	$30, $0e

369E: 3A 26 0E    ld   a,(SCREEN_SCROLLING)
36A1: A7          and  a
36A2: C8          ret  z
36A3: DD 35 41    dec  (ix+TABLE_Y_coord)
36A6: C9          ret
36A7: 21 55 0E    ld   hl,ENEMY_SPRITE_COUNT
36AA: 34          inc  (hl)
36AB: CD FD 72    call $36DF
36AE: DD 7E 50    ld   a,(ix+$14)
36B1: FE 20       cp   $02
36B3: 28 E0       jr   z,$36C3
36B5: 3A 20 0E    ld   a,(FRAME_SYNC)
36B8: 0F          rrca
36B9: 0F          rrca
36BA: 0F          rrca
36BB: E6 01       and  $01
36BD: 21 C6 73    ld   hl,$376C
36C0: EF          rst	INDEX_ED_AT_2A_PLUS_HL
36C1: 18 C0       jr   $36CF
36C3: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
36C6: 0F          rrca
36C7: 0F          rrca
36C8: 0F          rrca
36C9: E6 21       and  $03
36CB: 21 88 73    ld   hl,$3788
36CE: EF          rst	INDEX_ED_AT_2A_PLUS_HL
36CF: DD 7E 40    ld   a,(ix+TABLE_X_low)
36D2: F5          push af
36D3: DD 36 40 00 ld   (ix+TABLE_X_low),$00
36D7: CD 88 A3    call HW_SPRITE_UPDATER
36DA: F1          pop  af
36DB: DD 77 40    ld   (ix+TABLE_X_low),a
36DE: C9          ret
36DF: DD 7E 50    ld   a,(ix+$14)
36E2: FE 20       cp   $02
36E4: 28 B1       jr   z,$3701
36E6: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
36E9: 28 C4       jr   z,$3737
36EB: DD 56 E1    ld   d,(ix+$0f)
36EE: DD 5E 10    ld   e,(ix+$10)
36F1: DD 66 A1    ld   h,(ix+TABLE_X_Add_low)
36F4: DD 6E C0    ld   l,(ix+TABLE_X_Add_high)
36F7: 19          add  hl,de
36F8: DD 74 A1    ld   (ix+TABLE_X_Add_low),h
36FB: DD 75 C0    ld   (ix+TABLE_X_Add_high),l
36FE: C3 5C E9    jp   $8FD4
3701: CD F8 72    call $369E
3704: 3A 41 0F    ld   a,(PLAYER_Y)
3707: 47          ld   b,a
3708: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
370B: 90          sub  b
370C: FE 12       cp   $30
370E: 38 30       jr   c,$3722
3710: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
3713: A7          and  a
3714: 28 40       jr   z,$371A
3716: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
3719: C9          ret
371A: CD 96 50    call $1478
371D: DD 36 51 02 ld   (iy+TABLE_COUNTDOWN),$20
3721: C9          ret
3722: DD 34 50    inc  (ix+$14)
3725: CD B6 68    call SFX_BIKER_OFF
3728: 3E 20       ld   a,$02
372A: 18 B1       jr   $3747
372C: DD 7E 50    ld   a,(ix+$14)
372F: A7          and  a
3730: C8          ret  z
3731: FE 20       cp   $02
3733: CA E7 68    jp   z,SFX_VEHICLE
3736: C9          ret

3737: CD C2 73    call $372C
373A: DD 7E 50    ld   a,(ix+$14)
373D: FE 20       cp   $02
373F: C8          ret  z
3740: DD 34 50    inc  (ix+$14)
3743: FE 40       cp   $04
3745: 28 03       jr   z,$3768
3747: 21 D4 73    ld   hl,$375C
374A: 47          ld   b,a		
374B: 87          add  a,a
374C: 80          add  a,b		; get a * 5
374D: E7          rst	INDEX_A_PLUS_HL
374E: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a
3751: 23          inc  hl
3752: 5E          ld   e,(hl)
3753: 23          inc  hl
3754: 56          ld   d,(hl)
3755: DD 72 E1    ld   (ix+$0f),d
3758: DD 73 10    ld   (ix+$10),e
375B: C9          ret

375c:		db	$40, $05, $00 
375f:		db	$00, $00, $00
3762:		db	$30, $fa, $ff
3765:		db	$40, $fc, $ff

3768: E1          pop  hl
3769: C3 6B B2    jp   REMOVE_SPRITES

376C:		dw	$3770   ; Table 0
		dw	$377c   ; Table 1
		
3770:		db	$05, $50, $01, $60, $11, $ff, $f0, $68, $00, $69, $10, $6a
377c:		db	$05, $50, $01, $6b, $11, $ff, $f0, $61, $00, $62, $10, $63

3788: 
		dw	$3790   ; Table 0
		dw	$379c   ; Table 1
		dw	$37a8   ; Table 2
		dw	$37b4   ; Table 3
		
3790:	db	$05, $50, $01, $76, $11, $77, $f0, $68, $00, $7e, $10, $7f
379c:	db	$05, $50, $01, $75, $11, $77, $f0, $68, $00, $7e, $10, $7f
37a8:	db	$05, $50, $01, $7c, $11, $77, $f0, $68, $00, $7e, $10, $7f
37b4:	db	$05, $50, $01, $66, $11, $67, $f0, $68, $00, $6e, $10, $6f

37C0: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
37C3: 28 72       jr   z,$37FB
37C5: DD 7E 50    ld   a,(ix+$14)
37C8: E6 21       and  $03
37CA: FE 01       cp   $01
37CC: 38 23       jr   c,$37F1
37CE: 28 20       jr   z,$37D2
37D0: 18 A0       jr   $37DC
37D2: CD 5C E9    call $8FD4
37D5: 1E 5B       ld   e,$B5
37D7: 16 00       ld   d,$00
37D9: C3 9C D0    jp   SPRITE_UPDATE_DE
37DC: CD F8 72    call $369E
37DF: 21 CE 73    ld   hl,$37EC
37E2: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
37E5: E7          rst	INDEX_A_PLUS_HL
37E6: 5F          ld   e,a
37E7: 16 00       ld   d,$00
37E9: C3 9C D0    jp   SPRITE_UPDATE_DE

37EC:		db	$bc, $bc, $bb, $b9, $b8

37F1: CD F8 72    call $369E
37F4: 1E FA       ld   e,$BE
37F6: 16 00       ld   d,$00
37F8: C3 9C D0    jp   SPRITE_UPDATE_DE
37FB: DD 7E 50    ld   a,(ix+$14)
37FE: E6 21       and  $03
3800: DD 34 50    inc  (ix+$14)
3803: FE 00       cp   $00
3805: 28 A0       jr   z,$3811
3807: FE 20       cp   $02
3809: CA 6B B2    jp   z,REMOVE_SPRITES
380C: DD 36 51 41 ld   (iy+TABLE_COUNTDOWN),$05
3810: C9          ret
3811: DD 36 51 12 ld   (iy+TABLE_COUNTDOWN),$30
3815: C9          ret
3816: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
381A: FD 36 20 00 ld   (iy+sprite_x),$00
381E: FD 36 60 00 ld   (iy+sprite2_x),$00
3822: C9          ret
3823: CD F8 72    call $369E
3826: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
3829: A7          and  a
382A: 28 AE       jr   z,$3816
382C: CD 95 92    call $3859
382F: CD 33 92    call $3833
3832: C9          ret
3833: DD 7E 50    ld   a,(ix+$14)
3836: E6 21       and  $03
3838: 21 F3 92    ld   hl,$383F
383B: EF          rst	INDEX_ED_AT_2A_PLUS_HL
383C: C3 88 A3    jp   HW_SPRITE_UPDATER
383F: 65          ld   h,l
3840: 92          sub  d
3841: C5          push bc
3842: 92          sub  d
3843: 35          dec  (hl)
3844: 92          sub  d
3845: C5          push bc
3846: 92          sub  d
3847: 20 04       jr   nz,$3889
3849: 1E 04       ld   e,$40
384B: 00          nop
384C: 05          dec  b
384D: 20 04       jr   nz,$388F
384F: 1E 04       ld   e,$40
3851: 00          nop
3852: 24          inc  h
3853: 20 04       jr   nz,$3895
3855: 1E 04       ld   e,$40
3857: 00          nop
3858: A4          and  h
3859: DD 7E 50    ld   a,(ix+$14)
385C: E6 21       and  $03
385E: 20 31       jr   nz,$3873
3860: CD 2E C6    call $6CE2
3863: C6 60       add  a,$06
3865: 47          ld   b,a
3866: D6 9C       sub  $D8
3868: FE 02       cp   $20
386A: D0          ret  nc
386B: DD 70 20    ld   (ix+$02),b
386E: DD 34 50    inc  (ix+$14)
3871: 18 61       jr   $387A
3873: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
3876: C0          ret  nz
3877: DD 34 50    inc  (ix+$14)
387A: DD 36 51 20 ld   (iy+TABLE_COUNTDOWN),$02
387E: DD 7E 50    ld   a,(ix+$14)
3881: E6 01       and  $01
3883: C8          ret  z
3884: DD 7E 50    ld   a,(ix+$14)
3887: E6 20       and  $02
3889: 21 58 92    ld   hl,$3894
388C: E7          rst	INDEX_A_PLUS_HL
388D: 57          ld   d,a
388E: 23          inc  hl
388F: 5E          ld   e,(hl)
3890: EB          ex   de,hl
3891: C3 DF 39    jp   $93FD
3894: 60          ld   h,b
3895: BE          cp   (hl)
3896: A1          and  c
3897: 00          nop
3898: C9          ret
3899: CD F8 72    call $369E
389C: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
389F: CA 98 93    jp   z,$3998
38A2: DD 7E 50    ld   a,(ix+$14)
38A5: A7          and  a
38A6: 20 70       jr   nz,$38BE
38A8: 1E B4       ld   e,$5A
38AA: 16 14       ld   d,$50
38AC: C3 9C D0    jp   SPRITE_UPDATE_DE
38AF: FD E5       push iy
38B1: E1          pop  hl
38B2: 11 40 00    ld   de,$0004
38B5: 06 10       ld   b,$10
38B7: 3E FF       ld   a,$FF
38B9: 77          ld   (hl),a
38BA: 19          add  hl,de
38BB: 10 DE       djnz $38B9
38BD: C9          ret
38BE: CD EB 92    call $38AF
38C1: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
38C4: 0F          rrca
38C5: 0F          rrca
38C6: E6 E1       and  $0F
38C8: FE 61       cp   $07
38CA: CA 5E 92    jp   z,$38F4
38CD: FE 60       cp   $06
38CF: CA 5E 92    jp   z,$38F4
38D2: 21 F0 93    ld   hl,$391E
38D5: EF          rst	INDEX_ED_AT_2A_PLUS_HL
38D6: DD 46 21    ld   b,(ix+TABLE_X_coord)
38D9: DD 4E 41    ld   c,(ix+TABLE_Y_coord)
38DC: C5          push bc
38DD: 1A          ld   a,(de)
38DE: 13          inc  de
38DF: 80          add  a,b
38E0: DD 77 21    ld   (ix+TABLE_X_coord),a
38E3: 1A          ld   a,(de)
38E4: 13          inc  de
38E5: 81          add  a,c
38E6: DD 77 41    ld   (ix+TABLE_Y_coord),a
38E9: CD 88 A3    call HW_SPRITE_UPDATER
38EC: C1          pop  bc
38ED: DD 70 21    ld   (ix+TABLE_X_coord),b
38F0: DD 71 41    ld   (ix+TABLE_Y_coord),c
38F3: C9          ret
38F4: 3E 9E       ld   a,$F8
38F6: DD 86 21    add  a,(ix+TABLE_X_coord)
38F9: DD 77 21    ld   (ix+TABLE_X_coord),a
38FC: 3E 9E       ld   a,$F8
38FE: DD 86 41    add  a,(ix+TABLE_Y_coord)
3901: DD 77 41    ld   (ix+TABLE_Y_coord),a
3904: 11 F4 93    ld   de,$395E
3907: CD 88 A3    call HW_SPRITE_UPDATER
390A: CD 88 A3    call HW_SPRITE_UPDATER
390D: 3E 80       ld   a,$08
390F: DD 86 21    add  a,(ix+TABLE_X_coord)
3912: DD 77 21    ld   (ix+TABLE_X_coord),a
3915: 3E 80       ld   a,$08
3917: DD 86 41    add  a,(ix+TABLE_Y_coord)
391A: DD 77 41    ld   (ix+TABLE_Y_coord),a
391D: C9          ret

391e:   db      $30, $39, $3c, $39, $48, $39, $48, $39, $82, $39, $82, $39, $5e, $39, $5e, $39
392e:   db      $48, $39, $f8, $f8, $04, $70, $01, $80, $11, $81, $00, $88, $10, $89, $f8, $f8
393e:   db      $04, $70, $01, $82, $11, $83, $00, $8a, $10, $8b, $00, $00, $09, $70, $f1, $80
394e:   db      $01, $c8, $11, $81, $f0, $c0, $00, $c1, $10, $c2, $ff, $88, $0f, $c9, $1f, $89
395e:   db      $0c, $70, $f2, $8c, $02, $8d, $12, $8e, $22, $8f, $f1, $94, $01, $95, $11, $96, $21, $97, $f0, $9c, $00, $9d, $10, $9e, $20, $9f
3978:   db      $04, $74, $2f, $8f, $1f, $8e, $0f, $8d, $ff, $8c
3982:   db      $00, $00, $09, $70, $f1, $90, $01, $d8, $11, $91, $f0, $d0, $00, $d1, $10, $d2, $ff, $99, $0f, $d9, $1f, $91

3998: DD 7E 50    ld   a,(ix+$14)
399B: A7          and  a
399C: C2 6B B2    jp   nz,REMOVE_SPRITES
399F: DD 34 50    inc  (ix+$14)
39A2: DD 36 51 02 ld   (iy+TABLE_COUNTDOWN),$20
39A6: 3E 01       ld   a,$01
39A8: 32 B9 0E    ld   ($E09B),a
39AB: C9          ret
39AC: A0          and  b

UPDATE_DOORS:
39AD: 21 58 0E    ld   hl,$E094
39B0: 7E          ld   a,(hl)
39B1: A7          and  a
39B2: 28 F1       jr   z,$39D3
39B4: 36 00       ld   (hl),$00
39B6: DD 7E 50    ld   a,(ix+$14)
39B9: FE 01       cp   $01
39BB: 38 C0       jr   c,$39C9
39BD: 28 50       jr   z,$39D3
39BF: DD 36 50 01 ld   (ix+$14),$01
39C3: DD 36 51 01 ld   (iy+TABLE_COUNTDOWN),$01
39C7: 18 A0       jr   $39D3
39C9: DD 36 50 01 ld   (ix+$14),$01
39CD: DD 36 51 10 ld   (iy+TABLE_COUNTDOWN),$10
39D1: 18 00       jr   $39D3
39D3: CD 4F 93    call $39E5
39D6: DD 7E 50    ld   a,(ix+$14)		; Animation set for doors
39D9: E6 21       and  $03
39DB: 21 C0 B2    ld   hl,$3A0C
39DE: EF          rst	INDEX_ED_AT_2A_PLUS_HL
39DF: CD 88 A3    call HW_SPRITE_UPDATER	; Plot left side of doors
39E2: C3 88 A3    jp   HW_SPRITE_UPDATER	; And carry on with data for flipped right side.

39E5: CD C9 B2    call ADJUST_Y_POSITION
39E8: DD 7E 50    ld   a,(ix+$14)		; check if not 0
39EB: A7          and  a
39EC: C8          ret  z
39ED: DD 35 51    dec  (iy+TABLE_COUNTDOWN)			; countdown timer
39F0: C0          ret  nz			; when 0
39F1: DD 7E 50    ld   a,(ix+$14)		; check current animation number
39F4: FE 21       cp   $03			; only max 3
39F6: 28 A1       jr   z,$3A03
39F8: DD 34 50    inc  (ix+$14)			; Aminations number
39FB: 21 80 B2    ld   hl,$3A08			; now set a countdown timer value
39FE: E7          rst	INDEX_A_PLUS_HL		; call RETURN_BYTE_AT_HL_PLUS_A
39FF: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a		; Save value
3A02: C9          ret
3A03: DD 36 50 00 ld   (ix+$14),$00		; Animation to 0
3A07: C9          ret

3A08:		db	$40,$50,$40,$00

3a0c:		dw	$3a14
3a0e:		dw	$3a3c
3a10:		dw	$3a64
3a12:		dw	$3a3c
3a14:		db	$09, $50, $02, $a0, $12, $a1, $22, $a2	; End door just to show a little bit easier visually
		db	$01, $a8, $11, $a9, $21, $aa
		db	$00, $b0, $10, $b1, $20, $b2
	
3a3c:		db	$09, $50, $02, $a4, $12, $a5, $01, $ac, $11, $ad, $00, $b4, $10, $b5, $1f, $bd, $00, $ff, $00, $ff
3a64:		db	$09, $50, $02, $a3, $01, $ab, $00, $b3, $0f, $bb, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff
3a3c:		db	$09, $50, $02, $a4, $12, $a5, $01, $ac, $11, $ad, $00, $b4, $10, $b5, $1f, $bd, $00, $ff, $00, $ff

3a50:		db	$09, $58, $52, $a4, $42, $a5, $51, $ac, $41, $ad, $50, $b4, $40, $b5, $4f, $bd, $00, $ff, $00, $ff
3a64:		db	$09, $50, $02, $a3, $01, $ab, $00, $b3, $0f, $bb, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff
3a78:		db	$09, $58, $52, $a3, $51, $ab, $50, $b3, $5f, $bb, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff

3A8C: C9          ret				; after processing all sprite tables this is the single little return byte orrrr bless him.

		; So this will move all sprites down with scrolling, and if off bottom enought will kill the item from table list.
ADJUST_Y_POSITION:
3A8D: 3A 26 0E    ld   a,(SCREEN_SCROLLING)	; Check if screen is scrolling
3A90: A7          and  a			; 0 or 1
3A91: C8          ret  z			; return if zero

3A92: DD 66 40    ld   h,(ix+TABLE_X_low)		; otherwise get high Y
3A95: DD 6E 41    ld   l,(ix+TABLE_Y_coord)		; low Y
3A98: 2B          dec  hl			; -1
3A99: DD 74 40    ld   (ix+TABLE_X_low),h		; Save back
3A9C: DD 75 41    ld   (ix+TABLE_Y_coord),l		; to pointers
3A9F: 7C          ld   a,h			; check high y position
3AA0: A7          and  a			; is it -1
3AA1: C8          ret  z			; nope then exit
3AA2: 7D          ld   a,l			; otherwise is check low position
3AA3: FE 0C       cp   $C0			; less than $c0 ie $BF so that's like 4 sprites high off bottom 
3AA5: D0          ret  nc			; not so then return to processing
3AA6: E1          pop  hl			; otherwise let's not return back to processing

REMOVE_SPRITES:
3AA7: DD 36 00 00 ld   (ix+TABLE_STATUS),$00		; kill off this object type
3AAB: DD 46 B0    ld   b,(ix+TABLE_SPRITE_QTY)		; Check how many sprites this item is
3AAE: 11 40 00    ld   de,$0004			; 4 bytes / sprites hardware offset
3AB1: FD 36 20 00 ld   (iy+sprite_x),$00	; kill it with a x = 0
3AB5: FD 19       add  iy,de			; add pointer to next
3AB7: 10 9E       djnz $3AB1			; do all for this item/object
3AB9: C9          ret				; return back to the processing loop. as we skiped the immediate return address

DIAGNOSTICS_MENU:
3ABA: CD 2D B2    call DISPLAY_SETTINGS		; Show status of Coin Credit, player lives stage, difficulty
3ABD: CD A8 D3    call DISPLAY_DIP_SETTINGS	; Show the DIP SWITCH A and B settings and input controller buttons
3AC0: C3 80 F3    jp   SOUND_FX_DEMO		; Joystick left/right and fire to demo sound fx or music number.

DISPLAY_SETTINGS:
3AC3: 21 40 D2    ld   hl,$3C04			; COIN1
3AC6: 06 C0       ld   b,$0C
3AC8: CD 6C B3    call MESSAGE_DISPLAY
3ACB: 10 BF       djnz $3AC8
3ACD: CD 76 20    call READ_SW2_SETTINGS
3AD0: 3A 21 0E    ld   a,(START_BUTTONS)
3AD3: 32 B3 0E    ld   (START_BUTTON_MIRROR),a
3AD6: 3A 60 0E    ld   a,(PORT_STATE_DSW1)
3AD9: 47          ld   b,a			; save to b for temp measures.
3ADA: E6 21       and  $03
3ADC: 87          add  a,a
3ADD: 21 6E B3    ld   hl,$3BE6			; lookup the offset for the coin1 settings
3AE0: E7          rst	INDEX_A_PLUS_HL	 
3AE1: 32 F4 1D    ld   ($D15E),a		; x=10, y=01
3AE4: 23          inc  hl
3AE5: 7E          ld   a,(hl)			; Credits for this coin(s)
3AE6: 32 F4 3C    ld   ($D25E),a		; x=18, y=01
3AE9: 78          ld   a,b			; get back the SW1 value
3AEA: 0F          rrca
3AEB: 0F          rrca
3AEC: E6 21       and  $03
3AEE: 87          add  a,a
3AEF: 21 6E B3    ld   hl,$3BE6			; lookup the offset for the coin2 settings
3AF2: E7          rst	INDEX_A_PLUS_HL	
3AF3: 32 D5 1D    ld   ($D15D),a		; x=10, y=02
3AF6: 23          inc  hl
3AF7: 7E          ld   a,(hl)			; Credits for this coin(s)
3AF8: 32 D5 3C    ld   ($D25D),a
3AFB: 78          ld   a,b
3AFC: 07          rlca
3AFD: 07          rlca
3AFE: 07          rlca
3AFF: 07          rlca
3B00: E6 21       and  $03
3B02: 21 2E B3    ld   hl,$3BE2			; Players you get for a game
3B05: E7          rst	INDEX_A_PLUS_HL
3B06: 32 D4 1D    ld   ($D15C),a		; x=18, y=03
3B09: 78          ld   a,b
3B0A: 07          rlca
3B0B: 07          rlca
3B0C: E6 21       and  $03
3B0E: 21 BE B3    ld   hl,$3BFA			; Starting stage table
3B11: E7          rst	INDEX_A_PLUS_HL
3B12: 32 B7 3C    ld   ($D27B),a
3B15: 3A 61 0E    ld   a,(PORT_STATE_DSW2)
3B18: 47          ld   b,a
3B19: E6 01       and  $01
3B1B: CA 78 B3    jp   z,$3B96
3B1E: CB 48       bit  1,b
3B20: CA F9 B3    jp   z,$3B9F
3B23: 21 71 D3    ld   hl,$3D17			; "UPRIGHT_ONE PLAYER"
3B26: CD 6C B3    call MESSAGE_DISPLAY
3B29: CB 58       bit  3,b
3B2B: CA 48 B3    jp   z,$3B84
3B2E: 21 25 D3    ld   hl,$3D43			; "DIFFICULT" if hard or normal 
3B31: CD 6C B3    call MESSAGE_DISPLAY
3B34: CB 60       bit  4,b
3B36: CA C9 B3    jp   z,$3B8D
3B39: 21 EF D2    ld   hl,$3CEF
3B3C: CD 6C B3    call MESSAGE_DISPLAY
3B3F: 78          ld   a,b
3B40: 07          rlca
3B41: 07          rlca
3B42: 07          rlca
3B43: E6 61       and  $07
3B45: FE 61       cp   $07
3B47: CA 7B B3    jp   z,$3BB7
3B4A: 21 B5 D3    ld   hl,$3D5B
3B4D: CD 6C B3    call MESSAGE_DISPLAY
3B50: 21 56 D3    ld   hl,$3D74
3B53: CD 6C B3    call MESSAGE_DISPLAY
3B56: 78          ld   a,b
3B57: 07          rlca
3B58: 07          rlca
3B59: 07          rlca
3B5A: E6 61       and  $07
3B5C: FE 60       cp   $06
3B5E: CA 8A B3    jp   z,$3BA8
3B61: 87          add  a,a
3B62: 21 EE B3    ld   hl,$3BEE
3B65: E7          rst	INDEX_A_PLUS_HL
3B66: 32 71 3C    ld   ($D217),a
3B69: 23          inc  hl
3B6A: 7E          ld   a,(hl)
3B6B: 32 70 3C    ld   ($D216),a

3B6E: 21 54 1C    ld   hl,$D054			; x=02, y=11
3B71: 06 A1       ld   b,$0B
3B73: CD 9D B3    call DOTTED_LINE
3B76: 21 FE B3    ld   hl,$3BFE			; "BIT"
3B79: CD 6C B3    call MESSAGE_DISPLAY
3B7C: 21 54 3C    ld   hl,$D254			; x=18, y=11
3B7F: 06 A1       ld   b,$0B
3B81: C3 9D B3    jp   DOTTED_LINE

3B84: 21 E5 D3    ld   hl,$3D4F			; "NORMAL"
3B87: CD 6C B3    call MESSAGE_DISPLAY
3B8A: C3 52 B3    jp   $3B34

3B8D: 21 8F D2    ld   hl,$3CE9			; "ON"
3B90: CD 6C B3    call MESSAGE_DISPLAY
3B93: C3 F3 B3    jp   $3B3F

3B96: 21 01 D3    ld   hl,$3D01			; "TABLE"
3B99: CD 6C B3    call MESSAGE_DISPLAY
3B9C: C3 83 B3    jp   $3B29

3B9F: 21 C3 D3    ld   hl,$3D2D			; "UPRIGHT_TWO PLAYER"
3BA2: CD 6C B3    call MESSAGE_DISPLAY
3BA5: C3 83 B3    jp   $3B29

3BA8: 21 B8 D2    ld   hl,$3C9A			; "4"
3BAB: CD 6C B3    call MESSAGE_DISPLAY
3BAE: 21 F8 D2    ld   hl,$3C9E			; "10"
3BB1: CD 6C B3    call MESSAGE_DISPLAY
3BB4: C3 E6 B3    jp   $3B6E

3BB7: 21 2B D2    ld   hl,$3CA3			; " BONUS NECESSARY"
3BBA: CD 6C B3    call MESSAGE_DISPLAY
3BBD: 21 6C D2    ld   hl,$3CC6			; "                " spaces
3BC0: CD 6C B3    call MESSAGE_DISPLAY
3BC3: C3 E6 B3    jp   $3B6E

		; Display text to screen memory from the first two bytes then the string until the "@"
MESSAGE_DISPLAY:
3BC6: 5E          ld   e,(hl)			; screen memory low
3BC7: 23          inc  hl
3BC8: 56          ld   d,(hl)			; screen memory high
3BC9: 23          inc  hl
3BCA: 7E          ld   a,(hl)			; get first character
3BCB: 23          inc  hl
3BCC: FE 04       cp   $40			; end of string "@"
3BCE: C8          ret  z			; yes exit.
3BCF: 12          ld   (de),a			; display it
3BD0: 7B          ld   a,e
3BD1: C6 02       add  a,$20
3BD3: 5F          ld   e,a
3BD4: 30 5E       jr   nc,$3BCA			; if out side character range
3BD6: 14          inc  d
3BD7: 18 1F       jr   $3BCA

DOTTED_LINE:
3BD9: 11 02 00    ld   de,$0020			; next character space across
3BDC: 36 B5       ld   (hl),$5B			; "." special dot or dash graphic? Why not use $2e?
3BDE: 19          add  hl,de			; add to memory address
3BDF: 10 9E       djnz DOTTED_LINE
3BE1: C9          ret

3BE2:		db	"3245"			; Lives you get for new game
3BE6:		db	"11121321"		; Coin and credit values
3BEE: 		db	"151626273738"
3BFA:		db	"1357"			; Starting stage number
 
3BFE:	dw	$D1D4
	db	"BIT@"
3C04:	dw	$D05E
	db	" COIN1@"
3C0D:	dw	$D19E
	db	"COIN@"
3C14:	dw	$D29E
	db	"CREDIT@"
3C1D:	dw	$D05D
	db	" COIN2@"
3C26:	dw	$D19D
	db	"COIN @"
3C2E:	dw	$D29D
	db	"CREDIT@"
3C37:	dw	$D05C
	db	" PLAYER@"
3C41:	dw	$D058
	db	" SOUND@"
3C4A:	dw	$D05A
	db	" TYPE@"
3C52:	dw	$D058
	db	" SOUND @"
3C5C:	dw	$D05B
	db	" STARTING STAGE@"
3C6E:	dw	$D059
	db	" DEFFICULTY@"
3C7C:	dw	$D343
	db	"DIP SW OK   @"
3C8B:	dw	$D343
	db	"DIP SW CHECK@"
3C9A:	dw	$D217
	db	"4@"
3C9E:	dw	$D1F6
	db	"10@"
3CA3:	dw	$D057
	db	" BONUS NECESSARY                @"
3CC6:	dw	$D0B6
	db	"                                @"
3CE9:	dw	$D158
	db	"ON @"
3CEF:	dw	$D158
	db	"OFF@"
3CF5:	dw	$D289
	db	"ON @"
3CFB:	dw	$D289
	db	"OFF@"
3D01:	dw	$D15A
	db	"TABLE              @"
3D17:	dw	$D15A
	db	"UPRIGHT_ONE PLAYER @"
3D2D:	dw	$D15A
	db	"UPRIGHT_TWO PLAYERS@"
3D43:	dw	$D219
	db	"DIFFICULT@"
3D4F:	dw	$D219
	db	"NORMAL   @"
3D5B:	dw	$D057
	db	" FIRST BONUS  10000PTS@"
3D74:	dw	$D0B6
	db	"AND AFTER  50000PTS@"

3D8A: 21 D2 F2    ld   hl,$3E3C			; "DIP SWITCH A"
3D8D: 06 30       ld   b,$12
3D8F: CD 6C B3    call MESSAGE_DISPLAY
3D92: 10 BF       djnz $3D8F			; Show both messages ie Switch A & B
3D94: 3A 60 0E    ld   a,(PORT_STATE_DSW1 )	; First Switch Status
3D97: 4F          ld   c,a			; keep status in c
3D98: 21 32 3C    ld   hl,$D232			; x=17, y=13
3D9B: 11 02 00    ld   de,$0020			; Next character
3D9E: 06 80       ld   b,$08			; Show out all 8 bits
3DA0: E6 01       and  $01			; a 0 or a 1
3DA2: 77          ld   (hl),a			; display it
3DA3: 19          add  hl,de			; next character on screen
3DA4: CB 09       rrc  c			; move bits right
3DA6: 79          ld   a,c			; put back to a
3DA7: 10 7F       djnz $3DA0			; show all 8 bits right to left
3DA9: 3A 61 0E    ld   a,(PORT_STATE_DSW2)	; Now do 2nd switch
3DAC: 4F          ld   c,a
3DAD: 21 13 3C    ld   hl,$D231			; x=17, y=14
3DB0: 06 80       ld   b,$08
3DB2: E6 01       and  $01
3DB4: 77          ld   (hl),a			; do same as above show all 8 bits
3DB5: 19          add  hl,de
3DB6: CB 09       rrc  c
3DB8: 79          ld   a,c
3DB9: 10 7F       djnz $3DB2

3DBB: 3A 40 0E    ld   a,(CONTROLLER_1)		; player 1 controller bits
3DBE: 4F          ld   c,a
3DBF: 21 CA 1D    ld   hl,$D1AC			; x=13, y=19
3DC2: 06 40       ld   b,$04			; roll down screen 4 bit to match controller left/right/up/down
3DC4: E6 01       and  $01
3DC6: 77          ld   (hl),a
3DC7: 23          inc  hl
3DC8: CB 09       rrc  c
3DCA: 79          ld   a,c
3DCB: 10 7F       djnz $3DC4
3DCD: 21 AB 1D    ld   hl,$D1AB			; x=13, y=20
3DD0: E6 01       and  $01
3DD2: 77          ld   (hl),a
3DD3: 2B          dec  hl
3DD4: CB 09       rrc  c
3DD6: 79          ld   a,c
3DD7: E6 01       and  $01
3DD9: 77          ld   (hl),a
3DDA: 3A 41 0E    ld   a,(CONTROLLER_2)		; player 2 controller bits
3DDD: 4F          ld   c,a
3DDE: 21 C8 3D    ld   hl,$D38C			;  x=28, y=19
3DE1: 06 40       ld   b,$04			; roll down screen 4 bit to match controller left/right/up/down
3DE3: E6 01       and  $01
3DE5: 77          ld   (hl),a
3DE6: 23          inc  hl
3DE7: CB 09       rrc  c
3DE9: 79          ld   a,c
3DEA: 10 7F       djnz $3DE3
3DEC: 21 A9 3D    ld   hl,$D38B			; x=28, y=20
3DEF: E6 01       and  $01
3DF1: 77          ld   (hl),a
3DF2: 2B          dec  hl
3DF3: CB 09       rrc  c
3DF5: 79          ld   a,c
3DF6: E6 01       and  $01
3DF8: 77          ld   (hl),a
3DF9: 3A 21 0E    ld   a,(START_BUTTONS)	; Get start buttons 1P Start or 2P Start bits
3DFC: 47          ld   b,a
3DFD: E6 01       and  $01
3DFF: 21 89 3D    ld   hl,$D389			; x=28, y=22
3E02: 77          ld   (hl),a			; 1P
3E03: 2B          dec  hl
3E04: CB 08       rrc  b
3E06: 78          ld   a,b
3E07: E6 01       and  $01
3E09: 77          ld   (hl),a			; 2P
3E0A: 3A 21 0E    ld   a,(START_BUTTONS)	; Get Coin bits at this position
3E0D: 07          rlca
3E0E: 47          ld   b,a
3E0F: 21 8A 1D    ld   hl,$D1A8			; x=13, y=23
3E12: E6 01       and  $01
3E14: 77          ld   (hl),a			; Coin 1
3E15: 23          inc  hl
3E16: CB 00       rlc  b
3E18: 78          ld   a,b
3E19: E6 01       and  $01
3E1B: 77          ld   (hl),a			; Coin 2
3E1C: 21 64 1C    ld   hl,$D046			; x=02, y=25
3E1F: 06 A1       ld   b,$0B
3E21: CD 9D B3    call DOTTED_LINE
3E24: 21 33 F2    ld   hl,$3E33			; "OUTPUT"
3E27: CD 6C B3    call MESSAGE_DISPLAY
3E2A: 21 66 3C    ld   hl,$D266			; x=19, y=25
3E2D: 06 A1       ld   b,$0B
3E2F: CD 9D B3    call DOTTED_LINE
3E32: C9          ret

3E33:	dw	$D1A6
	db	"OUTPUT@"
3E3C:	dw	$D052
	db	" DIP SWICTH A@"
3E4C:	dw	$D051
	db	" DIP SWICTH B@"
3E5C:	dw	$D04F
	db	" 1P UP@"
3E65:	dw	$D04E
	db	" 1P DOWN@"
3E70:	dw	$D04D
	db	" 1P LEFT@"
3E7B:	dw	$D04C
	db	" 1P RIGHT@"
3E87:	dw	$D04B
	db	" 1P SHOOT1@"
3E94:	dw	$D04A
	db	" 1P SHOOT2@"
3EA1:	dw	$D049
	db	" COIN1@"
3EAA:	dw	$D048
	db	" COIN2@"
3EB3:	dw	$D24F
	db	"2P UP@"
3EBB:	dw	$D24E
	db	"2P DOWN@"
3EC5:	dw	$D24D
	db	"2P LEFT@"
3ECF:	dw	$D24C
	db	"2P RIGHT@"
3EDA:	dw	$D24B
	db	"2P SHOOT1@"
3EE6:	dw	$D24A
	db	"2P SHOOT2@"
3EF2:	dw	$D249
	db	"1P_START@"
3EFD:	dw	$D248
	db	"2P_START@"

SOUND_FX_DEMO:
3F08: 21 C5 F3    ld   hl,$3F4D			; Display TEST SOUND CODE
3F0B: 06 41       ld   b,$05
3F0D: CD 6C B3    call MESSAGE_DISPLAY
3F10: 10 BF       djnz $3F0D
3F12: 3A 44 0E    ld   a,(TEST_MODE_SFX_NUMBER)	; SFX / Music Number
3F15: 21 48 3C    ld   hl,$D284			; Character Screen x=20, y=27
3F18: 0E 00       ld   c,$00
3F1A: CD D8 D8    call PRINT_NUMBER
3F1D: 21 44 0E    ld   hl,TEST_MODE_SFX_NUMBER
3F20: CD 12 F3    call CHANGE_SOUND_CODE	; Left right to adjust the SFX number
3F23: 3A C0 0E    ld   a,(JOYSTICK1_FIRE1)
3F26: E6 61       and  $07
3F28: FE 01       cp   $01			; let's only call when long press is at a level
3F2A: C0          ret  nz
3F2B: 7E          ld   a,(hl)			; get current code
3F2C: 32 B2 0E    ld   (SOUND_CODE),a		; Send to sound hardware latch
3F2F: C9          ret

CHANGE_SOUND_CODE:
3F30: 3A 80 0E    ld   a,(JOYSTICK1_RIGHT)	; move right
3F33: E6 61       and  $07			; take lower bits
3F35: FE 01       cp   $01			; = 1?
3F37: 28 E0       jr   z,$3F47			; yes right is SFX number + 1
3F39: 3A 81 0E    ld   a,(JOYSTICK1_LEFT)
3F3C: E6 61       and  $07			; take lower bits
3F3E: FE 01       cp   $01			; =1?
3F40: C0          ret  nz			; exit is not left
3F41: 35          dec  (hl)			; otherwise -1 code
3F42: 7E          ld   a,(hl)			; get number
3F43: E6 F3       and  $3F			; sound effect test only $01 - $3f
3F45: 77          ld   (hl),a			; save back
3F46: C9          ret

3F47: 34          inc  (hl)			; Advance on code
3F48: 7E          ld   a,(hl)			; load in
3F49: E6 F3       and  $3F			; only 0 - $3f
3F4B: 77          ld   (hl),a			; save back
3F4C: C9          ret

3F4D:	dw	$D044
	db	" TEST SOUND CODE@"
3F60:	dw	$D042
	db	" COUNTER1 =@"
3F6E:	dw	$D041
	db	" COUNTER2 =@"
3F7C:	dw	$D1C2
	db	"PUSH 1P START@"
3F8C:	dw	$D1C1
	db	"PUSH 2P START@"
	
	; Note rest of this space is full of $ff00 words until end of this half of the rom ( remember it's split into two ROMs on the hardware)
	
	
ORG $4000
			; table for the x & y position for background trees and rocks only
			; delemiter for an Area is $ff
			; Byte 2 & 3 is scroll offset position
			; Byte 0 is x position 
			; Byte 1 is Sprite number $0A is palm tree, and $00 is top of rocks
			; if y position low byte is 8 then this indicates the image is reversed, but need to do a y - 8
			; also found the rocks need to also move one pixel, in fact seems to be y + 2
TREES_ROCKS_TABLE:
4000:		db	$80,$0a,$10,$00
		db	$a0,$0a,$18,$00
		db	$90,$0a,$20,$00
		db	$10,$0a,$60,$00
		db	$d0,$0a,$68,$00
		db	$50,$0a,$e0,$00
		db	$80,$0a,$10,$01
		db	$a0,$0a,$18,$01
		db	$90,$0a,$20,$01
		db	$50,$0a,$60,$01
		db	$00,$0a,$d0,$01
		db	$20,$0a,$d8,$01
		db	$10,$0a,$e0,$01
		db	$90,$0a,$e8,$01
		db	$50,$0a,$20,$02
		db	$90,$0a,$60,$02
		db	$d0,$0a,$a0,$02
		db	$10,$0a,$60,$03
		db	$90,$0a,$68,$03
		db	$50,$0a,$a0,$03
		db	$70,$00,$91,$04
		db	$10,$00,$b1,$04
		db	$e0,$00,$d1,$04
		db	$40,$00,$f1,$04
		db	$a0,$00,$11,$05
		db	$10,$00,$71,$05
		db	$70,$00,$71,$05
		db	$d0,$00,$71,$05
			; No data for area 2 & 3

			; Initial pointer to this area 4 $4070
TREES_ROCKS_TABLE2:
		db	$10,$0a,$20,$1a
		db	$80,$0a,$50,$1a
		db	$a0,$0a,$58,$1a
		db	$90,$0a,$60,$1a
		db	$a0,$0a,$20,$1c
		
		
		db	$10,$00,$71,$20	; Data for level 4 Helicopter ride
		db	$70,$00,$71,$20
		db	$d0,$00,$71,$20
		db	$10,$0a,$60,$21
		db	$90,$0a,$68,$21
		db	$50,$0a,$a0,$21
		db	$a0,$00,$11,$23
		db	$10,$00,$71,$23
		db	$70,$00,$71,$23
		db	$d0,$00,$71,$23
		db	$50,$0a,$20,$24			; last tree
		
		; Initial pointer to this area 5 $40b0
		db	$50,$0a,$20,$40
		db	$40,$0a,$d0,$41
		db	$60,$0a,$d8,$41
		db	$50,$0a,$e0,$41
		db	$40,$0a,$d0,$42
		db	$60,$0a,$d8,$42
		db	$50,$0a,$e0,$42
		db	$a0,$00,$11,$45
		db	$30,$00,$31,$45
		db	$20,$00,$91,$45
		db	$70,$00,$b1,$45
		db	$b0,$00,$d1,$45
		db	$10,$00,$31,$46
		db	$60,$00,$51,$46
		db	$90,$00,$71,$46
		db	$c0,$00,$b1,$46

		; $40f0 area 8 completed game over helicopter ride trees back to start level
		
		db	$10,$00,$71,$60
		db	$70,$00,$71,$60
		db	$d0,$00,$71,$60
		db	$10,$0a,$60,$61
		db	$90,$0a,$68,$61
		db	$50,$0a,$a0,$61
		db	$a0,$00,$11,$63
		db	$10,$00,$71,$63
		db	$70,$00,$71,$63
		db	$d0,$00,$71,$63
		db	$80,$0a,$10,$64
		db	$a0,$0a,$18,$64
		db	$90,$0a,$20,$64
		db	$10,$0a,$60,$64
		db	$d0,$0a,$68,$64
		db	$50,$0a,$e0,$64
		db	$a0,$00,$20,$ff


		; Maps are stored as 4 bytes per line which plots a 4x4 tile, so very small data set / tile row
		; Maps are draw bottom to top left - right. (as display memory allows)
		; From map data, this is list of unused inside this set which are not active
		; 04 05 0A 0D 36
		; 49 4B 58 59 5A 5B 5C 5D 5E 5F
		; 64 65 66 67 68 69 6A 6B 6C 6D
		; 6E 6F 70 71 72 77 78 79 7A 7B
		; 7C 7D 7E 7F 80 81 94 B5 B8
		; C2 C3 C4 C5

AREA1_MAP:
		; $4134 - $41b3 Area 1 map
		db	$0e,$0f,$1a,$20
		db	$21,$1f,$1d,$22
		db	$27,$2c,$1b,$00
		db	$12,$13,$23,$25
		db	$1d,$09,$1a,$34
		db	$27,$2e,$30,$0b
		db	$4a,$29,$26,$01
		db	$1a,$20,$24,$25
		db	$1e,$1c,$96,$20
		db	$0c,$34,$21,$09
		db	$02,$03,$29,$2e
		db	$34,$14,$15,$29
		db	$34,$20,$1f,$34
		db	$21,$2c,$24,$25
		db	$23,$1c,$34,$34
		db	$34,$34,$34,$96
		db	$c9,$ca,$cb,$cc
		db	$89,$88,$87,$86
		db	$2f,$32,$33,$34
		db	$34,$3c,$34,$2d
		db	$34,$34,$2d,$34
		db	$2f,$2a,$2b,$2f
		db	$34,$34,$34,$34
		db	$34,$96,$34,$34
		db	$34,$34,$c6,$c7
		db	$96,$34,$34,$34
		db	$34,$c8,$c7,$34
		db	$97,$98,$34,$34
		db	$34,$34,$34,$96
		db	$34,$34,$34,$34
		db	$34,$34,$34,$34
		db	$54,$55,$56,$57


		; $41b4 - $4233 Area 2 map
		db	$95,$9f,$95,$9f
		db	$9f,$95,$9f,$95
		db	$95,$9f,$95,$9f
		db	$9f,$95,$9f,$95
		db	$95,$9f,$95,$9f
		db	$9f,$95,$9f,$95
		db	$95,$9f,$95,$9f
		db	$d3,$b4,$9f,$95
		db	$95,$9f,$ce,$cf
		db	$d0,$cf,$d3,$d2
		db	$95,$ce,$cf,$9f
		db	$9f,$95,$d1,$d0
		db	$d3,$b4,$95,$9f
		db	$9f,$d1,$d0,$28
		db	$d1,$28,$95,$9f
		db	$9f,$95,$9f,$95
		db	$be,$bf,$c0,$c1
		db	$85,$84,$83,$82
		db	$9f,$95,$9f,$95
		db	$9b,$9c,$95,$9f
		db	$9d,$95,$9f,$95
		db	$4d,$4f,$51,$53
		db	$4c,$4e,$50,$52
		db	$99,$9f,$95,$9f
		db	$9f,$95,$9f,$95
		db	$95,$9f,$95,$9a
		db	$9f,$95,$9f,$95
		db	$99,$9f,$95,$06
		db	$3b,$95,$9f,$07
		db	$3f,$9f,$95,$07
		db	$3f,$95,$9f,$07
		db	$35,$b6,$b7,$31

		; $4234 - $42b3 Area 3 map
		db	$95,$9f,$95,$9f
		db	$9f,$95,$9f,$95
		db	$95,$9f,$95,$9f
		db	$9f,$95,$9f,$95
		db	$95,$9f,$95,$9f
		db	$9f,$95,$9f,$95
		db	$95,$9f,$95,$9f
		db	$d3,$b4,$9f,$95
		db	$95,$9f,$ce,$cf
		db	$d0,$cf,$d3,$d2
		db	$95,$ce,$cf,$9f
		db	$9f,$95,$d1,$d0
		db	$d3,$b4,$95,$9f
		db	$9f,$d1,$d0,$28
		db	$d1,$28,$95,$9f
		db	$9f,$95,$9f,$95
		db	$be,$bf,$c0,$c1
		db	$85,$84,$83,$82
		db	$9f,$95,$9f,$95
		db	$9b,$9c,$95,$9f
		db	$9d,$95,$9f,$95
		db	$4d,$4f,$51,$53
		db	$4c,$4e,$50,$52
		db	$99,$9f,$95,$9f
		db	$9f,$95,$9f,$95
		db	$95,$9f,$95,$9a
		db	$9f,$95,$9f,$95
		db	$99,$9f,$95,$06
		db	$3b,$95,$9f,$07
		db	$3f,$9f,$95,$07
		db	$3f,$95,$9f,$07
		db	$35,$b6,$b7,$31


		; $42b4 - $4333 Area 4 map
		db	$34,$34,$34,$34
		db	$34,$34,$34,$34
		db	$63,$63,$62,$63
		db	$34,$34,$34,$34
		db	$63,$61,$60,$63
		db	$34,$34,$34,$34
		db	$34,$34,$34,$34
		db	$63,$76,$63,$63
		db	$19,$34,$34,$34
		db	$34,$34,$1a,$34
		db	$97,$98,$17,$16
		db	$17,$16,$44,$44
		db	$44,$44,$44,$08
		db	$44,$3d,$3e,$11
		db	$3e,$44,$47,$48
		db	$3d,$46,$74,$75
		db	$37,$44,$18,$73
		db	$10,$45,$3e,$44
		db	$16,$44,$44,$3d
		db	$44,$3d,$3e,$44
		db	$3e,$44,$47,$48
		db	$47,$48,$3a,$39
		db	$34,$34,$34,$38
		db	$34,$34,$34,$34
		db	$8c,$8d,$34,$34
		db	$8b,$34,$34,$34
		db	$34,$34,$34,$34
		db	$34,$34,$34,$34
		db	$34,$34,$34,$34
		db	$34,$34,$34,$34
		db	$a2,$a3,$a6,$a7
		db	$a0,$a1,$a4,$a5

		; $4334 - $4373 1st Helicopter ride map
		db	$8f,$90,$91,$92
		db	$2f,$2a,$2b,$2f
		db	$34,$34,$34,$34
		db	$34,$96,$34,$34
		db	$34,$20,$1f,$34
		db	$21,$2c,$24,$25
		db	$23,$1c,$34,$34
		db	$34,$34,$34,$96
		db	$34,$34,$c6,$c7
		db	$96,$34,$34,$34
		db	$34,$c8,$c7,$34
		db	$97,$98,$34,$34
		db	$34,$34,$2d,$34
		db	$2f,$2a,$2b,$2f
		db	$34,$34,$34,$34
		db	$34,$96,$34,$34
		db	$10,$19,$04,$05
		db	$34,$34,$34,$34

		; $4374 - $43f3 Area 5 map
AREA2_MAP:
		db	$10,$19,$04,$05
		db	$34,$34,$34,$34
		db	$c4,$c5,$34,$34
		db	$c2,$c3,$34,$0b
		db	$0a,$34,$34,$01
		db	$59,$0c,$34,$49
		db	$58,$02,$03,$0b
		db	$34,$1a,$34,$01
		db	$34,$0b,$77,$34
		db	$34,$01,$6d,$0b
		db	$0a,$34,$34,$01
		db	$34,$1a,$34,$34
		db	$0c,$34,$0e,$0f
		db	$02,$03,$0b,$5b
		db	$34,$34,$01,$5a
		db	$34,$34,$34,$34
		db	$c9,$ca,$cb,$cc
		db	$89,$88,$87,$86
		db	$49,$4a,$5e,$5f
		db	$34,$34,$5c,$5d
		db	$2a,$2b,$2d,$34
		db	$34,$49,$4a,$c6
		db	$2d,$2a,$2b,$34
		db	$96,$34,$32,$33
		db	$2f,$34,$49,$4a
		db	$34,$2d,$2f,$34
		db	$c4,$c5,$34,$3c
		db	$c2,$c3,$96,$34
		db	$34,$34,$34,$34
		db	$34,$49,$4a,$34
		db	$4b,$98,$4b,$98
		db	$54,$55,$56,$57


		; $43f4 - $4473 Area 6 map
		db	$95,$9f,$95,$9f
		db	$9f,$95,$9f,$95
		db	$99,$9f,$95,$9f
		db	$9f,$95,$9f,$9a
		db	$95,$9f,$95,$9f
		db	$99,$95,$9f,$95
		db	$9f,$95,$9f,$95
		db	$95,$9f,$95,$9a
		db	$9f,$95,$9f,$95
		db	$3b,$9f,$95,$06
		db	$3f,$95,$9f,$07
		db	$3f,$9f,$95,$07
		db	$3f,$95,$9f,$07
		db	$3f,$9f,$95,$07
		db	$3f,$95,$9f,$07
		db	$64,$9f,$95,$65
		db	$be,$bf,$c0,$c1
		db	$85,$84,$83,$82
		db	$d2,$b4,$95,$d1
		db	$b4,$9f,$ce,$cf
		db	$53,$4d,$4f,$51
		db	$52,$4c,$4e,$50
		db	$95,$d3,$d2,$b4
		db	$d2,$b4,$95,$9f
		db	$b4,$9f,$ce,$cf
		db	$9f,$95,$d3,$b4
		db	$4f,$51,$53,$4d
		db	$4e,$50,$52,$4c
		db	$d3,$d2,$b4,$9f
		db	$9f,$95,$d1,$d0
		db	$d0,$cf,$9f,$d1
		db	$b5,$b6,$b7,$b8


		; $4474 - $44f3 Area 7 map
		db	$40,$41,$40,$41
		db	$66,$67,$41,$68
		db	$7a,$41,$78,$79
		db	$70,$40,$6e,$6f
		db	$7d,$7e,$7f,$41
		db	$7a,$40,$78,$79
		db	$70,$41,$6e,$6f
		db	$66,$67,$41,$40
		db	$40,$41,$40,$41
		db	$66,$67,$72,$7c
		db	$40,$41,$40,$41
		db	$41,$69,$6a,$40
		db	$7a,$41,$40,$7b
		db	$70,$80,$81,$71
		db	$40,$41,$40,$41
		db	$41,$40,$41,$40
		db	$aa,$a9,$a8,$9e
		db	$93,$8e,$8a,$cd
		db	$40,$41,$40,$41
		db	$41,$40,$41,$40
		db	$40,$41,$40,$41
		db	$41,$40,$41,$40
		db	$40,$41,$40,$41
		db	$41,$40,$41,$40
		db	$40,$41,$40,$41
		db	$41,$40,$41,$40
		db	$40,$41,$40,$41
		db	$41,$40,$41,$40
		db	$40,$41,$40,$41
		db	$41,$40,$41,$40
		db	$40,$41,$40,$41
		db	$b9,$ba,$bb,$bc


		; $44f4 - $4573 Area 8 map
		db	$34,$34,$34,$34
		db	$34,$97,$98,$34
		db	$63,$61,$60,$63
		db	$63,$76,$62,$63
		db	$c6,$c7,$34,$c6
		db	$34,$34,$34,$34
		db	$8c,$8d,$34,$17
		db	$8b,$17,$16,$44
		db	$16,$44,$3d,$3e
		db	$3d,$3e,$44,$44
		db	$44,$44,$47,$48
		db	$44,$46,$34,$34
		db	$37,$44,$36,$17
		db	$34,$45,$44,$08
		db	$16,$44,$44,$11
		db	$d4,$44,$3d,$3e
		db	$3d,$3e,$44,$44
		db	$44,$44,$47,$48
		db	$47,$48,$34,$34
		db	$8c,$8d,$34,$34
		db	$8b,$34,$34,$34
		db	$34,$34,$34,$34
		db	$34,$34,$34,$34
		db	$3a,$39,$6c,$34
		db	$34,$38,$6b,$17
		db	$36,$17,$16,$44
		db	$44,$44,$3d,$3e
		db	$3d,$3e,$44,$44
		db	$44,$44,$47,$48
		db	$47,$48,$34,$34
		db	$a2,$a3,$a6,$a7
		db	$a0,$a1,$a4,$a5

		; $4574 - $45c3 Final Helicopter ride completing the game
		db	$8f,$90,$91,$92
		db	$2f,$2a,$2b,$2f
		db	$34,$34,$34,$34
		db	$34,$96,$34,$34
		db	$34,$20,$1f,$34
		db	$21,$2c,$24,$25
		db	$23,$1c,$34,$34
		db	$34,$34,$34,$96
		db	$34,$34,$c6,$c7
		db	$96,$34,$34,$34
		db	$34,$c8,$c7,$34
		db	$97,$98,$34,$34
		db	$34,$34,$2d,$34
		db	$2f,$2a,$2b,$2f
		db	$34,$34,$34,$34
		db	$34,$96,$34,$34
		db	$0e,$0f,$1a,$20
		db	$21,$1f,$1d,$22
		db	$27,$2c,$1b,$00


		; Map data above points to these screen tiles, which is two bytes entry Character data, and Colour RAM
		; Note: Color RAM is split contains tile 16x16 tile value (0-3ff) also palette data, and X & Y flip bits
		; So below each byte pair has the follow bits
		; Byte 0 is LL low byte of the tile number ie ( $0ll)
		; Byte 1 is where the action is at. Bits 7 6 is tile number high bye (technically bit of course as is only 0-3 ( $xll)
		; Bit 5 Is horizontal flip
		; Bit 4 Ia vertical bit flip
		; Bits 0-3 is the palette number for the character.

		; From the AREA map data Some tiles are not used, but it's possible modified during gameplay (not checked this)
		; tiles only go up to $d3, there is a lot of unsed definitions at least from map data above.
		; You may notice a lot of 00 data, because the screen actually does not display left - right 8 pixels (due to hardware scrolling I guess)
		; Those bytes in the tiles are 00 00, either on left or on right, they seem to be trigger positions placements.
		; Tile data is stored one of 8 bytes at a time which is 16x16 tile and it's colour data, and 4 lines so a chunky 32x32pixel tile character.
		; Below is the 213 tiles. $1aa0 bytes in total (in case you wondered!)
TILE_DATA:
45C4:
		db	$88,$01,$89,$01,$8a,$01,$00,$00,$90,$01,$91,$01,$92,$01,$00,$00,$98,$01,$99,$01,$9a,$01,$00,$00,$37,$84,$3b,$84,$37,$a4,$00,$00	;	Tile 01
		db	$3b,$84,$3b,$a4,$37,$84,$3b,$84,$37,$84,$83,$21,$79,$21,$78,$21,$65,$21,$64,$21,$63,$21,$62,$21,$6d,$21,$6c,$21,$6b,$21,$6a,$21	;	Tile 02
		db	$78,$01,$78,$01,$79,$01,$83,$01,$62,$01,$62,$01,$62,$01,$9c,$01,$62,$01,$62,$01,$64,$01,$66,$01,$6a,$01,$6b,$01,$6c,$01,$6e,$01	;	Tile 03
		db	$3a,$84,$39,$84,$9e,$01,$9f,$01,$9d,$01,$3a,$84,$3b,$84,$37,$84,$67,$01,$3b,$84,$3a,$84,$39,$84,$6f,$01,$37,$84,$3b,$84,$3a,$84	;	Tile 04
		db	$37,$84,$3b,$84,$3a,$84,$42,$03,$3b,$a4,$48,$03,$49,$03,$4a,$03,$3a,$a4,$50,$03,$51,$03,$52,$02,$39,$a4,$58,$03,$59,$02,$5a,$02	;	Tile 05
		db	$43,$03,$44,$03,$3a,$84,$39,$84,$4b,$03,$4c,$03,$37,$a4,$3b,$84,$53,$02,$54,$02,$37,$84,$3a,$84,$5b,$02,$37,$84,$9e,$01,$9f,$01	;	Tile 06
		db	$c3,$2c,$d6,$2c,$d5,$2c,$00,$00,$5c,$ab,$c3,$2c,$c2,$2c,$00,$00,$5d,$ab,$5e,$ab,$5f,$ab,$00,$00,$5c,$ab,$5d,$ab,$5e,$ab,$00,$00	;	Tile 07
		db	$cc,$2c,$cb,$2c,$ca,$2c,$00,$00,$d4,$2c,$d3,$2c,$d2,$2c,$00,$00,$dc,$2c,$db,$2c,$da,$2c,$00,$00,$cf,$2c,$ce,$2c,$cd,$2c,$00,$00	;	Tile 08
		db	$b2,$ef,$b1,$ef,$b0,$ef,$00,$00,$ba,$ef,$b9,$ef,$b8,$ef,$00,$00,$79,$ef,$78,$ef,$45,$8a,$00,$00,$45,$8a,$45,$8a,$45,$8a,$00,$00	;	Tile 09
		db	$5d,$04,$2c,$84,$06,$84,$07,$84,$19,$a4,$18,$a4,$37,$84,$3b,$84,$13,$a4,$37,$84,$3b,$a4,$3a,$84,$55,$04,$05,$84,$04,$84,$29,$a4	;	Tile 0a
		db	$00,$00,$00,$03,$01,$03,$3b,$84,$00,$00,$08,$03,$09,$03,$3a,$84,$00,$00,$10,$03,$11,$03,$3b,$a4,$00,$00,$18,$03,$19,$03,$3a,$a4	;	Tile 0b
		db	$76,$21,$74,$21,$73,$21,$72,$21,$7d,$21,$7c,$21,$7b,$21,$7a,$21,$3b,$84,$a4,$21,$a3,$21,$a2,$21,$3a,$84,$3b,$84,$3a,$84,$3b,$84	;	Tile 0c
		db	$72,$01,$73,$01,$74,$01,$76,$01,$7a,$01,$7b,$01,$7c,$01,$7d,$01,$a2,$01,$a3,$01,$a4,$01,$37,$84,$37,$84,$37,$a4,$3b,$a4,$3b,$84	;	Tile 0d
		db	$05,$03,$06,$03,$07,$03,$00,$00,$0d,$03,$0e,$03,$0f,$03,$00,$00,$15,$03,$16,$03,$17,$03,$00,$00,$1d,$03,$1e,$03,$1f,$03,$00,$00	;	Tile 0e
		db	$3b,$84,$37,$84,$21,$03,$22,$03,$3a,$a4,$28,$03,$29,$03,$2a,$03,$3b,$a4,$30,$03,$31,$03,$32,$03,$3a,$a4,$38,$02,$39,$02,$3a,$02	;	Tile 0f
		db	$23,$03,$24,$03,$37,$a4,$3b,$84,$2b,$03,$2c,$03,$3b,$84,$3a,$84,$33,$03,$34,$03,$ae,$01,$37,$a4,$3b,$02,$3c,$02,$37,$84,$af,$01	;	Tile 10
		db	$00,$00,$07,$23,$06,$23,$05,$23,$00,$00,$0f,$23,$0e,$23,$0d,$23,$00,$00,$17,$23,$16,$23,$15,$23,$00,$00,$1f,$23,$1e,$23,$1d,$23	;	Tile 11
		db	$45,$8a,$45,$8a,$45,$8a,$00,$00,$45,$8a,$45,$8a,$45,$8a,$00,$00,$a2,$ef,$a1,$ef,$a0,$ef,$00,$00,$aa,$ef,$a9,$ef,$a8,$ef,$00,$00	;	Tile 12
		db	$86,$01,$87,$01,$9e,$01,$9f,$01,$8e,$01,$8f,$01,$b0,$01,$3b,$84,$96,$01,$97,$01,$b8,$01,$3a,$a4,$37,$84,$3b,$84,$3a,$84,$39,$84	;	Tile 13
		db	$07,$a4,$06,$a4,$2c,$a4,$4d,$04,$37,$84,$3b,$84,$18,$84,$19,$84,$3a,$84,$3c,$81,$3d,$81,$13,$84,$29,$84,$04,$a4,$05,$a4,$4d,$04	;	Tile 14
		db	$3a,$84,$3b,$84,$37,$84,$aa,$01,$3b,$a4,$84,$01,$b1,$01,$b2,$01,$3a,$a4,$8c,$01,$b9,$01,$ba,$01,$39,$a4,$94,$01,$95,$01,$96,$01	;	Tile 15
		db	$ab,$01,$ac,$01,$82,$21,$81,$21,$b3,$01,$b4,$01,$b5,$01,$3b,$a4,$bb,$01,$bc,$01,$bd,$01,$37,$a4,$97,$01,$b8,$01,$37,$84,$3b,$a4	;	Tile 16
		db	$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$46,$8a,$47,$8a,$45,$8a,$45,$8a,$3b,$84,$3a,$84,$46,$8a,$47,$8a	;	Tile 17
		db	$46,$8a,$47,$8a,$45,$8a,$45,$8a,$3b,$84,$3a,$84,$46,$8a,$47,$8a,$3a,$84,$3b,$84,$39,$84,$38,$84,$37,$84,$3a,$84,$3b,$84,$39,$84	;	Tile 18
		db	$45,$8a,$45,$8a,$45,$8a,$61,$ea,$45,$8a,$45,$8a,$61,$ea,$3b,$84,$45,$8a,$61,$ea,$3c,$81,$3d,$81,$61,$ea,$39,$84,$38,$84,$3b,$84	;	Tile 19
		db	$37,$84,$3b,$84,$3a,$84,$39,$84,$3b,$84,$3a,$84,$39,$84,$3a,$84,$3a,$84,$3c,$81,$3d,$81,$3b,$84,$39,$84,$38,$84,$39,$84,$3a,$84	;	Tile 1a
		db	$39,$84,$38,$84,$39,$84,$3a,$84,$3a,$84,$39,$84,$3a,$84,$3b,$84,$3b,$84,$3c,$81,$3d,$81,$37,$84,$3c,$81,$3d,$81,$3d,$a1,$3c,$a1	;	Tile 1b
		db	$00,$a4,$11,$84,$09,$84,$01,$84,$1a,$94,$1e,$a4,$9e,$01,$9f,$01,$55,$04,$4d,$04,$31,$84,$37,$84,$4d,$04,$55,$04,$27,$94,$29,$a4	;	Tile 1c
		db	$39,$84,$38,$84,$39,$84,$3a,$84,$3a,$84,$39,$84,$3a,$84,$3b,$84,$13,$a4,$3c,$81,$3d,$81,$37,$84,$55,$04,$27,$94,$06,$94,$07,$94	;	Tile 1d
		db	$07,$a4,$06,$a4,$11,$a4,$00,$84,$37,$84,$3b,$84,$3a,$84,$08,$84,$3b,$84,$3a,$84,$10,$84,$02,$a4,$3a,$84,$39,$84,$18,$84,$19,$84	;	Tile 1e
		db	$0b,$84,$37,$84,$3b,$84,$3a,$84,$55,$04,$05,$84,$12,$a4,$1e,$a4,$5d,$04,$55,$04,$4d,$04,$45,$04,$07,$a4,$06,$a4,$09,$a4,$27,$a4	;	Tile 1f
		db	$4d,$04,$45,$04,$2c,$84,$01,$84,$55,$04,$4d,$04,$2c,$94,$29,$a4,$5d,$04,$00,$a4,$11,$84,$29,$b4,$19,$a4,$18,$a4,$3b,$84,$37,$84	;	Tile 20
		db	$01,$a4,$2c,$a4,$45,$04,$4d,$04,$29,$84,$2c,$b4,$4d,$04,$55,$04,$29,$94,$11,$a4,$00,$84,$5d,$04,$37,$84,$3b,$84,$18,$84,$19,$84	;	Tile 21
		db	$13,$94,$55,$04,$5d,$04,$55,$04,$13,$84,$4d,$04,$45,$04,$4d,$04,$13,$94,$35,$84,$36,$84,$55,$04,$3b,$84,$07,$a4,$24,$94,$19,$84	;	Tile 22
		db	$0b,$84,$38,$84,$39,$84,$3a,$84,$16,$84,$39,$84,$3a,$84,$38,$84,$22,$84,$3d,$a1,$3c,$a1,$37,$84,$4d,$04,$15,$a4,$2e,$84,$1e,$a4	;	Tile 23
		db	$15,$a4,$2e,$a4,$18,$b4,$37,$84,$55,$04,$5d,$04,$2f,$a4,$1e,$a4,$4d,$04,$55,$04,$4d,$04,$45,$04,$55,$04,$5d,$04,$55,$04,$4d,$04	;	Tile 24
		db	$0b,$84,$37,$84,$3b,$84,$3a,$84,$55,$04,$05,$84,$12,$a4,$1e,$a4,$5d,$04,$36,$a4,$35,$a4,$55,$04,$55,$04,$4d,$04,$45,$04,$4d,$04	;	Tile 25
		db	$37,$84,$3b,$84,$3a,$84,$0b,$a4,$1e,$84,$12,$84,$05,$a4,$55,$04,$45,$04,$4d,$04,$55,$04,$5d,$04,$27,$84,$09,$84,$06,$84,$07,$84	;	Tile 26
		db	$55,$04,$5d,$04,$27,$84,$01,$84,$2c,$84,$01,$84,$37,$84,$3b,$84,$2f,$a4,$32,$84,$3b,$84,$3a,$84,$4d,$04,$16,$94,$3a,$84,$39,$84	;	Tile 27
		db	$37,$84,$18,$94,$2e,$84,$15,$84,$1e,$84,$2f,$84,$5d,$24,$55,$04,$45,$04,$4d,$04,$55,$04,$4d,$04,$4d,$04,$55,$04,$4d,$04,$55,$04	;	Tile 28
		db	$5e,$8b,$5d,$8b,$5e,$8b,$5f,$8b,$5d,$8b,$5e,$8b,$5c,$8b,$5d,$8b,$11,$eb,$10,$eb,$5d,$8b,$5e,$8b,$5e,$8b,$5d,$8b,$5c,$8b,$5d,$8b	;	Tile 29
		db	$37,$84,$3b,$84,$03,$84,$05,$a4,$3b,$84,$3a,$84,$39,$84,$0c,$84,$3a,$84,$14,$84,$15,$84,$55,$04,$13,$84,$55,$04,$5d,$04,$5d,$04	;	Tile 2a
		db	$38,$84,$39,$84,$3a,$84,$3b,$84,$3a,$84,$39,$84,$3b,$84,$3e,$84,$39,$84,$3a,$84,$39,$84,$3a,$84,$38,$84,$39,$84,$3a,$84,$3b,$84	;	Tile 2b
		db	$3a,$84,$39,$84,$39,$84,$3a,$84,$3f,$84,$39,$84,$3a,$84,$39,$84,$39,$84,$38,$84,$39,$84,$3a,$84,$3a,$84,$39,$84,$38,$84,$39,$84	;	Tile 2c
		db	$5d,$04,$55,$04,$4d,$04,$45,$04,$55,$04,$4d,$24,$45,$04,$4d,$04,$5d,$04,$55,$04,$4d,$24,$45,$24,$4d,$04,$55,$24,$5d,$04,$55,$04	;	Tile 2d
		db	$38,$84,$39,$84,$3a,$84,$3b,$84,$39,$84,$38,$84,$39,$84,$3a,$84,$3a,$84,$39,$84,$3a,$84,$3b,$84,$3b,$84,$39,$84,$3e,$84,$3f,$84	;	Tile 2e
		db	$45,$04,$55,$04,$5d,$04,$55,$04,$4d,$04,$55,$04,$4d,$04,$5d,$04,$55,$04,$35,$84,$36,$84,$55,$04,$4d,$04,$45,$04,$4d,$04,$5d,$04	;	Tile 2f
		db	$3b,$84,$3a,$84,$39,$84,$3a,$84,$3a,$84,$3e,$84,$3f,$84,$39,$84,$39,$84,$38,$84,$39,$84,$3a,$84,$3a,$84,$39,$84,$3a,$84,$3b,$84	;	Tile 30
		db	$55,$04,$5d,$04,$05,$84,$10,$a4,$4d,$04,$55,$04,$00,$a4,$10,$b4,$55,$04,$00,$a4,$10,$b4,$37,$84,$05,$94,$10,$b4,$3a,$84,$3b,$84	;	Tile 31
		db	$c4,$aa,$c3,$aa,$c2,$aa,$00,$00,$cc,$aa,$cb,$aa,$ca,$aa,$00,$00,$d4,$af,$d3,$af,$d2,$af,$00,$00,$df,$2c,$de,$2c,$dd,$2c,$00,$00	;	Tile 32
		db	$38,$84,$39,$84,$3a,$84,$3b,$84,$3a,$84,$39,$84,$3b,$84,$3a,$84,$39,$84,$3a,$84,$39,$84,$3a,$84,$38,$84,$39,$84,$3a,$84,$3e,$84	;	Tile 33
		db	$3a,$84,$39,$84,$39,$84,$3a,$84,$39,$84,$39,$84,$3a,$84,$39,$84,$39,$84,$38,$84,$39,$84,$3a,$84,$3f,$84,$39,$84,$38,$84,$39,$84	;	Tile 34
		db	$39,$84,$3a,$84,$3b,$84,$37,$84,$38,$84,$39,$84,$3a,$84,$3b,$84,$39,$a4,$38,$a4,$39,$84,$3a,$84,$38,$84,$39,$84,$3a,$84,$3b,$84	;	Tile 35
		db	$00,$00,$c2,$8a,$c3,$8a,$c4,$8a,$00,$00,$ca,$8a,$cb,$8a,$cc,$8a,$00,$00,$d2,$8f,$d3,$8f,$d4,$8f,$00,$00,$dd,$0c,$de,$0c,$df,$0c	;	Tile 36
		db	$45,$8a,$45,$8a,$45,$8a,$61,$ea,$45,$8a,$45,$8a,$61,$ea,$3b,$84,$45,$8a,$61,$ea,$39,$84,$3a,$84,$61,$ea,$39,$84,$38,$84,$3b,$84	;	Tile 37
		db	$37,$84,$3a,$84,$39,$84,$60,$ea,$3b,$84,$39,$84,$60,$ea,$45,$8a,$3a,$84,$60,$ea,$45,$8a,$45,$8a,$60,$ea,$45,$8a,$45,$8a,$45,$8a	;	Tile 38
		db	$3b,$84,$8e,$ca,$8f,$ca,$8e,$ea,$8d,$ca,$8c,$ca,$8c,$ca,$8c,$ea,$95,$ca,$96,$ca,$97,$ca,$96,$ea,$9d,$ca,$9e,$ca,$9f,$ca,$9e,$ea	;	Tile 39
		db	$a3,$ca,$a4,$ca,$a5,$ca,$a4,$ea,$ab,$ca,$ac,$ca,$ad,$ca,$ac,$ea,$b3,$ca,$b4,$ca,$b5,$ca,$b4,$ea,$bb,$ca,$bc,$ca,$bd,$ca,$bc,$ea	;	Tile 3a
		db	$3b,$84,$3a,$84,$39,$84,$7c,$ca,$3a,$84,$39,$84,$38,$84,$7a,$ca,$3b,$84,$37,$84,$3b,$84,$7b,$ca,$37,$84,$3b,$84,$3a,$84,$39,$84	;	Tile 3b
		db	$00,$00,$d5,$0c,$d6,$0c,$c3,$0c,$00,$00,$c2,$0c,$c3,$0c,$5c,$8c,$00,$00,$5f,$8c,$5e,$8c,$5d,$8c,$00,$00,$5e,$8c,$5d,$8c,$5c,$8c	;	Tile 3c
		db	$3a,$84,$39,$84,$39,$84,$3a,$84,$3e,$84,$3f,$84,$3a,$84,$39,$84,$39,$84,$38,$84,$39,$84,$3a,$84,$3a,$84,$39,$84,$38,$84,$39,$84	;	Tile 3d
		db	$da,$8a,$db,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$da,$8a,$db,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a	;	Tile 3e
		db	$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$da,$8a,$db,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$da,$8a,$db,$8a	;	Tile 3f
		db	$00,$00,$ca,$0c,$cb,$0c,$cc,$0c,$00,$00,$d2,$0c,$d3,$0c,$d4,$0c,$00,$00,$da,$0c,$db,$0c,$dc,$0c,$00,$00,$cd,$0c,$ce,$0c,$cf,$0c	;	Tile 40
		db	$40,$86,$41,$86,$42,$86,$43,$86,$41,$86,$42,$86,$42,$86,$44,$86,$41,$86,$43,$86,$43,$86,$44,$86,$41,$86,$42,$86,$44,$86,$43,$86	;	Tile 41
		db	$44,$86,$42,$86,$41,$86,$40,$86,$43,$86,$42,$86,$42,$86,$41,$86,$42,$86,$44,$86,$42,$86,$42,$86,$44,$86,$41,$86,$42,$86,$41,$86	;	Tile 42
		db	$42,$86,$49,$86,$4a,$86,$4b,$86,$50,$86,$51,$86,$52,$86,$53,$86,$58,$86,$59,$86,$5a,$86,$5b,$86,$43,$86,$44,$86,$43,$86,$42,$86	;	Tile 43
		db	$44,$86,$43,$86,$42,$86,$44,$86,$4c,$86,$4d,$86,$4e,$86,$42,$86,$54,$86,$55,$86,$56,$86,$41,$86,$41,$86,$42,$86,$43,$86,$43,$86	;	Tile 44
		db	$84,$cf,$85,$cf,$86,$cf,$87,$cf,$85,$cf,$86,$cf,$85,$cf,$87,$cf,$86,$cf,$85,$cf,$84,$cf,$85,$cf,$87,$cf,$86,$cf,$85,$cf,$84,$cf	;	Tile 45
		db	$46,$8a,$47,$8a,$45,$8a,$45,$8a,$3b,$84,$3a,$84,$4f,$8a,$45,$8a,$3a,$84,$78,$8a,$45,$8a,$45,$8a,$78,$8a,$45,$8a,$45,$8a,$45,$8a	;	Tile 46
		db	$45,$8a,$45,$8a,$45,$8a,$63,$8a,$45,$8a,$45,$8a,$63,$8a,$3b,$84,$45,$8a,$57,$8a,$39,$84,$3a,$84,$45,$8a,$45,$8a,$79,$8a,$7a,$8a	;	Tile 47
		db	$79,$8a,$7a,$8a,$3b,$84,$3a,$84,$45,$8a,$45,$8a,$79,$8a,$7a,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a,$45,$8a	;	Tile 48
		db	$3b,$84,$3a,$84,$39,$84,$3a,$84,$3a,$84,$39,$84,$38,$84,$3b,$84,$79,$8a,$7a,$8a,$39,$84,$3a,$84,$45,$8a,$45,$8a,$79,$8a,$7a,$8a	;	Tile 49
		db	$37,$84,$82,$88,$81,$88,$80,$88,$3b,$84,$83,$88,$84,$88,$84,$88,$3a,$84,$3b,$a4,$85,$88,$86,$88,$39,$84,$3a,$a4,$39,$a4,$3a,$84	;	Tile 4a
		db	$8c,$88,$3a,$84,$37,$84,$3b,$84,$84,$88,$8b,$88,$8a,$88,$37,$84,$87,$88,$88,$88,$89,$88,$3b,$84,$39,$84,$38,$84,$39,$a4,$3a,$84	;	Tile 4b
		db	$3a,$84,$39,$84,$3a,$84,$3b,$84,$39,$84,$3a,$84,$3b,$84,$3a,$84,$3b,$84,$37,$84,$c4,$0d,$c5,$0d,$3a,$84,$39,$84,$3a,$84,$3b,$84	;	Tile 4c
		db	$92,$80,$93,$80,$94,$80,$95,$80,$9a,$80,$a0,$80,$99,$88,$a8,$88,$98,$88,$99,$88,$98,$88,$b0,$88,$99,$88,$98,$88,$99,$88,$b8,$88	;	Tile 4d
		db	$98,$88,$99,$88,$98,$88,$b8,$88,$99,$88,$98,$88,$99,$88,$96,$88,$9b,$80,$9c,$80,$9d,$80,$9e,$80,$5c,$8b,$5d,$8b,$5e,$8b,$5f,$8b	;	Tile 4e
		db	$a1,$89,$a2,$89,$a3,$89,$a4,$89,$a9,$89,$aa,$89,$ab,$89,$ac,$89,$b1,$89,$b2,$89,$b3,$89,$b4,$89,$b9,$89,$aa,$89,$bb,$89,$bc,$89	;	Tile 4f
		db	$b9,$89,$ba,$89,$a7,$89,$c0,$89,$97,$89,$ae,$89,$af,$89,$c8,$89,$97,$89,$b6,$89,$b7,$89,$d0,$89,$9f,$80,$be,$89,$bf,$89,$d8,$89	;	Tile 50
		db	$a5,$89,$a1,$a9,$95,$a0,$93,$a0,$ad,$89,$a9,$a9,$a8,$a8,$7c,$a0,$b5,$89,$b1,$a9,$b0,$a8,$99,$88,$bd,$89,$b9,$a9,$b8,$a8,$98,$88	;	Tile 51
		db	$c1,$89,$b9,$a9,$b8,$a8,$99,$88,$c9,$89,$97,$a9,$96,$a8,$98,$88,$d1,$89,$97,$a9,$9b,$80,$9c,$80,$d9,$89,$5e,$8b,$5e,$8b,$5d,$8b	;	Tile 52
		db	$93,$a0,$93,$80,$93,$a0,$92,$a0,$7c,$a0,$7c,$80,$7c,$a0,$9a,$a0,$99,$88,$98,$88,$99,$88,$98,$88,$98,$88,$99,$88,$98,$88,$99,$88	;	Tile 53
		db	$99,$88,$98,$88,$99,$88,$98,$88,$98,$88,$99,$88,$98,$88,$99,$88,$9d,$80,$9d,$a0,$9c,$a0,$9b,$a0,$5e,$8b,$5d,$8b,$5c,$8b,$5d,$8b	;	Tile 54
		db	$00,$00,$c2,$8a,$c3,$8a,$c4,$8a,$00,$00,$ca,$8a,$cb,$8a,$cc,$8a,$00,$00,$d2,$8a,$d3,$8a,$d4,$8a,$00,$00,$37,$84,$3b,$84,$3a,$84	;	Tile 55
		db	$c5,$8a,$c6,$8a,$37,$84,$3b,$84,$cd,$8a,$ce,$8a,$3b,$84,$3a,$84,$d5,$8a,$d6,$8a,$3a,$84,$39,$84,$3a,$84,$3b,$84,$37,$84,$3b,$84	;	Tile 56
		db	$37,$84,$3b,$84,$c6,$aa,$c5,$aa,$3b,$84,$3a,$84,$ce,$aa,$cd,$aa,$3a,$84,$39,$84,$d6,$aa,$d5,$aa,$39,$84,$38,$84,$39,$84,$3a,$84	;	Tile 57
		db	$c4,$aa,$c3,$aa,$c2,$aa,$00,$00,$cc,$aa,$cb,$aa,$ca,$aa,$00,$00,$d4,$aa,$d3,$aa,$d2,$aa,$00,$00,$37,$84,$3b,$84,$3a,$84,$00,$00	;	Tile 58
		db	$78,$01,$79,$21,$78,$21,$78,$21,$78,$01,$62,$01,$62,$01,$a6,$01,$78,$01,$62,$01,$62,$01,$62,$01,$78,$01,$62,$01,$62,$01,$7f,$01	;	Tile 59
		db	$00,$00,$60,$01,$61,$01,$6c,$01,$00,$00,$68,$01,$69,$01,$74,$01,$00,$00,$70,$01,$71,$01,$7c,$01,$00,$00,$a2,$01,$a3,$01,$a7,$01	;	Tile 5a
		db	$3b,$84,$3a,$84,$83,$21,$00,$00,$78,$01,$78,$21,$62,$01,$9c,$01,$62,$01,$a6,$01,$62,$01,$66,$01,$62,$01,$62,$01,$62,$01,$6e,$01	;	Tile 5b
		db	$6c,$21,$61,$21,$60,$21,$00,$00,$74,$21,$69,$21,$68,$21,$00,$00,$7c,$21,$71,$21,$70,$21,$00,$00,$a7,$21,$a3,$21,$a2,$21,$00,$00	;	Tile 5c
		db	$37,$84,$3b,$84,$3a,$84,$03,$48,$3b,$84,$01,$48,$02,$48,$0b,$48,$00,$48,$09,$48,$98,$88,$99,$88,$08,$48,$98,$88,$99,$88,$98,$88	;	Tile 5d
		db	$04,$48,$05,$48,$06,$48,$42,$4b,$0c,$48,$98,$88,$99,$88,$4a,$4b,$98,$88,$99,$88,$98,$88,$99,$88,$99,$88,$98,$88,$99,$88,$98,$88	;	Tile 5e
		db	$10,$48,$99,$88,$98,$88,$99,$88,$18,$48,$19,$48,$99,$88,$98,$88,$3a,$84,$39,$84,$1a,$48,$99,$88,$39,$84,$38,$84,$1b,$48,$1c,$48	;	Tile 5f
		db	$98,$88,$99,$88,$98,$88,$99,$88,$99,$88,$98,$88,$99,$88,$99,$88,$98,$88,$99,$88,$98,$88,$99,$88,$1d,$48,$1e,$48,$1f,$48,$99,$88	;	Tile 60
		db	$76,$c6,$75,$c6,$4f,$c6,$4d,$c6,$7e,$ca,$7d,$ea,$57,$c6,$55,$c6,$7f,$ce,$77,$ee,$5f,$c6,$5d,$c6,$6f,$ce,$67,$ee,$68,$c6,$58,$c6	;	Tile 61
		db	$4d,$c6,$4e,$c6,$4f,$c6,$75,$c6,$55,$c6,$56,$c6,$57,$c6,$7d,$ca,$5d,$c6,$5e,$c6,$5f,$c6,$77,$ce,$58,$c6,$59,$c6,$5a,$c6,$67,$ce	;	Tile 62
		db	$4f,$c6,$75,$c6,$76,$c6,$75,$c6,$57,$c6,$7d,$ca,$7e,$ca,$7d,$ea,$5f,$c6,$77,$ce,$7f,$ce,$77,$ee,$5a,$c6,$67,$ce,$6f,$ce,$67,$ee	;	Tile 63
		db	$4d,$c6,$4e,$c6,$4f,$c6,$4d,$c6,$55,$c6,$56,$c6,$57,$c6,$55,$c6,$5d,$c6,$5e,$c6,$5f,$c6,$5d,$c6,$58,$c6,$59,$c6,$5a,$c6,$58,$c6	;	Tile 64
		db	$5c,$8b,$5e,$8b,$5d,$8b,$5f,$8b,$5e,$8b,$5d,$8b,$5e,$8b,$5d,$8b,$5d,$8b,$5c,$8b,$5d,$8b,$5e,$8b,$5c,$8b,$dd,$0c,$de,$0c,$df,$0c	;	Tile 65
		db	$5e,$8b,$5d,$8b,$5d,$8b,$5d,$8b,$5e,$8b,$5d,$8b,$5c,$8b,$5d,$8b,$5f,$8b,$5e,$8b,$5d,$8b,$5e,$8b,$df,$2c,$de,$2c,$dd,$2c,$df,$0c	;	Tile 66
		db	$00,$00,$42,$86,$41,$86,$42,$86,$00,$00,$38,$4e,$39,$4e,$23,$4e,$00,$00,$3a,$4e,$3b,$4e,$2b,$4e,$00,$00,$3c,$4e,$3d,$4e,$33,$4e	;	Tile 67
		db	$42,$86,$43,$86,$41,$86,$42,$86,$24,$4e,$11,$4e,$12,$4e,$25,$4e,$2c,$4e,$15,$4e,$16,$4e,$2d,$4e,$34,$4e,$0d,$4e,$0e,$4e,$35,$4e	;	Tile 68
		db	$40,$86,$41,$86,$42,$86,$00,$00,$20,$4e,$21,$4e,$22,$4e,$00,$00,$28,$4e,$29,$4e,$2a,$4e,$00,$00,$30,$4e,$31,$4e,$32,$4e,$00,$00	;	Tile 69
		db	$40,$86,$41,$86,$42,$86,$43,$86,$0a,$4e,$11,$4e,$12,$4e,$26,$4e,$14,$4e,$15,$4e,$16,$4e,$2e,$4e,$07,$4e,$0d,$4e,$0e,$4e,$36,$4e	;	Tile 6a
		db	$42,$86,$42,$86,$41,$86,$40,$86,$27,$4e,$11,$4e,$12,$4e,$13,$4e,$2f,$4e,$15,$4e,$16,$4e,$17,$4e,$37,$4e,$0d,$4e,$0e,$4e,$0f,$4e	;	Tile 6b
		db	$3b,$84,$3a,$84,$39,$84,$3a,$84,$8d,$ea,$39,$84,$38,$84,$39,$84,$95,$ea,$37,$84,$3b,$84,$3a,$84,$9d,$ea,$3b,$84,$3a,$84,$39,$84	;	Tile 6c
		db	$a3,$ea,$7c,$ea,$3b,$84,$3a,$84,$ab,$ea,$7a,$ea,$3a,$84,$39,$84,$b3,$ea,$7b,$ea,$39,$84,$3a,$84,$bb,$ea,$39,$84,$38,$84,$39,$84	;	Tile 6d
		db	$37,$84,$3b,$84,$3a,$84,$3b,$84,$78,$01,$79,$01,$83,$01,$3a,$84,$62,$01,$63,$01,$64,$01,$65,$01,$6a,$01,$6b,$01,$6c,$01,$6d,$01	;	Tile 6e
		db	$41,$86,$40,$86,$41,$86,$42,$86,$40,$86,$41,$86,$40,$86,$41,$86,$42,$86,$42,$86,$41,$86,$42,$86,$25,$6e,$12,$6e,$11,$6e,$24,$6e	;	Tile 6f
		db	$41,$86,$42,$86,$42,$86,$43,$86,$41,$86,$42,$86,$43,$86,$44,$86,$42,$86,$43,$86,$44,$86,$44,$86,$23,$6e,$39,$6e,$38,$6e,$00,$00	;	Tile 70
		db	$00,$00,$43,$86,$42,$86,$40,$86,$00,$00,$42,$86,$42,$86,$41,$86,$00,$00,$41,$86,$41,$86,$42,$86,$00,$00,$22,$6e,$21,$6e,$20,$6e	;	Tile 71
		db	$43,$86,$42,$86,$41,$86,$00,$00,$42,$86,$42,$86,$41,$86,$00,$00,$40,$86,$41,$86,$42,$86,$00,$00,$20,$4e,$21,$4e,$22,$4e,$00,$00	;	Tile 72
		db	$40,$86,$41,$86,$42,$86,$41,$86,$41,$86,$42,$86,$20,$4e,$21,$4e,$42,$86,$43,$86,$28,$4e,$29,$4e,$41,$86,$42,$86,$30,$4e,$31,$4e	;	Tile 73
		db	$7f,$8a,$47,$8a,$45,$8a,$00,$00,$3b,$84,$3a,$84,$46,$8a,$00,$00,$3a,$84,$39,$84,$3b,$84,$00,$00,$39,$8a,$a6,$ea,$94,$ea,$00,$00	;	Tile 74
		db	$3a,$84,$39,$84,$38,$84,$b6,$ea,$3b,$84,$3a,$84,$39,$84,$be,$ea,$3a,$84,$39,$84,$38,$84,$a7,$ea,$3b,$84,$3a,$84,$39,$84,$38,$84	;	Tile 75
		db	$ae,$ea,$81,$ea,$80,$ea,$00,$00,$8a,$ea,$89,$ea,$88,$ea,$00,$00,$92,$ea,$91,$ea,$90,$ea,$00,$00,$af,$ea,$b7,$ea,$bf,$ea,$00,$00	;	Tile 76
		db	$75,$c6,$76,$c6,$75,$c6,$4f,$c6,$7d,$ca,$7e,$ca,$7d,$ea,$57,$c6,$77,$ce,$7f,$ce,$77,$ee,$5f,$c6,$67,$ce,$6f,$ce,$67,$ee,$68,$c6	;	Tile 77
		db	$72,$01,$73,$01,$74,$01,$75,$01,$7a,$01,$7b,$01,$7c,$01,$7d,$01,$a2,$01,$a3,$01,$a4,$01,$a5,$01,$3a,$84,$39,$84,$3a,$84,$3b,$84	;	Tile 78
		db	$2d,$6e,$16,$6e,$15,$6e,$2c,$6e,$35,$6e,$0e,$6e,$0d,$6e,$34,$6e,$40,$86,$41,$86,$42,$86,$43,$86,$41,$86,$42,$86,$43,$86,$42,$86	;	Tile 79
		db	$2b,$6e,$3b,$6e,$3a,$6e,$00,$00,$33,$6e,$3d,$6e,$3c,$6e,$00,$00,$42,$86,$44,$86,$42,$86,$00,$00,$41,$86,$42,$86,$41,$86,$00,$00	;	Tile 7a
		db	$00,$00,$2a,$6e,$29,$6e,$28,$6e,$00,$00,$32,$6e,$31,$6e,$30,$6e,$00,$00,$44,$86,$43,$86,$42,$86,$00,$00,$42,$86,$40,$86,$41,$86	;	Tile 7b
		db	$28,$4e,$29,$4e,$2a,$4e,$00,$00,$30,$4e,$31,$4e,$32,$4e,$00,$00,$41,$86,$42,$86,$43,$86,$44,$86,$41,$86,$42,$86,$41,$86,$43,$86	;	Tile 7c
		db	$42,$86,$42,$86,$43,$86,$41,$86,$22,$4e,$13,$4e,$42,$86,$40,$86,$2a,$4e,$17,$4e,$42,$86,$41,$86,$32,$4e,$0f,$4e,$41,$86,$42,$86	;	Tile 7d
		db	$00,$00,$40,$86,$41,$86,$42,$86,$00,$00,$38,$4e,$39,$4e,$23,$4e,$00,$00,$3a,$4e,$3b,$4e,$2b,$4e,$00,$00,$3c,$4e,$3d,$4e,$33,$4e	;	Tile 7e
		db	$41,$86,$40,$86,$41,$86,$42,$86,$24,$4e,$11,$4e,$12,$4e,$26,$4e,$2c,$4e,$15,$4e,$16,$4e,$2e,$4e,$34,$4e,$0d,$4e,$0e,$4e,$36,$4e	;	Tile 7f
		db	$41,$86,$40,$86,$41,$86,$42,$86,$27,$4e,$11,$4e,$12,$4e,$13,$4e,$2f,$4e,$15,$4e,$16,$4e,$17,$4e,$37,$4e,$0d,$4e,$0e,$4e,$0f,$4e	;	Tile 80
		db	$40,$86,$41,$86,$42,$86,$42,$86,$43,$86,$42,$86,$0a,$4e,$11,$4e,$44,$86,$43,$86,$14,$4e,$15,$4e,$42,$86,$41,$86,$07,$4e,$0d,$4e	;	Tile 81
		db	$43,$86,$42,$86,$42,$86,$41,$86,$12,$4e,$13,$4e,$41,$86,$40,$86,$16,$4e,$17,$4e,$42,$86,$41,$86,$0e,$4e,$0f,$4e,$40,$86,$40,$86	;	Tile 82
		db	$5d,$8b,$5e,$8b,$5f,$8b,$5e,$8b,$5c,$8b,$5d,$8b,$5e,$8b,$5f,$8b,$5f,$8b,$5e,$8b,$5f,$8b,$5e,$8b,$21,$eb,$29,$eb,$29,$eb,$29,$eb	;	Tile 83
		db	$5f,$8b,$5e,$8b,$5d,$8b,$5c,$8b,$5e,$8b,$5f,$8b,$5e,$8b,$5d,$8b,$5d,$8b,$5c,$8b,$5d,$8b,$5e,$8b,$5c,$8b,$5e,$8b,$21,$eb,$21,$eb	;	Tile 84
		db	$5d,$8b,$5e,$8b,$5f,$8b,$5e,$8b,$5c,$8b,$5d,$8b,$5e,$8b,$5f,$8b,$5d,$8b,$5e,$8b,$5f,$8b,$5e,$8b,$21,$cb,$21,$cb,$5e,$8b,$5f,$8b	;	Tile 85
		db	$5f,$8b,$5e,$8b,$5d,$8b,$5c,$8b,$5e,$8b,$5f,$8b,$5e,$8b,$5d,$8b,$5d,$8b,$5c,$8b,$5d,$8b,$5c,$8b,$29,$cb,$29,$cb,$29,$cb,$21,$cb	;	Tile 86
		db	$38,$84,$3b,$84,$3a,$84,$39,$84,$39,$84,$3b,$84,$3a,$84,$39,$84,$38,$84,$3b,$84,$3a,$84,$39,$84,$01,$e6,$09,$e6,$09,$e6,$09,$e6	;	Tile 87
		db	$37,$84,$3b,$84,$3a,$84,$39,$84,$3b,$84,$3a,$84,$39,$84,$38,$84,$37,$84,$3b,$84,$3a,$84,$39,$84,$0a,$c6,$02,$e6,$01,$e6,$01,$e6	;	Tile 88
		db	$3a,$84,$3b,$84,$37,$84,$3b,$84,$39,$84,$3a,$84,$3b,$84,$37,$84,$3a,$84,$3b,$84,$37,$84,$3b,$84,$01,$c6,$01,$c6,$02,$c6,$0a,$c6	;	Tile 89
		db	$37,$84,$3b,$84,$3a,$84,$39,$84,$3b,$84,$3a,$84,$39,$84,$38,$84,$3a,$84,$39,$84,$38,$84,$39,$84,$09,$c6,$09,$c6,$09,$c6,$01,$c6	;	Tile 8a
		db	$40,$86,$41,$86,$42,$86,$43,$86,$41,$86,$42,$86,$43,$86,$44,$86,$42,$86,$43,$86,$43,$86,$43,$86,$17,$e6,$16,$e6,$01,$e6,$01,$e6	;	Tile 8b
		db	$00,$00,$3a,$84,$39,$84,$38,$84,$00,$00,$39,$84,$3a,$84,$39,$84,$00,$00,$37,$84,$3b,$84,$3a,$84,$00,$00,$94,$ca,$a6,$ca,$3b,$84	;	Tile 8c
		db	$00,$00,$80,$ca,$81,$ca,$ae,$ca,$00,$00,$88,$ca,$89,$ca,$8a,$ca,$00,$00,$90,$ca,$91,$ca,$92,$ca,$00,$00,$bf,$ca,$b7,$ca,$af,$ca	;	Tile 8d
		db	$b6,$ca,$38,$84,$39,$84,$3a,$84,$be,$ca,$39,$84,$3a,$84,$3b,$84,$a7,$ca,$3a,$84,$3b,$84,$37,$84,$3a,$84,$3b,$84,$3a,$84,$3b,$84	;	Tile 8e
		db	$44,$86,$43,$86,$42,$86,$41,$86,$43,$86,$42,$86,$41,$86,$40,$86,$44,$86,$43,$86,$42,$86,$41,$86,$01,$c6,$01,$c6,$16,$c6,$17,$c6	;	Tile 8f
		db	$00,$00,$3b,$84,$3a,$84,$39,$84,$00,$00,$a6,$4a,$a7,$4a,$bd,$4a,$00,$00,$ae,$4a,$af,$4a,$b0,$4a,$00,$00,$b6,$4a,$b7,$4a,$b8,$4a	;	Tile 90
		db	$38,$84,$39,$84,$3a,$84,$3b,$84,$be,$4a,$bf,$4a,$a4,$4a,$a5,$4a,$8f,$4a,$8f,$4a,$8f,$4a,$8f,$4a,$b9,$4a,$ba,$4a,$bb,$4a,$bc,$4a	;	Tile 91
		db	$3b,$a4,$3a,$a4,$39,$a4,$38,$a4,$a5,$6a,$a4,$6a,$bf,$6a,$be,$6a,$8f,$6a,$8f,$6a,$8f,$6a,$8f,$6a,$bc,$6a,$bb,$6a,$ba,$6a,$b9,$6a	;	Tile 92
		db	$39,$a4,$3a,$a4,$3b,$a4,$00,$00,$bd,$6a,$a7,$6a,$a6,$6a,$00,$00,$b0,$6a,$af,$6a,$ae,$6a,$00,$00,$b8,$6a,$b7,$6a,$b6,$6a,$00,$00	;	Tile 93
		db	$40,$86,$41,$86,$42,$86,$43,$86,$41,$86,$42,$86,$43,$86,$44,$86,$42,$86,$43,$86,$43,$86,$43,$86,$09,$c6,$09,$c6,$09,$c6,$01,$c6	;	Tile 94
		db	$45,$87,$45,$87,$37,$84,$3b,$84,$45,$87,$45,$87,$3b,$84,$3a,$84,$45,$87,$45,$87,$3a,$84,$37,$84,$45,$87,$45,$87,$39,$84,$3a,$84	;	Tile 95
		db	$5c,$8b,$5d,$8b,$5e,$8b,$5f,$8b,$5e,$8b,$5d,$8b,$5f,$8b,$5f,$8b,$5d,$8b,$5e,$8b,$5d,$8b,$5e,$8b,$5c,$8b,$5d,$8b,$5e,$8b,$5f,$8b	;	Tile 96
		db	$37,$84,$3b,$84,$3a,$84,$39,$84,$3b,$84,$3a,$84,$39,$84,$38,$84,$c4,$0d,$c5,$0d,$c6,$0d,$c7,$0d,$3a,$84,$39,$84,$3b,$84,$37,$84	;	Tile 97
		db	$37,$84,$3b,$84,$3a,$84,$39,$84,$3b,$84,$3a,$84,$39,$84,$39,$84,$c4,$0d,$c5,$0d,$c5,$0d,$c6,$0d,$3b,$84,$3a,$84,$39,$84,$3a,$84	;	Tile 98
		db	$3b,$84,$3a,$84,$39,$84,$39,$84,$3a,$84,$39,$84,$38,$84,$39,$84,$c6,$0d,$c7,$0d,$3a,$84,$39,$84,$39,$84,$38,$84,$39,$84,$3a,$84	;	Tile 99
		db	$5c,$8b,$5d,$8b,$5e,$8b,$5f,$8b,$5e,$8b,$5d,$8b,$c8,$0f,$5e,$8b,$5d,$8b,$d0,$0f,$d1,$0f,$c9,$0f,$5e,$8b,$d8,$0f,$d9,$0f,$5d,$8b	;	Tile 9a
		db	$5f,$8b,$5e,$8b,$5d,$8b,$3c,$8b,$5d,$8b,$c8,$2f,$5c,$8b,$5d,$8b,$c9,$2f,$d1,$2f,$d0,$2f,$5e,$8b,$5f,$8b,$d9,$2f,$d8,$2f,$5d,$8b	;	Tile 9b
		db	$00,$00,$80,$cf,$81,$cf,$82,$cf,$00,$00,$88,$cf,$89,$cf,$8a,$cf,$00,$00,$90,$cf,$91,$cf,$92,$cf,$00,$00,$98,$cf,$99,$cf,$9a,$cf	;	Tile 9c
		db	$83,$cf,$5e,$8b,$5d,$8b,$5c,$8b,$8b,$cf,$5f,$8b,$5e,$8b,$5d,$8b,$93,$cf,$5e,$8b,$5d,$8b,$5e,$8b,$5c,$8b,$5d,$8b,$5e,$8b,$5f,$8b	;	Tile 9d
		db	$00,$00,$5e,$8b,$5d,$8b,$5c,$8b,$00,$00,$5f,$8b,$5e,$8b,$5d,$8b,$00,$00,$5e,$8b,$5d,$8b,$5e,$8b,$00,$00,$9b,$cf,$9c,$cf,$5f,$8b	;	Tile 9e
		db	$00,$e6,$08,$e6,$08,$e6,$08,$e6,$07,$e6,$06,$e6,$06,$e6,$06,$e6,$04,$e6,$03,$e6,$03,$e6,$03,$e6,$0c,$e6,$0b,$e6,$0b,$e6,$0b,$e6	;	Tile 9f
		db	$5e,$8b,$5d,$8b,$5d,$8b,$5e,$8b,$5d,$8b,$5d,$8b,$5e,$8b,$5d,$8b,$5d,$8b,$5c,$8b,$5d,$8b,$5e,$8b,$5e,$8b,$5d,$8b,$5c,$8b,$5d,$8b	;	Tile a0
		db	$97,$4a,$80,$4a,$81,$4a,$82,$4a,$97,$4a,$88,$4a,$89,$4a,$8a,$4a,$97,$4a,$90,$4a,$91,$4a,$92,$4a,$9f,$4a,$98,$4a,$99,$4a,$9a,$4a	;	Tile a1
		db	$83,$4a,$84,$4a,$85,$4a,$86,$4a,$8b,$4a,$8c,$4a,$8d,$4a,$8e,$4a,$93,$4a,$94,$4a,$95,$4a,$96,$4a,$9b,$4a,$9c,$4a,$9d,$4a,$9e,$4a	;	Tile a2
		db	$3b,$84,$a0,$4a,$a1,$4a,$a2,$4a,$3a,$84,$a8,$4a,$a9,$4a,$aa,$4a,$39,$84,$38,$84,$b1,$4a,$b2,$4a,$3a,$84,$39,$84,$3a,$84,$3b,$94	;	Tile a3
		db	$a1,$4a,$a2,$4a,$a1,$4a,$a3,$4a,$ab,$4a,$a9,$4a,$ac,$4a,$ad,$4a,$b3,$4a,$b2,$4a,$b4,$4a,$b5,$4a,$37,$84,$3b,$84,$3a,$84,$39,$94	;	Tile a4
		db	$86,$6a,$85,$6a,$84,$6a,$83,$6a,$8e,$6a,$8d,$6a,$8c,$6a,$8b,$6a,$96,$6a,$95,$6a,$94,$6a,$93,$6a,$9e,$6a,$9d,$6a,$9c,$6a,$9b,$6a	;	Tile a5
		db	$82,$6a,$81,$6a,$80,$6a,$97,$6a,$8a,$6a,$89,$6a,$88,$6a,$97,$6a,$92,$6a,$91,$6a,$90,$6a,$97,$6a,$9a,$6a,$99,$6a,$98,$6a,$9f,$6a	;	Tile a6
		db	$a3,$6a,$a1,$6a,$a2,$6a,$a1,$6a,$ad,$6a,$ac,$6a,$a9,$6a,$ab,$6a,$b5,$6a,$b4,$6a,$b2,$6a,$b3,$6a,$3a,$84,$3b,$84,$3a,$84,$39,$84	;	Tile a7
		db	$a2,$6a,$a1,$6a,$a0,$6a,$37,$84,$aa,$6a,$a9,$6a,$a8,$6a,$3b,$84,$b2,$6a,$b1,$6a,$3b,$84,$3a,$84,$38,$84,$39,$84,$3a,$84,$3b,$84	;	Tile a8
		db	$17,$e6,$16,$e6,$00,$e6,$00,$e6,$17,$e6,$16,$e6,$07,$e6,$07,$e6,$17,$e6,$16,$e6,$05,$e6,$04,$e6,$1f,$e6,$1e,$e6,$0d,$e6,$0c,$e6	;	Tile a9
		db	$00,$c6,$00,$c6,$16,$c6,$17,$c6,$07,$c6,$07,$c6,$16,$c6,$17,$c6,$04,$c6,$05,$c6,$16,$c6,$17,$c6,$0c,$c6,$0d,$c6,$1e,$c6,$1f,$c6	;	Tile aa
		db	$08,$c6,$08,$c6,$08,$c6,$00,$c6,$06,$c6,$06,$c6,$06,$c6,$07,$c6,$03,$c6,$03,$c6,$03,$c6,$04,$c6,$0b,$c6,$0b,$c6,$0b,$c6,$0c,$c6	;	Tile ab
		db	$40,$86,$42,$86,$43,$86,$42,$86,$43,$86,$41,$86,$40,$86,$41,$86,$42,$86,$40,$86,$40,$c6,$41,$c6,$43,$86,$41,$86,$42,$86,$43,$86	;	Tile ac
		db	$44,$86,$43,$86,$42,$86,$41,$86,$43,$86,$42,$86,$41,$86,$40,$86,$41,$e6,$40,$e6,$43,$86,$42,$86,$42,$86,$41,$86,$40,$86,$41,$86	;	Tile ad
		db	$40,$86,$41,$86,$42,$86,$43,$86,$41,$86,$42,$86,$43,$86,$44,$86,$40,$c6,$41,$c6,$42,$c6,$42,$e6,$42,$86,$43,$86,$44,$86,$43,$86	;	Tile ae
		db	$44,$86,$43,$86,$42,$86,$41,$86,$3d,$ee,$3c,$ee,$41,$86,$40,$86,$19,$ee,$18,$ee,$44,$86,$42,$86,$1d,$ee,$1c,$ee,$44,$86,$43,$86	;	Tile af
		db	$40,$86,$41,$86,$42,$86,$43,$86,$41,$86,$42,$86,$3f,$ee,$3e,$ee,$42,$86,$43,$86,$1b,$ee,$1a,$ee,$41,$86,$42,$86,$3b,$ee,$3a,$ee	;	Tile b0
		db	$44,$86,$44,$86,$43,$86,$42,$86,$3c,$ce,$3d,$ce,$3e,$ce,$3f,$ce,$18,$ce,$19,$ce,$1a,$ce,$1b,$ce,$1c,$ce,$1d,$ce,$3a,$ce,$3b,$ce	;	Tile b1
		db	$44,$86,$43,$86,$42,$86,$41,$86,$36,$ce,$37,$ce,$41,$86,$40,$86,$32,$ce,$33,$ce,$42,$86,$42,$86,$3a,$ce,$3b,$ce,$43,$86,$44,$86	;	Tile b2
		db	$40,$86,$41,$86,$42,$86,$43,$86,$41,$86,$42,$86,$34,$ce,$35,$ce,$42,$86,$43,$86,$30,$ce,$31,$ce,$43,$86,$44,$86,$38,$ce,$39,$ce	;	Tile b3
		db	$40,$86,$41,$86,$42,$86,$43,$86,$37,$ee,$36,$ee,$35,$ee,$34,$ee,$33,$ee,$32,$ee,$31,$ee,$30,$ee,$3b,$ee,$3a,$ee,$39,$ee,$38,$ee	;	Tile b4
		db	$5e,$8b,$5d,$8b,$5c,$8b,$5d,$8b,$11,$eb,$10,$eb,$5d,$8b,$5e,$8b,$5e,$8b,$5d,$8b,$5c,$8b,$5e,$8b,$5d,$8b,$5e,$8b,$5f,$8b,$5e,$8b	;	Tile b5
		db	$00,$00,$c2,$8a,$c3,$8a,$c4,$8a,$00,$00,$ca,$8a,$cb,$8a,$cc,$8a,$00,$00,$d2,$8f,$d3,$8f,$d4,$8f,$00,$00,$5c,$8b,$5d,$8b,$5e,$8b	;	Tile b6
		db	$c5,$8a,$c6,$8f,$5d,$8b,$5e,$8b,$cd,$8a,$ce,$8f,$5e,$8b,$5f,$8b,$d5,$8f,$d6,$8f,$5f,$8b,$5e,$8b,$5c,$8b,$5d,$8b,$5e,$8b,$5f,$8b	;	Tile b7
		db	$5d,$8b,$5c,$8b,$c6,$af,$c5,$aa,$5c,$8b,$5d,$8b,$ce,$af,$cd,$aa,$5d,$8b,$5e,$8b,$d6,$af,$d5,$af,$5e,$8b,$5f,$8b,$5e,$8b,$5d,$8b	;	Tile b8
		db	$c4,$aa,$c3,$aa,$c2,$aa,$00,$00,$cc,$aa,$cb,$aa,$ca,$aa,$00,$00,$d4,$af,$d3,$af,$d2,$af,$00,$00,$5c,$8b,$5d,$8b,$5e,$8b,$00,$00	;	Tile b9
		db	$00,$00,$c2,$8a,$c3,$8a,$c4,$8a,$00,$00,$ca,$8a,$cb,$8a,$cc,$8a,$00,$00,$68,$8a,$69,$8a,$6a,$8a,$00,$00,$40,$86,$41,$86,$42,$86	;	Tile ba
		db	$c5,$8a,$60,$8a,$40,$86,$41,$86,$cd,$8a,$61,$8a,$41,$86,$42,$86,$6b,$8a,$62,$8a,$43,$86,$41,$86,$40,$86,$41,$86,$42,$86,$43,$86	;	Tile bb
		db	$40,$86,$41,$86,$60,$aa,$c5,$aa,$41,$86,$42,$86,$61,$aa,$cd,$aa,$43,$86,$44,$86,$62,$aa,$6b,$aa,$41,$86,$42,$86,$43,$86,$44,$86	;	Tile bc
		db	$c4,$aa,$c3,$aa,$c2,$aa,$00,$00,$cc,$aa,$cb,$aa,$ca,$aa,$00,$00,$6a,$aa,$69,$aa,$68,$aa,$00,$00,$40,$86,$41,$86,$42,$86,$00,$00	;	Tile bd
		db	$44,$86,$43,$86,$42,$86,$44,$86,$43,$86,$4e,$a6,$4d,$a6,$4c,$a6,$42,$86,$56,$a6,$55,$a6,$54,$a6,$41,$86,$42,$86,$43,$86,$43,$86	;	Tile be
		db	$28,$cb,$28,$cb,$28,$cb,$20,$cb,$26,$cb,$26,$cb,$26,$cb,$27,$cb,$23,$cb,$23,$cb,$23,$cb,$24,$cb,$2b,$cb,$2b,$cb,$2b,$cb,$2c,$cb	;	Tile bf
		db	$20,$cb,$20,$cb,$22,$cb,$2a,$cb,$27,$cb,$27,$cb,$22,$cb,$2a,$cb,$24,$cb,$25,$cb,$22,$cb,$2a,$cb,$2c,$cb,$2d,$cb,$2e,$cb,$2f,$cb	;	Tile c0
		db	$2a,$eb,$22,$eb,$20,$eb,$20,$eb,$2a,$eb,$22,$eb,$27,$eb,$27,$eb,$2a,$eb,$22,$eb,$25,$eb,$24,$eb,$2f,$eb,$2e,$eb,$2d,$eb,$2c,$eb	;	Tile c1
		db	$20,$eb,$28,$eb,$28,$eb,$28,$eb,$27,$eb,$26,$eb,$26,$eb,$26,$eb,$24,$eb,$23,$eb,$23,$eb,$23,$eb,$2c,$eb,$2b,$eb,$2b,$eb,$2b,$eb	;	Tile c2
		db	$98,$88,$06,$68,$05,$68,$04,$68,$99,$88,$99,$88,$98,$88,$0c,$68,$98,$88,$98,$88,$99,$88,$98,$88,$1d,$48,$99,$88,$98,$88,$99,$88	;	Tile c3
		db	$03,$48,$3a,$84,$3b,$84,$37,$84,$0b,$68,$02,$68,$01,$68,$3b,$84,$99,$88,$98,$88,$09,$68,$00,$68,$98,$88,$99,$88,$98,$88,$08,$68	;	Tile c4
		db	$98,$88,$98,$88,$99,$88,$98,$88,$99,$88,$99,$88,$98,$88,$99,$88,$98,$88,$98,$88,$99,$88,$98,$88,$1f,$48,$1f,$68,$1e,$48,$1d,$68	;	Tile c5
		db	$99,$88,$98,$88,$99,$88,$10,$68,$98,$88,$99,$88,$19,$68,$18,$68,$99,$88,$1a,$68,$3a,$84,$3b,$84,$1c,$68,$1b,$68,$39,$84,$3a,$84	;	Tile c6
		db	$c4,$0d,$c5,$0d,$c6,$0d,$c5,$0d,$3a,$84,$39,$84,$38,$84,$39,$84,$39,$84,$38,$84,$39,$84,$3a,$84,$3a,$84,$39,$84,$38,$84,$39,$84	;	Tile c7
		db	$c6,$0d,$c7,$0d,$37,$84,$3b,$84,$3b,$84,$37,$84,$3b,$84,$3a,$84,$39,$84,$3b,$84,$37,$84,$3b,$84,$38,$84,$3a,$84,$39,$84,$3a,$84	;	Tile c8
		db	$3b,$84,$39,$84,$c4,$0d,$c5,$0d,$37,$84,$3a,$84,$39,$84,$38,$84,$3a,$84,$39,$84,$38,$84,$39,$84,$3b,$84,$3a,$84,$39,$84,$38,$84	;	Tile c9
		db	$08,$c6,$08,$c6,$08,$c6,$00,$c6,$06,$c6,$06,$c6,$06,$c6,$07,$c6,$03,$c6,$03,$c6,$03,$c6,$04,$c6,$0b,$c6,$0b,$c6,$0b,$c6,$0c,$c6	;	Tile ca
		db	$00,$c6,$00,$c6,$02,$c6,$0a,$c6,$07,$c6,$07,$c6,$02,$c6,$0a,$c6,$04,$c6,$05,$c6,$02,$c6,$0a,$c6,$0c,$c6,$0d,$c6,$0e,$c6,$0f,$c6	;	Tile cb
		db	$0a,$e6,$02,$e6,$00,$e6,$00,$e6,$0a,$e6,$02,$e6,$07,$e6,$07,$e6,$0a,$e6,$02,$e6,$05,$e6,$04,$e6,$0f,$e6,$0e,$e6,$0d,$e6,$0c,$e6	;	Tile cc
		db	$00,$e6,$08,$e6,$08,$e6,$08,$e6,$07,$e6,$06,$e6,$06,$e6,$06,$e6,$04,$e6,$03,$e6,$03,$e6,$03,$e6,$0c,$e6,$0b,$e6,$0b,$e6,$0b,$e6	;	Tile cd
		db	$44,$86,$43,$86,$42,$86,$41,$86,$43,$86,$42,$86,$41,$86,$40,$86,$44,$86,$43,$86,$42,$86,$41,$86,$01,$e6,$09,$e6,$09,$e6,$09,$e6	;	Tile ce
		db	$5e,$8b,$5d,$8b,$5d,$8b,$5e,$8b,$5d,$8b,$5c,$8b,$14,$cb,$5d,$8b,$10,$cb,$11,$cb,$12,$cb,$13,$cb,$5e,$8b,$5d,$8b,$5c,$8b,$5d,$8b	;	Tile cf
		db	$5d,$8b,$5c,$8b,$5e,$8b,$5f,$8b,$5c,$8b,$5e,$8b,$5f,$8b,$5e,$8b,$12,$eb,$11,$eb,$10,$eb,$5d,$8b,$5d,$8b,$5e,$8b,$5d,$8b,$5e,$8b	;	Tile d0
		db	$5c,$8b,$5d,$8b,$5e,$8b,$5d,$8b,$14,$cb,$5e,$8b,$5d,$8b,$5c,$8b,$12,$cb,$13,$cb,$13,$eb,$12,$eb,$5d,$8b,$5c,$8b,$5d,$8b,$5e,$8b	;	Tile d1
		db	$5f,$8b,$5e,$8b,$5d,$8b,$5c,$8b,$5e,$8b,$5d,$8b,$5c,$8b,$14,$cb,$5f,$8b,$10,$cb,$11,$cb,$12,$cb,$5d,$8b,$5c,$8b,$5d,$8b,$5e,$8b	;	Tile d2
		db	$14,$cb,$5e,$8b,$5d,$8b,$15,$db,$12,$cb,$13,$cb,$13,$eb,$12,$eb,$5d,$8b,$5c,$8b,$5d,$8b,$5e,$8b,$5c,$8b,$5d,$8b,$5e,$8b,$5f,$8b	;	Tile d3
		db	$5e,$8b,$5d,$8b,$5c,$8b,$14,$cb,$5f,$8b,$10,$cb,$11,$cb,$12,$cb,$5e,$8b,$5d,$8b,$5c,$8b,$5d,$8b,$5d,$8b,$5c,$8b,$5d,$8b,$5e,$8b	;	Tile d4
		db	$00,$00,$c2,$cf,$45,$8a,$45,$8a,$00,$00,$ca,$cf,$45,$8a,$45,$8a,$00,$00,$d2,$cf,$45,$8a,$45,$8a,$00,$00,$da,$cf,$45,$8a,$45,$8a	;	Tile d5


		; This is a dataset which creates a character code based on the background character value
		; as there are $0-$3ff tiles it's a big ass table.
CHARACTER_LOOKUP:
		db	$01,$02,$00,$03,$06,$05,$06,$06,$06,$07,$09,$06,$06,$06,$06,$06
		db	$06,$38,$0b,$06,$19,$0c,$06,$06,$06,$0d,$00,$0e,$0f,$33,$2f,$30
		db	$00,$10,$06,$12,$00,$03,$13,$00,$14,$06,$06,$06,$15,$06,$06,$16
		db	$17,$06,$06,$06,$06,$06,$06,$18,$e0,$e3,$e3,$e3,$e2,$1b,$1c,$06
		db	$00,$00,$1d,$1e,$1f,$00,$20,$21,$22,$23,$06,$06,$06,$00,$06,$06
		db	$06,$06,$06,$06,$2a,$00,$06,$06,$06,$e4,$e4,$e5,$00,$00,$29,$25
		db	$2c,$2d,$06,$06,$06,$2e,$06,$0a,$00,$00,$06,$06,$06,$31,$06,$32
		db	$00,$00,$06,$06,$06,$34,$24,$35,$19,$36,$06,$06,$37,$1a,$00,$06
		db	$00,$00,$00,$9e,$9f,$a0,$a1,$a2,$a3,$a4,$06,$a6,$a7,$06,$06,$06
		db	$af,$06,$06,$a8,$a9,$aa,$06,$ab,$ac,$06,$47,$ad,$06,$ae,$00,$00
		db	$00,$00,$b5,$b6,$00,$00,$00,$00,$b7,$00,$b8,$b9,$ba,$00,$00,$00
		db	$bb,$06,$06,$06,$06,$bc,$00,$00,$bd,$06,$06,$06,$06,$be,$00,$00
		db	$00,$00,$00,$00,$3e,$04,$04,$3f,$40,$41,$06,$06,$0a,$06,$06,$0a
		db	$44,$b0,$06,$06,$0a,$06,$06,$00,$46,$00,$06,$06,$0a,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$d7,$00,$00,$d7,$d7,$67,$00,$dc,$23,$db,$e1,$06,$06,$68
		db	$00,$23,$23,$23,$06,$06,$06,$6a,$00,$da,$da,$00,$d9,$d9,$d9,$d8
		db	$6b,$23,$23,$23,$23,$23,$23,$23,$6c,$06,$06,$06,$06,$06,$06,$06
		db	$06,$06,$06,$06,$06,$06,$06,$06,$23,$23,$06,$06,$06,$06,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$06,$06,$06,$06,$06,$06,$06,$00,$06,$06,$06,$06,$06,$06,$06,$06
		db	$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
		db	$06,$06,$06,$06,$00,$00,$23,$6d,$06,$06,$06,$06,$00,$00,$06,$06
		db	$06,$06,$06,$06,$00,$00,$06,$06,$06,$06,$06,$06,$00,$00,$06,$06
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$4b,$4c,$4d,$4e,$4f,$50,$00
		db	$51,$52,$06,$0a,$54,$55,$56,$00,$57,$58,$59,$5a,$00,$00,$00,$00
		db	$06,$06,$93,$00,$00,$00,$00,$00,$93,$93,$93,$93,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$d3,$d4,$00
		db	$e7,$e8,$e9,$ea,$e1,$eb,$ec,$ed,$ee,$ef,$f0,$f1,$f2,$f3,$f4,$f5
		db	$f6,$f7,$00,$f8,$00,$fa,$e1,$2e,$e1,$e1,$d0,$fb,$fc,$fd,$00,$00
		db	$e1,$2b,$00,$00,$00,$00,$00,$00,$e1,$2e,$00,$00,$00,$00,$00,$00
		db	$e1,$2e,$00,$00,$00,$00,$00,$00,$e1,$2e,$00,$00,$00,$00,$00,$00
		db	$00,$00,$06,$06,$06,$06,$06,$00,$00,$00,$06,$06,$06,$06,$06,$00
		db	$00,$00,$93,$93,$93,$93,$93,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$06,$06,$07,$06,$06,$06,$06,$06,$06,$06,$00,$06,$06,$06,$07,$00
		db	$cb,$22,$22,$22,$00,$00,$07,$00,$06,$06,$06,$2e,$5e,$5f,$07,$00
		db	$06,$06,$38,$06,$06,$06,$06,$06,$06,$06,$00,$06,$06,$06,$07,$00
		db	$06,$06,$06,$2e,$60,$61,$63,$64,$5e,$5f,$65,$00,$60,$61,$63,$64
		db	$cb,$22,$22,$22,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$cd,$cd,$cd,$cf,$cf,$cf,$00,$00,$ce,$ce,$ce
		db	$00,$00,$00,$00,$00,$00,$00,$00,$cf,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$26,$06,$39,$28,$00,$00,$00,$00
		db	$06,$06,$42,$43,$00,$00,$00,$00,$06,$06,$06,$06,$06,$00,$00,$00
		db	$06,$06,$06,$45,$42,$00,$06,$06,$48,$06,$4a,$42,$43,$00,$06,$06
		db	$3b,$49,$53,$06,$06,$06,$5d,$45,$06,$06,$62,$06,$06,$06,$42,$4a
		db	$06,$06,$69,$06,$06,$06,$43,$06,$06,$06,$6f,$7b,$7c,$7c,$06,$48
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


6464: 		db	0,0,0,0,0,0,0,0,$1f,$1f,$1f,$1f,$1f,$1f,$1f,$1f,

		; Big wack of data $7f0 in size, not yet found where it's used. has to be map character related I feel
		
		db	$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
		db	$00,$3f,$ff,$ff,$ff,$ff,$ff,$ff
		db	$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		db	$00,$03,$07,$0f,$3f,$ff,$ff,$ff
		db	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		db	$f8,$f8,$f8,$f8,$f8,$f8,$f8,$f8
		db	$7f,$7f,$7f,$7f,$7f,$7f,$7f,$1f
		db	$1f,$1f,$ff,$ff,$ff,$ff,$ff,$ff
		db	$fc,$fc,$fc,$fc,$fc,$fc,$fc,$fc
		db	$7f,$7f,$7f,$2f,$1f,$1f,$1f,$0f
		db	$7f,$3f,$3f,$3f,$3f,$3f,$3f,$3f
		db	$fe,$fe,$fe,$fe,$fc,$f0,$c0,$c0
		db	$ff,$ff,$ff,$ff,$ff,$1f,$00,$00
		db	$ff,$ff,$ff,$ff,$ff,$f8,$f0,$00
		db	$00,$0f,$3f,$ff,$ff,$ff,$ff,$ff
		db	$c0,$c0,$c0,$c0,$80,$80,$00,$00
		db	$e0,$f0,$fc,$ff,$ff,$ff,$ff,$ff
		db	$00,$00,$80,$e0,$fc,$ff,$ff,$ff
		db	$1f,$1f,$1f,$3f,$3f,$3f,$3f,$3f
		db	$fc,$fc,$ff,$ff,$ff,$ff,$ff,$ff
		db	$c0,$e0,$f0,$f0,$f0,$f8,$fc,$fe
		db	$1f,$07,$03,$07,$07,$07,$07,$07
		db	$ff,$ff,$ff,$ff,$ff,$ff,$fc,$f8
		db	$ff,$ff,$ff,$ff,$ff,$fc,$fc,$fc
		db	$f0,$e0,$c0,$80,$00,$00,$00,$00
		db	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f0
		db	$ff,$ff,$ff,$ff,$fc,$f0,$00,$00
		db	$00,$00,$00,$3f,$7f,$ff,$ff,$ff
		db	$00,$3f,$ff,$ff,$ff,$ff,$ff,$ff
		db	$00,$c0,$f0,$f0,$fe,$ff,$ff,$ff
		db	$0f,$3f,$7f,$ff,$ff,$ff,$ff,$ff
		db	$e0,$f0,$ff,$ff,$ff,$ff,$ff,$ff
		db	$00,$00,$00,$ff,$ff,$ff,$ff,$ff
		db	$00,$00,$ff,$ff,$ff,$ff,$ff,$ff
		db	$fe,$fe,$fe,$fe,$fc,$fc,$fc,$f8
		db	$ff,$ff,$ff,$ff,$ff,$00,$00,$00
		db	$ff,$ff,$ff,$ff,$ff,$3f,$07,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$3f,$3f,$3f,$3f,$1f,$0f,$07,$00
		db	$7f,$3f,$1f,$1f,$0f,$00,$00,$00
		db	$01,$03,$03,$07,$07,$0f,$0f,$1f
		db	$00,$e0,$e0,$e0,$e0,$e0,$e0,$e0
		db	$1f,$1f,$1f,$ff,$ff,$ff,$ff,$ff
		db	$00,$e0,$f8,$f8,$f8,$f8,$f8,$f8
		db	$e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0
		db	$ff,$ff,$ff,$7f,$3f,$1f,$0f,$00
		db	$ff,$ff,$ff,$ff,$ff,$fc,$f8,$00
		db	$f8,$fc,$fc,$fc,$fc,$fe,$fe,$fe
		db	$fc,$fc,$fc,$fc,$fc,$f8,$f0,$e0
		db	$7f,$3f,$1f,$00,$00,$00,$00,$00
		db	$f8,$f8,$f8,$fc,$fc,$fc,$f8,$f0
		db	$00,$00,$fc,$fe,$ff,$ff,$ff,$ff
		db	$00,$f0,$fe,$ff,$ff,$ff,$ff,$ff
		db	$ff,$ff,$ff,$ff,$ff,$fc,$f8,$e0
		db	$fe,$fe,$fe,$fe,$fe,$fe,$fe,$fe
		db	$3f,$3f,$ff,$ff,$ff,$ff,$ff,$ff
		db	$03,$03,$03,$03,$03,$03,$03,$03
		db	$00,$00,$00,$03,$0f,$3f,$ff,$ff
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$7f,$7f,$ff,$ff,$ff,$ff,$ff
		db	$00,$80,$c0,$c0,$c0,$e0,$e0,$e0
		db	$00,$00,$30,$78,$fe,$ff,$ff,$ff
		db	$80,$c0,$e0,$e0,$00,$00,$00,$00
		db	$00,$c0,$f0,$fc,$ff,$ff,$ff,$ff
		db	$00,$00,$00,$00,$00,$c0,$f0,$fc
		db	$00,$01,$03,$03,$03,$0f,$0f,$0f
		db	$ff,$ff,$ff,$fe,$fc,$f8,$e0,$80
		db	$3f,$7e,$7e,$7e,$7e,$7e,$7f,$07
		db	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$fc
		db	$ff,$ff,$ff,$7f,$3f,$07,$03,$00
		db	$1f,$3f,$ff,$ff,$ff,$ff,$ff,$ff
		db	$ff,$fe,$fc,$f8,$f8,$f0,$e0,$c0
		db	$00,$00,$00,$00,$00,$00,$03,$0f
		db	$00,$00,$00,$03,$3f,$ff,$ff,$ff
		db	$00,$00,$00,$e0,$e0,$e0,$f8,$fc
		db	$7c,$fe,$fe,$ff,$ff,$ff,$ff,$7f
		db	$00,$00,$00,$07,$8f,$cf,$ff,$ff
		db	$00,$00,$00,$80,$c0,$e0,$e0,$e0
		db	$00,$00,$00,$00,$01,$07,$0f,$1f
		db	$3f,$3f,$3f,$ff,$ff,$ff,$ff,$ff
		db	$ff,$ff,$ff,$ff,$ff,$fe,$fc,$f8
		db	$0f,$07,$01,$00,$00,$00,$00,$00
		db	$ff,$ff,$ff,$7f,$1f,$00,$00,$00
		db	$f0,$f0,$f0,$e0,$c0,$00,$00,$00
		db	$1f,$1f,$1f,$1f,$1f,$1f,$0c,$00
		db	$ff,$ff,$fe,$f0,$c0,$00,$00,$00
		db	$ff,$ff,$3f,$0f,$03,$00,$00,$00
		db	$f8,$f8,$f0,$e0,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$c0,$f0,$fc,$ff
		db	$ff,$ff,$ff,$7f,$1f,$07,$01,$00
		db	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$7f
		db	$00,$00,$03,$0f,$3f,$ff,$ff,$ff
		db	$1f,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		db	$f8,$f0,$e0,$c0,$80,$00,$00,$00
		db	$00,$e0,$f8,$fe,$ff,$ff,$ff,$ff
		db	$00,$00,$00,$00,$80,$80,$80,$80
		db	$ff,$ff,$ff,$fe,$fc,$f8,$f0,$e0
		db	$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
		db	$7f,$7f,$7f,$7f,$3f,$3f,$3f,$3f
		db	$fe,$fe,$fe,$fe,$fc,$fc,$fc,$fc
		db	$c0,$c0,$c0,$e0,$e0,$f0,$f8,$fc
		db	$ff,$ff,$ff,$ff,$fe,$fe,$fe,$fe
		db	$00,$00,$3f,$3f,$3f,$3f,$7f,$7f
		db	$7f,$7f,$ff,$ff,$ff,$ff,$ff,$ff
		db	$07,$07,$ff,$ff,$ff,$ff,$ff,$ff
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$f8,$fc,$fc,$fc,$fe,$fe,$ff,$ff
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$ff,$ff,$3f,$1f,$0f,$07,$03,$00
		db	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$03,$0f,$3f,$ff,$ff,$ff,$ff
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$c0,$f8,$fc,$ff
		db	$00,$01,$03,$07,$0f,$0f,$0f,$1f
		db	$3c,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		db	$00,$f0,$fc,$ff,$ff,$ff,$ff,$ff
		db	$00,$00,$00,$f8,$fc,$ff,$ff,$ff
		db	$00,$01,$03,$07,$1f,$3f,$7f,$7f
		db	$3f,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$80,$c0,$f0,$f8,$f8,$f8,$f8
		db	$1f,$3f,$3f,$7f,$7f,$7f,$7f,$3f
		db	$f8,$f8,$f8,$f8,$fc,$ff,$ff,$ff
		db	$7f,$7f,$3f,$1f,$0f,$00,$00,$00
		db	$ff,$ff,$ff,$ff,$ff,$ff,$3f,$03
		db	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$f0
		db	$7f,$7f,$7f,$7f,$3f,$1f,$07,$00
		db	$ff,$fe,$fc,$f8,$f8,$e0,$80,$00
		db	$c0,$e0,$f8,$fc,$fc,$fe,$fe,$fe
		db	$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f
		db	$ff,$ff,$e0,$c0,$80,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$ff,$00,$00,$00,$00,$00,$00,$00
		db	$ff,$ff,$ff,$ff,$00,$00,$00,$00
		db	$f8,$e0,$c0,$00,$00,$00,$00,$00
		db	$ff,$ff,$ff,$ff,$ff,$fc,$c0,$00
		db	$00,$00,$00,$0f,$1f,$3f,$ff,$ff
		db	$3e,$7f,$ff,$00,$00,$00,$00,$00
		db	$00,$00,$c0,$f0,$f0,$f8,$fc,$fe
		db	$c0,$c0,$fc,$fc,$fc,$fc,$fc,$fc
		db	$00,$80,$c0,$e0,$f0,$fc,$fe,$ff
		db	$fe,$fc,$f8,$f0,$e0,$c0,$00,$00
		db	$ff,$ff,$ff,$ff,$ff,$ff,$fc,$fc
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$03,$07,$07,$01
		db	$00,$00,$ff,$ff,$ff,$ff,$ff,$ff
		db	$00,$00,$00,$00,$ff,$ff,$ff,$ff
		db	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		db	$ff,$ff,$ff,$ff,$ff,$00,$00,$00
		db	$00,$0f,$ff,$ff,$ff,$ff,$ff,$ff
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$03,$1f,$ff,$ff
		db	$00,$00,$0f,$7f,$ff,$ff,$ff,$ff
		db	$ff,$fe,$fe,$fe,$fc,$fc,$f8,$f8
		db	$e0,$c0,$80,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$ff
		db	$ff,$ff,$ff,$3f,$1f,$07,$03,$00
		db	$ff,$ff,$ff,$00,$00,$00,$00,$00
		db	$ff,$ff,$ff,$3f,$0f,$03,$00,$00
		db	$00,$00,$00,$03,$1f,$ff,$ff,$ff
		db	$07,$0f,$1f,$3f,$7f,$ff,$ff,$ff
		db	$00,$00,$00,$7f,$7f,$7f,$7f,$7f
		db	$00,$00,$ff,$ff,$ff,$ff,$ff,$ff
		db	$00,$00,$03,$0f,$0f,$0f,$07,$01
		db	$0f,$1f,$3f,$3f,$3f,$3f,$1f,$00
		db	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		db	$f8,$fc,$fe,$fe,$fc,$f0,$00,$00
		db	$ff,$ff,$ff,$ff,$ff,$ff,$00,$00
		db	$ff,$ff,$ff,$ff,$ff,$00,$00,$00
		db	$fe,$fe,$fc,$f8,$00,$00,$00,$00
		db	$07,$07,$07,$07,$07,$07,$07,$07
		db	$00,$00,$00,$00,$ff,$ff,$ff,$ff
		db	$00,$00,$00,$00,$00,$7f,$ff,$ff
		db	$00,$00,$00,$00,$00,$00,$07,$1f
		db	$3f,$3f,$3f,$1f,$0f,$07,$03,$01
		db	$7f,$3f,$0f,$07,$01,$00,$00,$00
		db	$ff,$ff,$ff,$ff,$ff,$00,$00,$00
		db	$ff,$ff,$ff,$ff,$ff,$07,$03,$00
		db	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00
		db	$f0,$f8,$f8,$f8,$f0,$e0,$c0,$00
		db	$00,$00,$00,$00,$f0,$f8,$fc,$fc
		db	$00,$c0,$e0,$fc,$ff,$ff,$ff,$ff
		db	$00,$00,$00,$00,$f0,$fc,$fe,$ff
		db	$03,$0f,$0f,$0f,$0f,$0f,$07,$03
		db	$3f,$1f,$0f,$07,$03,$01,$00,$00
		db	$80,$e0,$f0,$f0,$f0,$f0,$e0,$00
		db	$00,$00,$00,$00,$00,$fe,$ff,$ff
		db	$00,$00,$00,$00,$00,$07,$3f,$7f
		db	$00,$00,$00,$00,$00,$00,$7f,$ff
		db	$00,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$00,$00,$00,$00,$00,$ff
		db	$ff,$ff,$ff,$ff,$e0,$00,$00,$00
		db	$ff,$ff,$ff,$f0,$00,$00,$00,$00
		db	$ff,$00,$00,$00,$00,$00,$00,$00
		db	$00,$00,$ff,$ff,$ff,$ff,$ff,$ff
		db	$ff,$ff,$ff,$ff,$00,$00,$00,$00


6C64: DD 7E E1    ld   a,(ix+$0f)			; has like 14 entries
6C67: 21 30 E6    ld   hl,$6E12				; table index start
6C6A: EF          rst	INDEX_ED_AT_2A_PLUS_HL
6C6B: EB          ex   de,hl
6C6C: DD 7E 01    ld   a,(ix+$01)
6C6F: C6 01       add  a,$01				; + 1 to value
6C71: 47          ld   b,a
6C72: 0F          rrca
6C73: E6 F1       and  $1F
6C75: 28 92       jr   z,$6CAF
6C77: CB 70       bit  6,b
6C79: 20 80       jr   nz,$6C83
6C7B: 47          ld   b,a
6C7C: 2F          cpl
6C7D: E6 F1       and  $1F
6C7F: 4F          ld   c,a
6C80: C3 88 C6    jp   $6C88

6C83: 4F          ld   c,a
6C84: 2F          cpl
6C85: E6 F1       and  $1F
6C87: 47          ld   b,a
6C88: E5          push hl
6C89: 79          ld   a,c
6C8A: EF          rst	INDEX_ED_AT_2A_PLUS_HL
6C8B: 78          ld   a,b
6C8C: 42          ld   b,d
6C8D: 4B          ld   c,e
6C8E: E1          pop  hl
6C8F: EF          rst	INDEX_ED_AT_2A_PLUS_HL
6C90: DD CB 01 F6 bit  7,(ix+$01)
6C94: 28 80       jr   z,$6C9E
6C96: 21 00 00    ld   hl,$0000
6C99: A7          and  a
6C9A: ED 42       sbc  hl,bc
6C9C: 44          ld   b,h
6C9D: 4D          ld   c,l
6C9E: DD 7E 01    ld   a,(ix+$01)
6CA1: C6 04       add  a,$40
6CA3: CB 7F       bit  7,a
6CA5: C8          ret  z
6CA6: 21 00 00    ld   hl,$0000
6CA9: A7          and  a
6CAA: ED 52       sbc  hl,de
6CAC: 54          ld   d,h
6CAD: 5D          ld   e,l
6CAE: C9          ret

6CAF: 78          ld   a,b
6CB0: 4E          ld   c,(hl)
6CB1: 23          inc  hl
6CB2: 46          ld   b,(hl)
6CB3: 07          rlca
6CB4: 07          rlca
6CB5: E6 21       and  $03
6CB7: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$6cc0	; Table 0
		dw	$6cc6	; Table 1
		dw	$6cca	; Table 2
		dw	$6cd6	; Table 3

6CC0: 50 	  ld   d,b
6CC1: 59	  ld   e,c
6CC2: 01 00 00	  ld   bc,$0000
6CC5: C9          ret

6CC6: 11 00 00    ld   de,$0000
6CC9: C9          ret

6CCA: 21 00 00    ld   hl,$0000
6CCD: A7          and  a
6CCE: ED 42       sbc  hl,bc
6CD0: 54          ld   d,h
6CD1: 5D          ld   e,l
6CD2: 01 00 00    ld   bc,$0000
6CD5: C9          ret

6CD6: 21 00 00    ld   hl,$0000
6CD9: A7          and  a
6CDA: ED 42       sbc  hl,bc
6CDC: 44          ld   b,h
6CDD: 4D          ld   c,l
6CDE: 11 00 00    ld   de,$0000
6CE1: C9          ret
6CE2: 21 21 0F    ld   hl,PLAYER_X

6CE5: 0E 00       ld   c,$00
6CE7: 7E          ld   a,(hl)
6CE8: 2C          inc  l
6CE9: 2C          inc  l
6CEA: DD 46 21    ld   b,(ix+TABLE_X_coord)
6CED: 90          sub  b
6CEE: 28 37       jr   z,$6D63
6CF0: CB 19       rr   c
6CF2: CB 79       bit  7,c
6CF4: 28 20       jr   z,$6CF8
6CF6: ED 44       neg
6CF8: 57          ld   d,a
6CF9: 7E          ld   a,(hl)
6CFA: DD 46 41    ld   b,(ix+TABLE_Y_coord)
6CFD: 90          sub  b
6CFE: 28 C7       jr   z,$6D6D
6D00: CB 19       rr   c
6D02: CB 79       bit  7,c
6D04: 28 20       jr   z,$6D08
6D06: ED 44       neg
6D08: 5F          ld   e,a
6D09: 92          sub  d
6D0A: 28 27       jr   z,$6D6F
6D0C: CB 19       rr   c
6D0E: CB 79       bit  7,c
6D10: 20 41       jr   nz,$6D17
6D12: 62          ld   h,d
6D13: 2E 00       ld   l,$00
6D15: 18 40       jr   $6D1B
6D17: 63          ld   h,e
6D18: 5A          ld   e,d
6D19: 2E 00       ld   l,$00
6D1B: 06 80       ld   b,$08
6D1D: AF          xor  a
6D1E: ED 6A       adc  hl,hl
6D20: 7C          ld   a,h
6D21: 38 21       jr   c,$6D26
6D23: BB          cp   e
6D24: 38 21       jr   c,$6D29
6D26: 93          sub  e
6D27: 67          ld   h,a
6D28: AF          xor  a
6D29: 3F          ccf
6D2A: 10 3E       djnz $6D1E
6D2C: CB 15       rl   l
6D2E: 7D          ld   a,l
6D2F: 0F          rrca
6D30: 0F          rrca
6D31: 0F          rrca
6D32: E6 F1       and  $1F
6D34: 47          ld   b,a
6D35: 21 A5 C7    ld   hl,$6D4B
6D38: 79          ld   a,c
6D39: 07          rlca
6D3A: 07          rlca
6D3B: 07          rlca
6D3C: E6 61       and  $07
6D3E: 87          add  a,a
6D3F: E7          rst	INDEX_A_PLUS_HL
6D40: 4F          ld   c,a		; save 1st entry
6D41: 23          inc  hl
6D42: 7E          ld   a,(hl)		; get 2nd entry
6D43: CB 41       bit  0,c		; was 1st a 0 or 1 (only valid values here)
6D45: 20 20       jr   nz,$6D49		; if a 1
6D47: 80          add  a,b		; a = a+b for a 0
6D48: C9          ret
6D49: 90          sub  b		; a = a-b for a 1
6D4A: C9          ret

6D4B:		db	$01, $40	; 
6d4d:		db	$00, $40
6d4f:		db	$00, $c0
6d51:		db	$01, $c0
6d53:		db	$00, $00
6d55:		db	$01, $80
6d57:		db	$01, $00
6d59:		db	$00, $80
6d5b:		db	$01, $40
6d5d:		db	$00, $40
6d5f:		db	$00, $c0
6d61:		db	$01, $c0

6D63: 7E	  ld   a,(hl) 
6D63: DD 96 41    sub  (ix+TABLE_Y_coord)
6D67: CB 19       rr   c
6D69: 3E 04       ld   a,$40
6D6B: 81          add  a,c
6D6C: C9          ret
6D6D: 79          ld   a,c
6D6E: C9          ret
6D6F: 79          ld   a,c
6D70: 07          rlca
6D71: 07          rlca
6D72: E6 21       and  $03
6D74: 21 97 C7    ld   hl,$6D79
6D77: E7          rst	INDEX_A_PLUS_HL
6D78: C9          ret

6D79:		db	$20,$60,$e0,$a0

6D7D: FD 21 40 FE ld   iy,HW_SPRITE_1
6D81: 3A A1 0E    ld   a,(JOYSTICK1_UP)
6D84: E6 01       and  $01
6D86: 28 21       jr   z,$6D8B
6D88: FD 34 21    inc  (iy+sprite_y)
6D8B: 3A A0 0E    ld   a,(JOYSTICK1_LEFT)
6D8E: E6 01       and  $01
6D90: 28 21       jr   z,$6D95
6D92: FD 35 21    dec  (iy+sprite_y)
6D95: 3A 81 0E    ld   a,(JOYSTICK1_LEFT)
6D98: E6 01       and  $01
6D9A: 28 21       jr   z,$6D9F
6D9C: FD 35 20    dec  (iy+sprite_x)
6D9F: 3A 80 0E    ld   a,(JOYSTICK1_RIGHT)
6DA2: E6 01       and  $01
6DA4: 28 21       jr   z,$6DA9
6DA6: FD 34 20    inc  (iy+sprite_x)
6DA9: FD 36 01 00 ld   (iy+sprite_flags),$00
6DAD: FD 36 00 BA ld   (iy+sprite_number),$BA
6DB1: FD 21 80 FE ld   iy,HW_SPRITE_2
6DB5: 3A 31 0E    ld   a,(JOYSTICK2_UP)
6DB8: E6 01       and  $01
6DBA: 28 21       jr   z,$6DBF
6DBC: FD 34 21    inc  (iy+sprite_y)
6DBF: 3A 30 0E    ld   a,(JOYSTICK2_DOWN)
6DC2: E6 01       and  $01
6DC4: 28 21       jr   z,$6DC9
6DC6: FD 35 21    dec  (iy+sprite_y)
6DC9: 3A 11 0E    ld   a,(JOYSTICK2_LEFT)
6DCC: E6 01       and  $01
6DCE: 28 21       jr   z,$6DD3
6DD0: FD 35 20    dec  (iy+sprite_x)
6DD3: 3A 10 0E    ld   a,(JOYSTICK2_RIGHT)
6DD6: E6 01       and  $01
6DD8: 28 21       jr   z,$6DDD
6DDA: FD 34 20    inc  (iy+sprite_x)
6DDD: FD 36 01 00 ld   (iy+sprite_flags),$00
6DE1: FD 36 00 9A ld   (iy+sprite_number),$B8
6DE5: FD 7E 20    ld   a,(iy+sprite_x)
6DE8: 32 D7 0E    ld   ($E07D),a
6DEB: FD 7E 21    ld   a,(iy+sprite_y)
6DEE: 32 F7 0E    ld   ($E07F),a
6DF1: DD 21 00 6E ld   ix,ENEMY_SPRITES
6DF5: FD 21 40 FE ld   iy,HW_SPRITE_1
6DF9: FD 7E 20    ld   a,(iy+sprite_x)
6DFC: DD 77 21    ld   (ix+TABLE_X_coord),a
6DFF: FD 7E 21    ld   a,(iy+sprite_y)
6E02: DD 77 41    ld   (ix+TABLE_Y_coord),a
6E05: 21 D7 0E    ld   hl,$E07D
6E08: CD 4F C6    call $6CE5
6E0B: 21 D4 1C    ld   hl,$D05C				; Screen x=02, y=03
6E0E: C3 D8 D8    jp   PRINT_NUMBER
6E11: C9          ret

6E12: 		dw	$6e2e	; Table 0
		dw	$6e6e	; Table 1
		dw	$6eae	; Table 2
		dw	$6eee	; Table 3
		dw	$6f2e	; Table 4
		dw	$6f6e	; Table 5
		dw	$6fae	; Table 6
		dw	$6fee	; Table 7
		dw	$702e	; Table 8
		dw	$706e	; Table 9
		dw	$70ae	; Table A
		dw	$70ee	; Table B
		dw	$712e	; Table C
		dw	$716e	; Table D
		
6e2e:	db	$c8, $00, $c7, $00, $c7, $00, $c5, $00, $c4, $00, $c2, $00, $bf, $00, $bc, $00, $b8, $00, $b4, $00, $b0, $00, $ab, $00, $a6, $00, $a0, $00, $9a, $00, $94, $00, $8d, $00, $86, $00, $7e, $00, $77, $00, $6f, $00, $66, $00, $5e, $00, $55, $00, $4c, $00, $43, $00, $3a, $00, $30, $00, $27, $00, $1d, $00, $13, $00, $09, $00
6e6e:	db	$1a, $01, $19, $01, $18, $01, $16, $01, $14, $01, $11, $01, $0d, $01, $09, $01, $04, $01, $fe, $00, $f8, $00, $f1, $00, $ea, $00, $e2, $00, $d9, $00, $d0, $00, $c7, $00, $bd, $00, $b2, $00, $a7, $00, $9c, $00, $90, $00, $84, $00, $78, $00, $6b, $00, $5e, $00, $51, $00, $44, $00, $36, $00, $29, $00, $1b, $00, $0d, $00
6eae:	db	$33, $01, $32, $01, $31, $01, $2f, $01, $2c, $01, $29, $01, $25, $01, $20, $01, $1b, $01, $15, $01, $0e, $01, $07, $01, $ff, $00, $f6, $00, $ed, $00, $e3, $00, $d9, $00, $cd, $00, $c2, $00, $b6, $00, $aa, $00, $9d, $00, $90, $00, $83, $00, $75, $00, $67, $00, $59, $00, $4a, $00, $3b, $00, $2c, $00, $1e, $00, $0f, $00
6eee:	db	$4d, $01, $4c, $01, $4b, $01, $49, $01, $46, $01, $43, $01, $3e, $01, $39, $01, $33, $01, $2c, $01, $25, $01, $1d, $01, $14, $01, $0b, $01, $01, $01, $f6, $00, $eb, $00, $df, $00, $d3, $00, $c6, $00, $b8, $00, $ab, $00, $9c, $00, $8e, $00, $7f, $00, $6f, $00, $60, $00, $50, $00, $40, $00, $30, $00, $20, $00, $10, $00
6f2e:	db	$67, $01, $66, $01, $65, $01, $63, $01, $5f, $01, $5c, $01, $57, $01, $51, $01, $4b, $01, $44, $01, $3c, $01, $33, $01, $2a, $01, $20, $01, $15, $01, $09, $01, $fd, $00, $f0, $00, $e3, $00, $d5, $00, $c7, $00, $b8, $00, $a9, $00, $99, $00, $89, $00, $78, $00, $68, $00, $56, $00, $46, $00, $34, $00, $23, $00, $11, $00
6f6e:	db	$80, $01, $7f, $01, $7e, $01, $7b, $01, $78, $01, $74, $01, $6f, $01, $69, $01, $62, $01, $5a, $01, $52, $01, $49, $01, $3f, $01, $34, $01, $28, $01, $1c, $01, $0f, $01, $01, $01, $f3, $00, $e4, $00, $d5, $00, $c5, $00, $b4, $00, $a3, $00, $92, $00, $81, $00, $6f, $00, $5c, $00, $4a, $00, $38, $00, $25, $00, $12, $00
6fae:	db	$9a, $01, $99, $01, $97, $01, $95, $01, $91, $01, $8d, $01, $87, $01, $81, $01, $7a, $01, $72, $01, $69, $01, $5f, $01, $54, $01, $49, $01, $3c, $01, $2f, $01, $21, $01, $13, $01, $03, $01, $f3, $00, $e3, $00, $d2, $00, $c1, $00, $af, $00, $9c, $00, $89, $00, $76, $00, $63, $00, $4f, $00, $3b, $00, $28, $00, $14, $00
6fee:	db	$b3, $01, $b2, $01, $b0, $01, $ae, $01, $aa, $01, $a5, $01, $9f, $01, $99, $01, $91, $01, $88, $01, $7f, $01, $74, $01, $69, $01, $5d, $01, $50, $01, $41, $01, $33, $01, $23, $01, $13, $01, $02, $01, $f1, $00, $df, $00, $cc, $00, $b9, $00, $a6, $00, $92, $00, $7e, $00, $69, $00, $54, $00, $3f, $00, $2a, $00, $15, $00
702e:	db	$cc, $01, $cb, $01, $c9, $01, $c6, $01, $c2, $01, $be, $01, $b7, $01, $b0, $01, $a8, $01, $9f, $01, $95, $01, $8a, $01, $7e, $01, $71, $01, $63, $01, $54, $01, $45, $01, $34, $01, $23, $01, $11, $01, $ff, $00, $ec, $00, $d8, $00, $c4, $00, $af, $00, $9a, $00, $85, $00, $6f, $00, $59, $00, $43, $00, $2d, $00, $16, $00
706e:	db	$e7, $01, $e6, $01, $e4, $01, $e1, $01, $dd, $01, $d8, $01, $d1, $01, $ca, $01, $c1, $01, $b7, $01, $ad, $01, $a1, $01, $94, $01, $87, $01, $78, $01, $68, $01, $58, $01, $46, $01, $34, $01, $21, $01, $0e, $01, $fa, $00, $e5, $00, $cf, $00, $ba, $00, $a3, $00, $8d, $00, $75, $00, $5e, $00, $47, $00, $2f, $00, $17, $00
70ae:	db	$00, $02, $fe, $01, $fd, $01, $fa, $01, $f5, $01, $f0, $01, $e9, $01, $e1, $01, $d8, $01, $ce, $01, $c3, $01, $b6, $01, $a9, $01, $9b, $01, $8b, $01, $7a, $01, $69, $01, $57, $01, $44, $01, $30, $01, $1c, $01, $07, $01, $f1, $00, $da, $00, $c3, $00, $ac, $00, $94, $00, $7b, $00, $63, $00, $4a, $00, $32, $00, $19, $00
70ee:	db	$33, $02, $31, $02, $30, $02, $2c, $02, $27, $02, $22, $02, $1a, $02, $11, $02, $07, $02, $fc, $01, $f0, $01, $e2, $01, $d3, $01, $c4, $01, $b3, $01, $a0, $01, $8e, $01, $79, $01, $64, $01, $4e, $01, $38, $01, $21, $01, $09, $01, $f0, $00, $d7, $00, $bd, $00, $a3, $00, $88, $00, $6d, $00, $52, $00, $37, $00, $1b, $00
712e:	db	$66, $02, $64, $02, $62, $02, $5f, $02, $59, $02, $53, $02, $4a, $02, $41, $02, $36, $02, $2a, $02, $1c, $02, $0e, $02, $fe, $01, $ed, $01, $da, $01, $c6, $01, $b2, $01, $9b, $01, $85, $01, $6d, $01, $54, $01, $3b, $01, $21, $01, $06, $01, $ea, $00, $ce, $00, $b2, $00, $94, $00, $77, $00, $59, $00, $3c, $00, $1e, $00
716e:	db	$9a, $02, $98, $02, $96, $02, $92, $02, $8c, $02, $86, $02, $7c, $02, $72, $02, $66, $02, $59, $02, $4a, $02, $3a, $02, $29, $02, $16, $02, $02, $02, $ec, $01, $d6, $01, $be, $01, $a6, $01, $8c, $01, $71, $01, $56, $01, $39, $01, $1c, $01, $fe, $00, $df, $00, $c1, $00, $a1, $00, $81, $00, $61, $00, $41, $00, $20, $00


		; First set of bytes is Y scroll position inside map
		; 3rd byte is the animation or movable object type.
		;	01 Prisoner with two guards
		;	02 Guard which Walks away (normally with prisoner
		;	03 man with big launcher
		;	05 Large Block building with Turret Gun
		;	09 Gunner in windows at area end black guns
		;	0A Large truck
		;	0E gunner in hole up and down with bullets
		;	12 Barrack Door opening closing with enemy coming out sliding door
		;	13 Large double doors at end of level castle
		;	14 Large doors brick wall ones not castle 1st Area
		;	16 Big explosion
		;	17 Double barrel turret gun on floor 
		;	18 unused it seems!
		;	19 Man on Motorbike
		;	1A Large Sprite Bridge with track for vehicles
		;	1B Large Sprite Bridge broken gap in middle
		;	21 Slim single doors with enemy coming out.
		;	22 Cave rock area to hide enemy sprites exiting.
		;	23 Ammo Pickup single and double
		;	24 Double Ammo Not animated
		;	25 seems unused
		;	26 Gunner in trench
		;	27 gunner in tower
		;	28 Last area big door very end.
		;	29 Slid up and down door ways in metal looking huts
		;	2A motor bike large one on bridge
		;	2B slim motor bike or car either direction
		;	2C Jeep vehicle coming down screen
		;	2D Truck vehicle coming down screen
		;	2E Enemy in water up and down fire bullets
		;	2F gunner behind sandbags

		; 4th is the x position on screen, many elements use lower bits for flip or other bits
		; 5th and 6th are the hardware sprite pointer directly to use for the item(s) as some are more than one sprite.	
BG_EVENT_TABLE:	
		db	$1a,$02,$2f,$a0,$d4,$fe	;	Trigger 00	Area 1
		db	$30,$02,$23,$a1,$28,$fe	;	Trigger 01
		db	$fe,$02,$02,$96,$38,$fe	;	Trigger 02
		db	$fe,$02,$02,$b6,$40,$fe	;	Trigger 03
		db	$fe,$02,$01,$a6,$30,$fe	;	Trigger 04
		db	$e0,$03,$03,$d0,$c8,$fe	;	Trigger 05
		db	$e0,$03,$23,$c2,$28,$fe	;	Trigger 06
		db	$11,$04,$1a,$60,$90,$fe	;	Trigger 07
		db	$38,$04,$19,$e0,$7c,$fe	;	Trigger 08
		db	$97,$04,$2f,$78,$78,$fe	;	Trigger 09
		db	$b7,$04,$2f,$18,$74,$fe	;	Trigger 0a
		db	$d7,$04,$2f,$e4,$70,$fe	;	Trigger 0b
		db	$f7,$04,$2f,$48,$6c,$fe	;	Trigger 0c
		db	$17,$05,$2f,$a8,$68,$fe	;	Trigger 0d
		db	$77,$05,$2f,$18,$d4,$fe	;	Trigger 0e
		db	$77,$05,$2f,$78,$d0,$fe	;	Trigger 0f
		db	$77,$05,$2f,$d8,$cc,$fe	;	Trigger 10
		db	$da,$05,$00,$60,$c8,$fe	;	Trigger 11
		db	$e7,$05,$23,$51,$28,$fe	;	Trigger 12
		db	$3a,$06,$00,$c0,$c4,$fe	;	Trigger 13
		db	$3a,$06,$00,$a0,$c0,$fe	;	Trigger 14
		db	$5a,$06,$00,$20,$bc,$fe	;	Trigger 15
		db	$ba,$06,$00,$80,$b8,$fe	;	Trigger 16
		db	$da,$06,$00,$20,$b4,$fe	;	Trigger 17
		db	$e0,$06,$23,$31,$28,$fe	;	Trigger 18
		db	$da,$06,$00,$40,$d4,$fe	;	Trigger 19
		db	$1a,$07,$00,$e0,$d0,$fe	;	Trigger 1a
		db	$20,$07,$23,$c0,$24,$fe	;	Trigger 1b
		db	$d4,$07,$14,$50,$70,$fe	;	Trigger 1c
		db	$ff,$07,$20,$00,$04,$fe	;	Trigger 1d
7262:		db	$50,$08,$2b,$01,$a8,$fe	;	Trigger 1e	Area 2 offset 30th event
		db	$90,$08,$2b,$03,$78,$fe	;	Trigger 1f
		db	$33,$09,$1f,$00,$30,$fe	;	Trigger 20
		db	$50,$09,$2b,$02,$a8,$fe	;	Trigger 21
		db	$d0,$09,$23,$50,$28,$fe	;	Trigger 22
		db	$e0,$09,$2b,$00,$90,$fe	;	Trigger 23
		db	$00,$0a,$2b,$02,$78,$fe	;	Trigger 24
		db	$10,$0a,$0e,$c0,$d4,$fe	;	Trigger 25
		db	$10,$0a,$0e,$a0,$d0,$fe	;	Trigger 26
		db	$50,$0a,$0e,$18,$cc,$fe	;	Trigger 27
		db	$50,$0a,$0e,$38,$c8,$fe	;	Trigger 28
		db	$60,$0a,$0e,$c0,$c4,$fe	;	Trigger 29
		db	$c0,$0a,$23,$d2,$28,$fe	;	Trigger 2a
		db	$90,$0a,$0e,$60,$c0,$fe	;	Trigger 2b
		db	$90,$0a,$0e,$80,$bc,$fe	;	Trigger 2c
		db	$d0,$0a,$0e,$d0,$b8,$fe	;	Trigger 2d
		db	$20,$0b,$0e,$30,$d4,$fe	;	Trigger 2e
		db	$50,$0b,$0e,$70,$d0,$fe	;	Trigger 2f
		db	$50,$0b,$0e,$90,$cc,$fe	;	Trigger 30
		db	$50,$0b,$0e,$a8,$c8,$fe	;	Trigger 31
		db	$90,$0b,$0e,$30,$c4,$fe	;	Trigger 32
		db	$f0,$0b,$23,$a0,$28,$fe	;	Trigger 33
		db	$11,$0c,$1b,$60,$8c,$fe	;	Trigger 34
		db	$c1,$0c,$12,$2b,$7c,$fe	;	Trigger 35
		db	$ff,$0c,$23,$41,$28,$fe	;	Trigger 36
		db	$80,$0d,$2e,$c0,$d4,$fe	;	Trigger 37
		db	$d1,$0d,$05,$28,$58,$fe	;	Trigger 38
		db	$51,$0e,$05,$c8,$34,$fe	;	Trigger 39
		db	$c0,$0e,$23,$e0,$28,$fe	;	Trigger 3a
		db	$d1,$0e,$05,$28,$58,$fe	;	Trigger 3b
		db	$59,$0f,$22,$d0,$84,$fe	;	Trigger 3c
		db	$d4,$0f,$14,$50,$30,$fe	;	Trigger 3d
		db	$ff,$0f,$20,$00,$04,$fe	;	Trigger 3e
7328:		db	$83,$10,$21,$a8,$c8,$fe	;	Trigger 3f	Area 3 offset 63rd event
		db	$c3,$10,$21,$28,$bc,$fe	;	Trigger 40
		db	$e0,$10,$23,$c0,$28,$fe	;	Trigger 41
		db	$43,$11,$21,$29,$b0,$fe	;	Trigger 42
		db	$43,$11,$21,$a9,$a4,$fe	;	Trigger 43
		db	$c3,$11,$21,$68,$98,$fe	;	Trigger 44
		db	$43,$12,$21,$28,$c8,$fe	;	Trigger 45
		db	$70,$12,$23,$c1,$28,$fe	;	Trigger 46
		db	$83,$12,$21,$69,$bc,$fe	;	Trigger 47
		db	$03,$13,$21,$a8,$b0,$fe	;	Trigger 48
		db	$43,$13,$21,$68,$c8,$fe	;	Trigger 49
		db	$b0,$13,$23,$32,$28,$fe	;	Trigger 4a
		db	$11,$14,$1a,$60,$70,$fe	;	Trigger 4b
		db	$38,$14,$19,$e0,$54,$fe	;	Trigger 4c
		db	$e0,$14,$0a,$cf,$30,$fe	;	Trigger 4d
		db	$40,$15,$0a,$cf,$50,$fe	;	Trigger 4e
		db	$70,$15,$0b,$70,$70,$fe	;	Trigger 4f
		db	$b0,$15,$2b,$03,$90,$fe	;	Trigger 50
		db	$00,$16,$2b,$01,$a8,$fe	;	Trigger 51
		db	$40,$16,$2b,$03,$c0,$fe	;	Trigger 52
		db	$80,$16,$2b,$03,$90,$fe	;	Trigger 53
		db	$c0,$16,$2b,$00,$6c,$fe	;	Trigger 54
		db	$00,$17,$2b,$02,$84,$fe	;	Trigger 55
		db	$40,$17,$2b,$00,$9c,$fe	;	Trigger 56
		db	$80,$17,$2b,$00,$b4,$fe	;	Trigger 57
		db	$a0,$17,$23,$61,$28,$fe	;	Trigger 58
		db	$a0,$17,$23,$a1,$20,$fe	;	Trigger 59
		db	$b0,$17,$03,$20,$8c,$fe	;	Trigger 5a
		db	$b0,$17,$03,$d0,$7c,$fe	;	Trigger 5b
		db	$d4,$17,$14,$50,$30,$fe	;	Trigger 5c
		db	$ff,$17,$20,$00,$04,$fe	;	Trigger 5d
73E2:		db	$60,$19,$23,$d1,$28,$fe	;	Trigger 5e	; Area 4 offset 94th
		db	$9a,$1a,$00,$18,$ac,$fe	;	Trigger 5f
		db	$9a,$1a,$00,$38,$a8,$fe	;	Trigger 60
		db	$d0,$1a,$23,$32,$28,$fe	;	Trigger 61
		db	$50,$1c,$23,$41,$28,$fe	;	Trigger 62
		db	$50,$1d,$23,$b1,$28,$fe	;	Trigger 63
		db	$7f,$1d,$2b,$03,$7c,$fe	;	Trigger 64
		db	$80,$1d,$27,$d0,$30,$fe	;	Trigger 65
		db	$a0,$1d,$2b,$03,$90,$fe	;	Trigger 66
		db	$d0,$1d,$2b,$03,$a4,$fe	;	Trigger 67
		db	$01,$1e,$12,$2b,$7c,$fe	;	Trigger 68
		db	$d0,$1e,$23,$d0,$28,$fe	;	Trigger 69
		db	$80,$1f,$2b,$03,$90,$fe	;	Trigger 6a
		db	$91,$1f,$28,$60,$30,$fe	;	Trigger 6b
		db	$9d,$1f,$26,$38,$b0,$fe	;	Trigger 6c
		db	$9d,$1f,$26,$b8,$ac,$fe	;	Trigger 6d
		db	$b0,$1f,$2b,$03,$90,$fe	;	Trigger 6e
		db	$dd,$1f,$26,$60,$a8,$fe	;	Trigger 6f
		db	$dd,$1f,$26,$90,$a4,$fe	;	Trigger 70
7452:		db	$c0,$40,$2e,$40,$d4,$fe	;	Trigger 71	; Area 5
		db	$d0,$41,$23,$31,$28,$fe	;	Trigger 72
		db	$d0,$43,$23,$20,$28,$fe	;	Trigger 73
		db	$11,$44,$1a,$60,$a0,$fe	;	Trigger 74
		db	$35,$44,$2a,$e0,$8c,$fe	;	Trigger 75
		db	$17,$45,$2f,$a8,$74,$fe	;	Trigger 76
		db	$80,$45,$03,$d8,$cc,$fe	;	Trigger 77
		db	$90,$45,$23,$d2,$28,$fe	;	Trigger 78
		db	$97,$45,$2f,$28,$c8,$fe	;	Trigger 79
		db	$d7,$45,$2f,$b8,$c0,$fe	;	Trigger 7a
		db	$e0,$45,$03,$18,$b4,$fe	;	Trigger 7b
		db	$f0,$45,$23,$39,$20,$fe	;	Trigger 7c
		db	$37,$46,$2f,$18,$b0,$fe	;	Trigger 7d
		db	$77,$46,$2f,$98,$a8,$fe	;	Trigger 7e
		db	$b7,$46,$2f,$c8,$a4,$fe	;	Trigger 7f
		db	$c0,$46,$2e,$40,$d4,$fe	;	Trigger 80
		db	$da,$46,$00,$a8,$a0,$fe	;	Trigger 81
		db	$f0,$46,$23,$b9,$28,$fe	;	Trigger 82
		db	$9a,$47,$00,$38,$9c,$fe	;	Trigger 83
		db	$9a,$47,$00,$c8,$98,$fe	;	Trigger 84
		db	$d4,$47,$14,$50,$30,$fe	;	Trigger 85
74D2:		db	$91,$48,$05,$28,$30,$fe	;	Trigger 86	Area 6
		db	$d1,$48,$05,$c8,$54,$fe	;	Trigger 87
		db	$51,$49,$05,$28,$78,$fe	;	Trigger 88
		db	$d1,$49,$05,$c8,$30,$fe	;	Trigger 89
		db	$99,$4a,$25,$00,$b4,$fe	;	Trigger 8a
		db	$d0,$4a,$23,$40,$28,$fe	;	Trigger 8b
		db	$d9,$4a,$25,$00,$94,$fe	;	Trigger 8c
		db	$19,$4b,$25,$00,$74,$fe	;	Trigger 8d
		db	$40,$4b,$23,$c0,$2c,$fe	;	Trigger 8e
		db	$59,$4b,$25,$00,$54,$fe	;	Trigger 8f
		db	$99,$4b,$25,$00,$34,$fe	;	Trigger 90
		db	$11,$4c,$1b,$60,$9c,$fe	;	Trigger 91
		db	$90,$4c,$0e,$e0,$94,$fe	;	Trigger 92
		db	$a0,$4c,$0e,$28,$8c,$fe	;	Trigger 93
		db	$d0,$4c,$0e,$a8,$88,$fe	;	Trigger 94
		db	$00,$4d,$23,$31,$28,$fe	;	Trigger 95
		db	$40,$4d,$2e,$40,$d4,$fe	;	Trigger 96
		db	$a0,$4d,$0e,$70,$80,$fe	;	Trigger 97
		db	$a0,$4d,$0e,$90,$7c,$fe	;	Trigger 98
		db	$a0,$4d,$0e,$b0,$78,$fe	;	Trigger 99
		db	$e0,$4d,$0e,$30,$70,$fe	;	Trigger 9a
		db	$10,$4e,$0e,$a0,$d4,$fe	;	Trigger 9b
		db	$10,$4e,$0e,$c0,$d0,$fe	;	Trigger 9c
		db	$60,$4e,$0e,$b0,$cc,$fe	;	Trigger 9d
		db	$78,$4e,$23,$b2,$28,$fe	;	Trigger 9e
		db	$c0,$4e,$2e,$c0,$ac,$fe	;	Trigger 9f
		db	$20,$4f,$0e,$50,$c4,$fe	;	Trigger a0
		db	$20,$4f,$0e,$70,$c0,$fe	;	Trigger a1
		db	$50,$4f,$0e,$b0,$bc,$fe	;	Trigger a2
		db	$50,$4f,$0e,$c0,$b8,$fe	;	Trigger a3
		db	$90,$4f,$0e,$40,$b0,$fe	;	Trigger a4
		db	$d4,$4f,$14,$50,$30,$fe	;	Trigger a5
7592:		db	$40,$50,$29,$18,$cc,$fe	;	Trigger a6	; Area 7 left
		db	$40,$50,$29,$59,$c0,$fe	;	Trigger a7	; centre
		db	$a0,$50,$29,$10,$a8,$fe	;	Trigger a8	; left
		db	$a0,$50,$29,$99,$9c,$fe	;	Trigger a9	; centre
		db	$d0,$50,$23,$28,$28,$fe	;	Trigger aa	; 
		db	$00,$51,$29,$18,$84,$fe	;	Trigger ab	; left
		db	$00,$51,$29,$99,$cc,$fe	;	Trigger ac	; centre
		db	$60,$51,$29,$10,$c0,$fe	;	Trigger ad	; left
		db	$60,$51,$29,$da,$a8,$fe	;	Trigger ae	; right
		db	$c0,$51,$29,$18,$9c,$fe	;	Trigger af
		db	$40,$52,$29,$18,$84,$fe	;	Trigger b0
		db	$40,$52,$29,$59,$78,$fe	;	Trigger b1
		db	$90,$52,$23,$d1,$28,$fe	;	Trigger b2
		db	$90,$52,$23,$31,$28,$fe	;	Trigger b3
		db	$c0,$52,$29,$59,$c0,$fe	;	Trigger b4
		db	$20,$53,$29,$10,$a8,$fe	;	Trigger b5
		db	$40,$53,$29,$79,$90,$fe	;	Trigger b6
		db	$d0,$53,$23,$c2,$28,$fe	;	Trigger b7
		db	$d0,$53,$17,$28,$40,$fe	;	Trigger b8
		db	$11,$54,$1a,$60,$a0,$fe	;	Trigger b9
		db	$35,$54,$19,$e0,$78,$fe	;	Trigger ba
		db	$45,$54,$19,$e0,$8c,$fe	;	Trigger bb
		db	$28,$55,$0a,$cf,$30,$fe	;	Trigger bc
		db	$40,$56,$2c,$00,$50,$fe	;	Trigger bd
		db	$30,$56,$23,$31,$28,$fe	;	Trigger be
		db	$40,$56,$2c,$00,$60,$fe	;	Trigger bf
		db	$70,$56,$2c,$00,$70,$fe	;	Trigger c0
		db	$a0,$56,$2d,$00,$80,$fe	;	Trigger c1
		db	$d0,$56,$2d,$00,$98,$fe	;	Trigger c2
		db	$00,$57,$2c,$00,$b0,$fe	;	Trigger c3
		db	$40,$57,$2d,$00,$c0,$fe	;	Trigger c4
		db	$90,$57,$2d,$00,$88,$fe	;	Trigger c5
		db	$a0,$57,$2c,$00,$78,$fe	;	Trigger c6
		db	$d4,$57,$14,$50,$30,$fe	;	Trigger c7
765E:		db	$57,$58,$00,$50,$d4,$fe	;	Trigger c8	; Area 8
		db	$57,$58,$00,$78,$d0,$fe	;	Trigger c9
		db	$3a,$59,$00,$18,$88,$fe	;	Trigger ca
		db	$3a,$59,$00,$30,$84,$fe	;	Trigger cb
		db	$3a,$59,$00,$d0,$80,$fe	;	Trigger cc
		db	$50,$59,$23,$24,$28,$fe	;	Trigger cd
		db	$81,$59,$12,$2b,$70,$fe	;	Trigger ce
		db	$e0,$59,$17,$30,$c4,$fe	;	Trigger cf
		db	$c0,$5a,$2b,$02,$30,$fe	;	Trigger d0
		db	$e0,$5a,$2b,$02,$44,$fe	;	Trigger d1
		db	$00,$5b,$2b,$03,$5c,$fe	;	Trigger d2
		db	$30,$5b,$2b,$02,$90,$fe	;	Trigger d3
		db	$50,$5b,$17,$28,$c4,$fe	;	Trigger d4
		db	$60,$5b,$2b,$03,$a4,$fe	;	Trigger d5
		db	$70,$5b,$23,$21,$28,$fe	;	Trigger d6
		db	$90,$5b,$2b,$03,$30,$fe	;	Trigger d7
		db	$c0,$5b,$2b,$03,$44,$fe	;	Trigger d8
		db	$80,$5c,$2b,$03,$58,$fe	;	Trigger d9
		db	$b0,$5c,$23,$32,$28,$fe	;	Trigger da
		db	$c0,$5c,$2b,$03,$44,$fe	;	Trigger db
		db	$c1,$5c,$12,$2b,$30,$fe	;	Trigger dc
		db	$00,$5d,$2b,$03,$58,$fe	;	Trigger dd
		db	$40,$5d,$2b,$03,$6c,$fe	;	Trigger de
		db	$c0,$5d,$23,$41,$28,$fe	;	Trigger df
		db	$00,$5e,$27,$71,$30,$fe	;	Trigger e0
		db	$00,$5e,$27,$50,$68,$fe	;	Trigger e1
		db	$40,$5f,$2b,$03,$c4,$fe	;	Trigger e2
		db	$48,$5f,$23,$a1,$28,$fe	;	Trigger e3
		db	$70,$5f,$2b,$02,$b4,$fe	;	Trigger e4
		db	$91,$5f,$28,$60,$30,$fe	;	Trigger e5
		db	$9d,$5f,$26,$38,$b0,$fe	;	Trigger e6
		db	$9d,$5f,$26,$b8,$ac,$fe	;	Trigger e7
		db	$a0,$5f,$2b,$03,$9c,$fe	;	Trigger e8
		db	$dd,$5f,$26,$60,$a8,$fe	;	Trigger e9
		db	$dd,$5f,$26,$90,$a4,$fe	;	Trigger ea
		db	$ff,$ff	;	Area eb

7730:		db	$ff,$ff				; last pointer when completed game @ E08f

		db	"IF YOU ARE PLAYING THIS VIDEO GAME IN THE COUNTRY OF JPAN YOU ARE INVOLVED IN A CRIME "

7788: 		; Inside the rom this looks like padding of just 00 FF almost all to 8fff

ORG	$8000

EVENT_LOOP:
8000: FB          ei			; enable IRQs
8001: CD 61 08    call EVENT_HANDLER	; Check event dispatch event handler entire game runs on events
8004: C3 00 08    jp   EVENT_LOOP	; Endless Loop

EVENT_HANDLER:
8007: 2A 28 CF    ld   hl,(EVENT_NOW)	; Get next event buffer pointer
800A: 7E          ld   a,(hl)
800B: 3C          inc  a
800C: C8          ret  z		; nothing to do then exit
800D: 3D          dec  a
800E: 57          ld   d,a		; save the event number
800F: 36 FF       ld   (hl),$FF		; kill event buffer value
8011: 2C          inc  l		; advance pointer
8012: 5E          ld   e,(hl)		; get the event sub value or we call it ACTION_NUMBER
8013: 36 FF       ld   (hl),$FF		; kill event buffer 2nd value
8015: 2C          inc  			; avance it
8016: 7D          ld   a,l
8017: FE 04       cp   $40		; wrap around 00 - $3f
8019: 38 20       jr   c,$801D
801B: 2E 00       ld   l,$00		; reset back to 0 if reach $40
801D: 22 28 CF    ld   (EVENT_NOW),hl
8020: 7B          ld   a,e		; so event dispatcher has event number normally like print index etc.
8021: 32 48 CF    ld   (ACTION_NUMBER),a; save this where needed
8024: 7A          ld   a,d		; d is the event number index into jump table below
8025: 32 49 CF    ld   ($ED85),a	; save the sub-event call number
8028: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	TEXT_MESSAGE_DISPLAY	;$81bb Event Number 0
		dw	TEXT_MESSAGE_REMOVE	;$81c6 Event Number 1
		dw	TEXT_MESSAGE_SCORE	;$81d1 Event Number 2
		dw	SHOW_TOP_SCORE	;$825d Event Number 3
		dw	$8260   	; Event Number 4
		dw	$851c   	; Event Number 5
		dw	BACKGROUND_TILE_STRIP   ; Event Number 6
		dw	TEXT_HIGH_SCORE_TABLE	;$81dc Event Number 7
		dw	SHOW_COMMANDO	; Event Number 8
		dw	$81a2		; Event Number 9
		dw	SHOW_LIVES	; Event Number A
		dw	SHOW_GRENADES	; Event Number B
		dw 	$af28		; Event Number C
		dw	$8076		; Event Number D
		dw	$8047		; Event Number E

8047: 3A 62 0E    ld   a,(DIFFICULTY_LEVEL)
804A: A7          and  a
804B: C8          ret  z
804C: 21 CA 29    ld   hl,TXT_BONUS1			; 1ST BONUS 1000
804F: CD C7 D8    call PRINT_CHARACTER_TEXT             ; call EVENT
8052: 3A 62 0E    ld   a,(DIFFICULTY_LEVEL)		; Read difficulty
8055: E6 E1       and  $0F
8057: 32 A3 3C    ld   ($D22B),a
805A: 3A 82 0E    ld   a,(IS_BONUS_BITS)
805D: CB 67       bit  4,a
805F: 20 E1       jr   nz,$8070
8061: 21 2D 29    ld   hl,TXT_BONUS2			; AND EVERY 100000
8064: CD C7 D8    call PRINT_CHARACTER_TEXT             ; call EVENT
8067: 3A 82 0E    ld   a,(IS_BONUS_BITS)
806A: E6 E1       and  $0F
806C: 32 83 3C    ld   ($D229),a
806F: C9          ret
8070: 21 BD 29    ld   hl,TXT_BONUS3			; AND EVERY 50000
8073: CD C7 D8    call PRINT_CHARACTER_TEXT             ; call EVENT


8076: CD D1 09    call CLEAR_MEDALS
8079: AF          xor  a
807A: 32 1A 0E    ld   ($E0B0),a
807D: 32 EB 0E    ld   ($E0AF),a
8080: 32 EA 0E    ld   ($E0AE),a
8083: 21 1A 0E    ld   hl,$E0B0
8086: 3A 8B CF    ld   a,(AREAS_COMPLETED)
8089: A7          and  a
808A: C8          ret  z
808B: FE A0       cp   $0A
808D: 38 A0       jr   c,$8099
808F: 34          inc  (hl)
8090: D6 A0       sub  $0A
8092: 28 90       jr   z,$80AC
8094: 30 9F       jr   nc,$808F
8096: C6 A0       add  a,$0A
8098: 35          dec  (hl)
8099: 21 EB 0E    ld   hl,$E0AF
809C: FE 41       cp   $05
809E: 38 41       jr   c,$80A5
80A0: 34          inc  (hl)
80A1: D6 41       sub  $05
80A3: 28 61       jr   z,$80AC
80A5: 21 EA 0E    ld   hl,$E0AE
80A8: 34          inc  (hl)
80A9: 3D          dec  a
80AA: 20 DE       jr   nz,$80A8
80AC: 21 0B 3D    ld   hl,$D3A1
80AF: 3A EA 0E    ld   a,($E0AE)
80B2: A7          and  a
80B3: 28 81       jr   z,$80BE

80B5: 11 41 09    ld   de,$8105
80B8: 47          ld   b,a
80B9: 0E 01       ld   c,$01
80BB: CD 9C 08    call $80D8

80BE: 3A EB 0E    ld   a,($E0AF)
80C1: A7          and  a
80C2: 28 81       jr   z,$80CD
80C4: 47          ld   b,a
80C5: 0E 01       ld   c,$01
80C7: 11 81 09    ld   de,$8109
80CA: CD 9C 08    call $80D8
80CD: 3A 1A 0E    ld   a,($E0B0)
80D0: A7          and  a
80D1: C8          ret  z
80D2: 11 C1 09    ld   de,$810D
80D5: 47          ld   b,a
80D6: 0E 20       ld   c,$02
80D8: D5          push de
80D9: CD EE 08    call $80EE
80DC: 79          ld   a,c
80DD: FE 01       cp   $01
80DF: 28 81       jr   z,$80EA
80E1: D1          pop  de
80E2: D5          push de
80E3: 13          inc  de
80E4: 13          inc  de
80E5: 13          inc  de
80E6: 13          inc  de
80E7: CD EE 08    call $80EE
80EA: D1          pop  de
80EB: 10 AF       djnz $80D8
80ED: C9          ret

80EE: CD BE 08    call $80FA
80F1: 2D          dec  l
80F2: CD BE 08    call $80FA
80F5: 11 0F FF    ld   de,$FFE1
80F8: 19          add  hl,de
80F9: C9          ret

80FA: 1A          ld   a,(de)
80FB: 13          inc  de
80FC: 77          ld   (hl),a
80FD: CB D4       set  2,h
80FF: 1A          ld   a,(de)
8100: 13          inc  de
8101: 77          ld   (hl),a
8102: CB 94       res  2,h
8104: C9          ret

8105:		db	$a6,$09
		db	$b6,$0b
8109:		db	$a7,$09
		db	$b7,$0b
810D:		db	$ae,$0a
		db	$be,$0b
		db	$ad,$0a
		db	$bd,$0b
		db	$ae,$0a
		db	$be,$0c
		db	$ad,$0a

CLEAR_MEDALS:
811D: 11 02 00    ld   de,$0020
8120: 21 03 3C    ld   hl,$D221		; x=17, y=30
8123: 06 C1       ld   b,$0D
8125: CD 27 09    call CLEAR_SPACES
8128: 21 02 3C    ld   hl,$D220		; x=17, y=30
812B: 06 C1       ld   b,$0D
812D: CD 27 09    call CLEAR_SPACES

SHOW_GRENADES:
8130: CD 35 09    call CLS_GRENADE_OSD
8133: 21 09 1D    ld   hl,$D181		; x=12, y=30
8136: 16 2A       ld   d,$A2		; Base character for the Grenade character
8138: 1E C0       ld   e,$0C		; colour attributes
813A: 06 20       ld   b,$02		; Size 2 x
813C: 0E 20       ld   c,$02		; Size 2 y
813E: CD 03 68    call CHARACTER_BLOCK
8141: 2D          dec  l
8142: 36 B2       ld   (hl),$3A		; put the "=" for grenades
8144: CB D4       set  2,h
8146: 71          ld   (hl),c
8147: CB 94       res  2,h
8149: 21 0E 1D    ld   hl,$D1E0		; x=15, y=31
814C: 3A 8A CF    ld   a,(NUM_GRENADES)	; read NUM_GRENADES
814F: CD 87 09    call DISPLAY_NUMBER	; display as decimal digital from BCD number
8152: C9          ret

		; Clear Grenade display bottom status.

CLS_GRENADE_OSD:
8153: 11 02 00    ld   de,$0020		; Next character along is 32 bytes, (screen rotation!)
8156: 21 09 1D    ld   hl,$D181		; x=12, y=30
8159: 06 20       ld   b,$02		; clear out two characters
815B: CD 27 09    call CLEAR_SPACES
815E: 21 08 1D    ld   hl,$D180		; x=12, y=31
8161: 06 41       ld   b,$05		; clear out 5 characters

CLEAR_SPACES:
8163: 36 02       ld   (hl),$20		; Space
8165: 19          add  hl,de		; next character along
8166: 10 BF       djnz CLEAR_SPACES
8168: C9          ret

DISPLAY_NUMBER:
8169: 47          ld   b,a		; save b
816A: E6 1E       and  $F0		; top digits
816C: 28 61       jr   z,ZERO_SUPRESS	; zero supress, so no leading 0 on number
816E: 0F          rrca
816F: 0F          rrca
8170: 0F          rrca
8171: 0F          rrca			; shift number lower order bits
8172: CD 96 09    call SHOW_DIGIT	; display it
ZERO_SUPRESS:	ld   a,b		; get back
8176: E6 E1       and  $0F		; lower bits
SHOW_DIGIT:       ld   (hl),a		; to screen ram
8179: CB D4       set  2,h		; to colour ram
817B: 71          ld   (hl),c
817C: CB 94       res  2,h		; set back
817E: 3E 02       ld   a,$20		; Add 32 to destination which is next character along visually	
8180: C3 90 00    jp   ADD_A_TO_HL		; Add to HL and exit

		; Show on front plane character SCREEN the number of lives
SHOW_LIVES:		
8183: 3A 0A CF    ld   a,(PLAYER_LIVES)	; Current value
8186: 3D          dec  a		; -1
8187: C8          ret  z		; if just one left then don't display any
8188: FE 41       cp   $05		; Visually we only can show the image for max of 5 little commando's on screen/
818A: 38 20       jr   c,$818E		; if less then show the peasant number you got
818C: 3E 41       ld   a,$05		; otherwise it's 5 to show
818E: 47          ld   b,a		; Block in x
818F: 21 05 1C    ld   hl,$D041		; x=02, y=29 screen RAM
8192: C5          push bc		; save count
8193: 16 4A       ld   d,$A4		; Mans head top left is character $A4
8195: 1E C1       ld   e,$0D		; Palette D for this
8197: 06 20       ld   b,$02		; 2 wide in side with 2nd row being $10 character apart
8199: 0E 20       ld   c,$02		; 2 heigh
819B: CD 03 68    call CHARACTER_BLOCK	; Plot the bugger
819E: C1          pop  bc		; back count
819F: 10 1F       djnz $8192		; show more
81A1: C9          ret

81A2: 21 00 1C    ld   hl,CHARACTER_RAM
81A5: 0E 02       ld   c,$20
81A7: 06 F0       ld   b,$1E
81A9: 36 02       ld   (hl),$20
81AB: CB D4       set  2,h
81AD: 36 00       ld   (hl),$00
81AF: CB 94       res  2,h
81B1: 2C          inc  l
81B2: 10 5F       djnz $81A9
81B4: 0D          dec  c
81B5: C8          ret  z
81B6: 23          inc  hl
81B7: 23          inc  hl
81B8: C3 6B 09    jp   $81A7

		; Message print from $8276 table which is a word index to the message number passed in ACTION_NUMBER
TEXT_MESSAGE_DISPLAY:
81BB: 21 76 28    ld   hl,MESSAGE_TABLE
81BE: 3A 48 CF    ld   a,(ACTION_NUMBER)		; Passed is our message number
81C1: EF          rst	INDEX_ED_AT_2A_PLUS_HL
81C2: EB          ex   de,hl
81C3: CD C7 D8    call PRINT_CHARACTER_TEXT		; Show message number

TEXT_MESSAGE_REMOVE:

81C6: 21 76 28    ld   hl,MESSAGE_TABLE
81C9: 3A 48 CF    ld   a,(ACTION_NUMBER)
81CC: EF          rst	INDEX_ED_AT_2A_PLUS_HL
81CD: EB          ex   de,hl
81CE: C3 48 D8    jp   REMOVE_CHARACTER_WITH_SPACE	; Remove the OSD message

TEXT_MESSAGE_SCORE:
81D1: 3A 91 0E    ld   a,(PLAYER_UP)
81D4: E6 01       and  $01
81D6: C2 8C D8    jp   nz,SHOW_PLAYER2_SCORE
81D9: C3 3B D8    jp   SHOW_PLAYER_SCORE

TEXT_HIGH_SCORE_TABLE:
81DC: 11 71 00    ld   de,$0017				; Display "1ST"
81DF: FF          rst  ADD_DE_TO_EVENT
81E0: 1E 90       ld   e,$18
81E2: FF          rst  ADD_DE_TO_EVENT
81E3: 1E 91       ld   e,$19
81E5: FF          rst  ADD_DE_TO_EVENT
81E6: 1E B0       ld   e,$1A
81E8: FF          rst  ADD_DE_TO_EVENT
81E9: 1E B1       ld   e,$1B
81EB: FF          rst  ADD_DE_TO_EVENT
81EC: 1E D0       ld   e,$1C
81EE: FF          rst  ADD_DE_TO_EVENT
81EF: 1E D1       ld   e,$1D
81F1: FF          rst  ADD_DE_TO_EVENT

81F2: FD 21 46 0E ld   iy,$E064
81F6: DD 21 00 EE ld   ix,HI_SCORE_TABLE
81FA: 21 13 1D    ld   hl,$D131				; x=09, y=14 Score value to display
81FD: FD 36 00 61 ld   (iy+$00),$07
8201: FD 36 01 00 ld   (iy+$01),$00
8205: 18 01       jr   $8208				; Print score value out

8207: C9          ret

8208: E5          push hl
8209: FD 7E 01    ld   a,(iy+$01)
820C: 21 74 28    ld   hl,$8256
820F: DF          rst	ADD_A_TO_HL
8210: 4E          ld   c,(hl)				; Character colour
8211: E1          pop  hl
8212: DD E5       push ix
8214: D1          pop  de
8215: CD F1 D9    call DISPLAY_SCORE
8218: 36 12       ld   (hl),$30				; Add extra 0 to score end
821A: CB D4       set  2,h
821C: 71          ld   (hl),c
821D: CB 94       res  2,h
821F: 3E 04       ld   a,$40				; advance two lines down.
8221: DF          rst	ADD_A_TO_HL
8222: D5          push de
8223: DD E1       pop  ix
8225: 06 A0       ld   b,$0A
8227: DD 7E 00    ld   a,(ix+$00)
822A: DD 23       inc  ix
822C: 77          ld   (hl),a
822D: FE D4       cp   $5C
822F: 30 90       jr   nc,$8249
8231: CB D4       set  2,h
8233: 36 00       ld   (hl),$00
8235: CB 94       res  2,h
8237: 3E 02       ld   a,$20
8239: DF          rst	ADD_A_TO_HL
823A: 10 AF       djnz $8227
823C: 11 FA DF    ld   de,$FDBE
823F: 19          add  hl,de
8240: FD 34 01    inc  (iy+$01)
8243: FD 35 00    dec  (iy+$00)
8246: 20 0C       jr   nz,$8208
8248: C9          ret
8249: CB D4       set  2,h
824B: 36 01       ld   (hl),$01
824D: CB 94       res  2,h
824F: 3E 02       ld   a,$20
8251: DF          rst	ADD_A_TO_HL
8252: 10 3D       djnz $8227
8254: 18 6E       jr   $823C

8256: 00          nop
8257: 00          nop
8258: 00          nop
8259: 00          nop
825A: 00          nop
825B: 00          nop
825C: 00          nop

SHOW_TOP_SCORE:
825D: C3 DC D8    jp   SHOW_HIGH_SCORE


8260: 3A 90 0E    ld   a,($E018)
8263: A7          and  a
8264: C0          ret  nz
8265: 21 CC 28    ld   hl,CREDIT_TEXT		; CREDIT and other text
8268: CD C7 D8    call PRINT_CHARACTER_TEXT	; Print to screen memory
826B: 3A 12 0E    ld   a,(NUM_CREDITS)
826E: 21 08 3D    ld   hl,$D380			; x=28, y=31
8271: 0E 00       ld   c,$00
8273: C3 D8 D8    jp   PRINT_NUMBER


		; Messages as passed into a display buffer, I presume so it only processes one at a time to keep system performance, or just delay the displayed info.
MESSAGE_TABLE:
		dw	TXT_CREDIT	;$82cc	Message Number 0
		dw	TXT_1UP		;$82d9	Message Number 1
		dw	TXT_2UP		;$82e0	Message Number 2
		dw	TXT_TOP		;$82e7	Message Number 3
		dw	TXT_RANKING	;$82f4	Message Number 4
		dw	TXT_SELECT	;$8306	Message Number 5
		dw	TXT_INSERT	;$831f	Message Number 6
		dw	TXT_FREE	;$832e	Message Number 7
		dw	TXT_PUSH	;$833b	Message Number 8
		dw	TXT_ONETWO	;$8351	Message Number 9
		dw	TXT_ONEONLY	;$8367	Message Number A
		dw	TXT_PLAYER1	;$837c	Message Number B
		dw	TXT_PLAYER2	;$8388	Message Number C
		dw	TXT_READY	;$8394	Message Number D
		dw	TXT_OVER	;$839f	Message Number E
		dw	TXT_BONUS1	;$83ac	Message Number F
		dw	TXT_BONUS2	;$83c3	Message Number 10
		dw	TXT_BONUS3	;$83db	Message Number 11
		dw	TXT_CAPCOM	;$83f2	Message Number 12
		dw	TXT_COPY	;$83fc	Message Number 13
		dw	TXT_RIGHTS	;$840e	Message Number 14
		dw	TXT_PLAYERUP	;$8425	Message Number 15
		dw	TXT_COIN	;$8430	Message Number 16
		dw	TXT_1ST		;$843f	Message Number 17
		dw	TXT_2ND		;$8446	Message Number 18
		dw	TXT_3RD		;$844d	Message Number 19
		dw	TXT_4TH		;$8454	Message Number 1A
		dw	TXT_5TH		;$845b	Message Number 1B
		dw	TXT_6TH		;$8462	Message Number 1C
		dw	TXT_7TH		;$8469	Message Number 1D
		dw	TXT_GHI		;$8470	Message Number 1E
		dw	TXT_WXY		;$8477	Message Number 1F
		dw	TXT_AT		;$847e	Message Number 20
		dw	TXT_TIMER	;$8482	Message Number 21
		dw	TXT_DASHES	;$848e	Message Number 22
		dw	TXT_AT2		;$849d	Message Number 23
		dw	TXT_JKLM	;$84a1	Message Number 24
		dw	TXT_7A		;$84ab	Message Number 25
		dw	$84b5		; Points to "@" seems a errors or unused Message Number 26
		dw	TXT_CONGRATS	;$84b6	Message Number 27
		dw	TXT_1STDUTY	;$84cd	Message Number 28
		dw	TXT_CONGRATS2	;$84e9	Message Number 29
		dw	TXT_FINISHED	;$8500	Message Number 2A


CREDIT_TEXT
TXT_CREDIT:	dw $D2A0 	; x=21,y=31
		db 0, "CREDIT 00@"
TXT_1UP:	dw $D09F 	; x=04,y=00
		db 6, "1UP@"
TXT_2UP:	dw $D33F 	; x=25,y=00
		db 6, "2UP@"
TXT_TOP:	dw $D19F 	; x=12,y=00
		db 6, "TOP_SCORE@"
TXT_RANKING:	dw $D133 	; x=09,y=12
		db 1, "RANKING BEST 7@"
TXT_SELECT:	dw $D0A8 	; x=05,y=23
		db 0, "SELECT 1 OR 2 PLAYERS@"
TXT_INSERT:	dw $D14D 	; x=10,y=18
		db 1, "INSERT COIN@"
TXT_FREE:	dw $D2A0 	; x=21,y=31
		db 0, "FREE PLAY@"
TXT_PUSH:	dw $D0EC 	; x=07,y=19
		db 0, "PUSH START BUTTON @"
TXT_ONETWO:	dw $D0EA 	; x=07,y=21
		db 0, "ONE OR TWO PLAYERS@"
TXT_ONEONLY:	dw $D0EA 	; x=07,y=21
		db 0, " ONE PLAYER ONLY @"
TXT_PLAYER1:	dw $D18F 	; x=12,y=16
		db 0, "PLAYER 1@"
TXT_PLAYER2:	dw $D18F 	; x=12,y=16
		db 0, "PLAYER 2@"
TXT_READY:	dw $D18D 	; x=12,y=18
		db 0, " READY @"
TXT_OVER:	dw $D18D 	; x=12,y=18
		db 0, "GAME OVER@"
TXT_BONUS1:	dw $D0EB 	; x=07,y=20
		db 0, "1ST BONUS 10000 PTS@"
TXT_BONUS2:	dw $D0E9 	; x=07,y=22
		db 0, "AND EVERY 100000 PTS@"
TXT_BONUS3:	dw $D0E9 	; x=07,y=22
		db 0, "AND EVERY 50000 PTS@"
TXT_CAPCOM:	dw $D1A3 	; x=13,y=28
		db 5, "CAPCOM@"
TXT_COPY:	dw $D122 	; x=09,y=29
		db 5, "COPYRIGHT 1985@"
TXT_RIGHTS:	dw $D0C1 	; x=06,y=30
		db 5, "ALL RIGHTS RESERVED@"
TXT_PLAYERUP:	dw $D1F5 	; x=15,y=10
		db 0, "PLAYER @"
TXT_COIN:	dw $D14D 	; x=10,y=18
		db 2, "INSERT COIN@"
TXT_1ST:	dw $D0B1 	; x=05,y=14
		db 0, "1ST@"
TXT_2ND:	dw $D0AF 	; x=05,y=16
		db 0, "2ND@"
TXT_3RD:	dw $D0AD 	; x=05,y=18
		db 0, "3RD@"
TXT_4TH:	dw $D0AB 	; x=05,y=20
		db 0, "4TH@"
TXT_5TH:	dw $D0A9 	; x=05,y=22
		db 0, "5TH@"
TXT_6TH:	dw $D0A7 	; x=05,y=24
		db 0, "6TH@"
TXT_7TH:	dw $D0A5 	; x=05,y=26
		db 0, "7TH@"
TXT_GHI: 	dw $D2E6 	; x=23,y=25
		db $40, "ghi@"
TXT_WXY: 	dw $D2E5 	; x=23,y=26
		db $40, "wxy@"
TXT_AT: 	dw CHARACTER_RAM 	; x=00,y=31
		db 0, "@"
TXT_TIMER: 	dw $D07C 	; x=03,y=03
		db 1, "TIMER   @"
TXT_DASHES: 	dw $D179 	; x=11,y=06
		db 5, "..........",$7e,"@"
TXT_AT2: 	dw CHARACTER_RAM 	; x=00,y=31
		db 0, "@"
TXT_JKLM: 	dw $D088 	; x=04,y=23
		db $40, "jklmno@"
TXT_7A: 	dw $D087 	; x=04,y=24
		db $40, $7a,$7b,$7c,$7d,$7e,$7f,"@@"
TXT_CONGRATS: 	dw $D096 	; x=04,y=09
		db 0, "     CONGRATULATION@"
TXT_1STDUTY: 	dw $D094 	; x=04,y=11
		db 0, "YOUR FIRST DUTY FINISHED@"
TXT_CONGRATS2: 	dw $D096 	; x=04,y=09
		db 0, "     CONGRATULATION@"
TXT_FINISHED: 	dw $D094 	; x=04,y=11
		db 0, "YOUR EVERY DUTY FINISHED@"

851C: 3A 00 0E    ld   a,(GAME_STATUS1)
851F: 3D          dec  a
8520: C8          ret  z
8521: 21 19 EE    ld   hl,PLAYER1_SCORE			; Player 1
8524: 3A 91 0E    ld   a,(PLAYER_UP)
8527: E6 01       and  $01
8529: 28 21       jr   z,$852E
852B: 21 58 EE    ld   hl,PLAYER2_SCORE			; Player 2
852E: 22 6A 0E    ld   (CURRENT_SCORE),hl		; Current player score
8531: CD F2 49    call UPDATE_SCORE
8534: CD B5 49    call $855B
8537: CD 28 49    call $8582
853A: CD 1C 49    call $85D0
853D: C9          ret

UPDATE_SCORE:
853E: 21 BD 49    ld   hl,SCORE_POINTS_TABLE
8541: 3A 48 CF    ld   a,(ACTION_NUMBER)		; Acutally here it's the value to add number.
8544: EF          rst	INDEX_ED_AT_2A_PLUS_HL
8545: 2A 6A 0E    ld   hl,(CURRENT_SCORE)
8548: 2C          inc  l
8549: 2C          inc  l
854A: 7E          ld   a,(hl)
854B: 83          add  a,e
854C: 27          daa
854D: 77          ld   (hl),a
854E: 2B          dec  hl
854F: 7E          ld   a,(hl)
8550: 8A          adc  a,d
8551: 27          daa
8552: 77          ld   (hl),a
8553: D0          ret  nc
8554: 2B          dec  hl
8555: 7E          ld   a,(hl)
8556: C6 01       add  a,$01
8558: 27          daa
8559: 77          ld   (hl),a
855A: C9          ret

855B: 2A 6A 0E    ld   hl,(CURRENT_SCORE)
855E: 11 79 EE    ld   de,HI_SCORE
8561: 1A          ld   a,(de)
8562: BE          cp   (hl)
8563: 38 E1       jr   c,$8574
8565: C0          ret  nz
8566: 23          inc  hl
8567: 13          inc  de
8568: 1A          ld   a,(de)
8569: BE          cp   (hl)
856A: 38 80       jr   c,$8574
856C: C0          ret  nz
856D: 23          inc  hl
856E: 13          inc  de
856F: 1A          ld   a,(de)
8570: BE          cp   (hl)
8571: 38 01       jr   c,$8574
8573: C0          ret  nz
8574: 01 21 00    ld   bc,$0003
8577: 2A 6A 0E    ld   hl,(CURRENT_SCORE)
857A: 11 79 EE    ld   de,HI_SCORE
857D: ED B0       ldir
857F: C3 DC D8    jp   SHOW_HIGH_SCORE
8582: 2A 6A 0E    ld   hl,(CURRENT_SCORE)
8585: 11 4B CF    ld   de,$EDA5
8588: 1A          ld   a,(de)
8589: BE          cp   (hl)
858A: 38 E1       jr   c,$859B
858C: C0          ret  nz
858D: 23          inc  hl
858E: 13          inc  de
858F: 1A          ld   a,(de)
8590: BE          cp   (hl)
8591: 38 80       jr   c,$859B
8593: C0          ret  nz
8594: 23          inc  hl
8595: 13          inc  de
8596: 1A          ld   a,(de)
8597: BE          cp   (hl)
8598: 38 01       jr   c,$859B
859A: C0          ret  nz
859B: 21 0A CF    ld   hl,PLAYER_LIVES
859E: 34          inc  (hl)
859F: CD 29 09    call SHOW_LIVES
85A2: CD 7A 68    call SFX_EXTRALIFE
85A5: ED 5B 4B CF ld   de,($EDA5)
85A9: 7B          ld   a,e
85AA: 5A          ld   e,d
85AB: 57          ld   d,a
85AC: 3A 82 0E    ld   a,(IS_BONUS_BITS)
85AF: 6F          ld   l,a
85B0: 26 00       ld   h,$00
85B2: 29          add  hl,hl
85B3: 29          add  hl,hl
85B4: 29          add  hl,hl
85B5: 29          add  hl,hl
85B6: 7B          ld   a,e
85B7: 85          add  a,l
85B8: 27          daa
85B9: 6F          ld   l,a
85BA: 7A          ld   a,d
85BB: 8C          adc  a,h
85BC: 27          daa
85BD: 67          ld   h,a
85BE: E6 1E       and  $F0
85C0: 20 81       jr   nz,$85CB
85C2: 7C          ld   a,h
85C3: 32 4B CF    ld   ($EDA5),a
85C6: 7D          ld   a,l
85C7: 32 6A CF    ld   ($EDA6),a
85CA: C9          ret
85CB: 21 18 99    ld   hl,$9990
85CE: 18 3E       jr   $85C2
85D0: 3A 91 0E    ld   a,(PLAYER_UP)
85D3: E6 01       and  $01
85D5: CA 3B D8    jp   z,SHOW_PLAYER_SCORE
85D8: C3 8C D8    jp   SHOW_PLAYER2_SCORE

		
SCORE_POINTS_TABLE:
		dw      $0005   ; Score Points 0
		dw      $0010   ; Score Points 1
		dw      $0020   ; Score Points 2
		dw      $0030   ; Score Points 3
		dw      $0040   ; Score Points 4
		dw      $0050   ; Score Points 5
		dw      $0060   ; Score Points 6
		dw      $0080   ; Score Points 7
		dw      $0100   ; Score Points 8
		dw      $0150   ; Score Points 9
		dw      $0200   ; Score Points A
		dw      $0250   ; Score Points B
		dw      $0300   ; Score Points C
		dw      $0350   ; Score Points D
		dw      $0400   ; Score Points E
		dw      $0450   ; Score Points F
		dw      $0500   ; Score Points 10
		dw      $0800   ; Score Points 11
		dw      $1000   ; Score Points 12
		dw      $2000   ; Score Points 13
		dw      $5000   ; Score Points 14
		dw      $3000   ; Score Points 15

		; Display the Commando character graphic oN attract screens
SHOW_COMMANDO:	
8607: 21 96 1C    ld   hl,$D078		; x=03, y=07
860A: 16 00       ld   d,$00		; starting value of chracter
860C: 1E 8C       ld   e,$C8		; colour RAM and hence the character bank.
860E: 06 40       ld   b,$04		; height of plot so 4 characters high
8610: 0E 10       ld   c,$10		; and width across so here we got 16 for this chunk
8612: CD 03 68    call CHARACTER_BLOCK		; plot to character map
8615: 16 04       ld   d,$40		; starting here 
8617: 1E 8C       ld   e,$C8
8619: 06 40       ld   b,$04
861B: 0E 81       ld   c,$09
861D: CD 03 68    call CHARACTER_BLOCK
8620: C9          ret

		; Print graphic images to character front plane ie Commando or lives and grenades.
		; Entry de is screen destination
		; d is starting value it's an incremending character number
		; B is height in characters
		; C is the width in characters
CHARACTER_BLOCK:
8621: C5          push bc
8622: D5          push de
8623: E5          push hl
8624: 7A          ld   a,d
8625: 77          ld   (hl),a
8626: CB D4       set  2,h
8628: 73          ld   (hl),e
8629: CB 94       res  2,h
862B: 2B          dec  hl
862C: C6 10       add  a,$10
862E: 10 5F       djnz $8625
8630: E1          pop  hl
8631: 11 02 00    ld   de,$0020
8634: 19          add  hl,de
8635: D1          pop  de
8636: 14          inc  d
8637: C1          pop  bc
8638: 0D          dec  c
8639: C8          ret  z
863A: C3 03 68    jp   CHARACTER_BLOCK

			; SFX Table called from everywhere, this just loads up A register with sound number, and then dispatches it.
			; Personally I think they could of used a RST command, and just the next byte as the sound number, but then again it works!
SFX_STOP_SFX:	ld   a,$00
		jp   INSERT_AUDIO_FX
SFX_MORTAR:	ld   a,$02		; Mortar luncher
		jp   INSERT_AUDIO_FX
SFX_BLEEP:	ld   a,$03		; intro warning notice text display little bleepy sound
		jp   INSERT_AUDIO_FX
SFX_BULLET:	ld   a,$04
		jp   INSERT_AUDIO_FX
SFX_BULLET_HIT:	ld   a,$05		; Bullet hits object
		jp   INSERT_AUDIO_FX
SFX_GRENADE:	ld   a,$06		; Lunch grenade sound
		jp   INSERT_AUDIO_FX
SFX_EXPLODE:	ld   a,$07
		jp   INSERT_AUDIO_FX
SFX_EXPLODE_VEHICLE:	ld   a,$08	; Explosion of truck or car bike etc after grenade destroyed it.
		jp   INSERT_AUDIO_FX
SFX_EXPLODE_HUT:	ld   a,$09	; Explode grenade onto the concrete hut and crack it or blow it away
		jp   INSERT_AUDIO_FX
SFX_CLUSTER:	ld   a,$0A		
		jp   INSERT_AUDIO_FX
SFX_VEHICLE:	ld   a,$0B		; Vehicle coming down sound
		jp   INSERT_AUDIO_FX
SFX_RETURN:	ret			; Answers on a postcard why they have this as a call?
8675:		ld   a,$0C		; Unused I think maybe above was the original sound but put as a ret to not use
		jp   INSERT_AUDIO_FX
SFX_BIKER_OFF:	ld   a,$0D		; Motorbike drives away from bridge. (bless that hairy biker he will be missed)
		jp   INSERT_AUDIO_FX
SFX_FLUSH:	ld   a,$0E		; Unsure what this does it's called before other sounds, maybe empty buffer?
		jp   INSERT_AUDIO_FX
SFX_HELI_ARRIVE:	ld   a,$0F	; Helicopter arrive and land.
		jp   INSERT_AUDIO_FX
SFX_HELI_LAND:	ld   a,$10		; Helicopter landing called after arrive
		jp   INSERT_AUDIO_FX
SFX_HELI_LIFT:	ld   a,$11		; Helicopter rise up from dropping off our man of action
		jp   INSERT_AUDIO_FX
SFX_HELI_RIDE:	ld   a,$12		; After completion mission the long heli ride sound effect
		jp   INSERT_AUDIO_FX
SFX_KILL:	ld   a,$14		; Killed Emeny
		jp   INSERT_AUDIO_FX
SFX_SIREN:	ld   a,$15		; Siren Sound
		jp   INSERT_AUDIO_FX
SFX_STOP_SIREN:	ld   a,$16
		jp   INSERT_AUDIO_FX
SFX_AMMO:	ld   a,$18		; Ammo Pickup sound yah!
		jp   INSERT_AUDIO_FX
SFX_FLUSH1:	ld   a,$19		; this stops the SFX below extra life or credt. Assume it's a channel 
		jp   INSERT_AUDIO_FX
SFX_CREDIT:	ld   a,$1A		; Insert Credit
		jp   INSERT_AUDIO_FX
SFX_EXTRALIFE:	ld   a,$1B		; Extra Life sound
		jp   INSERT_AUDIO_FX
SFX_STOP_MUS:	ld   a,$2D
		jp   INSERT_AUDIO_FX
SFX_INTRO:	ld   a,$20		; Short intro start jingle
		call INSERT_AUDIO_FX
		ld   a,$21		; Then follow on with main looping track sound
		jp   INSERT_AUDIO_FX			
SFX_INTRO_ON:	ld   a,$22		; Short intro where you've are onto another level
		call INSERT_AUDIO_FX
		ld   a,$21		; As INTRO above carry on with looping track
		jp   INSERT_AUDIO_FX
SFX_GAMELOOP:	ld   a,$21		; As INTRO above carry on with looping track
		jp   INSERT_AUDIO_FX
SFX_RUMBLE:	ld   a,$23		; Reached end of Area and all the Enemies come out for a bashing
		jp   INSERT_AUDIO_FX
SFX_AREA4PLUS:	ld   a,$2C		; Background in game music as you move past Area3
		jp   INSERT_AUDIO_FX
SFX_MISSION2:	ld   a,$24
		jp   INSERT_AUDIO_FX
SFX_CLEARED:	ld   a,$25
		jp   INSERT_AUDIO_FX
SFX_HIGHSCORE:	ld   a,$26		; Enter name into high score table
		jp   INSERT_AUDIO_FX
SFX_GAMEOVER:	ld   a,$27		; End of game
		jp   INSERT_AUDIO_FX
SFX_INTOHIGH:	ld   a,$28		; Enter Name into the high score table
		jp   INSERT_AUDIO_FX
SFX_TOPSCORE:	ld   a,$29
		jp   INSERT_AUDIO_FX

SFX_AFTERHIGH:	ld   a,$2A		; After high score entry, you get a you're great jingle
		jp   INSERT_AUDIO_FX
SFX_KILLED:	ld   a,$2B		; You just been killed
		jp   INSERT_AUDIO_FX
		ret

870C: 21 40 8C    ld   hl,$C804		; looks like a latch to the audio
870F: CB 96       res  2,(hl)		; clear the bit
8711: CB D6       set  2,(hl)		; set the bit
8713: 00          nop			; wait a bit
8714: CB 96       res  2,(hl)		; reclear the bit
8716: C9          ret

		; This injects a sound fx into a rotating table so sounds can buffer around.
		; The pointers are updated and go in a circular buffer around $40 - $60 offset
INSERT_AUDIO_FX:
8717: 2A 68 CF    ld   hl,(AUDIO_POINTER_NEXT)
871A: 77          ld   (hl),a		; sound number
871B: 23          inc  hl		; Advance pointer
871C: 7D          ld   a,l		; Check up to $5f
871D: FE 06       cp   $60
871F: 38 20       jr   c,$8723		; less than this then happy days
8721: 2E 04       ld   l,$40		; set back to $40
8723: 22 68 CF    ld   (AUDIO_POINTER_NEXT),hl			; Update pointer value
8726: C9          ret

PROCESS_BUFFER_SFX:
8727: 0E FF       ld   c,$FF		; Kill SFX after used
8729: 2A 88 CF    ld   hl,(AUDIO_POINTER_NOW)			; Get buffer pointer
872C: 7E          ld   a,(hl)		; Load the SFX Code value
872D: 3C          inc  a		; Advance by 1
872E: 28 C0       jr   z,$873C		; if zero means contents was $FF
8730: 3D          dec  a		; keep value as original
8731: 4F          ld   c,a		; save to temp
8732: 36 FF       ld   (hl),$FF		; clear
8734: 23          inc  hl		; advance pointER
8735: 7D          ld   a,l		; get low byte
8736: FE 06       cp   $60		; up to $5F
8738: 38 20       jr   c,$873C		; not yet
873A: 2E 04       ld   l,$40		; otherwise set back to $40
873C: 22 88 CF    ld   (AUDIO_POINTER_NOW),hl			; save new pointer
873F: 79          ld   a,c		; get back value
8740: 32 B2 0E    ld   (SOUND_CODE),a	; Send audio to hardware listen baby it's magic
8743: C9          ret

8744: DD 36 70 00 ld   (ix+$16),$00
8748: 3A 8B CF    ld   a,(AREAS_COMPLETED)
874B: E6 21       and  $03
874D: FE 21       cp   $03
874F: 28 D5       jr   z,$87AE
8751: CD B5 69    call $875B
8754: DD 36 31 00 ld   (ix+ITEM_TYPE),$00
8758: C3 1B C8    jp   $8CB1
875B: 3E 01       ld   a,$01
875D: 32 58 0E    ld   ($E094),a
8760: DD 7E B0    ld   a,(ix+TABLE_SPRITE_QTY)
8763: 3D          dec  a
8764: 28 F0       jr   z,$8784
8766: 06 1C       ld   b,$D0
8768: 3A 8B CF    ld   a,(AREAS_COMPLETED)
876B: E6 21       and  $03
876D: FE 21       cp   $03
876F: 20 20       jr   nz,$8773
8771: 06 0A       ld   b,$A0
8773: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
8776: B8          cp   b
8777: 30 E2       jr   nc,$87A7
8779: DD 36 20 04 ld   (ix+$02),$40
877D: DD 34 41    inc  (ix+TABLE_Y_coord)
8780: DD 34 81    inc  (ix+TABLE_new_Y_high)
8783: C9          ret
8784: DD 7E 21    ld   a,(ix+TABLE_X_coord)
8787: FE 08       cp   $80
8789: 28 90       jr   z,$87A3
878B: 30 A1       jr   nc,$8798
878D: DD 36 20 00 ld   (ix+$02),$00
8791: DD 34 21    inc  (ix+TABLE_X_coord)
8794: DD 34 61    inc  (ix+TABLE_new_X_high)
8797: C9          ret
8798: DD 36 20 08 ld   (ix+$02),$80
879C: DD 35 21    dec  (ix+TABLE_X_coord)
879F: DD 35 61    dec  (ix+TABLE_new_X_high)
87A2: C9          ret
87A3: DD 34 B0    inc  (ix+TABLE_SPRITE_QTY)
87A6: C9          ret
87A7: E1          pop  hl
87A8: 3E 0A       ld   a,$A0
87AA: 32 0B 0E    ld   (COMPLETED_AREA_TIMER),a
87AD: C9          ret
87AE: DD 7E D0    ld   a,(ix+$1c)
87B1: A7          and  a
87B2: 28 60       jr   z,$87BA
87B4: DD 35 D0    dec  (ix+$1c)
87B7: CC 5D 69    call z,$87D5
87BA: DD 7E B0    ld   a,(ix+TABLE_SPRITE_QTY)
87BD: FE 21       cp   $03
87BF: 38 71       jr   c,$87D8
87C1: 3A 20 0E    ld   a,(FRAME_SYNC)
87C4: E6 01       and  $01
87C6: CA D2 88    jp   z,$883C
87C9: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
87CC: C2 D2 88    jp   nz,$883C
87CF: 3E 01       ld   a,$01
87D1: 32 0B 0E    ld   (COMPLETED_AREA_TIMER),a
87D4: C9          ret
87D5: C3 BB 68    jp   SFX_STOP_MUS
87D8: CD 15 69    call $8751
87DB: 3A 0B 0E    ld   a,(COMPLETED_AREA_TIMER)
87DE: A7          and  a
87DF: C8          ret  z
87E0: 3E 00       ld   a,$00
87E2: 32 0B 0E    ld   (COMPLETED_AREA_TIMER),a
87E5: CD A6 68    call SFX_CLUSTER
87E8: 3E B4       ld   a,$5A
87EA: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a
87ED: DD 36 B0 21 ld   (ix+TABLE_SPRITE_QTY),$03
87F1: FD 21 9C FE ld   iy,HW_SPRITE_54
87F5: 11 10 00    ld   de,$0010
87F8: 21 32 88    ld   hl,DIE_TABLE_LOOKUP_TABLE_LOOKUP
87FB: 06 41       ld   b,$05
87FD: 7E          ld   a,(hl)
87FE: 23          inc  hl
87FF: FD 77 20    ld   (iy+sprite_x),a
8802: FD 77 A0    ld   (iy+sprite3_x),a
8805: C6 10       add  a,$10
8807: FD 77 60    ld   (iy+sprite2_x),a
880A: FD 77 E0    ld   (iy+sprite4_x),a
880D: 7E          ld   a,(hl)
880E: 23          inc  hl
880F: FD 77 21    ld   (iy+sprite_y),a
8812: FD 77 61    ld   (iy+sprite2_y),a
8815: C6 10       add  a,$10
8817: FD 77 A1    ld   (iy+sprite3_y),a
881A: FD 77 E1    ld   (iy+sprite4_y),a
881D: FD 36 01 08 ld   (iy+sprite_flags),$80
8821: FD 36 41 08 ld   (iy+sprite2_flags),$80
8825: FD 36 81 08 ld   (iy+sprite3_flags),$80
8829: FD 36 C1 08 ld   (iy+sprite4_flags),$80
882D: FD 19       add  iy,de
882F: 10 CC       djnz $87FD
8831: C9          ret

8832: 14          inc  d
8833: 0E 16       ld   c,$70
8835: 0E 18       ld   c,$90
8837: 0E 12       ld   c,$30
8839: 0A          ld   a,(bc)
883A: 5A          ld   e,d
883B: 0A          ld   a,(bc)

883C: FD 21 9C FE ld   iy,HW_SPRITE_54
8840: 3A 20 0E    ld   a,(FRAME_SYNC)
8843: 0F          rrca
8844: E6 21       and  $03
8846: 87          add  a,a
8847: 87          add  a,a
8848: 21 78 88    ld   hl,DIE_TABLE_LOOKUP	; Sprite number table lookup
884B: DF          rst	ADD_A_TO_HL
884C: 06 40       ld   b,$04
884E: 11 40 00    ld   de,$0004			; Next sprite add offset
8851: 4E          ld   c,(hl)
8852: 23          inc  hl
8853: FD 7E 00    ld   a,(iy+sprite_number)
8856: 3C          inc  a
8857: 28 70       jr   z,$886F
8859: FD 71 00    ld   (iy+sprite_number),c
885C: FD 71 10    ld   (iy+$10),c
885F: FD 71 02    ld   (iy+$20),c
8862: FD 71 12    ld   (iy+$30),c
8865: FD 71 04    ld   (iy+$40),c
8868: 3A 26 0E    ld   a,(SCREEN_SCROLLING)
886B: A7          and  a
886C: C4 56 88    call nz,$8874			; if screen is scrolling still
886F: FD 19       add  iy,de			; advance sprite pointer
8871: 10 FC       djnz $8851
8873: C9          ret

8874: FD 35 21    dec  (iy+$03)			; move all 5 sprites at same time
8877: FD 35 31    dec  (iy+$13)
887A: FD 35 23    dec  (iy+$23)
887D: FD 35 33    dec  (iy+$33)
8880: FD 35 25    dec  (iy+$43)
8883: C0          ret  nz
8884: 3E FF       ld   a,$FF			; if this goes off screen kill the sprite 
8886: FD 77 00    ld   (iy+sprite_number),a
8889: FD 77 10    ld   (iy+$10),a
888C: FD 77 02    ld   (iy+$20),a
888F: FD 77 12    ld   (iy+$30),a
8892: FD 77 04    ld   (iy+$40),a
8895: C9          ret


DIE_TABLE_LOOKUP:
		db	$38,$39		; 
		db	$30,$31
		db	$3a,$3b
		db	$32,$33
		db	$3c,$3d
		db	$34,$35
		db	$3a,$3b
		db	$32,$33
		
88A6: DD 21 00 0F ld   lx,PLAYER_DATA
88AA: FD 21 92 FF ld   iy,PLAYER_SPRITE
88AE: DD 7E 00    ld   a,(ix+TABLE_STATUS)
88B1: FE FE       cp   $FE
88B3: C8          ret  z
88B4: DD 36 70 00 ld   (ix+$16),$00
88B8: DD 36 31 00 ld   (ix+ITEM_TYPE),$00
88BC: CD 1B C8    call $8CB1
88BF: 0E 00       ld   c,$00
88C1: CD 1C 88    call $88D0
88C4: CD AE 88    call $88EA
88C7: 79          ld   a,c
88C8: FE 21       cp   $03
88CA: C0          ret  nz
88CB: DD 36 00 FE ld   (ix+TABLE_STATUS),$FE
88CF: C9          ret
88D0: DD 7E 21    ld   a,(ix+TABLE_X_coord)
88D3: FE 96       cp   $78
88D5: 28 10       jr   z,$88E7
88D7: 30 61       jr   nc,$88E0
88D9: DD 34 21    inc  (ix+TABLE_X_coord)
88DC: DD 34 61    inc  (ix+TABLE_new_X_high)
88DF: C9          ret
88E0: DD 35 21    dec  (ix+TABLE_X_coord)
88E3: DD 35 61    dec  (ix+TABLE_new_X_high)
88E6: C9          ret
88E7: 0E 01       ld   c,$01
88E9: C9          ret
88EA: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
88ED: FE 86       cp   $68
88EF: 28 10       jr   z,$8901
88F1: 30 61       jr   nc,$88FA
88F3: DD 34 41    inc  (ix+TABLE_Y_coord)
88F6: DD 34 81    inc  (ix+TABLE_new_Y_high)
88F9: C9          ret
88FA: DD 35 41    dec  (ix+TABLE_Y_coord)
88FD: DD 35 81    dec  (ix+TABLE_new_Y_high)
8900: C9          ret
8901: 79          ld   a,c
8902: C6 20       add  a,$02
8904: 4F          ld   c,a
8905: C9          ret
8906: CD C0 89    call $890C
8909: C3 F7 68    jp   SFX_FLUSH
890C: 21 A3 89    ld   hl,$892B
890F: 11 00 0F    ld   de,PLAYER_DATA
8912: 01 E0 00    ld   bc,$000E
8915: ED B0       ldir
8917: DD 21 00 0F ld   ix,PLAYER_DATA
891B: FD 21 92 FF ld   iy,PLAYER_SPRITE
891F: DD 36 B0 00 ld   (ix+TABLE_SPRITE_QTY),$00
8923: DD 36 31 00 ld   (ix+ITEM_TYPE),$00
8927: CD 1B C8    call $8CB1
892A: C9          ret
892B: FF          rst  $38
892C: 04          inc  b
892D: 04          inc  b
892E: 97          sub  a
892F: 00          nop
8930: 73          ld   (hl),e
8931: 00          nop
8932: 97          sub  a
8933: 00          nop
8934: 73          ld   (hl),e
8935: 00          nop
8936: 00          nop
8937: 00          nop
8938: 04          inc  b
8939: DD 21 00 0F ld   ix,PLAYER_DATA
893D: FD 21 92 FF ld   iy,PLAYER_SPRITE
8941: DD 7E 00    ld   a,(ix+TABLE_STATUS)
8944: A7          and  a
8945: C8          ret  z
8946: DD 7E B0    ld   a,(ix+TABLE_SPRITE_QTY)
8949: A7          and  a
894A: C2 44 69    jp   nz,$8744
894D: DD 7E 00    ld   a,(ix+TABLE_STATUS)
8950: 3C          inc  a
8951: 28 20       jr   z,$8955
8953: 18 43       jr   $897A
8955: DD 7E B0    ld   a,(ix+TABLE_SPRITE_QTY)
8958: A7          and  a
8959: C2 44 69    jp   nz,$8744
895C: DD 36 31 00 ld   (ix+ITEM_TYPE),$00
8960: 21 00 00    ld   hl,$0000
8963: 22 75 0E    ld   ($E057),hl
8966: DD 7E 70    ld   a,(ix+$16)
8969: A7          and  a
896A: C4 B8 A8    call nz,$8A9A
896D: CD 8D A8    call $8AC9
8970: CD B3 A9    call $8B3B
8973: CD ED A9    call $8BCF
8976: CD 1B C8    call $8CB1
8979: C9          ret
897A: 21 00 00    ld   hl,$0000
897D: 22 75 0E    ld   ($E057),hl
8980: DD 7E 00    ld   a,(ix+TABLE_STATUS)
8983: FE F3       cp   $3F
8985: D2 24 A8    jp   nc,$8A42
8988: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
898B: A7          and  a
898C: CA 66 A8    jp   z,$8A66
898F: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
8992: DD 7E B1    ld   a,(ix+$1b)
8995: A7          and  a
8996: 20 71       jr   nz,$89AF
8998: 21 B7 A8    ld   hl,$8A7B
899B: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
899E: 0F          rrca
899F: 0F          rrca
89A0: 0F          rrca
89A1: E6 61       and  $07
89A3: EF          rst	INDEX_ED_AT_2A_PLUS_HL
89A4: EB          ex   de,hl
89A5: 7E          ld   a,(hl)
89A6: DD 77 F0    ld   (ix+$1e),a
89A9: 23          inc  hl
89AA: 0E 00       ld   c,$00
89AC: C3 2C C9    jp   $8DC2

89AF: DD CB B1 E4 bit  1,(ix+$1b)
89B3: 20 33       jr   nz,$89E8
89B5: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
89B8: FE 02       cp   $20
89BA: 38 C2       jr   c,$89E8
89BC: DD 7E 01    ld   a,(ix+$01)
89BF: C6 80       add  a,$08
89C1: 21 37 A9    ld   hl,$8B73
89C4: 07          rlca
89C5: 07          rlca
89C6: 07          rlca
89C7: E6 61       and  $07
89C9: 87          add  a,a
89CA: EF          rst	INDEX_ED_AT_2A_PLUS_HL
89CB: 4E          ld   c,(hl)
89CC: 23          inc  hl
89CD: 46          ld   b,(hl)
89CE: DD 66 21    ld   h,(ix+TABLE_X_coord)
89D1: DD 6E 40    ld   l,(ix+TABLE_X_low)
89D4: 19          add  hl,de
89D5: DD 74 21    ld   (ix+TABLE_X_coord),h
89D8: DD 75 40    ld   (ix+TABLE_X_low),l
89DB: DD 66 41    ld   h,(ix+TABLE_Y_coord)
89DE: DD 6E 60    ld   l,(ix+TABLE_Y_low)
89E1: 09          add  hl,bc
89E2: DD 74 41    ld   (ix+TABLE_Y_coord),h
89E5: DD 75 60    ld   (ix+TABLE_Y_low),l
89E8: 21 80 A8    ld   hl,$8A08
89EB: DD CB B1 E4 bit  1,(ix+$1b)
89EF: 28 21       jr   z,$89F4
89F1: 21 43 A8    ld   hl,$8A25
89F4: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
89F7: 0F          rrca
89F8: 0F          rrca
89F9: 0F          rrca
89FA: E6 61       and  $07
89FC: EF          rst	INDEX_ED_AT_2A_PLUS_HL
89FD: 1A          ld   a,(de)
89FE: DD 77 F0    ld   (ix+$1e),a
8A01: 13          inc  de
8A02: 0E 00       ld   c,$00
8A04: EB          ex   de,hl
8A05: C3 2C C9    jp   $8DC2

8a08:		db	$21, $8a, $1d, $8a, $19, $8a, $15, $8a
8a10:		db	$12, $8a, $00, $34, $3c, $01, $ff, $35
8a18:		db	$36, $02, $ff, $ff, $3d, $02, $ff, $ff
8a20:		db	$3e, $02, $ff, $ff, $bd

8A25:		dw	$8a3e	; Table 0
		dw	$8a3a	; Table 1
		dw	$8a36	; Table 2
		dw	$8a32	; Table 3
		dw	$8a2f	; Table 4

8a2f:		db	$00, $75, $7d
8a32:		db	$01, $ff, $76, $77
8a36:		db	$02, $ff, $ff, $7e
8a3a:		db	$02, $ff, $ff, $7f
8a3e:		db	$02, $ff, $ff, $ff 


8A42: CD BB 68    call SFX_STOP_MUS
8A45: CD D3 68    call SFX_STOP_SFX
8A48: CD F7 68    call SFX_FLUSH
8A4B: CD 60 69    call SFX_KILLED
8A4E: DD 7E B1    ld   a,(ix+$1b)
8A51: A7          and  a
8A52: 20 81       jr   nz,$8A5D
8A54: DD 36 00 F0 ld   (ix+TABLE_STATUS),$1E
8A58: DD 36 51 82 ld   (iy+TABLE_COUNTDOWN),$28
8A5C: C9          ret

8A5D: DD 36 00 F0 ld   (ix+TABLE_STATUS),$1E
8A61: DD 36 51 82 ld   (iy+TABLE_COUNTDOWN),$28
8A65: C9          ret

8A66: DD 35 00    dec  (ix+TABLE_STATUS)
8A69: C0          ret  nz
8A6A: FD 36 20 00 ld   (iy+sprite_x),$00
8A6E: FD 36 60 00 ld   (iy+sprite2_x),$00
8A72: FD 36 A0 00 ld   (iy+sprite3_x),$00
8A76: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
8A7A: C9          ret

8a7b:		db	$8d, $8a, $8d, $8a, $8d, $8a, $89
8a82:		db	$8a, $85, $8a, $02, $38, $39, $3a
8a89:		db	$02, $30, $31, $32, $00, $33, $3b

8A90: CD 20 39    call $9302
8A93: DD 36 31 00 ld   (ix+ITEM_TYPE),$00
8A97: C3 1B C8    jp   $8CB1

8A9A: DD 35 70    dec  (ix+$16)		; Countdown this include grenade status
8A9D: CA 18 A8    jp   z,$8A90
8AA0: DD 7E 70    ld   a,(ix+$16)
8AA3: 0F          rrca
8AA4: E6 21       and  $03
8AA6: 21 5B A8    ld   hl,$8AB5
8AA9: EF          rst	INDEX_ED_AT_2A_PLUS_HL
8AAA: EB          ex   de,hl
8AAB: 0E 00       ld   c,$00
8AAD: 7E          ld   a,(hl)
8AAE: DD 77 F0    ld   (ix+$1e),a
8AB1: 23          inc  hl
8AB2: C3 2C C9    jp   $8DC2

8AB5: 		dw	$8abd	; Table 0
		dw	$8ac5	; Table 1
		dw	$8ac1	; Table 2
		dw	$8ac5	; Table 3
	
8ABD:		db	$01, $c1, $c9, $ca
8ac1:		db	$00, $cb, $c8, $00
8ac5:		db	$01, $c0, $c2, $c3

8AC9: CD 34 E8    call $8E52
8ACC: E6 E1       and  $0F
8ACE: 28 75       jr   z,$8B27
8AD0: DD 46 01    ld   b,(ix+$01)
8AD3: DD 70 11    ld   (ix+$11),b
8AD6: 21 12 A9    ld   hl,$8B30
8AD9: E7          rst	INDEX_A_PLUS_HL
8ADA: DD 77 01    ld   (ix+$01),a
8ADD: B8          cp   b
8ADE: 28 21       jr   z,$8AE3
8AE0: CD A1 A9    call $8B0B
8AE3: DD 7E 20    ld   a,(ix+$02)
8AE6: DD BE 01    cp   (ix+$01)
8AE9: C8          ret  z
8AEA: 67          ld   h,a
8AEB: DD 6E 91    ld   l,(ix+$19)
8AEE: DD 56 71    ld   d,(ix+$17)
8AF1: DD 5E 90    ld   e,(ix+$18)
8AF4: 19          add  hl,de
8AF5: DD 74 20    ld   (ix+$02),h
8AF8: DD 75 91    ld   (ix+$19),l
8AFB: 7C          ld   a,h
8AFC: DD 96 01    sub  (ix+$01)
8AFF: C6 41       add  a,$05
8B01: FE A1       cp   $0B
8B03: D0          ret  nc
8B04: DD 7E 01    ld   a,(ix+$01)
8B07: DD 77 20    ld   (ix+$02),a
8B0A: C9          ret

8B0B: DD 7E 01    ld   a,(ix+$01)
8B0E: DD 96 20    sub  (ix+$02)
8B11: 67          ld   h,a
8B12: 2E 00       ld   l,$00
8B14: CB 2C       sra  h
8B16: CB 1D       rr   l
8B18: CB 2C       sra  h
8B1A: CB 1D       rr   l
8B1C: DD 74 71    ld   (ix+$17),h
8B1F: DD 75 90    ld   (ix+$18),l
8B22: DD 36 91 00 ld   (ix+$19),$00
8B26: C9          ret

8B27: DD CB 31 FE set  7,(ix+ITEM_TYPE)
8B2B: DD 36 11 FF ld   (ix+$11),$FF
8B2F: C9          ret

8B30:		db	$ff, $00, $7f, $ff, $c0, $e0, $a0, $ff, $40, $20, $60

8B3B: DD CB 31 F6 bit  7,(ix+ITEM_TYPE)
8B3F: C0          ret  nz
8B40: DD 7E 01    ld   a,(ix+$01)
8B43: C6 80       add  a,$08
8B45: 21 37 A9    ld   hl,$8B73
8B48: 07          rlca
8B49: 07          rlca
8B4A: 07          rlca
8B4B: E6 61       and  $07
8B4D: 87          add  a,a
8B4E: EF          rst	INDEX_ED_AT_2A_PLUS_HL
8B4F: 4E          ld   c,(hl)
8B50: 23          inc  hl
8B51: 46          ld   b,(hl)
8B52: DD 70 C1    ld   (ix+$0d),b
8B55: DD 71 E0    ld   (ix+$0e),c
8B58: DD 66 21    ld   h,(ix+TABLE_X_coord)
8B5B: DD 6E 40    ld   l,(ix+TABLE_X_low)
8B5E: 19          add  hl,de
8B5F: DD 74 61    ld   (ix+TABLE_new_X_high),h
8B62: DD 75 80    ld   (ix+TABLE_new_X_low),l
8B65: DD 66 41    ld   h,(ix+TABLE_Y_coord)
8B68: DD 6E 60    ld   l,(ix+TABLE_Y_low)
8B6B: 09          add  hl,bc
8B6C: DD 74 81    ld   (ix+TABLE_new_Y_high),h
8B6F: DD 75 A0    ld   (ix+TABLE_new_Y_low),l
8B72: C9          ret

8b73:		db	$26, $01, $00, $00
8b77:		db	$dc, $00, $c0, $00
8b7b:		db	$00, $00, $00, $01
8b7f:		db	$24, $ff, $c0, $00
8b83:		db	$da, $fe, $00, $00
8b87:		db	$24, $ff, $40, $ff
8b8b:		db	$00, $00, $00, $ff
8b8f:		db	$dc, $00, $40, $ff

8B93: DD E5       push ix
8B95: 21 CC A9    ld   hl,$8BCC
8B98: E5          push hl
8B99: DD 66 61    ld   h,(ix+TABLE_new_X_high)
8B9C: DD 6E 81    ld   l,(ix+TABLE_new_Y_high)
8B9F: 06 80       ld   b,$08
8BA1: 11 10 00    ld   de,$0010
8BA4: DD 21 00 8E ld   ix,TREE_ROCK_SPRITES
8BA8: DD 7E 00    ld   a,(ix+TABLE_STATUS)
8BAB: 3C          inc  a
8BAC: 20 90       jr   nz,$8BC6
8BAE: 7D          ld   a,l
8BAF: DD 96 41    sub  (ix+TABLE_Y_coord)
8BB2: FE AF       cp   $EB
8BB4: 38 10       jr   c,$8BC6
8BB6: 7C          ld   a,h
8BB7: DD 96 21    sub  (ix+TABLE_X_coord)
8BBA: DD 86 81    add  a,(ix+TABLE_new_Y_high)
8BBD: DD BE A0    cp   (ix+TABLE_new_Y_low)
8BC0: 30 40       jr   nc,$8BC6
8BC2: 3E 01       ld   a,$01
8BC4: A7          and  a
8BC5: C9          ret
8BC6: DD 19       add  ix,de
8BC8: 10 FC       djnz $8BA8
8BCA: AF          xor  a
8BCB: C9          ret

8BCC: DD E1       pop  ix
8BCE: C9          ret
8BCF: DD CB 31 F6 bit  7,(ix+ITEM_TYPE)
8BD3: C0          ret  nz
8BD4: DD 36 B1 00 ld   (ix+$1b),$00
8BD8: CD 39 A9    call $8B93
8BDB: A7          and  a
8BDC: C2 08 C8    jp   nz,$8C80
8BDF: DD 7E 81    ld   a,(ix+TABLE_new_Y_high)
8BE2: 47          ld   b,a
8BE3: 3A 30 EF    ld   a,($EF12)
8BE6: E6 E1       and  $0F
8BE8: 80          add  a,b
8BE9: 47          ld   b,a
8BEA: DD 7E 61    ld   a,(ix+TABLE_new_X_high)
8BED: C6 61       add  a,$07
8BEF: 4F          ld   c,a
8BF0: 3A 10 EF    ld   a,($EF10)
8BF3: 57          ld   d,a
8BF4: 3A 11 EF    ld   a,($EF11)
8BF7: 5F          ld   e,a
8BF8: 78          ld   a,b
8BF9: E6 1E       and  $F0
8BFB: 6F          ld   l,a
8BFC: 26 00       ld   h,$00
8BFE: 29          add  hl,hl
8BFF: 19          add  hl,de
8C00: 79          ld   a,c
8C01: CB 3F       srl  a
8C03: 4F          ld   c,a
8C04: CB 3F       srl  a
8C06: CB 3F       srl  a
8C08: E6 F0       and  $1E
8C0A: DF          rst	ADD_A_TO_HL
8C0B: 7C          ld   a,h
8C0C: E6 BF       and  $FB
8C0E: 67          ld   h,a
8C0F: 7E          ld   a,(hl)
8C10: A7          and  a
8C11: 28 73       jr   z,$8C4A
8C13: 5F          ld   e,a
8C14: FE 1C       cp   $D0
8C16: 38 60       jr   c,$8C1E
8C18: DD 36 B1 01 ld   (ix+$1b),$01
8C1C: 18 80       jr   $8C26
8C1E: FE 8C       cp   $C8
8C20: 38 40       jr   c,$8C26
8C22: DD 36 B1 20 ld   (ix+$1b),$02
8C26: 23          inc  hl
8C27: 7E          ld   a,(hl)
8C28: A7          and  a
8C29: 28 21       jr   z,$8C2E
8C2B: 79          ld   a,c
8C2C: 2F          cpl
8C2D: 4F          ld   c,a
8C2E: 6B          ld   l,e
8C2F: 26 00       ld   h,$00
8C31: 29          add  hl,hl
8C32: 29          add  hl,hl
8C33: 29          add  hl,hl
8C34: 78          ld   a,b
8C35: 0F          rrca
8C36: 2F          cpl
8C37: E6 61       and  $07
8C39: DF          rst	ADD_A_TO_HL
8C3A: 11 46 46    ld   de,$6464
8C3D: 19          add  hl,de
8C3E: 56          ld   d,(hl)
8C3F: 79          ld   a,c
8C40: E6 61       and  $07
8C42: 21 8B C8    ld   hl,$8CA9
8C45: DF          rst	ADD_A_TO_HL
8C46: 7E          ld   a,(hl)
8C47: A2          and  d
8C48: 20 72       jr   nz,$8C80
8C4A: DD 7E 61    ld   a,(ix+TABLE_new_X_high)
8C4D: D6 10       sub  $10
8C4F: FE 1C       cp   $D0
8C51: 30 C0       jr   nc,$8C5F
8C53: DD 66 61    ld   h,(ix+TABLE_new_X_high)
8C56: DD 6E 80    ld   l,(ix+TABLE_new_X_low)
8C59: DD 74 21    ld   (ix+TABLE_X_coord),h
8C5C: DD 75 40    ld   (ix+TABLE_X_low),l
8C5F: 0E 04       ld   c,$40
8C61: 3A F9 0E    ld   a,(AREA_END)
8C64: A7          and  a
8C65: 28 20       jr   z,$8C69
8C67: 0E 1A       ld   c,$B0
8C69: DD 7E 81    ld   a,(ix+TABLE_new_Y_high)
8C6C: B9          cp   c
8C6D: 30 F1       jr   nc,$8C8E
8C6F: FE 80       cp   $08
8C71: 38 53       jr   c,$8CA8
8C73: DD 66 81    ld   h,(ix+TABLE_new_Y_high)
8C76: DD 6E A0    ld   l,(ix+TABLE_new_Y_low)
8C79: DD 74 41    ld   (ix+TABLE_Y_coord),h
8C7C: DD 75 60    ld   (ix+TABLE_Y_low),l
8C7F: C9          ret
8C80: DD CB 31 EE set  5,(ix+ITEM_TYPE)
8C84: DD 7E B1    ld   a,(ix+$1b)
8C87: A7          and  a
8C88: C8          ret  z
8C89: DD 36 00 F3 ld   (ix+TABLE_STATUS),$3F
8C8D: C9          ret
8C8E: DD 56 C1    ld   d,(ix+$0d)
8C91: DD 5E E0    ld   e,(ix+$0e)
8C94: ED 53 75 0E ld   ($E057),de
8C98: A7          and  a
8C99: DD 66 81    ld   h,(ix+TABLE_new_Y_high)
8C9C: DD 6E A0    ld   l,(ix+TABLE_new_Y_low)
8C9F: ED 52       sbc  hl,de
8CA1: DD 74 41    ld   (ix+TABLE_Y_coord),h
8CA4: DD 75 60    ld   (ix+TABLE_Y_low),l
8CA7: C9          ret
8CA8: C9          ret

8ca9:		db	$80, $40, $20, $10, $08, $04, $02, $01

8CB1: DD CB 31 F6 bit  7,(ix+ITEM_TYPE)
8CB5: C0          ret  nz
8CB6: DD 7E 70    ld   a,(ix+$16)
8CB9: A7          and  a
8CBA: C0          ret  nz
8CBB: DD 34 10    inc  (ix+$10)
8CBE: DD 7E 20    ld   a,(ix+$02)
8CC1: C6 80       add  a,$08
8CC3: 0F          rrca
8CC4: 0F          rrca
8CC5: 0F          rrca
8CC6: 0F          rrca
8CC7: E6 E1       and  $0F
8CC9: 47          ld   b,a
8CCA: 21 3E C8    ld   hl,$8CF2
8CCD: DF          rst	ADD_A_TO_HL
8CCE: 4E          ld   c,(hl)
8CCF: 78          ld   a,b
8CD0: 87          add  a,a
8CD1: 87          add  a,a
8CD2: 47          ld   b,a
8CD3: 87          add  a,a
8CD4: 80          add  a,b
8CD5: 47          ld   b,a
8CD6: DD 7E 10    ld   a,(ix+$10)
8CD9: 0F          rrca
8CDA: 0F          rrca
8CDB: E6 21       and  $03
8CDD: FE 21       cp   $03
8CDF: 20 20       jr   nz,$8CE3
8CE1: 3E 01       ld   a,$01
8CE3: 87          add  a,a
8CE4: 87          add  a,a
8CE5: 80          add  a,b
8CE6: 21 20 C9    ld   hl,$8D02
8CE9: E7          rst	INDEX_A_PLUS_HL
8CEA: DD 77 F0    ld   (ix+$1e),a
8CED: 23          inc  hl
8CEE: CD 2C C9    call $8DC2
8CF1: C9          ret

8cf2:		db	$00, $00, $00, $00, $00, $08, $08, $08
8cfa:		db	$08, $08, $08, $08, $00, $00, $00, $00

8D02:		db	$01, $00, $08, $09, $01, $01, $10, $11, $01, $02, $18, $19, $00, $03, $0b, $0b
8d12:		db	$00, $03, $0b, $0b, $00, $03, $0b, $0b, $01, $13, $1a, $1b, $00, $14, $1c, $00
8d22:		db	$01, $15, $1d, $1e, $00, $0a, $12, $00, $00, $0a, $12, $00, $00, $0a, $12, $00
8d32:		db	$00, $05, $0d, $00, $00, $06, $0e, $00, $00, $07, $0f, $00, $00, $0a, $12, $00
8d42:		db	$00, $0a, $12, $00, $00, $0a, $12, $00, $01, $13, $1b, $1a, $00, $14, $1c, $00
8d52:		db	$01, $15, $1e, $1d, $00, $03, $0b, $0b, $00, $03, $0b, $0b, $00, $03, $0b, $0b
8d62:		db	$01, $00, $09, $08, $01, $01, $11, $10, $01, $02, $19, $18, $01, $27, $37, $2f
8d72:		db	$01, $27, $37, $2f, $01, $27, $37, $2f, $00, $24, $2c, $00, $00, $25, $2d, $00
8d82:		db	$00, $26, $2e, $00, $00, $23, $2b, $00, $00, $23, $2b, $00, $00, $23, $2b, $00
8d92:		db	$00, $20, $28, $00, $00, $21, $29, $00, $00, $22, $2a, $00, $00, $23, $2b, $00
8da2:		db	$00, $23, $2b, $00, $00, $23, $2b, $00, $00, $24, $2c, $00, $00, $25, $2d, $00
8db2:		db	$00, $26, $2e, $00, $01, $27, $2f, $37, $01, $27, $2f, $37, $01, $27, $2f, $37

		; c is sprite flags 
		; hl is the sprite number three bytes in the table
		; IY is our sprite hardware pointer
		; IX is table for this object/enemy
		
UPDATE_SPRITES:
8DC2: FD 71 01    ld   (iy+sprite_flags),c		; same passed c for three sprites
8DC5: FD 71 41    ld   (iy+sprite2_flags),c
8DC8: FD 71 81    ld   (iy+sprite3_flags),c
8DCB: 7E          ld   a,(hl)				; 1st sprite number
8DCC: 23          inc  hl
8DCD: FD 77 00    ld   (iy+sprite_number),a
8DD0: 7E          ld   a,(hl)				; 2nd sprite number
8DD1: 23          inc  hl
8DD2: FD 77 40    ld   (iy+sprite2_number),a
8DD5: 7E          ld   a,(hl)				; last sprite number
8DD6: 23          inc  hl
8DD7: FD 77 80    ld   (iy+sprite3_number),a
8DDA: DD 7E F0    ld   a,(ix+$1e)			; how many sprites here
8DDD: E6 21       and  $03
8DDF: FE 01       cp   $01
8DE1: 38 40       jr   c,SPRITES_1AND1				; if = 0 two hight same line
8DE3: 28 22       jr   z,SPRITES_1AND2			; if = 1 then 1 head two body parts
8DE5: 18 05       jr   SPRITES_2AND1				; so mostly likley = 2 or 3

							; +-----+
							; |     |
							; |  1  |
							; |     |
							; +-----+
							; |     |
							; |  2  |
							; |     |
							; +-----+
SPRITES_1AND1:
8DE7: DD 7E 21    ld   a,(ix+TABLE_X_coord)		; this is when two sprites ontop of eachother one by 2
8DEA: FD 77 20    ld   (iy+sprite_x),a
8DED: FD 77 60    ld   (iy+sprite2_x),a
8DF0: FD 36 A0 00 ld   (iy+sprite3_x),$00		; kill off the 3rd sprite as no need to display anything.
8DF4: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
8DF7: FD 77 61    ld   (iy+sprite2_y),a
8DFA: C6 10       add  a,$10				; Sprites 16 pixels heigh
8DFC: 38 40       jr   c,$8E02				; If this Y is off bottom then kill off 
8DFE: FD 77 21    ld   (iy+sprite_y),a			; otherwise it's going to be his legs showing
8E01: C9          ret

8E02: FD 36 20 00 ld   (iy+sprite_x),$00		; zap out sprite
8E06: C9          ret

							   ; +-----+
							   ; |     |
							   ; |  1  |
							   ; |     |
							; +-----+-----+
							; |     |     |
							; |  2  |  3  |
							; |     |     |
SPRITES_1AND2:							; +-----+-----+
8E07: DD 7E 21    ld   a,(ix+TABLE_X_coord)		; for 3 sprites man left/right we adjust from head
8E0A: FD 77 20    ld   (iy+sprite_x),a
8E0D: C6 9E       add  a,$F8				; -8 pixels left
8E0F: FD 77 60    ld   (iy+sprite2_x),a
8E12: C6 10       add  a,$10				; then +8 back and +8 for right creates a pyramid shape of 3
8E14: FD 77 A0    ld   (iy+sprite3_x),a
8E17: DD 7E 41    ld   a,(ix+TABLE_Y_coord)		; legs left / right is the y
8E1A: FD 77 61    ld   (iy+sprite2_y),a
8E1D: FD 77 A1    ld   (iy+sprite3_y),a
8E20: C6 10       add  a,$10				; add to y for top
8E22: 38 FC       jr   c,$8E02				; if off top then don't display
8E24: FD 77 21    ld   (iy+sprite_y),a
8E27: C9          ret
							; +-----+-----+
							; |     |     |
							; |  1  |  2  |
							; |     |     |
							; +-----+-----+
							   ; |     |
							   ; |  3  |
							   ; |     |
SPRITES_2AND1:						   ; +-----+
8E28: DD 7E 21    ld   a,(ix+TABLE_X_coord)		; two body parts and single for legs
8E2B: FD 77 A0    ld   (iy+sprite3_x),a			; so x is sprite 3
8E2E: C6 9E       add  a,$F8				; -8 
8E30: FD 77 20    ld   (iy+sprite_x),a			; sprite 1 left
8E33: C6 10       add  a,$10
8E35: FD 77 60    ld   (iy+sprite2_x),a			; sprite 2 is right
8E38: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
8E3B: FD 77 A1    ld   (iy+sprite3_y),a
8E3E: C6 10       add  a,$10				; add 16 height for two two
8E40: 38 61       jr   c,$8E49				; if off screen don't display
8E42: FD 77 21    ld   (iy+sprite_y),a
8E45: FD 77 61    ld   (iy+sprite2_y),a
8E48: C9          ret
8E49: FD 36 20 00 ld   (iy+sprite_x),$00		; need to kill off top two here
8E4D: FD 36 60 00 ld   (iy+sprite2_x),$00
8E51: C9          ret


		; Read controllers
8E52: 21 40 0E    ld   hl,CONTROLLER_1				;
8E55: 3A 91 0E    ld   a,(PLAYER_UP)
8E58: E6 01       and  $01
8E5A: 28 E0       jr   z,$8E6A
8E5C: 3A 93 0E    ld   a,(IS_SCREEN_YFLIPPED)
8E5F: E6 01       and  $01
8E61: 20 60       jr   nz,$8E69
8E63: 3A 83 0E    ld   a,(IS_SINGLE_STICK_SETUP)		; Two controllers or one set?
8E66: A7          and  a
8E67: 20 01       jr   nz,$8E6A
8E69: 2C          inc  l
8E6A: 7E          ld   a,(hl)
8E6B: C9          ret
8E6C: 3A 26 0E    ld   a,(SCREEN_SCROLLING)
8E6F: A7          and  a
8E70: 28 21       jr   z,$8E75
8E72: DD 35 41    dec  (ix+TABLE_Y_coord)
8E75: CD 46 C6    call $6C64
8E78: DD 66 21    ld   h,(ix+TABLE_X_coord)
8E7B: DD 6E 40    ld   l,(ix+TABLE_X_low)
8E7E: 19          add  hl,de
8E7F: DD 74 61    ld   (ix+TABLE_new_X_high),h
8E82: DD 75 80    ld   (ix+TABLE_new_X_low),l
8E85: DD 66 41    ld   h,(ix+TABLE_Y_coord)
8E88: DD 6E 60    ld   l,(ix+TABLE_Y_low)
8E8B: 09          add  hl,bc
8E8C: DD 74 81    ld   (ix+TABLE_new_Y_high),h
8E8F: DD 75 A0    ld   (ix+TABLE_new_Y_low),l
8E92: C9          ret

8E93: CD B8 E8    call UPDATE_BULLETS		; Process all bullet data
8E96: CD 00 19    call $9100
8E99: C9          ret

	; I *think* this routine is responsible for positioning player bullet sprites you think? 
	; I do also, hence why I made the comments! ;-)
UPDATE_BULLETS:
8E9A: DD 21 00 2E ld   ix,BULLET_SPRITES
8E9E: 26 E0       ld   h,$0E			; max amount of bullet types to process
8EA0: 11 02 00    ld   de,$0020              ; each bullet data set is 32 bytes of entries
8EA3: FD 21 84 FF ld   iy,BULLET_SPRITES     ; IY = pointer to sprites
8EA7: 01 40 00    ld   bc,$0004              ; BC
8EAA: D9          exx
8EAB: DD 7E 00    ld   a,(ix+TABLE_STATUS)
8EAE: A7          and  a
8EAF: CA 0C E9    jp   z,$8FC0
8EB2: 3C          inc  a
8EB3: C2 A0 18    jp   nz,$900A

8EB6: DD 7E 50    ld   a,(ix+$14)
8EB9: FE 01       cp   $01
8EBB: CA 0B E9    jp   z,$8FA1
8EBE: 38 91       jr   c,$8ED9
8EC0: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
8EC3: CA 93 18    jp   z,$9039
8EC6: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
8EC9: 0F          rrca
8ECA: E6 21       and  $03
8ECC: 21 7C E8    ld   hl,$8ED6
8ECF: E7          rst	INDEX_A_PLUS_HL
8ED0: FD 77 00    ld   (iy+sprite_number),a		; Set bullet sprite number from table
8ED3: C3 0C E9    jp   $8FC0

8ED6:		db	$bc,$b9,$b8,$dd


8ED9: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
8EDC: CA 39 E9    jp   z,$8F93

8EDF: DD CB 31 64 bit  0,(ix+ITEM_TYPE)
8EE3: 20 03       jr   nz,$8F06

8EE5: DD 7E 91    ld   a,(ix+$19)
8EE8: 21 33 E9    ld   hl,$8F33
8EEB: EF          rst	INDEX_ED_AT_2A_PLUS_HL
8EEC: FD 73 00    ld   (iy+sprite_number),e
8EEF: FD 72 01    ld   (iy+sprite_flags),d
8EF2: 3A 26 0E    ld   a,(SCREEN_SCROLLING)
8EF5: ED 44       neg
8EF7: DD 86 41    add  a,(ix+TABLE_Y_coord)
8EFA: FD 77 21    ld   (iy+sprite_y),a
8EFD: DD 7E 21    ld   a,(ix+TABLE_X_coord)
8F00: FD 77 20    ld   (iy+sprite_x),a
8F03: C3 0C E9    jp   $8FC0

8F06: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
8F09: CA 39 E9    jp   z,$8F93
8F0C: DD 7E 91    ld   a,(ix+$19)
8F0F: 21 C3 E9    ld   hl,$8F2D
8F12: EF          rst	INDEX_ED_AT_2A_PLUS_HL
8F13: FD 73 00    ld   (iy+sprite_number),e
8F16: FD 72 01    ld   (iy+sprite_flags),d
8F19: 3A 26 0E    ld   a,($E062)
8F1C: ED 44       neg
8F1E: DD 86 41    add  a,(ix+TABLE_Y_coord)
8F21: FD 77 21    ld   (iy+sprite_y),a
8F24: DD 7E 21    ld   a,(ix+TABLE_X_coord)
8F27: FD 77 20    ld   (iy+sprite_x),a
8F2A: C3 0C E9    jp   $8FC0


8f2d:		db	$bf, $08, $ae, $00, $bf, $00
8f33:		db	$aa, $00, $aa, $00, $a9, $00
8f39:		db	$a9, $00, $a8, $00, $a9, $08
8f3f:		db	$a9, $08, $aa, $08, $aa, $08
8f45:		db	$aa, $0c, $a9, $0c, $a9, $0c
8f4b:		db	$a8, $0c, $a9, $04, $a9, $04
8f51:		db	$aa, $04

8F53: DD 36 50 01 ld   (ix+$14),$01			; This is rockets being lunched at player
8F57: 06 4B       ld   b,$A5				; Angled slightly right /  left (if flipped)
8F59: DD CB 91 64 bit  0,(ix+$19)
8F5D: 28 20       jr   z,$8F61
8F5F: 06 EB       ld   b,$AF				; going right of left
8F61: FD 70 00    ld   (iy+sprite_number),b
8F64: DD 35 30    dec  (ix+$12)
8F67: 28 70       jr   z,$8F7F
8F69: CD 5C E9    call $8FD4
8F6C: DD 7E 21    ld   a,(ix+TABLE_X_coord)
8F6F: FE 10       cp   $10
8F71: DA D1 18    jp   c,$901D
8F74: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
8F77: FE 80       cp   $08
8F79: DA D1 18    jp   c,$901D
8F7C: C3 0C E9    jp   $8FC0

8F7F: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
8F83: FD 36 20 00 ld   (iy+sprite_x),$00
8F87: DD 66 21    ld   h,(ix+TABLE_X_coord)
8F8A: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
8F8D: CD C1 38    call MAKE_EXPLOSION
8F90: C3 0C E9    jp   $8FC0
8F93: DD CB 31 64 bit  0,(ix+ITEM_TYPE)
8F97: 20 BA       jr   nz,$8F53				; this is a rocker luncher bullet with flames from gun

8F99: FD 36 00 5B ld   (iy+sprite_number),$B5		; small 2x2 pixel bullet sprite
8F9D: DD 36 50 01 ld   (ix+$14),$01
8FA1: DD CB 31 64 bit  0,(ix+ITEM_TYPE)
8FA5: 20 DB       jr   nz,$8F64
8FA7: DD 35 30    dec  (ix+$12)
8FAA: 28 F0       jr   z,$8FCA
8FAC: CD 5C E9    call $8FD4
8FAF: DD 7E 21    ld   a,(ix+TABLE_X_coord)
8FB2: FE 10       cp   $10
8FB4: 38 67       jr   c,$901D
8FB6: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
8FB9: FE 80       cp   $08
8FBB: 38 06       jr   c,$901D
8FBD: CD B7 18    call $907B

8FC0: D9          exx
8FC1: DD 19       add  ix,de
8FC3: FD 09       add  iy,bc
8FC5: 25          dec  h
8FC6: C8          ret  z
8FC7: C3 AA E8    jp   $8EAA


8FCA: DD 36 50 20 ld   (ix+$14),$02
8FCE: DD 36 51 60 ld   (iy+TABLE_COUNTDOWN),$06
8FD2: 18 CE       jr   $8FC0

8FD4: DD 66 21    ld   h,(ix+TABLE_X_coord)
8FD7: DD 6E 40    ld   l,(ix+TABLE_X_low)
8FDA: DD 56 A1    ld   d,(ix+TABLE_X_Add_low)
8FDD: DD 5E C0    ld   e,(ix+TABLE_X_Add_high)
8FE0: 19          add  hl,de
8FE1: DD 74 21    ld   (ix+TABLE_X_coord),h
8FE4: FD 74 20    ld   (iy+sprite_x),h
8FE7: DD 75 40    ld   (ix+TABLE_X_low),l
8FEA: 3A 26 0E    ld   a,(SCREEN_SCROLLING)
8FED: A7          and  a
8FEE: 28 21       jr   z,$8FF3
8FF0: DD 35 41    dec  (ix+TABLE_Y_coord)
8FF3: DD 66 41    ld   h,(ix+TABLE_Y_coord)
8FF6: DD 6E 60    ld   l,(ix+TABLE_Y_low)
8FF9: DD 56 C1    ld   d,(ix+$0d)
8FFC: DD 5E E0    ld   e,(ix+$0e)
8FFF: 19          add  hl,de
9000: DD 74 41    ld   (ix+TABLE_Y_coord),h
9003: FD 74 21    ld   (iy+sprite_y),h
9006: DD 75 60    ld   (ix+TABLE_Y_low),l
9009: C9          ret

900A: DD CB 31 64 bit  0,(ix+ITEM_TYPE)
900E: C2 F7 E9    jp   nz,$8F7F
9011: DD 7E 00    ld   a,(ix+TABLE_STATUS)
9014: FE 10       cp   $10
9016: 30 31       jr   nc,$902B
9018: DD 35 00    dec  (ix+TABLE_STATUS)
901B: 20 2B       jr   nz,$8FC0

901D: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
9021: DD 36 21 00 ld   (ix+TABLE_X_coord),$00
9025: FD 36 20 00 ld   (iy+sprite_x),$00
9029: 18 59       jr   $8FC0

902B: DD 36 00 61 ld   (ix+TABLE_STATUS),$07
902F: FD 36 00 9A ld   (iy+sprite_number),$B8
9033: FD 36 01 00 ld   (iy+sprite_flags),$00
9037: 18 69       jr   $8FC0

9039: DD 36 00 F3 ld   (ix+TABLE_STATUS),$3F
903D: 18 09       jr   $8FC0

903F: DD E5       push ix
9041: 21 96 18    ld   hl,$9078
9044: E5          push hl
9045: DD 66 21    ld   h,(ix+TABLE_X_coord)
9048: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
904B: 06 80       ld   b,$08
904D: 11 10 00    ld   de,$0010
9050: DD 21 00 8E ld   ix,TREE_ROCK_SPRITES
9054: DD 7E 00    ld   a,(ix+TABLE_STATUS)
9057: 3C          inc  a
9058: 20 90       jr   nz,$9072
905A: 7D          ld   a,l
905B: DD 96 41    sub  (ix+TABLE_Y_coord)
905E: FE AF       cp   $EB
9060: 38 10       jr   c,$9072
9062: 7C          ld   a,h
9063: DD 96 21    sub  (ix+TABLE_X_coord)
9066: DD 86 81    add  a,(ix+TABLE_new_Y_high)
9069: DD BE A0    cp   (ix+TABLE_new_Y_low)
906C: 30 40       jr   nc,$9072
906E: 3E 01       ld   a,$01
9070: A7          and  a
9071: C9          ret

9072: DD 19       add  ix,de
9074: 10 FC       djnz $9054
9076: AF          xor  a
9077: C9          ret

9078: DD E1       pop  ix
907A: C9          ret

907B: DD CB 31 F6 bit  7,(ix+ITEM_TYPE)
907F: C0          ret  nz
9080: DD 7E F1    ld   a,(ix+$1f)
9083: E6 01       and  $01
9085: 47          ld   b,a
9086: 3A 20 0E    ld   a,(FRAME_SYNC)
9089: E6 01       and  $01
908B: B8          cp   b
908C: C8          ret  z
908D: CD F3 18    call $903F
9090: 20 B4       jr   nz,$90EC
9092: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
9095: 47          ld   b,a
9096: 3A 30 EF    ld   a,($EF12)
9099: E6 E1       and  $0F
909B: 80          add  a,b
909C: 47          ld   b,a
909D: DD 7E 21    ld   a,(ix+TABLE_X_coord)
90A0: C6 61       add  a,$07
90A2: 4F          ld   c,a
90A3: 3A 10 EF    ld   a,($EF10)
90A6: 57          ld   d,a
90A7: 3A 11 EF    ld   a,($EF11)
90AA: 5F          ld   e,a
90AB: 78          ld   a,b
90AC: E6 1E       and  $F0
90AE: 6F          ld   l,a
90AF: 26 00       ld   h,$00
90B1: 29          add  hl,hl
90B2: 19          add  hl,de
90B3: 79          ld   a,c
90B4: CB 3F       srl  a
90B6: 4F          ld   c,a
90B7: CB 3F       srl  a
90B9: CB 3F       srl  a
90BB: E6 F0       and  $1E
90BD: DF          rst	ADD_A_TO_HL
90BE: 7C          ld   a,h
90BF: E6 BF       and  $FB
90C1: 67          ld   h,a
90C2: 7E          ld   a,(hl)
90C3: A7          and  a
90C4: C8          ret  z
90C5: FE 0C       cp   $C0
90C7: D0          ret  nc
90C8: 23          inc  hl
90C9: 5F          ld   e,a
90CA: 7E          ld   a,(hl)
90CB: A7          and  a
90CC: 28 21       jr   z,$90D1
90CE: 79          ld   a,c
90CF: 2F          cpl
90D0: 4F          ld   c,a
90D1: 6B          ld   l,e
90D2: 26 00       ld   h,$00
90D4: 29          add  hl,hl
90D5: 29          add  hl,hl
90D6: 29          add  hl,hl
90D7: 78          ld   a,b
90D8: 0F          rrca
90D9: 2F          cpl
90DA: E6 61       and  $07
90DC: DF          rst	ADD_A_TO_HL
90DD: 11 46 46    ld   de,$6464
90E0: 19          add  hl,de
90E1: 56          ld   d,(hl)
90E2: 79          ld   a,c
90E3: E6 61       and  $07
90E5: 21 9E 18    ld   hl,BIT_TABLE
90E8: DF          rst	ADD_A_TO_HL
90E9: 7E          ld   a,(hl)
90EA: A2          and  d
90EB: C8          ret  z
90EC: DD 36 50 20 ld   (ix+$14),$02
90F0: DD 36 51 60 ld   (iy+TABLE_COUNTDOWN),$06
90F4: CD 15 68    call SFX_BULLET_HIT
90F7: C9          ret

BIT_TABLE:		db $80,$40,$20,$10,$08,$04,$02,$01

90FE: 20 01       jr   nz,$9101

9100: CD 26 38    call CHECK_EXPLOSION		; 9262
9103: DD 21 04 0F ld   ix,grenade_TABLE		; table offset into grenade data
9107: FD 21 44 FF ld   iy,HW_SPRITE_81		; Single sprite for player grenade
910B: DD 7E 00    ld   a,(ix+TABLE_STATUS)
910E: A7          and  a
910F: CA 6D 38    jp   z,$92C7
9112: 3C          inc  a
9113: 20 95       jr   nz,$916E
9115: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
9118: 28 54       jr   z,$916E
911A: DD 34 41    inc  (ix+TABLE_Y_coord)
911D: 3A 26 0E    ld   a,(SCREEN_SCROLLING)
9120: A7          and  a
9121: 28 60       jr   z,$9129
9123: DD 35 41    dec  (ix+TABLE_Y_coord)
9126: DD 35 61    dec  (ix+TABLE_new_X_high)
9129: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)		; animation counter
912C: 0F          rrca
912D: 0F          rrca
912E: 0F          rrca				; divide by 8
912F: E6 61       and  $07			; just 0 - 7 for lookup	
9131: 47          ld   b,a			; save value
9132: 21 26 19    ld   hl,$9162
9135: EF          rst	INDEX_ED_AT_2A_PLUS_HL
9136: DD 66 41    ld   h,(ix+TABLE_Y_coord)
9139: DD 6E 60    ld   l,(ix+TABLE_Y_low)
913C: 19          add  hl,de
913D: DD 74 41    ld   (ix+TABLE_Y_coord),h
9140: DD 75 60    ld   (ix+TABLE_Y_low),l
9143: 78          ld   a,b
9144: 21 D4 19    ld   hl,$915C			; sprites for Grenade
9147: E7          rst	INDEX_A_PLUS_HL
9148: FD 77 00    ld   (iy+sprite_number),a
914B: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
914E: FD 77 21    ld   (iy+sprite_y),a
9151: DD 7E 21    ld   a,(ix+TABLE_X_coord)
9154: FD 77 20    ld   (iy+sprite_x),a
9157: FD 36 01 10 ld   (iy+sprite_flags),$10
915B: C9          ret

915c:		db	$b4, $b3, $b2, $b2, $b3, $b4
9162:		dw	$00a0, $00c0, $00e0, $0120, $0140, $0160

916E: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
9172: FD 36 20 00 ld   (iy+sprite_x),$00
9176: DD 66 21    ld   h,(ix+TABLE_X_coord)
9179: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
917C: CD C1 38    call MAKE_EXPLOSION
917F: DD 7E 21    ld   a,(ix+TABLE_X_coord)
9182: 32 D9 0E    ld   ($E09D),a
9185: 67          ld   h,a
9186: 32 D8 0E    ld   ($E09C),a
9189: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
918C: 32 F8 0E    ld   ($E09E),a
918F: 6F          ld   l,a
9190: FD 21 65 0E ld   iy,COUNTDOWN_TIMER
9194: FD 36 00 00 ld   (iy+sprite_number),$00
9198: DD 21 00 6E ld   ix,ENEMY_SPRITES
919C: 11 02 00    ld   de,$0020
919F: 06 80       ld   b,$08
91A1: DD 7E 00    ld   a,(ix+TABLE_STATUS)
91A4: 3C          inc  a
91A5: 20 B1       jr   nz,$91C2
91A7: DD 7E 21    ld   a,(ix+TABLE_X_coord)
91AA: 94          sub  h
91AB: C6 90       add  a,$18
91AD: FE 13       cp   $31
91AF: 30 11       jr   nc,$91C2
91B1: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
91B4: 95          sub  l
91B5: C6 82       add  a,$28
91B7: FE 04       cp   $40
91B9: 30 61       jr   nc,$91C2
91BB: DD 36 00 F3 ld   (ix+TABLE_STATUS),$3F
91BF: FD 34 00    inc  (iy+sprite_number)
91C2: DD 19       add  ix,de
91C4: 10 BD       djnz $91A1
91C6: DD 21 00 8E ld   ix,TREE_ROCK_SPRITES
91CA: 11 10 00    ld   de,$0010
91CD: 06 C0       ld   b,$0C
91CF: DD 7E 00    ld   a,(ix+TABLE_STATUS)
91D2: 3C          inc  a
91D3: 20 F1       jr   nz,$91F4
91D5: DD 7E 60    ld   a,(ix+TABLE_Y_low)
91D8: A7          and  a
91D9: 20 91       jr   nz,$91F4
91DB: 7C          ld   a,h
91DC: DD 96 21    sub  (ix+TABLE_X_coord)
91DF: FE E1       cp   $0F
91E1: 30 11       jr   nc,$91F4
91E3: 7D          ld   a,l
91E4: DD 96 41    sub  (ix+TABLE_Y_coord)
91E7: C6 31       add  a,$13
91E9: FE 91       cp   $19
91EB: 30 61       jr   nc,$91F4
91ED: DD 36 00 F3 ld   (ix+TABLE_STATUS),$3F
91F1: FD 34 00    inc  (iy+$00)
91F4: DD 19       add  ix,de
91F6: 10 7D       djnz $91CF
91F8: FD 7E 00    ld   a,(iy+$00)
91FB: A7          and  a
91FC: C8          ret  z
91FD: FE 80       cp   $08
91FF: 38 20       jr   c,$9203
9201: 3E 80       ld   a,$08
9203: 3D          dec  a
9204: 21 BB 38    ld   hl,$92BB
9207: E7          rst	INDEX_A_PLUS_HL
9208: 16 41       ld   d,$05
920A: 5F          ld   e,a
920B: FF          rst  ADD_DE_TO_EVENT
920C: C9          ret

			; Now explode, could be grenade or rocket luncher which exploded
			; Passes H and L as X coord and Y coord respectively. Below is visual of 2x2 sprite number
			; +-----+-----+
			; |     |     |
			; |  1  |  2  |
			; |     |     |
			; +-----+-----+
			; |     |     |
			; |  3  |  4  |
			; |     |     |
			; +-----+-----+		
		
MAKE_EXPLOSION:
920D: 3E 10       ld   a,$10
920F: 32 08 0E    ld   (DO_EXPLOSION),a
9212: FD E5       push iy
9214: FD 21 40 FE ld   iy,HW_SPRITE_1
9218: 7C          ld   a,h			; Get x coordinate
9219: C6 9E       add  a,$F8			; good old 8 bit negative add -8 lol
921B: FD 77 20    ld   (iy+sprite_x),a		
921E: FD 77 A0    ld   (iy+sprite3_x),a		; so we move x from original - 8 so it's centered
9221: C6 10       add  a,$10			; back the 8 and added on 8 for right side sprites
9223: FD 77 60    ld   (iy+sprite2_x),a
9226: FD 77 E0    ld   (iy+sprite4_x),a
9229: 7D          ld   a,l			; get y coordinate
922A: C6 80       add  a,$08			; down 8 pixels for start of two Ys
922C: FD 77 21    ld   (iy+sprite_y),a
922F: FD 77 61    ld   (iy+sprite2_y),a
9232: C6 1E       add  a,$F0			; then a wopper of a -16 for bottom half
9234: FD 77 A1    ld   (iy+sprite3_y),a
9237: FD 77 E1    ld   (iy+sprite4_y),a
923A: FD E1       pop  iy
923C: 3A 00 0F    ld   a,(PLAYER_DATA)
923F: 3C          inc  a
9240: C2 B5 68    jp   nz,SFX_EXPLODE
9243: 3A 21 0F    ld   a,(PLAYER_X)
9246: 94          sub  h
9247: C6 10       add  a,$10
9249: FE 03       cp   $21
924B: D2 B5 68    jp   nc,SFX_EXPLODE
924E: 3A 41 0F    ld   a,(PLAYER_Y)
9251: 95          sub  l
9252: C6 10       add  a,$10
9254: FE 03       cp   $21
9256: D2 B5 68    jp   nc,SFX_EXPLODE
9259: 3E F3       ld   a,$3F
925B: 32 00 0F    ld   (PLAYER_DATA),a
925E: C3 B5 68    jp   SFX_EXPLODE
9261: C9          ret


9262: 32 D8 0E    ld   ($E09C),a
9265: 3A 08 0E    ld   a,(DO_EXPLOSION)
9268: A7          and  a
9269: C8          ret  z			; Not set so exit
926A: FD 21 40 FE ld   iy,HW_SPRITE_1		; First sprite as highest priority on system
926E: 21 08 0E    ld   hl,DO_EXPLOSION
9271: 35          dec  (hl)			; Countdown
9272: 28 93       jr   z,$92AD
9274: 7E          ld   a,(hl)
9275: 0F          rrca
9276: 0F          rrca
9277: E6 21       and  $03
9279: 21 2D 38    ld   hl,$92C3
927C: E7          rst	INDEX_A_PLUS_HL
927D: FD 77 00    ld   (iy+sprite_number),a
9280: 3C          inc  a
9281: FD 77 40    ld   (iy+sprite2_number),a
9284: C6 61       add  a,$07
9286: FD 77 80    ld   (iy+sprite3_number),a
9289: 3C          inc  a
928A: FD 77 C0    ld   (iy+sprite4_number),a
928D: 3E 16       ld   a,$70
928F: FD 77 01    ld   (iy+sprite_flags),a
9292: FD 77 41    ld   (iy+sprite2_flags),a
9295: FD 77 81    ld   (iy+sprite3_flags),a
9298: FD 77 C1    ld   (iy+sprite4_flags),a
929B: 3A 26 0E    ld   a,(SCREEN_SCROLLING)
929E: A7          and  a
929F: C8          ret  z
92A0: FD 35 21    dec  (iy+sprite_y)
92A3: FD 35 61    dec  (iy+sprite2_y)
92A6: FD 35 A1    dec  (iy+sprite3_y)
92A9: FD 35 E1    dec  (iy+sprite4_y)
92AC: C9          ret

92AD: AF          xor  a
92AE: FD 77 20    ld   (iy+sprite_x),a
92B1: FD 77 60    ld   (iy+sprite2_x),a
92B4: FD 77 A0    ld   (iy+sprite3_x),a
92B7: FD 77 E0    ld   (iy+sprite4_x),a
92BA: C9          ret

92BB:		db	$02,$03,$04,$05,$07,$08,$0a,$0c
92C3:		db	$80,$82,$90,$92

92C7: 32 d8 E0    ld   ($E09C),a
92CA: 3A 00 0F    ld   a,($e100)         	; player active?
92CD: 3C          inc  a
92CE: C0          ret  nz
92CF: 3A 91 0E    ld   a,(PLAYER_UP)		; am I player 1 or 2
92D2: E6 01       and  $01
92D4: 28 A1       jr   z,$92E1			; ok so I'm player 2 then
92D6: 3A 51 0E    ld   a,(JOYSTICK1_FIRE2)
92D9: E6 61       and  $07
92DB: C8          ret  z
92DC: FE 01       cp   $01
92DE: C0          ret  nz
92DF: 18 81       jr   $92EA

92E1: 3A C1 0E    ld   a,(JOYSTICK1_FIRE2)	; lunch a grenade then?
92E4: E6 61       and  $07
92E6: C8          ret  z			; nope
92E7: FE 01       cp   $01
92E9: C0          ret  nz
92EA: 3A 70 0F    ld   a,(GRENADE_LUNCHED)	; Already lunched one still animating the throw
92ED: A7          and  a
92EE: C0          ret  nz			; if so exit
92EF: 3A 8A CF    ld   a,(NUM_GRENADES)		; read NUM_GRENADES
92F2: A7          and  a
92F3: C8          ret  z			; none to throw, picks some up then!
92F4: 3D          dec  a			; one less
92F5: 27          daa				; decimal only number
92F6: 32 8A CF    ld   (NUM_GRENADES),a		; update NUM_GRENADES
92F9: 16 A1       ld   d,$0B
92FB: FF          rst  ADD_DE_TO_EVENT		; update grenade display counter value
92FC: 3E 80       ld   a,$08			; Set animation action and action for throw
92FE: 32 70 0F    ld   (GRENADE_LUNCHED),a
9301: C9          ret

9302: DD 21 04 0F ld   ix,grenade_TABLE		; only one can throw at a time
9306: DD 35 00    dec  (ix+TABLE_STATUS)			; make active grenade now.
9309: DD 36 51 12 ld   (iy+TABLE_COUNTDOWN),$30
930D: 3A 21 0F    ld   a,(PLAYER_X)
9310: DD 77 21    ld   (ix+TABLE_X_coord),a	; grenade X
9313: 3A 41 0F    ld   a,(PLAYER_Y)
9316: DD 77 41    ld   (ix+TABLE_Y_coord),a	; grenade Y
9319: CD 74 68    call SFX_GRENADE		; Lunch Grenade sound FX
931C: C9          ret
931D: 3A 00 0F    ld   a,(PLAYER_DATA)
9320: 3C          inc  a
9321: C0          ret  nz
9322: CD 83 39    call $9329
9325: CD 94 39    call $9358
9328: C9          ret
9329: 3A 91 0E    ld   a,(PLAYER_UP)
932C: E6 01       and  $01
932E: 28 A0       jr   z,$933A
9330: 3A 50 0E    ld   a,(JOYSTICK1_FIRE1)
9333: E6 61       and  $07
9335: FE 01       cp   $01
9337: C0          ret  nz
9338: 18 80       jr   $9342
933A: 3A C0 0E    ld   a,(JOYSTICK1_FIRE1)
933D: E6 61       and  $07
933F: FE 01       cp   $01
9341: C0          ret  nz
9342: 21 89 0E    ld   hl,$E089
9345: 7E          ld   a,(hl)
9346: A7          and  a
9347: 28 61       jr   z,$9350
9349: FE 41       cp   $05
934B: 28 01       jr   z,$934E
934D: 34          inc  (hl)
934E: 34          inc  (hl)
934F: C9          ret
9350: 36 20       ld   (hl),$02
9352: 21 D6 0E    ld   hl,$E07C
9355: 36 01       ld   (hl),$01
9357: C9          ret
9358: 3A 89 0E    ld   a,($E089)
935B: A7          and  a
935C: C8          ret  z
935D: 21 D6 0E    ld   hl,$E07C
9360: 35          dec  (hl)
9361: C0          ret  nz
9362: CD E7 39    call $936F
9365: 21 89 0E    ld   hl,$E089
9368: 35          dec  (hl)
9369: 3E 40       ld   a,$04
936B: 32 D6 0E    ld   ($E07C),a
936E: C9          ret


936F: DD 21 00 2E ld   ix,BULLET_SPRITES
9373: 11 02 00    ld   de,$0020
9376: 06 60       ld   b,$06
9378: DD 7E 00    ld   a,(ix+TABLE_STATUS)
937B: A7          and  a
937C: 28 41       jr   z,$9383
937E: DD 19       add  ix,de
9380: 10 7E       djnz $9378
9382: C9          ret
9383: DD 70 F1    ld   (ix+$1f),b
9386: DD 35 00    dec  (ix+TABLE_STATUS)
9389: 3A 21 0F    ld   a,(PLAYER_X)
938C: 57          ld   d,a
938D: 3A 41 0F    ld   a,(PLAYER_Y)
9390: 5F          ld   e,a
9391: 3A 20 0F    ld   a,($E102)
9394: DD 77 01    ld   (ix+$01),a
9397: DD 36 E1 C1 ld   (ix+$0f),$0D
939B: C6 61       add  a,$07
939D: 0F          rrca
939E: 0F          rrca
939F: 0F          rrca
93A0: 0F          rrca
93A1: E6 E1       and  $0F
93A3: DD 77 91    ld   (ix+$19),a
93A6: 87          add  a,a
93A7: 21 DD 39    ld   hl,$93DD
93AA: E7          rst	INDEX_A_PLUS_HL
93AB: 82          add  a,d
93AC: DD 77 21    ld   (ix+TABLE_X_coord),a
93AF: 23          inc  hl
93B0: 7E          ld   a,(hl)
93B1: 83          add  a,e
93B2: DD 77 41    ld   (ix+TABLE_Y_coord),a
93B5: DD 36 30 31 ld   (ix+$12),$13           ; set shot length
93B9: DD 36 50 00 ld   (ix+$14),$00
93BD: DD 36 51 21 ld   (iy+TABLE_COUNTDOWN),$03
93C1: CD 46 C6    call $6C64
93C4: EB          ex   de,hl
93C5: 29          add  hl,hl
93C6: DD 74 A1    ld   (ix+TABLE_X_Add_low),h
93C9: DD 75 C0    ld   (ix+TABLE_X_Add_high),l
93CC: 60          ld   h,b
93CD: 69          ld   l,c
93CE: 29          add  hl,hl
93CF: DD 74 C1    ld   (ix+$0d),h
93D2: DD 75 E0    ld   (ix+$0e),l
93D5: DD 36 31 00 ld   (ix+ITEM_TYPE),$00
93D9: C3 65 68    jp   SFX_BLEEP
93DC: C9          ret

93DD:		db	$0f, $05, $0a, $09, $09, $0a, $07, $0c
93e5:		db	$04, $0e, $f9, $0c, $f7, $0a, $f6, $09
93ed:		db	$f1, $05, $f4, $00, $f9, $fc, $fc, $fe
93f5:		db	$fc, $fb, $04, $fe, $07, $fc, $0c, $00

93FD: 3A 00 0F    ld   a,(PLAYER_DATA)
9400: 3C          inc  a
9401: C0          ret  nz
9402: 3E 00       ld   a,$00
9404: 08          ex   af,af'
9405: DD 7E 21    ld   a,(ix+TABLE_X_coord)			; get object X position
9408: 84          add  a,h				; add passed data paramater in my example was $f4 with means x - 12 ( signed 8 bit)
9409: 67          ld   h,a
940A: DD 7E 41    ld   a,(ix+TABLE_Y_coord)			; get object Y position
940D: 85          add  a,l				; add passed data for Y can be positive or negative
940E: 6F          ld   l,a
940F: 18 E0       jr   $941F

9411: 3A 00 0F    ld   a,(PLAYER_DATA)
9414: 3C          inc  a
9415: C0          ret  nz
9416: DD 66 21    ld   h,(ix+TABLE_X_coord)
9419: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
941C: 3E 01       ld   a,$01
941E: 08          ex   af,af'

941F: 3A 3F 0E    ld   a,(BULLET_TIMER)
9422: A7          and  a
9423: C0          ret  nz
9424: 3A 1F 0E    ld   a,($E0F1)
9427: 57          ld   d,a
9428: 87          add  a,a
9429: 3C          inc  a
942A: 5F          ld   e,a
942B: 3A 21 0F    ld   a,(PLAYER_X)
942E: 94          sub  h
942F: 82          add  a,d
9430: BB          cp   e
9431: 30 61       jr   nc,$943A
9433: 3A 41 0F    ld   a,(PLAYER_Y)
9436: 95          sub  l
9437: 82          add  a,d
9438: BB          cp   e
9439: D8          ret  c
943A: DD E5       push ix
943C: E5          push hl				; save the cordinates
943D: 2E 00       ld   l,$00
943F: DD 7E 31    ld   a,(ix+ITEM_TYPE)
9442: A7          and  a
9443: 20 20       jr   nz,$9447
9445: 2E 08       ld   l,$80
9447: 3A 1E 0E    ld   a,(MAX_BULLETS)			; how many bullets can be fired by enemy.
944A: 47          ld   b,a
944B: DD 21 0C 2E ld   ix,ENEMY_BULLETS
944F: 11 02 00    ld   de,$0020				; each bullet entry has a giant 32 bytes table! (mostly unused)
9452: DD 7E 00    ld   a,(ix+TABLE_STATUS)			; $00 for active bullet
9455: A7          and  a
9456: 28 80       jr   z,$9460				; free slot for bullet
9458: DD 19       add  ix,de				; 
945A: 10 7E       djnz $9452
945C: E1          pop  hl
945D: DD E1       pop  ix
945F: C9          ret

				; Add bullet to shoot at the player, not very sporting is it.
9460: DD 75 31    ld   (ix+ITEM_TYPE),l
9463: E1          pop  hl
9464: DD 35 00    dec  (ix+TABLE_STATUS)				; set to active now as $ff
9467: DD 74 21    ld   (ix+TABLE_X_coord),h
946A: DD 75 41    ld   (ix+TABLE_Y_coord),l
946D: CD 2E C6    call $6CE2
9470: DD 77 01    ld   (ix+$01),a
9473: C6 80       add  a,$08
9475: 0F          rrca
9476: 0F          rrca
9477: 0F          rrca
9478: 0F          rrca
9479: E6 E1       and  $0F
947B: DD 77 91    ld   (ix+$19),a
947E: 3A 9F 0E    ld   a,($E0F9)
9481: DD 77 E1    ld   (ix+$0f),a
9484: CD 46 C6    call $6C64
9487: DD 72 A1    ld   (ix+TABLE_X_Add_low),d
948A: DD 73 C0    ld   (ix+TABLE_X_Add_high),e
948D: DD 70 C1    ld   (ix+$0d),b
9490: DD 71 E0    ld   (ix+$0e),c
9493: DD 36 30 96 ld   (ix+$12),$78			; Enemy Bullet reload speed (not sure why didn't change of difficulty)
9497: DD 36 50 00 ld   (ix+$14),$00
949B: DD 36 51 21 ld   (iy+TABLE_COUNTDOWN),$03
949F: 08          ex   af,af'
94A0: A7          and  a
94A1: 28 02       jr   z,$94C3
94A3: DD 7E 01    ld   a,(ix+$01)
94A6: C6 80       add  a,$08
94A8: 0F          rrca
94A9: 0F          rrca
94AA: 0F          rrca
94AB: 0F          rrca
94AC: E6 E1       and  $0F
94AE: 87          add  a,a
94AF: 21 9D 58    ld   hl,$94D9			; addition table
94B2: E7          rst	INDEX_A_PLUS_HL
94B3: DD 86 21    add  a,(ix+TABLE_X_coord)
94B6: DD 77 21    ld   (ix+TABLE_X_coord),a
94B9: 23          inc  hl
94BA: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
94BD: 86          add  a,(hl)
94BE: DD 77 41    ld   (ix+TABLE_Y_coord),a
94C1: 18 40       jr   $94C7
94C3: DD 36 31 08 ld   (ix+ITEM_TYPE),$80
94C7: DD 7E 01    ld   a,(ix+$01)
94CA: DD E1       pop  ix
94CC: DD 77 20    ld   (ix+$02),a
94CF: CD C4 68    call SFX_BULLET
94D2: 3A 3E 0E    ld   a,(BULLET_TIMER_RESET)
94D5: 32 3F 0E    ld   (BULLET_TIMER),a
94D8: C9          ret

94D9: 		db	$0f, $05
		db	$0a, $09
		db	$09, $0a
		db	$07, $0c
		db	$04, $0e
		db	$f9, $0c
		db	$f7, $0a
		db	$f6, $09
		db	$f1, $05
		db	$f4, $00
		db	$f9, $fc
		db	$fc, $fe
		db	$fc, $fb
		db	$04, $fe
		db	$07, $fc
		db	$0c, $00

94F9: C9          ret
94FA: 3A F9 0E    ld   a,(AREA_END)
94FD: A7          and  a
94FE: 20 61       jr   nz,$9507
9500: 3A 9E 0E    ld   a,(STANDING_TIMER)		; you standing still?
9503: A7          and  a
9504: CA 81 78    jp   z,$9609				; if so then generate enemies automatically 
9507: DD 2A 78 0E ld   ix,(SPAWN_POSITION)		; table position
950B: DD 66 01    ld   h,(ix+$01)
950E: DD 6E 00    ld   l,(ix+$00)
9511: ED 5B B5 0E ld   de,(MAP_OFFSET)
9515: 7B          ld   a,e
9516: 5A          ld   e,d
9517: 57          ld   d,a
9518: A7          and  a
9519: ED 52       sbc  hl,de
951B: 7C          ld   a,h
951C: A7          and  a
951D: C2 4B 59    jp   nz,$95A5
9520: 7D          ld   a,l
9521: FE 04       cp   $40				; With distance of 
9523: DA EB 59    jp   c,$95AF
9526: 32 98 0E    ld   ($E098),a
9529: 4D          ld   c,l
952A: 21 8B 0E    ld   hl,$E0A9
952D: 7E          ld   a,(hl)
952E: E6 61       and  $07
9530: DD 6E 20    ld   l,(ix+$02)
9533: DD 66 21    ld   h,(ix+$03)
9536: EF          rst	INDEX_ED_AT_2A_PLUS_HL
9537: EB          ex   de,hl
9538: D9          exx
9539: DD 21 00 6E ld   ix,ENEMY_SPRITES
953D: 06 80       ld   b,$08
953F: 11 02 00    ld   de,$0020
9542: DD 7E 00    ld   a,(ix+TABLE_STATUS)
9545: A7          and  a
9546: 28 41       jr   z,$954D
9548: DD 19       add  ix,de
954A: 10 7E       djnz $9542
954C: C9          ret

954D: D9          exx
954E: DD 36 E1 01 ld   (ix+$0f),$01
9552: DD 36 11 00 ld   (ix+$11),$00
9556: DD 36 50 00 ld   (ix+$14),$00
955A: DD 36 51 00 ld   (iy+TABLE_COUNTDOWN),$00
955E: 7E          ld   a,(hl)
955F: 23          inc  hl
9560: DD 77 21    ld   (ix+TABLE_X_coord),a
9563: DD 77 61    ld   (ix+TABLE_new_X_high),a
9566: 7E          ld   a,(hl)
9567: E6 01       and  $01
9569: DD 77 31    ld   (ix+ITEM_TYPE),a
956C: 7E          ld   a,(hl)
956D: 23          inc  hl
956E: 81          add  a,c
956F: FE 94       cp   $58
9571: 38 A5       jr   c,$95BE
9573: DD 77 41    ld   (ix+TABLE_Y_coord),a
9576: DD 77 81    ld   (ix+TABLE_new_Y_high),a
9579: DD 74 70    ld   (ix+$16),h
957C: DD 75 71    ld   (ix+$17),l
957F: DD CB 31 64 bit  0,(ix+ITEM_TYPE)
9583: 28 41       jr   z,$958A
9585: CD A0 79    call $970A
9588: 20 52       jr   nz,$95BE
958A: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
958E: CD 4C 59    call $95C4
9591: 3A 5F 0E    ld   a,(ENEMY_TIMER_RESET)
9594: 32 7E 0E    ld   (ENEMY_TIMER),a
9597: 21 8B 0E    ld   hl,$E0A9
959A: 34          inc  (hl)
959B: 3A F9 0E    ld   a,(AREA_END)
959E: A7          and  a
959F: C8          ret  z
95A0: 21 0A 0E    ld   hl,ENDING_ENEMIES
95A3: 35          dec  (hl)
95A4: C9          ret
95A5: AF          xor  a
95A6: 32 98 0E    ld   ($E098),a
95A9: 7C          ld   a,h
95AA: FE 08       cp   $80
95AC: DA E0 78    jp   c,$960E
95AF: DD 23       inc  ix
95B1: DD 23       inc  ix
95B3: DD 23       inc  ix
95B5: DD 23       inc  ix
95B7: DD 22 78 0E ld   (SPAWN_POSITION),ix
95BB: 18 15       jr   $960E
95BD: C9          ret

95BE: 21 8B 0E    ld   hl,$E0A9
95C1: 34          inc  (hl)
95C2: 18 A4       jr   $960E

95C4: 3A 20 0E    ld   a,(FRAME_SYNC)
95C7: E6 06       and  $60
95C9: C0          ret  nz
95CA: 21 DE 0E    ld   hl,$E0FC
95CD: 7E          ld   a,(hl)
95CE: A7          and  a
95CF: C8          ret  z
95D0: 36 00       ld   (hl),$00
95D2: DD 7E 31    ld   a,(ix+ITEM_TYPE)
95D5: A7          and  a
95D6: 20 40       jr   nz,$95DC
95D8: DD 36 90 04 ld   (ix+$18),$40
95DC: DD 36 31 A0 ld   (ix+ITEM_TYPE),$0A
95E0: DD 7E 21    ld   a,(ix+TABLE_X_coord)
95E3: FE 08       cp   $80
95E5: 38 A0       jr   c,$95F1
95E7: DD 36 91 01 ld   (ix+$19),$01
95EB: DD 36 01 1A ld   (ix+$01),$B0
95EF: 18 80       jr   $95F9
95F1: DD 36 91 00 ld   (ix+$19),$00
95F5: DD 36 01 1C ld   (ix+$01),$D0
95F9: CD 46 C6    call $6C64
95FC: DD 72 A1    ld   (ix+TABLE_X_Add_low),d
95FF: DD 73 C0    ld   (ix+TABLE_X_Add_high),e
9602: DD 70 C1    ld   (ix+$0d),b
9605: DD 71 E0    ld   (ix+$0e),c
9608: C9          ret

9609: 3E 01       ld   a,$01
960B: 32 BE 0E    ld   ($E0FA),a
960E: DD 21 00 6E ld   ix,ENEMY_SPRITES
9612: 06 80       ld   b,$08
9614: 11 02 00    ld   de,$0020
9617: DD 7E 00    ld   a,(ix+TABLE_STATUS)
961A: A7          and  a
961B: 28 41       jr   z,$9622
961D: DD 19       add  ix,de
961F: 10 7E       djnz $9617
9621: C9          ret
9622: 3A BE 0E    ld   a,($E0FA)
9625: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$962c   ; Value 0
		dw	$9668   ; Value 1
		dw	$96cb   ; Value 2
	
962C: DD 35 00    dec  (ix+TABLE_STATUS)
962F: DD 36 11 00 ld   (ix+$11),$00
9633: DD 36 31 21 ld   (ix+ITEM_TYPE),$03		; Enemy type
9637: CD E3 98    call $982F
963A: E6 0E       and  $E0
963C: DD 77 21    ld   (ix+TABLE_X_coord),a
963F: DD 77 61    ld   (ix+TABLE_new_X_high),a
9642: DD 36 41 1E ld   (ix+TABLE_Y_coord),$F0
9646: DD 36 81 1E ld   (ix+TABLE_new_Y_high),$F0
964A: DD 36 50 00 ld   (ix+$14),$00
964E: DD 36 51 00 ld   (iy+TABLE_COUNTDOWN),$00
9652: DD 36 90 00 ld   (ix+$18),$00
9656: 3A 5F 0E    ld   a,(ENEMY_TIMER_RESET)
9659: 32 7E 0E    ld   (ENEMY_TIMER),a
965C: DD 36 01 0C ld   (ix+$01),$C0
9660: DD 36 20 0C ld   (ix+$02),$C0
9664: C3 6E 78    jp   $96E6
9667: C9          ret

9668: DD 35 00    dec  (ix+TABLE_STATUS)
966B: DD 36 11 00 ld   (ix+$11),$00
966F: DD 36 31 40 ld   (ix+ITEM_TYPE),$04
9673: CD E3 98    call $982F
9676: 47          ld   b,a
9677: E6 0E       and  $E0
9679: DD 77 41    ld   (ix+TABLE_Y_coord),a
967C: DD 77 81    ld   (ix+TABLE_new_Y_high),a
967F: 3E 1E       ld   a,$F0
9681: 0E 08       ld   c,$80
9683: CB 50       bit  2,b
9685: 28 40       jr   z,$968B
9687: 3E 00       ld   a,$00
9689: 0E 00       ld   c,$00
968B: DD 77 21    ld   (ix+TABLE_X_coord),a
968E: DD 77 61    ld   (ix+TABLE_new_X_high),a
9691: 78          ld   a,b
9692: E6 E1       and  $0F
9694: D6 80       sub  $08
9696: 81          add  a,c
9697: DD 77 01    ld   (ix+$01),a
969A: DD 77 20    ld   (ix+$02),a
969D: DD 36 50 00 ld   (ix+$14),$00
96A1: DD 36 51 00 ld   (iy+TABLE_COUNTDOWN),$00
96A5: DD 36 90 00 ld   (ix+$18),$00
96A9: DD 36 71 00 ld   (ix+$17),$00
96AD: 3A 5F 0E    ld   a,(ENEMY_TIMER_RESET)
96B0: 32 7E 0E    ld   (ENEMY_TIMER),a
96B3: CD 46 C6    call $6C64
96B6: DD 72 A1    ld   (ix+TABLE_X_Add_low),d
96B9: DD 73 C0    ld   (ix+TABLE_X_Add_high),e
96BC: DD 70 C1    ld   (ix+$0d),b
96BF: DD 71 E0    ld   (ix+$0e),c
96C2: CD A0 79    call $970A
96C5: C8          ret  z
96C6: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
96CA: C9          ret

96CB: DD 35 00    dec  (ix+TABLE_STATUS)
96CE: DD 36 11 00 ld   (ix+$11),$00
96D2: DD 36 31 41 ld   (ix+ITEM_TYPE),$05
96D6: CD E3 98    call $982F
96D9: 47          ld   b,a
96DA: E6 F7       and  $7F
96DC: C6 08       add  a,$80
96DE: DD 77 41    ld   (ix+TABLE_Y_coord),a
96E1: DD 77 81    ld   (ix+TABLE_new_Y_high),a
96E4: 18 99       jr   $967F
96E6: 06 21       ld   b,$03
96E8: 0E 02       ld   c,$20
96EA: FE 08       cp   $80
96EC: DD 7E 21    ld   a,(ix+TABLE_X_coord)
96EF: 38 20       jr   c,$96F3
96F1: 0E 0E       ld   c,$E0
96F3: C5          push bc
96F4: CD A0 79    call $970A
96F7: C1          pop  bc
96F8: C8          ret  z
96F9: DD 7E 21    ld   a,(ix+TABLE_X_coord)
96FC: 81          add  a,c
96FD: DD 77 21    ld   (ix+TABLE_X_coord),a
9700: DD 77 61    ld   (ix+TABLE_new_X_high),a
9703: 10 EE       djnz $96F3
9705: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
9709: C9          ret
970A: CD 39 A9    call $8B93
970D: A7          and  a
970E: C2 A6 79    jp   nz,$976A
9711: DD 7E 81    ld   a,(ix+TABLE_new_Y_high)
9714: 47          ld   b,a
9715: 3A 30 EF    ld   a,($EF12)
9718: E6 E1       and  $0F
971A: 80          add  a,b
971B: 47          ld   b,a
971C: DD 7E 61    ld   a,(ix+TABLE_new_X_high)
971F: C6 61       add  a,$07
9721: 4F          ld   c,a
9722: 3A 10 EF    ld   a,($EF10)
9725: 57          ld   d,a
9726: 3A 11 EF    ld   a,($EF11)
9729: 5F          ld   e,a
972A: 78          ld   a,b
972B: E6 1E       and  $F0
972D: 6F          ld   l,a
972E: 26 00       ld   h,$00
9730: 29          add  hl,hl
9731: 19          add  hl,de
9732: 79          ld   a,c
9733: CB 3F       srl  a
9735: 4F          ld   c,a
9736: CB 3F       srl  a
9738: CB 3F       srl  a
973A: E6 F0       and  $1E
973C: DF          rst	ADD_A_TO_HL
973D: 7C          ld   a,h
973E: E6 BF       and  $FB
9740: 67          ld   h,a
9741: 7E          ld   a,(hl)
9742: A7          and  a
9743: C8          ret  z
9744: 5F          ld   e,a
9745: 23          inc  hl
9746: 7E          ld   a,(hl)
9747: A7          and  a
9748: 28 21       jr   z,$974D
974A: 79          ld   a,c
974B: 2F          cpl
974C: 4F          ld   c,a
974D: 6B          ld   l,e
974E: 26 00       ld   h,$00
9750: 29          add  hl,hl
9751: 29          add  hl,hl
9752: 29          add  hl,hl
9753: 78          ld   a,b
9754: 0F          rrca
9755: 2F          cpl
9756: E6 61       and  $07
9758: DF          rst	ADD_A_TO_HL
9759: 11 46 46    ld   de,$6464
975C: 19          add  hl,de
975D: 56          ld   d,(hl)
975E: 79          ld   a,c
975F: E6 61       and  $07
9761: 21 E6 79    ld   hl,BIT_TABLE2
9764: DF          rst	ADD_A_TO_HL
9765: 7E          ld   a,(hl)
9766: A2          and  d
9767: 20 01       jr   nz,$976A
9769: C9          ret
976A: 3E 01       ld   a,$01
976C: A7          and  a
976D: C9          ret

BIT_TABLE2: 		db $80,$40,$20,$10,$08,$04,$02,$01		; Another bit table! why duplicate this twice!

9776: 3A 20 0E    ld   a,(FRAME_SYNC)
9779: E6 F1       and  $1F
977B: C0          ret  nz
977C: 3A 55 0E    ld   a,(ENEMY_SPRITE_COUNT)
977F: FE 20       cp   $02
9781: D0          ret  nc
9782: 21 AE 79    ld   hl,$97EA
9785: E5          push hl
9786: 3A BA 0E    ld   a,($E0BA)
9789: 21 8C 7B    ld   hl,$B7C8
978C: EF          rst	INDEX_ED_AT_2A_PLUS_HL
978D: D5          push de
978E: FD E1       pop  iy
9790: FD 4E 00    ld   c,(iy+$00)
9793: FD 23       inc  iy
9795: DD 21 00 6E ld   ix,ENEMY_SPRITES
9799: 06 80       ld   b,$08
979B: DD 7E 00    ld   a,(ix+TABLE_STATUS)
979E: A7          and  a
979F: 28 80       jr   z,$97A9
97A1: 11 02 00    ld   de,$0020
97A4: DD 19       add  ix,de
97A6: 10 3F       djnz $979B
97A8: C9          ret
97A9: DD 35 00    dec  (ix+TABLE_STATUS)
97AC: FD 7E 00    ld   a,(iy+$00)
97AF: DD 77 21    ld   (ix+TABLE_X_coord),a
97B2: DD 77 61    ld   (ix+TABLE_new_X_high),a
97B5: FD 7E 01    ld   a,(iy+$01)
97B8: DD 77 41    ld   (ix+TABLE_Y_coord),a
97BB: DD 77 81    ld   (ix+TABLE_new_Y_high),a
97BE: FD 7E 21    ld   a,(iy+$03)
97C1: DD 77 70    ld   (ix+$16),a
97C4: FD 7E 20    ld   a,(iy+$02)
97C7: DD 77 71    ld   (ix+$17),a
97CA: FD 7E 40    ld   a,(iy+$04)
97CD: DD 77 31    ld   (ix+ITEM_TYPE),a
97D0: DD 36 E1 00 ld   (ix+$0f),$00
97D4: DD 36 11 00 ld   (ix+$11),$00
97D8: DD 36 50 00 ld   (ix+$14),$00
97DC: DD 36 51 00 ld   (iy+TABLE_COUNTDOWN),$00
97E0: 11 41 00    ld   de,$0005
97E3: FD 19       add  iy,de
97E5: 0D          dec  c
97E6: C8          ret  z
97E7: C3 0B 79    jp   $97A1
97EA: 21 BB 0E    ld   hl,$E0BB
97ED: 35          dec  (hl)
97EE: C9          ret
97EF: 3A B0 0F    ld   a,($E11A)
97F2: A7          and  a
97F3: C0          ret  nz
97F4: 3A BB 0E    ld   a,($E0BB)
97F7: A7          and  a
97F8: C2 76 79    jp   nz,$9776
97FB: 3A 7E 0E    ld   a,(ENEMY_TIMER)
97FE: A7          and  a
97FF: C0          ret  nz
9800: 3A 55 0E    ld   a,(ENEMY_SPRITE_COUNT)
9803: 47          ld   b,a
9804: 3A 5E 0E    ld   a,(MAX_ENEMY)
9807: B8          cp   b
9808: D8          ret  c
9809: 3A F9 0E    ld   a,(AREA_END)
980C: A7          and  a
980D: 28 60       jr   z,$9815
980F: 21 0A 0E    ld   hl,ENDING_ENEMIES
9812: 7E          ld   a,(hl)
9813: A7          and  a
9814: C8          ret  z
9815: CD BE 58    call $94FA
9818: C9          ret
9819: 21 43 98    ld   hl,$9825
981C: 11 0C EE    ld   de,$EEC0
981F: 01 A0 00    ld   bc,$000A
9822: ED B0       ldir
9824: C9          ret

9825:		db	$af, $e1, $32, $7d, $4b, $00, $96, $c8, $64, $19

982F: E5          push hl
9830: D5          push de
9831: C5          push bc
9832: 3A 0C EE    ld   a,($EEC0)
9835: 47          ld   b,a
9836: 3A 20 0E    ld   a,(FRAME_SYNC)
9839: 80          add  a,b
983A: 47          ld   b,a
983B: 3A 92 FF    ld   a,(PLAYER_SPRITE)
983E: 80          add  a,b
983F: 21 0D EE    ld   hl,$EEC1
9842: 11 0C EE    ld   de,$EEC0
9845: ED A0       ldi
9847: ED A0       ldi
9849: ED A0       ldi
984B: ED A0       ldi
984D: ED A0       ldi
984F: ED A0       ldi
9851: ED A0       ldi
9853: ED A0       ldi
9855: ED A0       ldi
9857: 32 8D EE    ld   ($EEC9),a
985A: C1          pop  bc
985B: D1          pop  de
985C: E1          pop  hl
985D: C9          ret
985E: C9          ret
985F: 21 97 1D    ld   hl,$D179
9862: 22 A7 0E    ld   ($E06B),hl
9865: 21 7C 1C    ld   hl,$D0D6
9868: 22 19 0E    ld   ($E091),hl
986B: AF          xor  a
986C: 32 71 0E    ld   ($E017),a
986F: 32 9A 0E    ld   ($E0B8),a
9872: 32 9B 0E    ld   ($E0B9),a
9875: CD 6E 98    call $98E6
9878: CD AB 98    call $98AB
987B: CD AD 98    call $98CB
987E: CD C9 98    call $988D
9881: 3E 06       ld   a,$60
9883: 32 E7 0E    ld   ($E06F),a
9886: CD BB 68    call SFX_STOP_MUS
9889: CD 7F 68    call SFX_INTOHIGH
988C: C9          ret
988D: DD 21 00 2E ld   ix,BULLET_SPRITES
9891: 06 40       ld   b,$04
9893: 11 10 00    ld   de,$0010
9896: CD 2A 98    call $98A2
9899: DD 21 0C 2E ld   ix,ENEMY_BULLETS
989D: 06 A0       ld   b,$0A
989F: 11 40 00    ld   de,$0004
98A2: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
98A6: DD 19       add  ix,de
98A8: 10 9E       djnz $98A2
98AA: C9          ret


98AB: DD 21 00 0F ld   ix,PLAYER_DATA
98AF: FD 21 92 FF ld   iy,PLAYER_SPRITE
98B3: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
98B7: DD 36 21 C2 ld   (ix+TABLE_X_coord),$2C
98BB: DD 36 41 04 ld   (ix+TABLE_Y_coord),$40
98BF: 11 4D 98    ld   de,$98C5
98C2: C3 88 A3    jp   HW_SPRITE_UPDATER
98C5: 20 00       jr   nz,$98C7
98C7: 01 60 00    ld   bc,$0006
98CA: E0          ret  po
98CB: DD 21 80 0F ld   ix,$E108
98CF: FD 21 04 FF ld   iy,HW_SPRITE_80
98D3: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
98D7: DD 36 21 C2 ld   (ix+TABLE_X_coord),$2C
98DB: DD 36 41 CA ld   (ix+TABLE_Y_coord),$AC
98DF: 1E 7F       ld   e,$F7
98E1: 16 08       ld   d,$80
98E3: C3 9C D0    jp   SPRITE_UPDATE_DE
98E6: 11 61 99    ld   de,$9907
98E9: 21 7C 1C    ld   hl,$D0D6
98EC: 0E 21       ld   c,$03
98EE: 06 A0       ld   b,$0A
98F0: E5          push hl
98F1: CB D4       set  2,h
98F3: 36 00       ld   (hl),$00
98F5: CB 94       res  2,h
98F7: 1A          ld   a,(de)
98F8: 77          ld   (hl),a
98F9: 3E 04       ld   a,$40
98FB: DF          rst	ADD_A_TO_HL
98FC: 13          inc  de
98FD: 10 3E       djnz $98F1
98FF: E1          pop  hl
9900: 0D          dec  c
9901: C8          ret  z
9902: 2D          dec  l
9903: 2D          dec  l
9904: 18 8E       jr   $98EE
9906: C9          ret

9907:			db "ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]"

9921: B5          or   l
9922: D4 D5 F6    call nc,$7E5D

9925: 3A 9A 0E    ld   a,($E0B8)
9928: A7          and  a
9929: 20 C2       jr   nz,$9957
992B: CD 49 99    call $9985
992E: CD FB 99    call $99BF
9931: CD C5 B8    call $9A4D
9934: CD 05 99    call $9941
9937: CD BD B8    call $9ADB
993A: CD F3 B9    call $9B3F
993D: CD 21 D8    call $9C03
9940: C9          ret
9941: DD 7E 21    ld   a,(ix+TABLE_X_coord)
9944: 0F          rrca
9945: 0F          rrca
9946: E6 21       and  $03
9948: 21 F3 D8    ld   hl,$9C3F
994B: FD 21 92 FF ld   iy,PLAYER_SPRITE
994F: EF          rst	INDEX_ED_AT_2A_PLUS_HL
9950: FD 73 00    ld   (iy+sprite_number),e
9953: FD 72 40    ld   (iy+sprite2_number),d
9956: C9          ret

9957: CD F3 B9    call $9B3F
995A: CD 21 D8    call $9C03
995D: DD 21 00 2E ld   ix,BULLET_SPRITES
9961: 11 10 00    ld   de,$0010
9964: 06 40       ld   b,$04				; Player bullets max 4
9966: CD B6 99    call $997A
9969: C0          ret  nz
996A: DD 21 0C 2E ld   ix,ENEMY_BULLETS
996E: 11 40 00    ld   de,$0004
9971: 06 A0       ld   b,$0A				; Enemy bullets max 10
9973: CD B6 99    call $997A
9976: C0          ret  nz
9977: C3 8B 99    jp   $99A9

997A: DD 7E 00    ld   a,(ix+TABLE_STATUS)
997D: A7          and  a
997E: C0          ret  nz
997F: DD 19       add  ix,de
9981: 10 7F       djnz $997A
9983: AF          xor  a
9984: C9          ret

9985: 3A 16 0E    ld   a,($E070)
9988: A7          and  a
9989: 28 41       jr   z,$9990
998B: 3D          dec  a
998C: 32 16 0E    ld   ($E070),a
998F: C9          ret

9990: 3E D2       ld   a,$3C
9992: 32 16 0E    ld   ($E070),a
9995: 21 E7 0E    ld   hl,$E06F
9998: 7E          ld   a,(hl)
9999: D6 01       sub  $01
999B: 27          daa
999C: DA 5F B9    jp   c,$9BF5
999F: 77          ld   (hl),a
99A0: 21 D2 1D    ld   hl,$D13C
99A3: 0E 01       ld   c,$01
99A5: C3 D8 D8    jp   PRINT_NUMBER
99A8: C9          ret

99A9: 3E 01       ld   a,$01
99AB: 32 71 0E    ld   ($E017),a
99AE: 11 B8 EE    ld   de,$EE9A
99B1: 21 97 1D    ld   hl,$D179
99B4: 06 A0       ld   b,$0A
99B6: 7E          ld   a,(hl)
99B7: 12          ld   (de),a
99B8: 3E 02       ld   a,$20
99BA: DF          rst	ADD_A_TO_HL
99BB: 13          inc  de
99BC: 10 9E       djnz $99B6
99BE: C9          ret

99BF: DD 21 00 0F ld   ix,PLAYER_DATA
99C3: FD 21 92 FF ld   iy,PLAYER_SPRITE
99C7: DD 7E 00    ld   a,(ix+TABLE_STATUS)
99CA: A7          and  a
99CB: 28 D3       jr   z,$9A0A
99CD: 06 20       ld   b,$02
99CF: DD 7E 01    ld   a,(ix+$01)
99D2: A7          and  a
99D3: 28 20       jr   z,$99D7
99D5: 06 FE       ld   b,$FE
99D7: DD 7E 21    ld   a,(ix+TABLE_X_coord)
99DA: 80          add  a,b
99DB: DD 77 21    ld   (ix+TABLE_X_coord),a
99DE: DD 77 A1    ld   (ix+TABLE_X_Add_low),a
99E1: FD 77 A0    ld   (iy+sprite3_x),a
99E4: CD FB 98    call $98BF
99E7: DD 35 00    dec  (ix+TABLE_STATUS)
99EA: C0          ret  nz
99EB: 21 9B 0E    ld   hl,$E0B9
99EE: ED 5B 19 0E ld   de,($E091)
99F2: DD 7E 01    ld   a,(ix+$01)
99F5: A7          and  a
99F6: 20 81       jr   nz,$9A01
99F8: 34          inc  (hl)
99F9: 21 04 00    ld   hl,$0040
99FC: 19          add  hl,de
99FD: 22 19 0E    ld   ($E091),hl
9A00: C9          ret

9A01: 35          dec  (hl)
9A02: 21 0C FF    ld   hl,$FFC0
9A05: 19          add  hl,de
9A06: 22 19 0E    ld   ($E091),hl
9A09: C9          ret

9A0A: 3A 91 0E    ld   a,(PLAYER_UP)
9A0D: E6 01       and  $01
9A0F: 28 E1       jr   z,$9A20
9A11: 3A 11 0E    ld   a,(JOYSTICK2_LEFT)
9A14: E6 01       and  $01
9A16: 20 71       jr   nz,$9A2F
9A18: 3A 10 0E    ld   a,(JOYSTICK2_RIGHT)
9A1B: E6 01       and  $01
9A1D: 20 F1       jr   nz,$9A3E
9A1F: C9          ret

9A20: 3A 81 0E    ld   a,(JOYSTICK1_LEFT)
9A23: E6 01       and  $01
9A25: 20 80       jr   nz,$9A2F
9A27: 3A 80 0E    ld   a,(JOYSTICK1_RIGHT)
9A2A: E6 01       and  $01
9A2C: 20 10       jr   nz,$9A3E
9A2E: C9          ret

9A2F: DD 7E 21    ld   a,(ix+TABLE_X_coord)
9A32: FE C2       cp   $2C
9A34: C8          ret  z
9A35: DD 36 01 01 ld   (ix+$01),$01
9A39: DD 36 00 80 ld   (ix+TABLE_STATUS),$08
9A3D: C9          ret

9A3E: DD 7E 21    ld   a,(ix+TABLE_X_coord)
9A41: FE DA       cp   $BC
9A43: C8          ret  z
9A44: DD 36 01 00 ld   (ix+$01),$00
9A48: DD 36 00 80 ld   (ix+TABLE_STATUS),$08
9A4C: C9          ret

9A4D: DD 21 80 0F ld   ix,$E108
9A51: FD 21 04 FF ld   iy,HW_SPRITE_80
9A55: DD 7E 00    ld   a,(ix+TABLE_STATUS)
9A58: A7          and  a
9A59: 28 D3       jr   z,$9A98
9A5B: 06 20       ld   b,$02
9A5D: DD 7E 01    ld   a,(ix+$01)
9A60: A7          and  a
9A61: 28 20       jr   z,$9A65
9A63: 06 FE       ld   b,$FE
9A65: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
9A68: 80          add  a,b
9A69: DD 77 41    ld   (ix+TABLE_Y_coord),a
9A6C: CD FD 98    call $98DF
9A6F: DD 35 00    dec  (ix+TABLE_STATUS)
9A72: C0          ret  nz
9A73: 21 9B 0E    ld   hl,$E0B9
9A76: ED 5B 19 0E ld   de,($E091)
9A7A: DD 7E 01    ld   a,(ix+$01)
9A7D: A7          and  a
9A7E: 20 C0       jr   nz,$9A8C
9A80: 7E          ld   a,(hl)
9A81: C6 7E       add  a,$F6
9A83: 77          ld   (hl),a
9A84: 21 20 00    ld   hl,$0002
9A87: 19          add  hl,de
9A88: 22 19 0E    ld   ($E091),hl
9A8B: C9          ret

9A8C: 7E          ld   a,(hl)
9A8D: C6 A0       add  a,$0A
9A8F: 77          ld   (hl),a
9A90: 21 FE FF    ld   hl,$FFFE
9A93: 19          add  hl,de
9A94: 22 19 0E    ld   ($E091),hl
9A97: C9          ret

9A98: 3A 91 0E    ld   a,(PLAYER_UP)
9A9B: E6 01       and  $01
9A9D: 28 E1       jr   z,$9AAE
9A9F: 3A 31 0E    ld   a,(JOYSTICK2_UP)
9AA2: E6 01       and  $01
9AA4: 20 71       jr   nz,$9ABD
9AA6: 3A 30 0E    ld   a,(JOYSTICK2_DOWN)
9AA9: E6 01       and  $01
9AAB: 20 F1       jr   nz,$9ACC
9AAD: C9          ret

9AAE: 3A A1 0E    ld   a,(JOYSTICK1_UP)
9AB1: E6 01       and  $01
9AB3: 20 80       jr   nz,$9ABD
9AB5: 3A A0 0E    ld   a,(JOYSTICK1_LEFT)
9AB8: E6 01       and  $01
9ABA: 20 10       jr   nz,$9ACC
9ABC: C9          ret

9ABD: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
9AC0: FE CA       cp   $AC
9AC2: C8          ret  z
9AC3: DD 36 01 00 ld   (ix+$01),$00
9AC7: DD 36 00 80 ld   (ix+TABLE_STATUS),$08
9ACB: C9          ret

9ACC: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
9ACF: FE C8       cp   $8C
9AD1: C8          ret  z
9AD2: DD 36 01 01 ld   (ix+$01),$01
9AD6: DD 36 00 80 ld   (ix+TABLE_STATUS),$08
9ADA: C9          ret

9ADB: 21 C0 0E    ld   hl,JOYSTICK1_FIRE1
9ADE: 3A 91 0E    ld   a,(PLAYER_UP)
9AE1: E6 01       and  $01
9AE3: 28 21       jr   z,$9AE8
9AE5: 21 50 0E    ld   hl,JOYSTICK1_FIRE1
9AE8: 7E          ld   a,(hl)
9AE9: E6 61       and  $07
9AEB: FE 01       cp   $01
9AED: C0          ret  nz
9AEE: DD 21 00 2E ld   ix,BULLET_SPRITES
9AF2: FD 21 84 FF ld   iy,BULLET_SPRITES
9AF6: 11 40 00    ld   de,$0004
9AF9: 01 10 00    ld   bc,$0010
9AFC: 26 40       ld   h,$04
9AFE: DD 7E 00    ld   a,(ix+TABLE_STATUS)
9B01: A7          and  a
9B02: 28 81       jr   z,$9B0D
9B04: DD 09       add  ix,bc
9B06: FD 19       add  iy,de
9B08: 25          dec  h
9B09: C8          ret  z
9B0A: C3 FE B8    jp   $9AFE
9B0D: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
9B11: 3A 21 0F    ld   a,(PLAYER_X)
9B14: FD 77 20    ld   (iy+sprite_x),a
9B17: 3A C1 0F    ld   a,($E10D)
9B1A: DD 77 40    ld   (ix+TABLE_X_low),a
9B1D: 3A 41 0F    ld   a,(PLAYER_Y)
9B20: FD 77 21    ld   (iy+sprite_y),a
9B23: FD 36 00 5B ld   (iy+sprite_number),$B5
9B27: FD 36 01 00 ld   (iy+sprite_flags),$00
9B2B: 3A 9B 0E    ld   a,($E0B9)
9B2E: 21 61 99    ld   hl,$9907
9B31: E7          rst	INDEX_A_PLUS_HL
9B32: DD 77 01    ld   (ix+$01),a
9B35: 2A 19 0E    ld   hl,($E091)
9B38: DD 74 20    ld   (ix+$02),h
9B3B: DD 75 21    ld   (ix+TABLE_X_coord),l
9B3E: C9          ret

9B3F: DD 21 00 2E ld   ix,BULLET_SPRITES
9B43: FD 21 84 FF ld   iy,BULLET_SPRITES
9B47: 06 40       ld   b,$04
9B49: C5          push bc
9B4A: DD 7E 00    ld   a,(ix+TABLE_STATUS)
9B4D: A7          and  a
9B4E: 28 21       jr   z,$9B53
9B50: CD 07 B9    call $9B61
9B53: C1          pop  bc
9B54: 11 10 00    ld   de,$0010
9B57: DD 19       add  ix,de
9B59: 11 40 00    ld   de,$0004
9B5C: FD 19       add  iy,de
9B5E: 10 8F       djnz $9B49
9B60: C9          ret

9B61: FD 34 21    inc  (iy+sprite_y)
9B64: FD 34 21    inc  (iy+sprite_y)
9B67: FD 34 21    inc  (iy+sprite_y)
9B6A: DD 7E 40    ld   a,(ix+TABLE_X_low)
9B6D: FD 96 21    sub  (iy+sprite_y)
9B70: D0          ret  nc
9B71: 3A 9A 0E    ld   a,($E0B8)
9B74: A7          and  a
9B75: C2 BE B9    jp   nz,$9BFA
9B78: DD 7E 01    ld   a,(ix+$01)
9B7B: FE F6       cp   $7E
9B7D: 28 76       jr   z,$9BF5
9B7F: FE D5       cp   $5D
9B81: 28 E5       jr   z,$9BD2
9B83: DD 66 01    ld   h,(ix+$01)
9B86: DD 56 20    ld   d,(ix+$02)
9B89: DD 5E 21    ld   e,(ix+TABLE_X_coord)
9B8C: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
9B90: FD 36 20 00 ld   (iy+sprite_x),$00
9B94: D9          exx
9B95: DD E5       push ix
9B97: DD 21 0C 2E ld   ix,ENEMY_BULLETS
9B9B: 11 40 00    ld   de,$0004
9B9E: DD 7E 00    ld   a,(ix+TABLE_STATUS)
9BA1: A7          and  a
9BA2: 28 41       jr   z,$9BA9
9BA4: DD 19       add  ix,de
9BA6: C3 F8 B9    jp   $9B9E
9BA9: D9          exx
9BAA: DD 36 00 06 ld   (ix+TABLE_STATUS),$60
9BAE: DD 74 01    ld   (ix+$01),h
9BB1: DD 72 20    ld   (ix+$02),d
9BB4: DD 73 21    ld   (ix+TABLE_X_coord),e
9BB7: DD E1       pop  ix
9BB9: 7C          ld   a,h
9BBA: 2A A7 0E    ld   hl,($E06B)
9BBD: 77          ld   (hl),a
9BBE: 11 02 00    ld   de,$0020
9BC1: 19          add  hl,de
9BC2: 22 A7 0E    ld   ($E06B),hl
9BC5: 11 9B 3C    ld   de,$D2B9
9BC8: 7C          ld   a,h
9BC9: BA          cp   d
9BCA: C0          ret  nz
9BCB: 7D          ld   a,l
9BCC: BB          cp   e
9BCD: C0          ret  nz
9BCE: C3 5F B9    jp   $9BF5
9BD1: C9          ret

9BD2: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
9BD6: FD 36 20 00 ld   (iy+sprite_x),$00
9BDA: 11 97 1D    ld   de,$D179
9BDD: 2A A7 0E    ld   hl,($E06B)
9BE0: 7C          ld   a,h
9BE1: BA          cp   d
9BE2: 20 40       jr   nz,$9BE8
9BE4: 7D          ld   a,l
9BE5: BB          cp   e
9BE6: 28 A0       jr   z,$9BF2
9BE8: 11 0E FF    ld   de,$FFE0
9BEB: 19          add  hl,de
9BEC: 22 A7 0E    ld   ($E06B),hl
9BEF: 36 E2       ld   (hl),$2E
9BF1: C9          ret

9BF2: 36 E2       ld   (hl),$2E
9BF4: C9          ret

9BF5: 3E 01       ld   a,$01
9BF7: 32 9A 0E    ld   ($E0B8),a
9BFA: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
9BFE: FD 36 20 00 ld   (iy+sprite_x),$00
9C02: C9          ret

9C03: DD 21 0C 2E ld   ix,ENEMY_BULLETS
9C07: 11 40 00    ld   de,$0004
9C0A: 06 A0       ld   b,$0A
9C0C: D9          exx
9C0D: DD 7E 00    ld   a,(ix+TABLE_STATUS)
9C10: A7          and  a
9C11: 28 21       jr   z,$9C16
9C13: CD D0 D8    call $9C1C
9C16: D9          exx
9C17: DD 19       add  ix,de
9C19: 10 1F       djnz $9C0C
9C1B: C9          ret
9C1C: DD 35 00    dec  (ix+TABLE_STATUS)

9C1F: 28 D2       jr   z,$9C5D
9C21: DD 7E 00    ld   a,(ix+TABLE_STATUS)
9C24: 0F          rrca
9C25: E6 61       and  $07
9C27: 47          ld   b,a
9C28: E6 21       and  $03
9C2A: FE 20       cp   $02
9C2C: 28 83       jr   z,$9C57
9C2E: 78          ld   a,b
9C2F: 21 65 D8    ld   hl,$9C47
9C32: EF          rst	INDEX_ED_AT_2A_PLUS_HL
9C33: CD 47 D8    call $9C65
9C36: DD 7E 01    ld   a,(ix+$01)
9C39: 83          add  a,e
9C3A: 77          ld   (hl),a
9C3B: CB D4       set  2,h
9C3D: 72          ld   (hl),d
9C3E: C9          ret

9c3f:		db	$05, $0d, $06, $0e, $07, $0f, $06, $0e
9c47:		db	$00, $00, $40, $00, $40, $00, $40, $20
		db	$00, $20, $20, $20, $20, $00, $20, $00

9C57: CD 47 D8    call $9C65
9C5A: 36 F7       ld   (hl),$7F
9C5C: C9          ret

9C5D: CD 47 D8    call $9C65
9C60: DD 7E 01    ld   a,(ix+$01)
9C63: 77          ld   (hl),a
9C64: C9          ret

9C65: DD 66 20    ld   h,(ix+$02)
9C68: DD 6E 21    ld   l,(ix+TABLE_X_coord)
9C6B: C9          ret

9C6C: C9          ret


		; Prints text to the character memory, source is in HL registers
		; First two bytes define the destination address in Lo/Hi in Front character memory
		; Next byte is the colour Ram value
		; Then all text up until $40 "@" is found then exit
PRINT_CHARACTER_TEXT:
EVENT:
9C6D: 5E          ld   e,(hl)		; Desgination address low into E
9C6E: 23          inc  hl		; next byte
9C6F: 56          ld   d,(hl)		; Destination address High into D for the address
9C70: 23          inc  hl		; next byte
9C71: 4E          ld   c,(hl)		; Next c is colour
9C72: 23          inc  hl		; next byte
9C73: EB          ex   de,hl		; Swap de - lh address - so now HL is the video RAM
9C74: 1A          ld   a,(de)		; Now start loading the text string
9C75: FE 04       cp   $40		; Check for end of string
9C77: C8          ret  z		; job done return.
9C78: 77          ld   (hl),a		; Save to video ram
9C79: CB D4       set  2,h		; Change desgination to the Colour Memory Address (ie from $d000 to $d4000)
9C7B: 71          ld   (hl),c		; write the colour
9C7C: CB 94       res  2,h		; Change back to the Character Memory Address
9C7E: 3E 02       ld   a,$20		; Add 32 to destination because screen is stored on the side this is next character visually.
9C80: DF          rst	ADD_A_TO_HL	; call ADD_A_TO_HL
9C81: 13          inc  de		; increment source memory
9C82: 18 1E       jr   $9C74		; jmp back until completed.

		; Prints Spaces to the character memory where text would of been before, source is in HL registers
		; First two bytes define the destination address in Lo/Hi in Front character memory
		; Next byte is the colour Ram value
		; Then all text up until $40 "@" is found then exit
REMOVE_CHARACTER_WITH_SPACE:
9C84: 5E          ld   e,(hl)		; Destination address Low into E
9C85: 23          inc  hl		; Next byte
9C86: 56          ld   d,(hl)		; Destination address High into D for the character RAM
9C87: 23          inc  hl
9C88: 4E          ld   c,(hl)		; Colour Palette Valur
9C89: 23          inc  hl		; next byte
9C8A: EB          ex   de,hl		; swap over so HL is video RAM
9C8B: 1A          ld   a,(de)		; Read
9C8C: FE 04       cp   $40		; Check Delimeter character "@"
9C8E: C8          ret  z		; exit if true
9C8F: 36 02       ld   (hl),$20		; otherwise write space chracter
9C91: CB D4       set  2,h		; and now set colour ram; technically no point as it's a blank space anyhow
9C93: 71          ld   (hl),c		; save it
9C94: CB 94       res  2,h		; back to character ram
9C96: 3E 02       ld   a,$20		; next position. ( remember 32 is next character due to sideways screen orinatation
9C98: DF          rst	ADD_A_TO_HL	; call ADD_A_TO_HL
9C99: 13          inc  de		; next character
9C9A: 18 EF       jr   $9C8B		; until completed

		; hl is destination address in Character memory, c is colour memory value, a is number
PRINT_NUMBER:
9C9C: 47          ld   b,a		; save copy of original value to background
9C9D: 0F          rrca			; top 4 bits down to lower 4 bits
9C9E: 0F          rrca
9C9F: 0F          rrca
9CA0: 0F          rrca
9CA1: E6 E1       and  $0F		; remove any carry flag bits
9CA3: CD 8B D8    call $9CA9		; print this number first
9CA6: 78          ld   a,b		; get back original
9CA7: E6 E1       and  $0F		; now do lower bits
9CA9: 77          ld   (hl),a		; save to character memory
9CAA: CB D4       set  2,h		; adjust for character colour
9CAC: 71          ld   (hl),c		; save colour
9CAD: CB 94       res  2,h		; set back character memory
9CAF: 3E 02       ld   a,$20		; now add 32 for next position (side ways visuals hence 32 is next space)
9CB1: DF          rst	ADD_A_TO_HL	; call ADD_A_TO_HL
9CB2: C9          ret			; exit

SHOW_PLAYER_SCORE:
9CB3: 3E 00       ld   a,$00		; Character Screen colour
9CB5: 4F          ld   c,a
9CB6: 21 F0 1D    ld   hl,$D11E		; x=8, y=1 position
9CB9: 36 12       ld   (hl),$30		; "0" to print
9CBB: CB D4       set  2,h		; point to Character colour memory
9CBD: 71          ld   (hl),c		; set colour memory as c=0
9CBE: 21 F4 1C    ld   hl,$D05E		; Screen position x=02, y=01
9CC1: 11 19 EE    ld   de,PLAYER1_SCORE	; Player1 Score Value
9CC4: C3 F1 D9    jp   DISPLAY_SCORE
9CC7: C9          ret

SHOW_PLAYER2_SCORE:
9CC8: 3E 00       ld   a,$00		; colour
9CCA: 4F          ld   c,a		; keep in c
9CCB: 21 FA 3D    ld   hl,$D3BE		; x=29, y=1
9CCE: 36 12       ld   (hl),$30		; Print "0" to video RAM
9CD0: CB D4       set  2,h		; point to Color RAM
9CD2: 71          ld   (hl),c		; set colour
9CD3: 21 FE 3C    ld   hl,$D2FE		; Screen position  x=23, y=01
9CD6: 11 58 EE    ld   de,PLAYER2_SCORE	; Player2 Score Value
9CD9: C3 F1 D9    jp   DISPLAY_SCORE

SHOW_HIGH_SCORE:
9CDC: 3E 00       ld   a,$00
9CDE: 4F          ld   c,a
9CDF: 21 F4 3C    ld   hl,$D25E		; Screen position x=18, y=01
9CE2: 36 12       ld   (hl),$30		; Print "0"
9CE4: CB D4       set  2,h
9CE6: 71          ld   (hl),c		; Colour Ram
9CE7: CB 94       res  2,h
9CE9: 21 F8 1D    ld   hl,$D19E		; Screen position x=12, y=01
9CEC: 11 79 EE    ld   de,HI_SCORE
9CEF: C3 F1 D9    jp   DISPLAY_SCORE

9CF2: 47          ld   b,a
9CF3: 0F          rrca
9CF4: 0F          rrca
9CF5: 0F          rrca
9CF6: 0F          rrca
9CF7: E6 E1       and  $0F
9CF9: CA 01 D9    jp   z,$9D01
9CFC: CD 8B D8    call $9CA9
9CFF: 18 E1       jr   $9D10
9D01: 08          ex   af,af'
9D02: 7E          ld   a,(hl)
9D03: FE 02       cp   $20
9D05: 28 60       jr   z,$9D0D
9D07: 08          ex   af,af'
9D08: CD 8B D8    call $9CA9
9D0B: 18 21       jr   $9D10
9D0D: 3E 02       ld   a,$20		; Next character position
9D0F: DF          rst	ADD_A_TO_HL
9D10: 78          ld   a,b
9D11: E6 E1       and  $0F
9D13: C2 8B D8    jp   nz,$9CA9
9D16: 7E          ld   a,(hl)
9D17: FE 02       cp   $20
9D19: C8          ret  z
9D1A: C3 8B D8    jp   $9CA9
9D1D: C9          ret
9D1E: C9          ret

		; Print Scrore called when new score value has been changed.
		; Value to print passed in DE

DISPLAY_SCORE:
9F1F: AF          xor  a		; clear A
9D20: 32 45 0E    ld   ($E045),a	; character 0
9D23: 3E 60       ld   a,$06		; count for how many digits to print for score
9D25: 32 64 0E    ld   ($E046),a
9D28: 1A          ld   a,(de)		; Store value
9D29: 13          inc  de
9D2A: 47          ld   b,a
9D2B: 0F          rrca			; shift top 4 bits down for value
9D2C: 0F          rrca
9D2D: 0F          rrca
9D2E: 0F          rrca
9D2F: E6 E1       and  $0F		; only printing 0 - 9 ( no hex used in digits )
9D31: 28 B1       jr   z,$9D4E
9D33: 32 45 0E    ld   ($E045),a
9D36: 77          ld   (hl),a
9D37: CB D4       set  2,h
9D39: 71          ld   (hl),c
9D3A: CB 94       res  2,h
9D3C: 3E 02       ld   a,$20
9D3E: DF          rst	ADD_A_TO_HL
9D3F: 3A 64 0E    ld   a,($E046)	; next character
9D42: 3D          dec  a		; countdown until all printed
9D43: C8          ret  z
9D44: 32 64 0E    ld   ($E046),a	; save count
9D47: E6 01       and  $01		; use position for high low nybble score in each byte
9D49: 28 DD       jr   z,$9D28
9D4B: 78          ld   a,b
9D4C: 18 0F       jr   $9D2F

9D4E: 08          ex   af,af		; keep printed value for 2nd half to print later
9D4F: 3A 45 0E    ld   a,($E045)
9D52: A7          and  a
9D53: 28 6F       jr   z,$9D3C
9D55: 08          ex   af,af
9D56: 18 FC       jr   $9D36
9D58: 3A 80 0E    ld   a,(JOYSTICK1_RIGHT)
9D5B: E6 61       and  $07
9D5D: FE 01       cp   $01
9D5F: 28 D0       jr   z,$9D7D
9D61: 3A 81 0E    ld   a,(JOYSTICK1_LEFT)
9D64: E6 61       and  $07
9D66: FE 01       cp   $01
9D68: 28 90       jr   z,$9D82
9D6A: 3A A1 0E    ld   a,(JOYSTICK1_UP)
9D6D: E6 61       and  $07
9D6F: FE 01       cp   $01
9D71: 28 50       jr   z,$9D87
9D73: 3A A0 0E    ld   a,(JOYSTICK1_LEFT)
9D76: E6 61       and  $07
9D78: FE 01       cp   $01
9D7A: 28 10       jr   z,$9D8C
9D7C: C9          ret
9D7D: 11 00 41    ld   de,$0500
9D80: FF          rst  ADD_DE_TO_EVENT
9D81: C9          ret
9D82: 11 01 41    ld   de,$0501
9D85: FF          rst  ADD_DE_TO_EVENT
9D86: C9          ret
9D87: 11 21 41    ld   de,$0503
9D8A: FF          rst  ADD_DE_TO_EVENT
9D8B: C9          ret
9D8C: 11 41 41    ld   de,$0505
9D8F: FF          rst  ADD_DE_TO_EVENT
9D90: C9          ret
9D91: AF          xor  a
9D92: 32 85 0E    ld   ($E049),a
9D95: 32 84 0E    ld   ($E048),a
9D98: C9          ret

9D99: CD 8D D9    call $9DC9
9D9C: CD 0A D9    call $9DA0
9D9F: C9          ret

9DA0: 3A 85 0E    ld   a,($E049)
9DA3: 4F          ld   c,a
9DA4: 3A 84 0E    ld   a,($E048)
9DA7: 21 4A 9D    ld   hl,$D9A4
9DAA: CD 1A D9    call $9DB0
9DAD: 21 4A 9C    ld   hl,$D8A4
9DB0: D9          exx
9DB1: 06 40       ld   b,$04
9DB3: D9          exx
9DB4: 06 80       ld   b,$08
9DB6: 77          ld   (hl),a
9DB7: CB D4       set  2,h
9DB9: 71          ld   (hl),c
9DBA: CB 94       res  2,h
9DBC: 3C          inc  a
9DBD: 2C          inc  l
9DBE: 10 7E       djnz $9DB6
9DC0: 11 9C FF    ld   de,$FFD8
9DC3: 19          add  hl,de
9DC4: D9          exx
9DC5: 10 CE       djnz $9DB3
9DC7: D9          exx
9DC8: C9          ret
9DC9: CD 3D D9    call $9DD3
9DCC: CD 3F D9    call $9DF3
9DCF: CD 50 F8    call $9E14
9DD2: C9          ret
9DD3: 3A 80 0E    ld   a,(JOYSTICK1_RIGHT)
9DD6: E6 61       and  $07
9DD8: FE 21       cp   $03
9DDA: 28 E1       jr   z,$9DEB
9DDC: 3A 81 0E    ld   a,(JOYSTICK1_LEFT)
9DDF: E6 61       and  $07
9DE1: FE 21       cp   $03
9DE3: C0          ret  nz
9DE4: 21 85 0E    ld   hl,$E049
9DE7: 7E          ld   a,(hl)
9DE8: 3C          inc  a
9DE9: 77          ld   (hl),a
9DEA: C9          ret
9DEB: 21 85 0E    ld   hl,$E049
9DEE: 7E          ld   a,(hl)
9DEF: D6 10       sub  $10
9DF1: 77          ld   (hl),a
9DF2: C9          ret
9DF3: 3A A1 0E    ld   a,(JOYSTICK1_UP)
9DF6: E6 61       and  $07
9DF8: FE 21       cp   $03
9DFA: 28 10       jr   z,$9E0C
9DFC: 3A A0 0E    ld   a,(JOYSTICK1_LEFT)
9DFF: E6 61       and  $07
9E01: FE 21       cp   $03
9E03: C0          ret  nz
9E04: 21 84 0E    ld   hl,$E048
9E07: 7E          ld   a,(hl)
9E08: C6 0E       add  a,$E0
9E0A: 77          ld   (hl),a
9E0B: C9          ret
9E0C: 21 84 0E    ld   hl,$E048
9E0F: 7E          ld   a,(hl)
9E10: C6 02       add  a,$20
9E12: 77          ld   (hl),a
9E13: C9          ret
9E14: 21 D1 3C    ld   hl,$D21D		; Screen position x=16, y=02
9E17: 3A 85 0E    ld   a,($E049)
9E1A: 0E 01       ld   c,$01
9E1C: CD D8 D8    call PRINT_NUMBER
9E1F: 21 BD 1C    ld   hl,$D0DB
9E22: 3A 84 0E    ld   a,($E048)
9E25: 0E 01       ld   c,$01
9E27: CD D8 D8    call PRINT_NUMBER
9E2A: 21 AD 1C    ld   hl,$D0CB
9E2D: 3A 84 0E    ld   a,($E048)
9E30: C6 02       add  a,$20
9E32: 0E 01       ld   c,$01
9E34: C3 D8 D8    jp   PRINT_NUMBER


9E37: 3A 90 0E    ld   a,($E018)
9E3A: A7          and  a
9E3B: C0          ret  nz
9E3C: CD B7 F8    call $9E7B
9E3F: CD 64 F8    call $9E46
9E42: CD F5 F8    call $9E5F
9E45: C9          ret

9E46: 21 33 0E    ld   hl,$E033			; Coin 1  rollover
9E49: 3A 21 0E    ld   a,(START_BUTTONS)
9E4C: 07          rlca
9E4D: CB 16       rl   (hl)
9E4F: 7E          ld   a,(hl)
9E50: E6 61       and  $07
9E52: C8          ret  z
9E53: FE 21       cp   $03
9E55: C0          ret  nz
9E56: CD 1B 68    call SFX_CREDIT
9E59: CD 4D F8    call $9EC5
9E5C: C3 ED F8    jp   $9ECF
9E5F: 21 52 0E    ld   hl,$E034			; Coin 2 rollover
9E62: 3A 21 0E    ld   a,(START_BUTTONS)
9E65: 07          rlca
9E66: 07          rlca
9E67: CB 16       rl   (hl)
9E69: 7E          ld   a,(hl)
9E6A: E6 61       and  $07
9E6C: C8          ret  z
9E6D: FE 21       cp   $03
9E6F: C0          ret  nz
9E70: CD 1B 68    call SFX_CREDIT
9E73: CD AC F8    call $9ECA
9E76: 0E 01       ld   c,$01
9E78: C3 7E F8    jp   $9EF6

9E7B: CD 09 F8    call $9E81
9E7E: C3 2B F8    jp   $9EA3

9E81: 21 53 0E    ld   hl,$E035
9E84: 11 B3 0E    ld   de,START_BUTTON_MIRROR
9E87: 7E          ld   a,(hl)
9E88: A7          and  a
9E89: 28 C0       jr   z,$9E97
9E8B: 35          dec  (hl)
9E8C: 7E          ld   a,(hl)
9E8D: FE E1       cp   $0F
9E8F: 20 40       jr   nz,$9E95
9E91: EB          ex   de,hl
9E92: CB 8E       res  1,(hl)
9E94: EB          ex   de,hl
9E95: A7          and  a
9E96: C0          ret  nz
9E97: 2C          inc  l
9E98: 7E          ld   a,(hl)
9E99: A7          and  a
9E9A: C8          ret  z
9E9B: 35          dec  (hl)
9E9C: 2D          dec  l
9E9D: 36 F1       ld   (hl),$1F
9E9F: EB          ex   de,hl
9EA0: CB CE       set  1,(hl)
9EA2: C9          ret

9EA3: 21 73 0E    ld   hl,$E037
9EA6: 11 B3 0E    ld   de,START_BUTTON_MIRROR
9EA9: 7E          ld   a,(hl)
9EAA: A7          and  a
9EAB: 28 C0       jr   z,$9EB9
9EAD: 35          dec  (hl)
9EAE: 7E          ld   a,(hl)
9EAF: FE E1       cp   $0F
9EB1: 20 40       jr   nz,$9EB7
9EB3: EB          ex   de,hl
9EB4: CB 86       res  0,(hl)
9EB6: EB          ex   de,hl
9EB7: A7          and  a
9EB8: C0          ret  nz
9EB9: 2C          inc  l
9EBA: 7E          ld   a,(hl)
9EBB: A7          and  a
9EBC: C8          ret  z
9EBD: 35          dec  (hl)
9EBE: 2D          dec  l
9EBF: 36 F1       ld   (hl),$1F
9EC1: EB          ex   de,hl
9EC2: CB C6       set  0,(hl)
9EC4: C9          ret
9EC5: 21 72 0E    ld   hl,$E036
9EC8: 34          inc  (hl)
9EC9: C9          ret
9ECA: 21 92 0E    ld   hl,$E038
9ECD: 34          inc  (hl)
9ECE: C9          ret

9ECF: 3A 22 0E    ld   a,(COINS-PER-CREDIT)
9ED2: 47          ld   b,a
9ED3: 21 13 0E    ld   hl,$E031
9ED6: 34          inc  (hl)
9ED7: 7E          ld   a,(hl)
9ED8: B8          cp   b
9ED9: D8          ret  c
9EDA: 36 00       ld   (hl),$00
9EDC: 3A 02 0E    ld   a,(CREDITS_PER_COIN)
9EDF: 4F          ld   c,a
9EE0: 3A 12 0E    ld   a,(NUM_CREDITS)
9EE3: FE 99       cp   $99
9EE5: D0          ret  nc
9EE6: 81          add  a,c
9EE7: 27          daa
9EE8: 32 12 0E    ld   (NUM_CREDITS),a
9EEB: 3A 00 0E    ld   a,(GAME_STATUS1)
9EEE: FE 21       cp   $03
9EF0: C8          ret  z
9EF1: 16 40       ld   d,$04
9EF3: C3 92 00    jp   ADD_DE_TO_EVENT

9EF6: 3A 23 0E    ld   a,(COINS_PER_CREDIT_B)
9EF9: 47          ld   b,a
9EFA: 21 32 0E    ld   hl,COINS_PER_CREDIT_B
9EFD: 34          inc  (hl)
9EFE: 7E          ld   a,(hl)
9EFF: B8          cp   b
9F00: D8          ret  c
9F01: 36 00       ld   (hl),$00
9F03: 3A 03 0E    ld   a,(CREDITS_PER_COIN_B)
9F06: 4F          ld   c,a
9F07: 18 7D       jr   $9EE0
9F09: AF          xor  a
9F0A: 32 26 0E    ld   (SCREEN_SCROLLING),a
9F0D: 3A F9 0E    ld   a,(AREA_END)
9F10: A7          and  a
9F11: C0          ret  nz
9F12: 21 99 2B    ld   hl,$A399
9F15: E5          push hl
9F16: 21 90 2B    ld   hl,$A318
9F19: E5          push hl
9F1A: 2A 75 0E    ld   hl,($E057)
9F1D: 7D          ld   a,l
9F1E: B4          or   h
9F1F: C8          ret  z
9F20: DD 21 00 EF ld   ix,TILE_POINTERS_RAM
9F24: DD 56 01    ld   d,(ix+$01)
9F27: DD 5E 20    ld   e,(ix+$02)
9F2A: 19          add  hl,de
9F2B: DD 74 01    ld   (ix+$01),h
9F2E: DD 75 20    ld   (ix+$02),l
9F31: 3A D4 0E    ld   a,(MAP_OFFSET_H)
9F34: 57          ld   d,a
9F35: 7C          ld   a,h
9F36: 32 D4 0E    ld   (MAP_OFFSET_H),a
9F39: 32 2A CF    ld   (MAP_OFFSET_HIGH),a
9F3C: 7D          ld   a,l
9F3D: 32 D5 0E    ld   ($E05D),a
9F40: DD 7E 00    ld   a,(ix+$00)
9F43: CE 00       adc  a,$00
9F45: DD 77 00    ld   (ix+$00),a
9F48: 32 B5 0E    ld   (MAP_OFFSET),a		; duplicate pointer
9F4B: 32 2B CF    ld   ($EDA3),a		; position y pointer in map
9F4E: 6F          ld   l,a
9F4F: 7C          ld   a,h
9F50: 92          sub  d
9F51: 32 26 0E    ld   (SCREEN_SCROLLING),a
9F54: A7          and  a
9F55: C8          ret  z
9F56: DD 34 30    inc  (ix+$12)
9F59: DD 7E 30    ld   a,(ix+$12)
9F5C: E6 E1       and  $0F
9F5E: 20 31       jr   nz,$9F73
9F60: DD 66 10    ld   h,(ix+$10)
9F63: DD 6E 11    ld   l,(ix+$11)
9F66: 11 02 00    ld   de,$0020
9F69: 19          add  hl,de
9F6A: DD 75 11    ld   (ix+$11),l
9F6D: 7C          ld   a,h
9F6E: E6 BF       and  $FB
9F70: DD 77 10    ld   (ix+$10),a
9F73: 3A B5 0E    ld   a,(MAP_OFFSET)
9F76: 21 D5 1C    ld   hl,$D05D
9F79: 0E 00       ld   c,$00
9F7B: 3A D4 0E    ld   a,(MAP_OFFSET_H)
9F7E: 21 D9 1C    ld   hl,$D09D
9F81: DD 7E 01    ld   a,(ix+$01)
9F84: E6 F3       and  $3F
9F86: C0          ret  nz
9F87: 16 60       ld   d,$06
9F89: FF          rst  ADD_DE_TO_EVENT
9F8A: C9          ret

			; So this prints one row tile set starts always bottom of screen when pointers are zero
			; Each call will carry on to the row above the last one. When initialized you see 4 strips as one screen
			; However the screen scrolls, and so 5 tile strips are plotted. one strip tile is 4x4 characters of which each is 16x16pixels
			; So just one row only reads 4 byes for the tile. as that's 16 characters we're only 256 pixels (minus borders) wide
		
BACKGROUND_TILE_STRIP:
9F8B: CD 7D F9    call LEVEL_DATA_SET
9F8E: DD 21 00 EF ld   ix,TILE_POINTERS_RAM	; MEMORY tiles pointers init
9F92: CD DB 6A    call PLOT_TILE_4X4
9F95: CD 70 6B    call UPDATE_PLOT_POINTERS
9F98: CD 95 6B    call DRAW_TILE_BLOCK
9F9B: DD 35 31    dec  (ix+$13)			; Tile Block count in pixels to draw
9F9E: C0          ret  nz
9F9F: CD B5 6A    call SETUP_DECODE_OFFSETS
9FA2: DD 35 41    dec  (ix+$05)
9FA5: C0          ret  nz
9FA6: C3 16 4B    jp   SETUP_BG_SPRITES		; All pointers for background sprites

9FA9: 21 3F 0E    ld   hl,BULLET_TIMER
9FAC: 7E          ld   a,(hl)
9FAD: A7          and  a
9FAE: 28 01       jr   z,$9FB1
9FB0: 35          dec  (hl)
9FB1: 21 7E 0E    ld   hl,ENEMY_TIMER
9FB4: 7E          ld   a,(hl)
9FB5: A7          and  a
9FB6: 28 01       jr   z,$9FB9
9FB8: 35          dec  (hl)
9FB9: 3A 20 0E    ld   a,(FRAME_SYNC)
9FBC: E6 01       and  $01
9FBE: C0          ret  nz
9FBF: 21 9E 0E    ld   hl,STANDING_TIMER
9FC2: 7E          ld   a,(hl)
9FC3: A7          and  a
9FC4: 28 01       jr   z,$9FC7
9FC6: 35          dec  (hl)
9FC7: C9          ret
9FC8: C9          ret

9FC9: 21 BF 0E    ld   hl,$E0FB
9FCC: 34          inc  (hl)
9FCD: 7E          ld   a,(hl)
9FCE: FE 12       cp   $30
9FD0: 38 70       jr   c,$9FE8
9FD2: 36 E2       ld   (hl),$2E
9FD4: C3 8E F9    jp   $9FE8

		; Set level data tables from current positions.
LEVEL_DATA_SET:
9FD7: 3A B5 0E    ld   a,(MAP_OFFSET)
9FDA: 32 BF 0E    ld   ($E0FB),a		; Current Area save
9FDD: 11 A5 0A    ld   de,AREA_TABLE1		; Set table offset
9FE0: CB 77       bit  6,a			; If Area is 5 or > then use other table
9FE2: 28 21       jr   z,$9FE7
9FE4: 11 A9 0B    ld   de,AREA_TABLE2		; Table Address for higher AREAs 5 6 7 8
9FE7: D5          push de			; save
9FE8: E6 F1       and  $1F			; tables 32 entries depending on position
9FEA: 6F          ld   l,a
9FEB: 26 00       ld   h,$00
9FED: 29          add  hl,hl			; offset * 2
9FEE: 54          ld   d,h
9FEF: 5D          ld   e,l
9FF0: 29          add  hl,hl			; * 4
9FF1: 29          add  hl,hl			; * 8
9FF2: 19          add  hl,de			; + * 2 = offset * 10
9FF3: D1          pop  de
9FF4: 19          add  hl,de			; add to table offset
9FF5: 0E 00       ld   c,$00
9FF7: 3A C2 0E    ld   a,(IS_DIFFICULT)
9FFA: A7          and  a
9FFB: 28 20       jr   z,$9FFF
9FFD: 0E 01       ld   c,$01			; c=1 if we're playing hard of c=0 if a wussy
9FFF: 7E          ld   a,(hl)			; Read 1st
A000: 23          inc  hl			; table+1
A001: 32 1E 0E    ld   (MAX_BULLETS),a		; first bytes in table save
A004: 7E          ld   a,(hl)			; Read 2nd
A005: 23          inc  hl			; table+1
A006: 32 1F 0E    ld   ($E0F1),a		; next byte in table save
A009: 7E          ld   a,(hl)			; Read 3rd
A00A: 23          inc  hl			; table+1
A00B: 32 3E 0E    ld   (BULLET_TIMER_RESET),a	; save to a 2nd place the same byte
A00E: 32 3F 0E    ld   (BULLET_TIMER),a		; saved to 3rd place same byte
A011: 7E          ld   a,(hl)			; Read 4th
A012: 23          inc  hl			; table+1
A013: 32 5E 0E    ld   (MAX_ENEMY),a		; save
A016: 7E          ld   a,(hl)			; Read 5th
A017: 23          inc  hl			; table+1
A018: 32 5F 0E    ld   (ENEMY_TIMER_RESET),a	; save to 1st place
A01B: 32 7E 0E    ld   (ENEMY_TIMER),a		; save the 2nd place
A01E: 7E          ld   a,(hl)			; Read 6th
A01F: 23          inc  hl			; table+1
A020: 32 7F 0E    ld   ($E0F7),a		; save to 2 places
A023: 32 9E 0E    ld   (STANDING_TIMER),a		; 2nd place
A026: 7E          ld   a,(hl)			; Read 7th
A027: 23          inc  hl			; table+1
A028: 81          add  a,c			; Add on the difficult bit
A029: 32 9F 0E    ld   ($E0F9),a		; save it
A02C: 7E          ld   a,(hl)			; Read 8th
A02D: 23          inc  hl
A02E: 32 BE 0E    ld   ($E0FA),a
A031: 3A D4 0E    ld   a,(MAP_OFFSET_H)		; we in moddle of an area?
A034: A7          and  a			; check high offset <> 0
A035: C0          ret  nz			; exit if true
A036: 7E          ld   a,(hl)			; Read 9th
A037: 23          inc  hl			; table+1
A038: 32 BA 0E    ld   ($E0BA),a		; save
A03B: 7E          ld   a,(hl)			; Read last byte 10th one from table set
A03C: 47          ld   b,a			; save this
A03D: E6 E1       and  $0F			; mask 0-15 only
A03F: 23          inc  hl			; table+1 seems redundant
A040: 32 BB 0E    ld   ($E0BB),a		; save masked values
A043: 78          ld   a,b			; get back 10th byte
A044: 07          rlca				; * 2
A045: E6 01       and  $01			; odd or even
A047: 32 DE 0E    ld   ($E0FC),a		; save this value
A04A: C9          ret

				;  Tables for Area 1 2 3 4
				; 1st Number of bullets
AREA_TABLE1:		db	$03,$28,$3c,$03,$2d,$f0,$01,$00,$00,$00		; 0
			db	$04,$30,$3a,$04,$2d,$f0,$02,$00,$01,$00		; 1
			db	$05,$28,$32,$04,$2e,$f0,$02,$00,$02,$00		; 2
			db	$05,$28,$32,$06,$2e,$f0,$02,$00,$03,$00		; 3
			db	$04,$28,$2d,$06,$23,$f0,$02,$01,$04,$00		; 4
			db	$05,$28,$28,$06,$21,$f0,$02,$00,$05,$00		; 5
			db	$04,$24,$26,$06,$1e,$f0,$02,$01,$06,$00		; 6
			db	$05,$24,$1e,$06,$18,$f0,$02,$00,$07,$80		; 7
			db	$07,$24,$1c,$04,$19,$d2,$02,$00,$00,$00		; 8
			db	$08,$24,$14,$05,$19,$d2,$02,$00,$00,$00		; 9
			db	$08,$24,$14,$05,$19,$d2,$02,$01,$00,$00		; 10
			db	$08,$24,$14,$06,$1e,$d2,$02,$00,$00,$00		; 11
			db	$05,$28,$19,$03,$1b,$d2,$02,$02,$00,$80		; 12
			db	$05,$24,$1e,$04,$1b,$d2,$02,$00,$00,$00		; 13
			db	$05,$22,$19,$03,$1b,$d2,$02,$00,$00,$00		; 14
			db	$05,$22,$1e,$05,$14,$f0,$02,$00,$00,$80		; 15
			db	$04,$24,$19,$05,$18,$b4,$02,$01,$00,$00		; 16
			db	$05,$22,$19,$05,$14,$b4,$02,$01,$00,$80		; 17
			db	$04,$24,$14,$05,$14,$b4,$02,$01,$00,$80		; 18
			db	$07,$22,$14,$05,$0e,$b4,$02,$00,$00,$00		; 19
			db	$04,$28,$14,$04,$1a,$f0,$02,$01,$00,$00		; 20
			db	$08,$22,$14,$03,$14,$f0,$02,$00,$00,$00		; 21
			db	$08,$20,$12,$03,$14,$f0,$02,$00,$00,$00		; 22
			db	$06,$20,$12,$06,$1e,$f0,$02,$00,$00,$80		; 23
			db	$03,$20,$10,$06,$26,$f0,$02,$02,$00,$00		; 24
			db	$04,$20,$0f,$06,$26,$f0,$02,$02,$00,$00		; 25
			db	$07,$20,$0e,$04,$14,$f0,$02,$00,$00,$00		; 26
			db	$06,$20,$0e,$04,$13,$f0,$02,$01,$00,$00		; 27
			db	$07,$20,$0e,$04,$12,$f0,$02,$00,$00,$00		; 28
			db	$08,$20,$0e,$03,$10,$f0,$02,$02,$00,$80		; 29
			db	$08,$20,$0e,$04,$14,$f0,$02,$00,$00,$00		; 30
			db	$08,$20,$0e,$06,$1e,$f0,$02,$01,$00,$80		; 31 ( $1f as per mask!)

				;  Tables for Area 5 6 7 8
AREA_TABLE2:
A18B: 			db	$04,$24,$0e,$07,$1a,$f0,$02,$00,$00,$00		; 0
			db	$04,$24,$0e,$07,$1a,$f0,$02,$00,$00,$00		; 1
			db	$05,$24,$0e,$06,$1a,$f0,$02,$00,$00,$00		; 2
			db	$05,$24,$0e,$05,$1a,$f0,$02,$01,$00,$00		; 3
			db	$05,$24,$0e,$04,$1a,$f0,$02,$01,$00,$00		; 4
			db	$05,$24,$0e,$04,$1a,$f0,$02,$01,$00,$00		; 5
			db	$07,$24,$0e,$03,$1a,$f0,$02,$02,$00,$00		; 6
			db	$06,$24,$0e,$06,$1a,$f0,$02,$01,$00,$80		; 7
			db	$04,$24,$0e,$04,$18,$f0,$02,$01,$00,$00		; 8
			db	$04,$24,$0e,$04,$18,$f0,$02,$01,$00,$00		; 9
			db	$08,$24,$0e,$03,$18,$f0,$02,$02,$00,$80		; 10
			db	$08,$24,$0e,$04,$18,$f0,$02,$00,$00,$00		; 11
			db	$06,$24,$0e,$05,$18,$f0,$02,$02,$00,$00		; 12
			db	$06,$24,$0e,$04,$18,$f0,$02,$02,$00,$00		; 13
			db	$06,$24,$0e,$05,$18,$f0,$02,$02,$00,$00		; 14
			db	$07,$24,$0e,$06,$18,$f0,$02,$00,$00,$80		; 15
			db	$04,$24,$0e,$06,$17,$f0,$02,$01,$00,$00		; 16
			db	$04,$24,$0e,$05,$17,$f0,$02,$01,$00,$80		; 17
			db	$04,$24,$0e,$05,$17,$f0,$02,$01,$00,$80		; 18
			db	$04,$24,$0e,$06,$17,$f0,$02,$01,$00,$00		; 19
			db	$06,$24,$0e,$04,$17,$f0,$02,$02,$00,$00		; 20
			db	$06,$24,$0e,$04,$17,$f0,$02,$02,$00,$00		; 21
			db	$08,$24,$0e,$03,$17,$f0,$02,$02,$00,$00		; 22
			db	$07,$24,$0e,$06,$17,$f0,$02,$00,$00,$80		; 23
			db	$07,$24,$0e,$04,$16,$f0,$02,$02,$00,$80		; 24
			db	$08,$24,$0e,$04,$16,$f0,$02,$02,$00,$80		; 25
			db	$07,$24,$0e,$04,$16,$f0,$02,$02,$00,$00		; 26
			db	$05,$24,$0e,$05,$16,$f0,$02,$01,$00,$00		; 27
			db	$07,$24,$0e,$04,$16,$f0,$02,$02,$00,$80		; 28
			db	$07,$24,$0e,$06,$16,$f0,$02,$00,$00,$00		; 29
			db	$04,$24,$0e,$04,$16,$f0,$02,$01,$00,$00		; 30
			db	$08,$24,$0e,$06,$16,$f0,$02,$00,$00,$80		; 31

OFFSET_A2CB: 	db $01,$20,$40,$00


A2CF: 3A 37 0F    ld   a,($E173)
A2D2: E6 21       and  $03
A2D4: 21 AD 2A    ld   hl,OFFSET_A2CB		; Some table offsets
A2D7: E7          rst	INDEX_A_PLUS_HL
A2D8: 21 A8 0E    ld   hl,$E08A
A2DB: 86          add  a,(hl)
A2DC: 77          ld   (hl),a
A2DD: 7E          ld   a,(hl)
A2DE: 0F          rrca
A2DF: 0F          rrca
A2E0: 0F          rrca
A2E1: 0F          rrca
A2E2: E6 21       and  $03
A2E4: 21 50 2B    ld   hl,OFFSETS_A314
A2E7: DF          rst	ADD_A_TO_HL
A2E8: 4E          ld   c,(hl)			; Get the base sprite number
A2E9: DD 21 00 8E ld   ix,TREE_ROCK_SPRITES
A2ED: FD 21 CA FE ld   iy,HW_SPRITE_43		
A2F1: 11 10 00    ld   de,$0010			; add 16 to x and y
A2F4: 06 C0       ld   b,$0C			; 12 in the loop
A2F6: DD 7E 00    ld   a,(ix+TABLE_STATUS)		; Is there an active sprite in table FF is yes
A2F9: A7          and  a
A2FA: 28 11       jr   z,$A30D			; if 0 then skip
A2FC: 79          ld   a,c			; Write sprite number the sprite data is top left top right, bottom left, bottom right
A2FD: FD 77 80    ld   (iy+sprite3_number),a	; However visually the sprites are offset 3 4 top l/r, and 0,1 bottom l/r
A300: 3C          inc  a			; advance number arranged in a nice pattern in sprite memory as a square if display 8 across in mame f4 debugger
A301: FD 77 C0    ld   (iy+sprite4_number),a	; top right sprite
A304: C6 61       add  a,$07			; now get to bottom line already added 1 just 7 more for 8th
A306: FD 77 00    ld   (iy+sprite_number),a	; bottom left is physically first sprite in tabke
A309: 3C          inc  a			; bottom right next one
A30A: FD 77 40    ld   (iy+sprite2_number),a	; sprite 2
A30D: DD 19       add  ix,de			; add pointers for sprites and sprite data
A30F: FD 19       add  iy,de
A311: 10 2F       djnz $A2F6			; dec b more to do if not zero
A313: C9          ret

OFFSETS_A314:		db $02,$10,$12,$10	; This is sprite table for 2x2 depending on Area
					; These are palm tree tops number $202, or $210, $212 or $210 again
TREES_AND_ROCKS:
A318: FD 2A F4 0E ld   iy,(TREE_ROCK_TABLE)	; Level pointer starts at $4000 inside ROM
A31C: 3A B5 0E    ld   a,(MAP_OFFSET)
A31F: 67          ld   h,a
A320: 3A D4 0E    ld   a,(MAP_OFFSET_H)
A323: 6F          ld   l,a
A324: FD 7E 21    ld   a,(iy+$03)		; is the y offset high $FF
A327: FE FF       cp   $FF
A329: C8          ret  z			; if so it's the end of the table
A32A: 57          ld   d,a
A32B: FD 7E 20    ld   a,(iy+$02)		; y offset low byte
A32E: 47          ld   b,a			; save low
A32F: E6 1E       and  $F0			; groups of 16 pixels only ie top bits
A331: 5F          ld   e,a			; now do a position caculation
A332: EB          ex   de,hl
A333: ED 52       sbc  hl,de			; so very first is 0010 - 0000
A335: 7C          ld   a,h			; save result
A336: A7          and  a			; if less than 256 ie high results is <> 0
A337: 28 A0       jr   z,$A343			; if 0 means the sprite will display
A339: CB 7F       bit  7,a			; set a return if a negative number also
A33B: C8          ret  z			; then exit loop

A33C: 11 40 00    ld   de,$0004			; otherwise add 4 to pointer for next data set
A33F: FD 19       add  iy,de			; update index
A341: 18 9D       jr   $A31C			; jump and do next

A343: 78          ld   a,b			; get original table low position
A344: E6 61       and  $07			; remove anything other than 0-7
A346: 57          ld   d,a			; save this
A347: 78          ld   a,b			; bring back original again
A348: E6 80       and  $08
A34A: C6 1A       add  a,$B0			; The sprites are set to the nice palette for the level green leaves or brown rocks! yah!
A34C: 4F          ld   c,a			; save to C
A34D: FD 66 00    ld   h,(iy+$00)		; now get first byte x-coordinate of sprite
A350: FD 46 01    ld   b,(iy+$01)		; and 2nd byte this is the sprite number
A353: D9          exx				; save them
A354: 01 10 00    ld   bc,$0010			; setup a counter 16 slots for bg sprite table
A357: DD 21 00 8E ld   ix,TREE_ROCK_SPRITES 	; get memory pointer $e800 in case you wondered
A35B: D9          exx				; get back our data values

FIND_FREE_SLOT:
A35C: DD 7E 00    ld   a,(ix+TABLE_STATUS)		; check free slot
A35F: A7          and  a			; 0 or -1 used
A360: 20 12       jr   nz,$A392			; if not free advance to next
A362: DD 35 00    dec  (ix+TABLE_STATUS)			; now set to -1 as first byte yes that's $ff in binary language
A365: DD 74 21    ld   (ix+TABLE_X_coord),h	; save table value this now x-coordinate on display
A368: DD 36 40 00 ld   (ix+TABLE_X_low),$00	; always set to 0
A36C: DD 75 41    ld   (ix+TABLE_Y_coord),l	; y position of sprite
A36F: DD 72 60    ld   (ix+TABLE_Y_low),d	; save the d ($0000)
A372: DD 70 61    ld   (ix+TABLE_new_X_high),b	; $0a value
A375: DD 71 80    ld   (ix+TABLE_new_X_low),c	; This is attribute value
A378: 01 90 40    ld   bc,$0418			; init values
A37B: CB 42       bit  0,d
A37D: 28 21       jr   z,$A382
A37F: 01 43 C0    ld   bc,$0C25			; change values if odd/even
A382: DD 70 81    ld   (ix+TABLE_new_Y_high),b
A385: DD 71 A0    ld   (ix+TABLE_new_Y_low),c	; save these settings
A388: 11 40 00    ld   de,$0004			; Each table entry is just 4bytes
A38B: FD 19       add  iy,de			; advance the index pointer
A38D: FD 22 F4 0E ld   (TREE_ROCK_TABLE),iy	; Save back
A391: C9          ret				; bye bye

A392: D9          exx				; save data
A393: DD 09       add  ix,bc			; advance to next table entry
A395: D9          exx				; bring back
A396: C3 D4 2B    jp   FIND_FREE_SLOT		; Carry on until found a free place

A399: DD 21 00 8E ld   ix,TREE_ROCK_SPRITES
A39D: FD 21 12 FE ld   iy,HW_SPRITE_12		; Large sprite 1 is first one to use
A3A1: 3A 01 0E    ld   a,(GAME_STATUS2)
A3A4: FE 41       cp   $05
A3A6: 38 40       jr   c,$A3AC
A3A8: FD 21 CA FE ld   iy,HW_SPRITE_43
A3AC: D9          exx
A3AD: 0E 30       ld   c,$12
A3AF: 21 80 00    ld   hl,$0008
A3B2: 11 10 00    ld   de,$0010
A3B5: 06 81       ld   b,$09
A3B7: D9          exx
A3B8: DD 7E 00    ld   a,(ix+TABLE_STATUS)
A3BB: A7          and  a
A3BC: 28 E2       jr   z,$A3EC
A3BE: 3C          inc  a
A3BF: 20 44       jr   nz,$A405
A3C1: 11 00 00    ld   de,$0000			; add to the y position 0 as standard
A3C4: 3A 26 0E    ld   a,(SCREEN_SCROLLING)	; if screen is on the scroll
A3C7: A7          and  a
A3C8: 28 21       jr   z,$A3CD			; yes 1 no 0
A3CA: 11 FF FF    ld   de,$FFFF			; add -1 basically means subtract 1
A3CD: DD 66 40    ld   h,(ix+TABLE_X_low)
A3D0: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
A3D3: 19          add  hl,de			; move y high and low
A3D4: DD 74 40    ld   (ix+TABLE_X_low),h
A3D7: DD 75 41    ld   (ix+TABLE_Y_coord),l	; save
A3DA: 7C          ld   a,h
A3DB: A7          and  a			; chcek high byte
A3DC: 28 A1       jr   z,$A3E9			; 0 no need check high
A3DE: 7D          ld   a,l			; get the low down! (get it?)
A3DF: FE 0E       cp   $E0			; -32 pixels off bottom
A3E1: 30 60       jr   nc,$A3E9
A3E3: DD 36 00 00 ld   (ix+TABLE_STATUS),$00		; if so then kill the table entry
A3E7: 18 21       jr   $A3EC
A3E9: CD 98 4A    call $A498

A3EC: D9          exx
A3ED: DD 19       add  ix,de
A3EF: 10 6C       djnz $A3B7
A3F1: 79          ld   a,c
A3F2: A7          and  a
A3F3: C8          ret  z
A3F4: 47          ld   b,a
A3F5: 11 80 00    ld   de,$0008
A3F8: FD 36 20 00 ld   (iy+sprite_x),$00
A3FC: FD 36 60 00 ld   (iy+sprite2_x),$00
A400: FD 19       add  iy,de
A402: 10 5E       djnz $A3F8
A404: C9          ret

A405: 21 CE 2B    ld   hl,$A3EC			; Return address on stack
A408: E5          push hl
A409: DD 7E 00    ld   a,(ix+TABLE_STATUS)
A40C: FE F3       cp   $3F
A40E: D2 49 4A    jp   nc,$A485
A411: DD 35 00    dec  (ix+TABLE_STATUS)
A414: CA 19 4A    jp   z,$A491
A417: 11 D7 4A    ld   de,$A47D
A41A: 0E 50       ld   c,$14
A41C: DD 7E 00    ld   a,(ix+TABLE_STATUS)
A41F: FE 80       cp   $08
A421: 30 41       jr   nc,$A428
A423: 11 09 4A    ld   de,$A481
A426: 0E 51       ld   c,$15
A428: FD 71 00    ld   (iy+sprite_number),c
A42B: FD 71 40    ld   (iy+sprite2_number),c
A42E: 79          ld   a,c
A42F: C6 61       add  a,$07
A431: FD 77 80    ld   (iy+sprite3_number),a
A434: FD 77 C0    ld   (iy+sprite4_number),a
A437: FD 36 01 1A ld   (iy+sprite_flags),$B0
A43B: FD 36 41 9A ld   (iy+sprite2_flags),$B8
A43F: FD 36 81 1A ld   (iy+sprite3_flags),$B0
A443: FD 36 C1 9A ld   (iy+sprite4_flags),$B8
A447: 3A 26 0E    ld   a,(SCREEN_SCROLLING)
A44A: A7          and  a
A44B: 28 21       jr   z,$A450
A44D: DD 35 41    dec  (ix+TABLE_Y_coord)
A450: DD 66 21    ld   h,(ix+TABLE_X_coord)
A453: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
A456: 1A          ld   a,(de)
A457: 13          inc  de
A458: 84          add  a,h
A459: FD 77 20    ld   (iy+sprite_x),a
A45C: FD 77 A0    ld   (iy+sprite3_x),a
A45F: 1A          ld   a,(de)
A460: 13          inc  de
A461: 85          add  a,l
A462: FD 77 21    ld   (iy+sprite_y),a
A465: FD 77 61    ld   (iy+sprite2_y),a
A468: 1A          ld   a,(de)
A469: 13          inc  de
A46A: 84          add  a,h
A46B: FD 77 60    ld   (iy+sprite2_x),a
A46E: FD 77 E0    ld   (iy+sprite4_x),a
A471: 1A          ld   a,(de)
A472: 13          inc  de
A473: 85          add  a,l
A474: FD 77 A1    ld   (iy+sprite3_y),a
A477: FD 77 E1    ld   (iy+sprite4_y),a
A47A: C3 30 4B    jp   $A512
A47D: 9F          sbc  a,a
A47E: 31 71 FE    ld   sp,$FE17
A481: 3E 50       ld   a,$14
A483: F0          ret  p
A484: BF          cp   a
A485: DD 36 00 10 ld   (ix+TABLE_STATUS),$10
A489: 16 41       ld   d,$05
A48B: 1E 20       ld   e,$02
A48D: FF          rst  ADD_DE_TO_EVENT
A48E: C3 30 4B    jp   $A512
A491: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
A495: C3 30 4B    jp   $A512

A498: DD 7E 60    ld   a,(ix+TABLE_Y_low)	; if the sprite is 2x1
A49B: FE 01       cp   $01
A49D: 38 41       jr   c,$A4A4			; must be a 2x2 sprite in table
A49F: CA 23 4B    jp   z,$A523
A4A2: 18 F7       jr   $A523

A4A4: DD CB 80 F4 bit  3,(ix+TABLE_new_X_low)
A4A8: 28 31       jr   z,$A4BD
A4AA: DD 7E 21    ld   a,(ix+TABLE_X_coord)
A4AD: FD 77 60    ld   (iy+sprite2_x),a
A4B0: FD 77 E0    ld   (iy+sprite4_x),a
A4B3: C6 10       add  a,$10
A4B5: FD 77 20    ld   (iy+sprite_x),a
A4B8: FD 77 A0    ld   (iy+sprite3_x),a
A4BB: 18 11       jr   $A4CE
A4BD: DD 7E 21    ld   a,(ix+TABLE_X_coord)
A4C0: FD 77 20    ld   (iy+sprite_x),a
A4C3: FD 77 A0    ld   (iy+sprite3_x),a
A4C6: C6 10       add  a,$10
A4C8: FD 77 60    ld   (iy+sprite2_x),a
A4CB: FD 77 E0    ld   (iy+sprite4_x),a
A4CE: DD 66 40    ld   h,(ix+TABLE_X_low)
A4D1: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
A4D4: FD 75 21    ld   (iy+sprite_y),l
A4D7: FD 75 61    ld   (iy+sprite2_y),l
A4DA: 7D          ld   a,l
A4DB: C6 10       add  a,$10
A4DD: FD 77 A1    ld   (iy+sprite3_y),a
A4E0: FD 77 E1    ld   (iy+sprite4_y),a
A4E3: DD 7E 61    ld   a,(ix+TABLE_new_X_high)
A4E6: FD 77 00    ld   (iy+sprite_number),a
A4E9: 3C          inc  a
A4EA: FD 77 40    ld   (iy+sprite2_number),a
A4ED: C6 7F       add  a,$F7
A4EF: FD 77 80    ld   (iy+sprite3_number),a
A4F2: 3C          inc  a
A4F3: FD 77 C0    ld   (iy+sprite4_number),a
A4F6: 7C          ld   a,h
A4F7: E6 01       and  $01
A4F9: DD 86 80    add  a,(ix+TABLE_new_X_low)
A4FC: FD 77 01    ld   (iy+sprite_flags),a
A4FF: FD 77 41    ld   (iy+sprite2_flags),a
A502: 01 10 00    ld   bc,$0010
A505: 09          add  hl,bc
A506: 7C          ld   a,h
A507: E6 01       and  $01
A509: DD 86 80    add  a,(ix+TABLE_new_X_low)
A50C: FD 77 81    ld   (iy+sprite3_flags),a
A50F: FD 77 C1    ld   (iy+sprite4_flags),a
A512: D9          exx
A513: EB          ex   de,hl
A514: FD 19       add  iy,de
A516: 0D          dec  c
A517: CA E6 4B    jp   z,$A56E
A51A: FD 19       add  iy,de
A51C: EB          ex   de,hl
A51D: 0D          dec  c
A51E: CA E6 4B    jp   z,$A56E
A521: D9          exx
A522: C9          ret

		; handles 2 x 1 sprites for background
A523: DD CB 80 F4 bit  3,(ix+TABLE_new_X_low)	; checks if sprite is reversed
A527: 28 C1       jr   z,$A536			; yes if so
A529: DD 7E 21    ld   a,(ix+TABLE_X_coord)	; x coordinate of sprite in table reversed
A52C: FD 77 60    ld   (iy+sprite2_x),a		; save to physical sprite 2nd as left
A52F: C6 10       add  a,$10			; now 2nd sprite is + 16
A531: FD 77 20    ld   (iy+sprite_x),a		; save to physical sprite 1st as right
A534: 18 A1       jr   DO_SPRITES_Y		; now move on to y cords

A536: DD 7E 21    ld   a,(ix+TABLE_X_coord)	; x cord in table
A539: FD 77 20    ld   (iy+sprite_x),a		; hardware sprite X cord
A53C: C6 10       add  a,$10			; 2nd sprite 16 pixels on
A53E: FD 77 60    ld   (iy+sprite2_x),a		; 2nd hardware sprite+1 X cord  

DO_SPRITES_Y:
A541: DD 66 40    ld   h,(ix+TABLE_X_low)	; msb for x (but Y visually)
A544: DD 6E 41    ld   l,(ix+TABLE_Y_coord)	; y cord in table
A547: FD 75 21    ld   (iy+sprite_y),l		; hardware sprite y cord
A54A: FD 75 61    ld   (iy+sprite2_y),l		; and the 2nd sprites same y
A54D: DD 7E 61    ld   a,(ix+TABLE_new_X_high)	; Sprite number in table
A550: FD 77 00    ld   (iy+sprite_number),a	; hardware sprite number
A553: 3C          inc  a			; +1 for sprite nuber
A554: FD 77 40    ld   (iy+sprite2_number),a	; sprite number for 2nd sprite
A557: 7C          ld   a,h			; get back from h
A558: E6 01       and  $01			; get the single bit
A55A: DD 86 80    add  a,(ix+TABLE_new_X_low)	; add the msb to the attributes
A55D: FD 77 01    ld   (iy+sprite_flags),a	; save into 
A560: FD 77 41    ld   (iy+sprite2_flags),a
A563: D9          exx
A564: EB          ex   de,hl
A565: FD 19       add  iy,de			; advance table pointer
A567: EB          ex   de,hl
A568: 0D          dec  c			; process all data
A569: CA E6 4B    jp   z,$A56E
A56C: D9          exx
A56D: C9          ret

A56E: E1          pop  hl
A56F: C9          ret

SETUP_BG_SPRITES:				; Reset character map pointers
A570: 21 00 04    ld   hl,BG_SPRITES_DATA	; Background sprite table start, looks like they padded this start
A573: 22 F4 0E    ld   (TREE_ROCK_TABLE),hl	; so it fits perfectly at $4000 a nice round number for tables.
A576: 21 EA 17    ld   hl,BG_EVENT_TABLE	; Control items, bridge, cars, pickup etc
A579: 22 E9 0E    ld   (BG_EVENT_POINTER),hl
A57C: 21 1B EB    ld   hl,$AFB1
A57F: 22 78 0E    ld   (SPAWN_POSITION),hl
A582: 21 00 00    ld   hl,$0000			; Begining area of game
A585: 22 2A CF    ld   (MAP_OFFSET_HIGH),hl	; Map position in pixels low and high
A588: AF          xor  a
A589: 32 4A CF    ld   (GAME_LEVEL),a		; EDA4 is game level position from 0 - 7 which indicated the area
A58C: 18 A6       jr   $A5F8

			; This is the master background or pickups, for trees and enemy
			; The table is a list of events and types which are inserted to an active event tableset
			; The handler for the table will display and draw, items as needed whereever inside the map pointers
            
UPDATE_OVERLAY_OBJECTS:
A58E: DD 21 EA 17 ld   ix,BG_EVENT_TABLE	; Table of positions
A592: 01 60 00    ld   bc,$0006			; Table length is 6 bytes / entry
A595: ED 5B 2A CF ld   de,(MAP_OFFSET_HIGH)

FIND_START1:
A599: DD 66 01    ld   h,(ix+$01)		; y position high 2nd byte
A59C: DD 6E 00    ld   l,(ix+$00)		; y position low 1st byte
A59F: A7          and  a
A5A0: ED 52       sbc  hl,de
A5A2: 7C          ld   a,h
A5A3: A7          and  a
A5A4: 28 81       jr   z,$A5AF
A5A6: CB 7F       bit  7,a
A5A8: 28 41       jr   z,$A5AF
A5AA: DD 09       add  ix,bc			; advance to next table entry
A5AC: C3 99 4B    jp   FIND_START1

A5AF: DD 22 E9 0E ld   (BG_EVENT_POINTER),ix	; save the table pointer
A5B3: DD 21 00 04 ld   ix,TREES_ROCKS_TABLE	; Offset Area tables in ROM
A5B7: 01 40 00    ld   bc,$0004

FIND_START2:
A5BA: DD 66 21    ld   h,(ix+$03)	; high byte coordinate
A5BD: DD 7E 20    ld   a,(ix+$02)		; low byte coordinate
A5C0: E6 1E       and  $F0			; ignore the lower bits as sprites are to each 16 pixels in y position
A5C2: 6F          ld   l,a			; save y cordinatw
A5C3: A7          and  a
A5C4: ED 52       sbc  hl,de			; subtract current map position
A5C6: 7C          ld   a,h
A5C7: A7          and  a
A5C8: 28 81       jr   z,$A5D3
A5CA: CB 7F       bit  7,a
A5CC: 28 41       jr   z,$A5D3
A5CE: DD 09       add  ix,bc			; next table entry advance.
A5D0: C3 BA 4B    jp   FIND_START2

A5D3: DD 22 F4 0E ld   (TREE_ROCK_TABLE),ix	; save new position check
A5D7: DD 21 1B EB ld   ix,$AFB1			; table start
A5DB: 01 40 00    ld   bc,$0004

FIND_START3:
A5DE: DD 66 01    ld   h,(ix+$01)
A5E1: DD 6E 00    ld   l,(ix+$00)		; x position
A5E4: A7          and  a
A5E5: ED 52       sbc  hl,de
A5E7: 7C          ld   a,h
A5E8: A7          and  a
A5E9: 28 81       jr   z,$A5F4
A5EB: CB 7F       bit  7,a
A5ED: 28 41       jr   z,$A5F4
A5EF: DD 09       add  ix,bc
A5F1: C3 FC 4B    jp   FIND_START3

A5F4: DD 22 78 0E ld   (SPAWN_POSITION),ix		; Init

A5F8: 21 00 8E    ld   hl,TREE_ROCK_SPRITES	; clear out e800 36 bytes
A5FB: 11 80 00    ld   de,$0008			; There is 8 sets max of trees or rocks at one time.
A5FE: 06 42       ld   b,$24
A600: 36 00       ld   (hl),$00			; first byte in table set is 0 for not active.
A602: 19          add  hl,de			; next table entry
A603: 10 BF       djnz $A600
A605: DD 21 00 EF ld   ix,TILE_POINTERS_RAM	; init ix offset address for pointers
A609: 21 00 9E    ld   hl,$F800			; $f800 seems to be detection map for background objects
A60C: DD 74 A0    ld   (ix+$0a),h
A60F: DD 75 A1    ld   (ix+$0b),l
A612: DD 74 10    ld   (ix+$10),h
A615: DD 75 11    ld   (ix+$11),l
A618: CD B5 6A    call SETUP_DECODE_OFFSETS
A61B: 11 00 9C    ld   de,VIDEO_RAM
A61E: 3A B5 0E    ld   a,(MAP_OFFSET)		; position
A621: E6 01       and  $01			; 0 or 1
A623: 67          ld   h,a
A624: 3A D4 0E    ld   a,(MAP_OFFSET_H)
A627: 6F          ld   l,a
A628: 29          add  hl,hl
A629: 19          add  hl,de
A62A: DD 74 E0    ld   (ix+$0e),h
A62D: DD 75 E1    ld   (ix+$0f),l
A630: CD A9 F9    call BACKGROUND_TILE_STRIP	; tile strip 1 ( 4 rows) bottom to top
A633: CD A9 F9    call BACKGROUND_TILE_STRIP	; tile strip 2 ( 5 6 7 8)
A636: CD A9 F9    call BACKGROUND_TILE_STRIP	; tile strip 3 ( 9 10 11 12)
A639: CD A9 F9    call BACKGROUND_TILE_STRIP	; tile strip 4 ( 13 14 15 16)
A63C: CD A9 F9    call BACKGROUND_TILE_STRIP	; tile strip 5 ( 17 18 19 20) this is off display for scroll area.
A63F: CD 90 2B    call TREES_AND_ROCKS
A642: CD 90 2B    call TREES_AND_ROCKS		; We process 8 lots of trees / rock tip sprites
A645: CD 90 2B    call TREES_AND_ROCKS
A648: CD 90 2B    call TREES_AND_ROCKS
A64B: CD 90 2B    call TREES_AND_ROCKS
A64E: CD 90 2B    call TREES_AND_ROCKS
A651: CD 90 2B    call TREES_AND_ROCKS
A654: CD 90 2B    call TREES_AND_ROCKS
A657: CD 99 2B    call $A399
A65A: C9          ret

SETUP_DECODE_OFFSETS:
A65B: 11 52 05    ld   de,AREA1_MAP		; Map Data for Area 1 - 8 in R
A65E: 2A 2A CF    ld   hl,(MAP_OFFSET_HIGH)	; Initial value is $0800
A661: CB 74       bit  6,h			; Check the bit 6 this is AREA 5 - 8 data
A663: 28 21       jr   z,$A668			; if zero keep my de pointer as above
A665: 11 56 25    ld   de,AREA2_MAP		; Map Areas 5-8 start location decoding
A668: 7D          ld   a,l
A669: 32 D4 0E    ld   (MAP_OFFSET_H),a		;  Hardware scroll Y value starts at 0 of course
A66C: DD 77 01    ld   (ix+$01),a
A66F: 7C          ld   a,h
A670: 32 B5 0E    ld   (MAP_OFFSET),a
A673: DD 77 00    ld   (ix+$00),a
A676: 3E 00       ld   a,$00
A678: 32 D5 0E    ld   ($E05D),a		; Redunant storage, never used anywhere. 0 40 80 c0 only
A67B: DD 77 20    ld   (ix+$02),a
A67E: DD 77 41    ld   (ix+$05),a
A681: 7C          ld   a,h			; divide the high y position by 16
A682: E6 F3       and  $3F			; making sure we wrap around right data set
A684: 67          ld   h,a			; So we're adding offset address into the table
A685: CB 3C       srl  h			; With each area is a multiple of $80 bytes
A687: CB 1D       rr   l
A689: CB 3C       srl  h
A68B: CB 1D       rr   l
A68D: CB 3C       srl  h
A68F: CB 1D       rr   l
A691: CB 3C       srl  h
A693: CB 1D       rr   l
A695: 19          add  hl,de			; add start of table to value
A696: DD 74 21    ld   (ix+$03),h
A699: DD 75 40    ld   (ix+$04),l
A69C: 21 06 1E    ld   hl,TILE_POINTERS_RAM+$60	; init save address for map decode
A69F: DD 74 60    ld   (ix+$06,h
A6A2: DD 75 61    ld   (ix+$07),l
A6A5: 21 00 1E    ld   hl,TILE_DECODE_RAM	; start of map decode save address
A6A8: DD 74 80    ld   (ix+$08),h
A6AB: DD 75 81    ld   (ix+$09),l
A6AE: DD 74 C0    ld   (ix+$0c),h
A6B1: DD 75 C1    ld   (ix+$0d),l
A6B4: DD 36 30 00 ld   (ix+$12),$00
A6B8: DD 36 31 1A ld   (ix+$13),$B0
A6BC: C9          ret

		  ; Tiles start from $45c4
		  ; Tile draw 4 x 4 for 16 byte but use 2 one for char.ram and other for colour ram, hence * 32
		  ; charcter tiles are 16x16 pixels, with this being tiled as 4 x 4 for pixel size of 64x64
		  ; with screen only 256 x 256 visble screen is only 16 bytes! (minus 16 pixels left - right that is)
PLOT_TILE_4X4:
A6BD: 06 40       ld   b,$04			; decode map data 4 is the amount of strips?
; Column Loop
A6BF: D9          exx				; keep the registers for later
A6C0: DD 66 21    ld   h,(ix+$03)		; read current map data position this starts at $41b4
A6C3: DD 6E 40    ld   l,(ix+$04)
A6C6: 7E          ld   a,(hl)			; read the Tile number byte number here
A6C7: 23          inc  hl			; advance the address source map data
A6C8: DD 74 21    ld   (ix+$03),h
A6CB: DD 75 40    ld   (ix+$04),l		; save the advanced address
A6CE: 6F          ld   l,a			; move to l for multiply
A6CF: 26 00       ld   h,$00			; source tile 0-255 only well we only read one byte!)
A6D1: 29          add  hl,hl
A6D2: 29          add  hl,hl
A6D3: 29          add  hl,hl
A6D4: 29          add  hl,hl
A6D5: 29          add  hl,hl			; now value * 32
A6D6: 11 4C 45    ld   de,TILE_DATA		; tile data is 32 bytes  and we add get start address
A6D9: 19          add  hl,de			; add tile start offset to get base data
A6DA: DD 56 60    ld   d,(ix+$06)		; get save address in RAM $f060 (starting value)
A6DD: DD 5E 61    ld   e,(ix+$07)
A6E0: 3E 40       ld   a,$04
; Row loop
A6E2: 08          ex   af,af'
A6E3: D5          push de
A6E4: 01 80 00    ld   bc,$0008			; now add 8 to memory address
A6E7: ED B0       ldir
A6E9: D1          pop  de
A6EA: EB          ex   de,hl
A6EB: 3E 0E       ld   a,$E0			; Add address is four rows down from memory address ie 4 * 32 bytes
A6ED: 85          add  a,l
A6EE: 6F          ld   l,a
A6EF: EB          ex   de,hl
A6F0: 08          ex   af,af'			; swap register set
A6F1: 3D          dec  a
A6F2: 20 EE       jr   nz,$A6E2			; tile across

A6F4: DD 66 60    ld   h,(ix+$06)
A6F7: DD 6E 61    ld   l,(ix+$07)
A6FA: 01 80 00    ld   bc,$0008			; add to save address 8 bytes as tiles is 4 lot of 2 bytes
A6FD: 09          add  hl,bc
A6FE: DD 74 60    ld   (ix+$06),h		; save back the data to the pointers low and high
A701: DD 75 61    ld   (ix+$07),l
A704: D9          exx				; get registers back basically the count for each row
A705: 10 9A       djnz $A6BF

A707: D9          exx
A708: 01 06 00    ld   bc,$0060			; if we started at $f000 plots from $f060 then next big tile memory is 4 lines below so $f0c0
A70B: 09          add  hl,bc
A70C: 7C          ld   a,h
A70D: E6 3F       and  $F3
A70F: DD 77 60    ld   (ix+$06),a
A712: DD 75 61    ld   (ix+$07),l
A715: C9          ret

		; Called after decode to update the display and memory pointers, and keep within the memory ranges in a constant circular buffer space
		; basically when the screen display is exhausted it will want to update the memory what can't be seen.
		; so tiles and positions are tracks as is the memory places.
UPDATE_PLOT_POINTERS:
A716: DD 56 80    ld   d,(ix+$08)		; Read address for background tile data plotted
A719: DD 5E 81    ld   e,(ix+$09)
A71C: D9          exx				; preserve address
A71D: DD 56 A0    ld   d,(ix+$0a)		; our character map for the plotted characters
A720: DD 5E A1    ld   e,(ix+$0b)
A723: 06 04       ld   b,$40			; 64 count this is one chunk strip of tile data plotted

A725: D9          exx				; get back original offset
A726: 1A          ld   a,(de)			; Read first plot character memory (first was $3a for example)
A727: 13          inc  de			; advance memory
A728: 21 46 06    ld   hl,CHARACTER_LOOKUP	; now lookup the index table for character offset
A72B: DF          rst	ADD_A_TO_HL	 	; call ADD_A_TO_HL
A72C: 1A          ld   a,(de)			; read the value here that's colour info info and
A72D: 4F          ld   c,a			; save the value to A
A72E: 13          inc  de			; skip attribute to next screen character memory address
A72F: 07          rlca
A730: 07          rlca
A731: E6 21       and  $03
A733: 84          add  a,h
A734: 67          ld   h,a
A735: 7E          ld   a,(hl)
A736: D9          exx
A737: 12          ld   (de),a
A738: 13          inc  de
A739: D9          exx
A73A: 79          ld   a,c
A73B: 07          rlca
A73C: 07          rlca
A73D: 07          rlca
A73E: E6 01       and  $01
A740: D9          exx
A741: 12          ld   (de),a
A742: 13          inc  de
A743: 10 0E       djnz $A725

A745: 7A          ld   a,d
A746: E6 BF       and  $FB
A748: DD 77 A0    ld   (ix+$0a),a
A74B: DD 73 A1    ld   (ix+$0b),e
A74E: D9          exx
A74F: 7A          ld   a,d
A750: E6 3F       and  $F3
A752: DD 77 80    ld   (ix+$08),a
A755: DD 73 81    ld   (ix+$09),e
A758: C9          ret

		; this draws a strip of tile characters across, the system draws 4 rows of them at a time, and it's just 16 across.
		; ix is index to the current strip of data, de being the screen memory.
		; Source and Destination are pre-setup at index locations in IX which seems always $ef00 scratch ram
		; once the chunk of characters has been written, all locations are updated and saved back.
		; This acts as a circular buffer so it's constantly rotating around the source - destination memory.
DRAW_TILE_BLOCK:
A759: 0E 40       ld   c,$04		; This is y row counter
A75B: DD 66 C0    ld   h,(ix+$0c)	; Source character tile map buffer High
A75E: DD 6E C1    ld   l,(ix+$0d)	; and Low bytes
A761: DD 56 E0    ld   d,(ix+$0e)	; Destination Hi
A764: DD 5E E1    ld   e,(ix+$0f)
A767: 06 10       ld   b,$10		; setup the x counter
A769: 7E          ld   a,(hl)		; get tile data
A76A: 12          ld   (de),a		; save to screen
A76B: 23          inc  hl		; add 1 to source
A76C: 7E          ld   a,(hl)		; get palette and other character bits
A76D: CB D2       set  2,d		; add $400 setting the high bit 2 does this trick
A76F: 12          ld   (de),a		; save the color RAM data
A770: CB 92       res  2,d		; back to video RAM values
A772: 23          inc  hl		; move source on
A773: 13          inc  de		; move destination on
A774: 10 3F       djnz $A769		; count all 16 across
A776: EB          ex   de,hl		; swap destination and source for the add function.
A777: 3E 10       ld   a,$10		; now add on to next line. remember one line is actually 32 ($20) but pointers already at halfway
A779: DF          rst	ADD_A_TO_HL	; call ADD_A_TO_HL
A77A: EB          ex   de,hl		; swap back source and destination
A77B: 0D          dec  c		; now do all in the y position
A77C: 20 8F       jr   nz,$A767		; loop until completed.
A77E: 7C          ld   a,h
A77F: E6 3F       and  $F3		; Keep source data in a circular buffer so it's always $f000 - $f300 masking
A781: DD 77 C0    ld   (ix+$0c),a	; save HL positions back to indexed data
A784: DD 75 C1    ld   (ix+$0d),l	; save the low
A787: EB          ex   de,hl		; swap over
A788: 7C          ld   a,h		; now keep destination address as $d800 - $db00
A789: E6 BD       and  $DB
A78B: DD 77 E0    ld   (ix+$0e),a	; save the destination screen memory High
A78E: DD 75 E1    ld   (ix+$0f),l	; and save low
A791: C9          ret			; Get out of here.

CLEAR_BACKGROUND:
A792: 21 00 9C    ld   hl,VIDEO_RAM
A795: 11 01 9C    ld   de,VIDEO_RAM+1
A798: 01 FF 21    ld   bc,$03FF		; 1k of video memory
A79B: 36 9E       ld   (hl),$F8		; $f8 is blank
A79D: ED B0       ldir
A79F: 01 00 40    ld   bc,$0400		; 1k colour memory
A7A2: 36 00       ld   (hl),$00
A7A4: ED B0       ldir
A7A6: C9          ret


		; Helicopter sprite table, pairs of sprite numbers and attributes
		; Each table entry is pointed too by table at $AC7E first bytes are low high order for this table set
		
a7a7:		db	$c4, $80, $c5, $80, $ca, $80, $cb, $80, $cc, $80, $cd, $80, $ce, $80
a7b5:		db	$d2, $88, $cd, $8c, $cc, $8c, $cb, $8c, $ca, $8c, $d3, $88, $da, $88, $d9, $88, $d8, $88
a7c7:		db	$ca, $84, $cb, $84, $cc, $84, $cd, $84, $d2, $80, $d8, $80, $d9, $80, $da, $80, $d3, $80
a7d9:		db	$c5, $88, $c4, $88, $ce, $88, $cd, $88, $cc, $88, $cb, $88, $ca, $88
a7e7:		db	$c8, $84, $d0, $88, $d0, $80, $dd, $88, $dc, $80, $dc, $80, $dd, $80
a7f5:		db	$c0, $88, $c0, $80, $c8, $80
a7fb:		db	$ca, $80, $cb, $80, $c6, $80, $c7, $80
a803:		db	$d5, $88, $cd, $8c, $cc, $8c, $cb, $8c, $ca, $8c, $d4, $88, $d8, $88
a811:		db	$ca, $84, $cb, $84, $cc, $84, $cd, $84, $d5, $80, $d8, $80, $d4, $80
a81f:		db 	$c7, $88, $c6, $88, $cb, $88, $ca, $88
a827:		db	$c8, $8c, $d0, $88, $d0, $80
a82d:		db	$de, $88, $de, $80, $c8, $80
a833:		db	$ca, $80, $db, $80, $df, $80, $d7, $80
a83b:		db	$d6, $88, $c3, $88, $cc, $8c, $cb, $8c, $ca, $8c, $c1, $88, $cf, $88
a849:		db	$ca, $84, $cb, $84, $cc, $84, $c3, $80, $d6, $80, $cf, $80, $c1, $80
a857:		db	$d7, $88, $df, $88, $db, $88, $ca, $88
a85f:		db	$c8, $8c, $c9, $88, $c9, $80
a865:		db	$c8, $80

HELICOPTER_RIDE:
A867: DD 21 06 0F ld   ix,HELICOPTER_DATA	; Helicopter Data table
A86B: FD 21 C4 FE ld   iy,HW_SPRITE_19		; sprite address
A86F: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
A873: DD 36 21 08 ld   (ix+TABLE_X_coord),$80
A877: DD 36 40 00 ld   (ix+TABLE_X_low),$00
A87B: DD 36 41 12 ld   (ix+TABLE_Y_coord),$30
A87F: DD 36 60 00 ld   (ix+TABLE_Y_low),$00
A883: 21 00 01    ld   hl,$0100
A886: DD 74 61    ld   (ix+TABLE_new_X_high),h
A889: DD 75 80    ld   (ix+TABLE_new_X_low),l
A88C: 21 DE FF    ld   hl,$FFFC
A88F: DD 74 81    ld   (ix+TABLE_new_Y_high),h
A892: DD 75 A0    ld   (ix+TABLE_new_Y_low),l
A895: DD 36 A1 08 ld   (ix+TABLE_X_Add_low),$80
A899: DD 36 31 00 ld   (ix+ITEM_TYPE),$00
A89D: DD 36 50 00 ld   (ix+$14),$00
A8A1: 21 00 01    ld   hl,$0100			; Countdown passed
A8A4: CD E1 AB    call $AB0F
A8A7: C9          ret

A8A8: CD 27 CB    call $AD63
A8AB: DD 21 06 0F ld   ix,HELICOPTER_DATA
A8AF: FD 21 C4 FE ld   iy,HW_SPRITE_19
A8B3: CD 0D 8A    call $A8C1
A8B6: DD 7E 00    ld   a,(ix+TABLE_STATUS)
A8B9: A7          and  a
A8BA: C8          ret  z
A8BB: CD 63 AB    call $AB27
A8BE: C3 EC AB    jp   $ABCE
A8C1: DD 66 51    ld   h,(iy+TABLE_COUNTDOWN)
A8C4: DD 6E 70    ld   l,(ix+$16)
A8C7: 2B          dec  hl
A8C8: DD 74 51    ld   (iy+TABLE_COUNTDOWN),h
A8CB: DD 75 70    ld   (ix+$16),l
A8CE: 7C          ld   a,h
A8CF: B5          or   l
A8D0: CC 9F 8A    call z,$A8F9
A8D3: DD 7E 50    ld   a,(ix+$14)
A8D6: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$a8f1	; Table 0
		dw	$a8f4	; Table 1
		dw	$a8f4	; Table 2
		dw	$a8f4	; Table 3
		dw	$a8f4	; Table 4
		dw	$a8f4	; Table 5
		dw	$a8f4	; Table 6
		dw	$a8f4	; Table 7
		dw	$a8f4	; Table 8
		dw	$a8f4	; Table 9
		dw	$a8f4	; Table A
		dw	$a8f4	; Table B
		dw	$a8f5	; Table C

A8F1: C3 64 AA    jp   $AA46
A8F4: C9          ret
A8F5: C3 64 AA    jp   $AA46

A8F8: C9          ret
A8F9: DD 7E 50    ld   a,(ix+$14)
A8FC: DD 34 50    inc  (ix+$14)
A8FF: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$a91a	; Table 0
		dw	$a91d	; Table 1
		dw	$a92c	; Table 2
		dw	$a92f	; Table 3
		dw	$a955	; Table 4
		dw	$a958	; Table 5
		dw	$a95e	; Table 6
		dw	$a972	; Table 7
		dw	$a975	; Table 8
		dw	$a978	; Table 9
		dw	$a97b	; Table A
		dw	$a97e	; Table B

A918: 09          add  hl,bc
A919: 8B          adc  a,e
A91A: C3 79 AA    jp   $AA97

A91D: DD 34 31    inc  (ix+ITEM_TYPE)
A920: 21 8E FF    ld   hl,$FFE8
A923: CD 01 AB    call $AB01
A926: 21 90 00    ld   hl,ADD_A_TO_HL
A929: C3 E1 AB    jp   $AB0F

A92C: C3 BB AA    jp   $AABB

A92F: 3A 00 0F    ld   a,(PLAYER_DATA)
A932: FE FE       cp   $FE
A934: C2 A5 8B    jp   nz,$A94B
A937: AF          xor  a
A938: 32 00 0F    ld   (PLAYER_DATA),a
A93B: 32 B2 FF    ld   ($FF3A),a
A93E: 32 F2 FF    ld   ($FF3E),a
A941: 32 24 FF    ld   ($FF42),a
A944: 3C          inc  a
A945: 32 7B 0E    ld   ($E0B7),a
A948: C3 0D AA    jp   $AAC1
A94B: DD 36 50 21 ld   (ix+$14),$03
A94F: 21 61 00    ld   hl,$0007
A952: C3 E1 AB    jp   $AB0F

A955: C3 6D AA    jp   $AAC7

A958: CD 39 68    call SFX_HELI_RIDE
A95B: C3 9D AA    jp   $AAD9

A95E: 3A 7B 0E    ld   a,($E0B7)
A961: FE 20       cp   $02
A963: 20 21       jr   nz,$A968
A965: C3 79 AA    jp   $AA97
A968: DD 36 50 60 ld   (ix+$14),$06
A96C: 21 61 00    ld   hl,$0007
A96F: C3 E1 AB    jp   $AB0F

A972: C3 8B AA    jp   $AAA9

A975: C3 BB AA    jp   $AABB

A978: C3 0D AA    jp   $AAC1

A97B: C3 6D AA    jp   $AAC7

A97E: C3 9D AA    jp   $AAD9

A981: E1          pop  hl
A982: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
A986: CD 2B 8B    call $A9A3
A989: C9          ret

A98A: 21 12 FE    ld   hl,HW_SPRITE_12		; Large sprite 1
A98D: 11 CA FE    ld   de,HW_SPRITE_43
A990: 01 08 00    ld   bc,$0080
A993: ED B0       ldir
A995: 21 D2 FE    ld   hl,HW_SPRITE_15		; $FE3C
A998: 11 D3 FE    ld   de,$FE3D
A99B: 36 00       ld   (hl),$00
A99D: 01 E1 00    ld   bc,$000F
A9A0: ED B0       ldir
A9A2: C9          ret

A9A3: 11 12 FE    ld   de,HW_SPRITE_12		; Large sprite 1
A9A6: 21 CA FE    ld   hl,HW_SPRITE_43
A9A9: 01 08 00    ld   bc,$0080
A9AC: ED B0       ldir
A9AE: 21 CA FE    ld   hl,HW_SPRITE_43
A9B1: 11 CB FE    ld   de,$FEAD
A9B4: 36 00       ld   (hl),$00
A9B6: 01 F7 00    ld   bc,$007F
A9B9: ED B0       ldir
A9BB: C9          ret

A9BC: CD 48 68    call SFX_HELI_ARRIVE
A9BF: CD A8 8B    call $A98A
A9C2: DD 21 06 0F ld   ix,HELICOPTER_DATA	; large sprite data table for heli-ride
A9C6: FD 21 C4 FE ld   iy,HW_SPRITE_19		; Used for helicopter ride
A9CA: DD 36 00 FF ld   (ix+TABLE_STATUS),$FF
A9CE: DD 36 21 08 ld   (ix+TABLE_X_coord),$80
A9D2: DD 36 40 00 ld   (ix+TABLE_X_low),$00
A9D6: DD 36 41 12 ld   (ix+TABLE_Y_coord),$30
A9DA: DD 36 60 00 ld   (ix+TABLE_Y_low),$00
A9DE: 21 00 01    ld   hl,$0100
A9E1: DD 74 61    ld   (ix+TABLE_new_X_high),h
A9E4: DD 75 80    ld   (ix+TABLE_new_X_low),l
A9E7: 21 DE FF    ld   hl,$FFFC
A9EA: DD 74 81    ld   (ix+TABLE_new_Y_high),h
A9ED: DD 75 A0    ld   (ix+TABLE_new_Y_low),l
A9F0: DD 36 A1 08 ld   (ix+TABLE_X_Add_low),$80
A9F4: DD 36 31 00 ld   (ix+ITEM_TYPE),$00
A9F8: DD 36 50 00 ld   (ix+$14),$00
A9FC: 21 00 01    ld   hl,$0100
A9FF: CD E1 AB    call $AB0F
AA02: C9          ret

AA03: CD 27 CB    call $AD63
AA06: DD 21 06 0F ld   ix,HELICOPTER_DATA	; Helicopter table
AA0A: FD 21 C4 FE ld   iy,HW_SPRITE_19		; start with this sprite as there is a bucket load needed
AA0E: CD 71 AA    call $AA17
AA11: CD 63 AB    call $AB27
AA14: C3 F1 AB    jp   $AB1F

AA17: DD 66 51    ld   h,(iy+TABLE_COUNTDOWN)	; used for a countdown timer two bytes
AA1A: DD 6E 70    ld   l,(ix+$16)
AA1D: 2B          dec  hl			; -1
AA1E: DD 74 51    ld   (iy+TABLE_COUNTDOWN),h
AA21: DD 75 70    ld   (ix+$16),l		; save back
AA24: 7C          ld   a,h
AA25: B5          or   l			; check if reached 0
AA26: CC F7 AA    call z,$AA7F			; if so then call next phase of animation
AA29: DD 7E 50    ld   a,(ix+$14)		; jump action number
AA2C: E6 61       and  $07			; keep it real 0-7 (actually just 6)
AA2E: F7          rst  JUMP_TABLE		; Jump table from count a
 
		dw	$aa3d	; Table 0
		dw	$aa41	; Table 1
		dw	$aa41	; Table 2
		dw	$aa41	; Table 3
		dw	$aa41	; Table 4
		dw	$aa41	; Table 5
		dw	$aa42	; Table 6

AA3D: CD 64 AA    call $AA46
AA40: C9          ret
AA41: C9          ret
AA42: CD 64 AA    call $AA46
AA45: C9          ret
AA46: DD 66 61    ld   h,(ix+TABLE_new_X_high)
AA49: DD 6E 80    ld   l,(ix+TABLE_new_X_low)
AA4C: 3A 20 0E    ld   a,(FRAME_SYNC)
AA4F: E6 21       and  $03
AA51: 20 70       jr   nz,$AA69
AA53: DD 7E A1    ld   a,(ix+TABLE_X_Add_low)
AA56: A7          and  a
AA57: 28 10       jr   z,$AA69
AA59: DD 35 A1    dec  (ix+TABLE_X_Add_low)
AA5C: DD 56 81    ld   d,(ix+TABLE_new_Y_high)
AA5F: DD 5E A0    ld   e,(ix+TABLE_new_Y_low)
AA62: 19          add  hl,de
AA63: DD 74 61    ld   (ix+TABLE_new_X_high),h
AA66: DD 75 80    ld   (ix+TABLE_new_X_low),l
AA69: DD 7E 40    ld   a,(ix+TABLE_X_low)
AA6C: DD 56 41    ld   d,(ix+TABLE_Y_coord)
AA6F: DD 5E 60    ld   e,(ix+TABLE_Y_low)
AA72: 19          add  hl,de
AA73: DD 74 41    ld   (ix+TABLE_Y_coord),h
AA76: DD 75 60    ld   (ix+TABLE_Y_low),l
AA79: CE 00       adc  a,$00
AA7B: DD 77 40    ld   (ix+TABLE_X_low),a
AA7E: C9          ret

AA7F: DD 7E 50    ld   a,(ix+$14)		; jump table current value
AA82: DD 34 50    inc  (ix+$14)
AA85: FE 60       cp   $06
AA87: CA 70 AB    jp   z,$AB16
AA8A: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$aa97	; Table 0
		dw	$aaa9	; Table 1
		dw	$aabb	; Table 2
		dw	$aac1	; Table 3
		dw	$aac7	; Table 4
		dw	$aad9	; Table 5

AA97: CD 89 68    call SFX_HELI_LAND		; Helicopter Sound
AA9A: DD 34 31    inc  (ix+ITEM_TYPE)
AA9D: 21 8E FF    ld   hl,$FFE8
AAA0: CD 01 AB    call $AB01
AAA3: 21 90 00    ld   hl,$0018
AAA6: C3 E1 AB    jp   $AB0F

AAA9: DD 34 31    inc  (ix+ITEM_TYPE)
AAAC: 21 8E FF    ld   hl,$FFE8
AAAF: CD 01 AB    call $AB01
AAB2: CD 54 CB    call $AD54
AAB5: 21 90 00    ld   hl,$0018
AAB8: C3 E1 AB    jp   $AB0F

AABB: 21 01 00    ld   hl,$0001
AABE: C3 E1 AB    jp   $AB0F

AAC1: 21 10 00    ld   hl,$0010
AAC4: C3 E1 AB    jp   $AB0F

AAC7: CD E8 68    call SFX_HELI_LIFT
AACA: DD 35 31    dec  (ix+ITEM_TYPE)
AACD: 21 90 00    ld   hl,$0018
AAD0: CD 01 AB    call $AB01
AAD3: 21 10 00    ld   hl,$0010
AAD6: C3 E1 AB    jp   $AB0F

AAD9: DD 35 31    dec  (ix+ITEM_TYPE)
AADC: 21 90 00    ld   hl,$0018
AADF: CD 01 AB    call $AB01
AAE2: 21 00 00    ld   hl,$0000
AAE5: DD 74 61    ld   (ix+TABLE_new_X_high),h
AAE8: DD 75 80    ld   (ix+TABLE_new_X_low),l
AAEB: 21 11 00    ld   hl,$0011
AAEE: DD 74 81    ld   (ix+TABLE_new_Y_high),h
AAF1: DD 75 A0    ld   (ix+TABLE_new_Y_low),l
AAF4: DD 36 A1 08 ld   (ix+TABLE_X_Add_low),$80
AAF8: 21 08 00    ld   hl,$0080
AAFB: C3 E1 AB    jp   $AB0F

AAFE: 21 8E FF    ld   hl,$FFE8
AB01: DD 56 40    ld   d,(ix+TABLE_X_low)
AB04: DD 5E 41    ld   e,(ix+TABLE_Y_coord)
AB07: 19          add  hl,de
AB08: DD 74 40    ld   (ix+TABLE_X_low),h
AB0B: DD 75 41    ld   (ix+TABLE_Y_coord),l
AB0E: C9          ret

AB0F: DD 74 51    ld   (iy+TABLE_COUNTDOWN),h
AB12: DD 75 70    ld   (ix+$16),l
AB15: C9          ret

AB16: E1          pop  hl
AB17: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
AB1B: CD 2B 8B    call $A9A3
AB1E: C9          ret
AB1F: DD 7E 00    ld   a,(ix+TABLE_STATUS)
AB22: A7          and  a
AB23: C8          ret  z
AB24: C3 EC AB    jp   $ABCE
AB27: DD 7E 31    ld   a,(ix+ITEM_TYPE)
AB2A: 21 52 AB    ld   hl,$AB34
AB2D: EF          rst	INDEX_ED_AT_2A_PLUS_HL
AB2E: CD 88 A3    call HW_SPRITE_UPDATER		; do one set
AB31: C3 88 A3    jp   HW_SPRITE_UPDATER		; then do another set sprites below table

AB34:		dw	$ab3a	; Table 0
		dw	$ab6a	; Table 1
		dw	$ab9a	; Table 2
		
		; 11 sprites * 2 here big!
ab3a:		db	$0b, $90, $f0, $e7, $ef, $ee, $ff, $ef, $ee, $e4, $fe, $e5, $ed, $ec, $fd, $ed, $ec, $f4, $fc, $f5, $eb, $fc, $fb, $fd
		db	$0b, $98, $00, $e7, $1f, $ee, $0f, $ef, $1e, $e4, $0e, $e5, $1d, $ec, $0d, $ed, $1c, $f4, $0c, $f5, $1b, $fc, $0b, $fd
ab6a:		db	$0b, $90, $f0, $e6, $ef, $e2, $ff, $e3, $ee, $ea, $fe, $eb, $ed, $f2, $fd, $f3, $ec, $fa, $fc, $fb, $ed, $ff, $ed, $ff
		db	$0b, $98, $00, $e6, $1f, $e2, $0f, $e3, $1e, $ea, $0e, $eb, $1d, $f2, $0d, $f3, $1c, $fa, $0c, $fb, $1d, $ff, $1d, $ff
ab9a:		db	$0b, $90, $e0, $e0, $f0, $e1, $ef, $e8, $ff, $e9, $ee, $f0, $fe, $f1, $ed, $f8, $fd, $f9, $ed, $ff, $ed, $ff, $ed, $ff
		db	$0b, $98, $10, $e0, $00, $e1, $1f, $e8, $0f, $e9, $1e, $f0, $0e, $f1, $1d, $f8, $0d, $f9, $1d, $ff, $1d, $ff, $1d, $ff

ABC9: FF          rst  $38
ABCA: DD 21 06 0F ld   ix,HELICOPTER_DATA
ABCE: CD 62 CB    call $AD26
ABD1: DD 7E 00    ld   a,(ix+TABLE_STATUS)
ABD4: A7          and  a
ABD5: C8          ret  z
ABD6: 21 ED 2A    ld   hl,$A2CF
ABD9: E5          push hl
ABDA: DD 34 71    inc  (ix+$17)
ABDD: DD 7E 71    ld   a,(ix+$17)
ABE0: FE 60       cp   $06
ABE2: 38 41       jr   c,$ABE9
ABE4: 3E 00       ld   a,$00
ABE6: DD 77 71    ld   (ix+$17),a
ABE9: DD 66 40    ld   h,(ix+TABLE_X_low)
ABEC: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
ABEF: 11 7E FF    ld   de,$FFF6
ABF2: 19          add  hl,de
ABF3: DD 74 C0    ld   (ix+TABLE_X_Add_high),h
ABF6: DD 75 C1    ld   (ix+$0d),l
ABF9: FD 21 90 FE ld   iy,HW_SPRITE_6
ABFD: 47          ld   b,a
ABFE: DD 7E 31    ld   a,(ix+ITEM_TYPE)
AC01: E6 21       and  $03
AC03: 21 54 CA    ld   hl,$AC54
AC06: EF          rst	INDEX_ED_AT_2A_PLUS_HL
AC07: DD 66 21    ld   h,(ix+TABLE_X_coord)
AC0A: DD 6E C1    ld   l,(ix+$0d)
AC0D: DD 7E C0    ld   a,(ix+TABLE_X_Add_high)
AC10: E6 01       and  $01
AC12: 4F          ld   c,a
AC13: E5          push hl
AC14: 78          ld   a,b
AC15: EB          ex   de,hl
AC16: EF          rst	INDEX_ED_AT_2A_PLUS_HL
AC17: D5          push de			; transfer de to IX
AC18: DD E1       pop  ix
AC1A: DD 5E 00    ld   e,(ix+TABLE_STATUS)		; get mast sprite data table low byte
AC1D: DD 56 01    ld   d,(ix+$01)		; get master sprite data table entry high byte starts @ $a7a7
AC20: DD 7E 20    ld   a,(ix+$02)		; how many sprites in the y direction to plot
AC23: 08          ex   af,af'
AC24: E1          pop  hl

AC25: DD 46 21    ld   b,(ix+TABLE_X_coord)		; how many sprites across the x direction to plot
AC28: 7C          ld   a,h
AC29: DD 86 40    add  a,(ix+TABLE_X_low)
AC2C: 67          ld   h,a
AC2D: 7D          ld   a,l
AC2E: E5          push hl
AC2F: D5          push de
AC30: 61          ld   h,c
AC31: DD 5E 41    ld   e,(ix+TABLE_Y_coord)
AC34: 16 00       ld   d,$00
AC36: CB 7B       bit  7,e
AC38: 28 01       jr   z,$AC3B
AC3A: 14          inc  d
AC3B: 19          add  hl,de
AC3C: 7C          ld   a,h
AC3D: E6 01       and  $01
AC3F: 4F          ld   c,a
AC40: 7D          ld   a,l
AC41: D1          pop  de
AC42: E1          pop  hl
AC43: 6F          ld   l,a
AC44: CD 52 CB    call $AD34
AC47: DD 23       inc  ix
AC49: DD 23       inc  ix
AC4B: DD 23       inc  ix
AC4D: 08          ex   af,af'
AC4E: 3D          dec  a
AC4F: C8          ret  z
AC50: 08          ex   af,af'
AC51: C3 43 CA    jp   $AC25

AC54:	dw	$ac5a	; Table 0
AC56:	dw	$ac66	; Table 1
AC58:	dw	$ac72	; Table 2

ac5a:   dw      $ac7e
ac5c:   dw      $ac87
ac5e:   dw      $ac93
ac60:   dw      $ac9f
ac62:   dw      $aca8
ac64:   dw      $acb4
ac66:   dw      $acbd
ac68:   dw      $acc3
ac6a:   dw      $accf
ac6c:   dw      $acdb
ac6e:   dw      $ace1
ac70:   dw      $acea
ac72:   dw      $acf3
ac74:   dw      $acf9
ac76:   dw      $ad05
ac78:   dw      $ad11
ac7a:   dw      $ad17
ac7c:   dw      $ad20

		; Helicopter sprite table; quite complex set of table to pointers.
		
ac7e:   db      $a7, $a7, $02, $02, $20, $20, $05, $c0, $f0
ac87:   db      $b5, $a7, $03, $05, $b0, $00, $01, $a0, $f3, $03, $00, $fd
ac93:   db      $c7, $a7, $03, $05, $00, $00, $03, $d0, $f0, $01, $00, $03
ac9f:   db      $d9, $a7, $02, $02, $c0, $20, $05, $d0, $f0
aca8:   db      $e7, $a7, $03, $01, $f8, $00, $02, $e8, $f0, $04, $d0, $f0
acb4:   db      $f5, $a7, $02, $02, $f0, $20, $01, $e8, $f0
acbd:   db      $fb, $a7, $01, $04, $00, $10
acc3:   db      $03, $a8, $03, $01, $b0, $f8, $04, $00, $08, $02, $c0, $f0
accf:   db      $11, $a8, $03, $04, $00, $00, $01, $00, $f8, $02, $d0, $f8
acdb:   db      $1f, $a8, $01, $04, $c0, $10
ace1:   db      $27, $a8, $02, $01, $f8, $00, $02, $e8, $f0
acea:   db      $2d, $a8, $02, $02, $f0, $20, $01, $e8, $f0
acf3:   db      $33, $a8, $01, $04, $00, $10
acf9:   db      $3b, $a8, $03, $01, $b0, $f8, $04, $00, $08, $02, $c0, $f0
ad05:   db      $49, $a8, $03, $04, $00, $00, $01, $00, $f8, $02, $d0, $f8
ad11:   db      $57, $a8, $01, $04, $c0, $10
ad17:   db      $5f, $a8, $02, $01, $f8, $00, $02, $e8, $f0
ad20:   db      $65, $a8, $01, $01, $f8, $10

AD26: 21 B0 FE    ld   hl,$FE1A
AD29: 11 40 00    ld   de,$0004
AD2C: 06 81       ld   b,$09
AD2E: 36 00       ld   (hl),$00
AD30: 19          add  hl,de
AD31: 10 BF       djnz $AD2E
AD33: C9          ret

AD34: FD 74 20    ld   (iy+sprite_x),h		; x increased per hw sprite used
AD37: FD 75 21    ld   (iy+sprite_y),l		; y is same for this loop
AD3A: 1A          ld   a,(de)			; read data table entry
AD3B: 13          inc  de
AD3C: FD 77 00    ld   (iy+sprite_number),a	; use as sprite number
AD3F: 1A          ld   a,(de)			; now get flags
AD40: 13          inc  de			; advance pointer
AD41: 81          add  a,c			; c was current flag point to add to
AD42: FD 77 01    ld   (iy+sprite_flags),a	; save to sprite HW
AD45: 7C          ld   a,h
AD46: C6 10       add  a,$10			; add 16 to sprite x
AD48: 67          ld   h,a
AD49: FD 23       inc  iy			; IY + 4 is next sprite
AD4B: FD 23       inc  iy
AD4D: FD 23       inc  iy
AD4F: FD 23       inc  iy
AD51: 10 0F       djnz $AD34			; b was the count do do as many as requested
AD53: C9          ret

AD54: 3E FF       ld   a,$FF
AD56: 32 02 4E    ld   ($E420),a
AD59: 3C          inc  a
AD5A: 32 52 4E    ld   ($E434),a
AD5D: 3E 90       ld   a,$18
AD5F: 32 53 4E    ld   ($E435),a
AD62: C9          ret


AD63: DD 21 02 4E ld   ix,$E420
AD67: FD 21 D2 FE ld   iy,HW_SPRITE_15
AD6B: DD 7E 00    ld   a,(ix+TABLE_STATUS)
AD6E: A7          and  a
AD6F: C8          ret  z
AD70: DD 35 51    dec  (iy+TABLE_COUNTDOWN)
AD73: CA A7 EA    jp   z,$AE6B
AD76: DD 7E 50    ld   a,(ix+$14)
AD79: E6 21       and  $03
AD7B: F7          rst  JUMP_TABLE		; Jump table from count a

		dw	$ad84	; Table 0
		dw	$ada3	; Table 1
		dw	$ae08	; Table 2
		dw	$ae32	; Table 3
		
AD84: 3A 27 0F    ld   a,($E163)
AD87: C6 10       add  a,$10
AD89: FD 77 20    ld   (iy+sprite_x),a
AD8C: DD 77 21    ld   (ix+TABLE_X_coord),a
AD8F: 3A 47 0F    ld   a,($E165)
AD92: C6 3E       add  a,$F2
AD94: FD 77 21    ld   (iy+sprite_y),a
AD97: DD 77 41    ld   (ix+TABLE_Y_coord),a
AD9A: FD 36 00 EC ld   (iy+sprite_number),$CE
AD9E: FD 36 01 00 ld   (iy+sprite_flags),$00
ADA2: C9          ret

ADA3: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
ADA6: 0F          rrca
ADA7: 0F          rrca
ADA8: 0F          rrca
ADA9: E6 61       and  $07
ADAB: 47          ld   b,a
ADAC: 21 8E CB    ld   hl,$ADE8
ADAF: EF          rst	INDEX_ED_AT_2A_PLUS_HL
ADB0: 1A          ld   a,(de)
ADB1: 13          inc  de
ADB2: DD 77 F0    ld   (ix+$1e),a
ADB5: DD 72 81    ld   (ix+TABLE_new_Y_high),d
ADB8: DD 73 A0    ld   (ix+TABLE_new_Y_low),e
ADBB: 78          ld   a,b
ADBC: 21 FE CB    ld   hl,$ADFE
ADBF: EF          rst	INDEX_ED_AT_2A_PLUS_HL
ADC0: 01 96 00    ld   bc,$0078				; 
ADC3: DD 66 21    ld   h,(ix+TABLE_X_coord)
ADC6: DD 6E 40    ld   l,(ix+TABLE_X_low)
ADC9: 09          add  hl,bc
ADCA: DD 74 21    ld   (ix+TABLE_X_coord),h
ADCD: DD 75 40    ld   (ix+TABLE_X_low),l
ADD0: DD 66 41    ld   h,(ix+TABLE_Y_coord)
ADD3: DD 6E 60    ld   l,(ix+TABLE_Y_low)
ADD6: 19          add  hl,de
ADD7: DD 74 41    ld   (ix+TABLE_Y_coord),h
ADDA: DD 75 60    ld   (ix+TABLE_Y_low),l
ADDD: 0E 00       ld   c,$00
ADDF: DD 66 81    ld   h,(ix+TABLE_new_Y_high)
ADE2: DD 6E A0    ld   l,(ix+TABLE_new_Y_low)
ADE5: C3 2C C9    jp   $8DC2

ADE8:		dw	$adfa	; Table 0
		dw	$adf6	; Table 1
		dw	$adf6	; Table 2
		dw	$adf2	; Table 3
		dw	$adf2	; Table 4
		
adf2:		db	$00, $c4, $cc, $00
adf6:		db	$00, $c5, $cd, $00
adfa:		db	$01, $13, $1a, $1b

ADFE: 		dw	$ff20	; minus about 88% of a pixel
		dw	$ff70	; minus 1/2 of a pixel
		dw	$ffb0	; - 1/4 of a pixel 
		dw	$0040	; + 1/4 of a pixel
		dw	$0080	; + half a pixel
	
AE08: 21 02 EA    ld   hl,$AE20
AE0B: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
AE0E: 0F          rrca
AE0F: 0F          rrca
AE10: 0F          rrca
AE11: 0F          rrca
AE12: E6 21       and  $03
AE14: EF          rst	INDEX_ED_AT_2A_PLUS_HL
AE15: EB          ex   de,hl
AE16: 7E          ld   a,(hl)
AE17: 23          inc  hl
AE18: DD 77 F0    ld   (ix+$1e),a
AE1B: 0E 04       ld   c,$40
AE1D: C3 2C C9    jp   $8DC2

AE20: 		dw	$ae2f	; Table 0
		dw	$ae2c	; Table 1
		dw	$ae2f	; Table 2
		dw	$ae2c	; Table 3

		; first byte is spirites extra, when throw a grenade it's a 2 otherwise it's a 0
AE28:		db      $02, $45, $46, $4f

AE2C: 		db	$00, $46, $4f
ae2f:		db	$00, $47, $4f

AE32: DD 7E 51    ld   a,(iy+TABLE_COUNTDOWN)
AE35: 0F          rrca
AE36: 0F          rrca
AE37: 0F          rrca
AE38: 0F          rrca
AE39: E6 E1       and  $0F
AE3B: 21 27 EA    ld   hl,$AE63
AE3E: EF          rst	INDEX_ED_AT_2A_PLUS_HL
AE3F: DD 73 01    ld   (ix+$01),e
AE42: DD 72 20    ld   (ix+$02),d
AE45: CD B3 A9    call $8B3B
AE48: DD 66 61    ld   h,(ix+TABLE_new_X_high)
AE4B: DD 6E 80    ld   l,(ix+TABLE_new_X_low)
AE4E: DD 56 81    ld   d,(ix+TABLE_new_Y_high)
AE51: DD 5E A0    ld   e,(ix+TABLE_new_Y_low)
AE54: DD 74 21    ld   (ix+TABLE_X_coord),h
AE57: DD 75 40    ld   (ix+TABLE_X_low),l
AE5A: DD 72 41    ld   (ix+TABLE_Y_coord),d
AE5D: DD 73 60    ld   (ix+TABLE_Y_low),e
AE60: C3 1B C8    jp   $8CB1
AE63: 0A          ld   a,(bc)
AE64: 04          inc  b
AE65: 1A          ld   a,(de)
AE66: 04          inc  b
AE67: 1A          ld   a,(de)
AE68: 04          inc  b
AE69: 0C          inc  c
AE6A: 04          inc  b
AE6B: DD 34 50    inc  (ix+$14)
AE6E: DD 7E 50    ld   a,(ix+$14)
AE71: FE 40       cp   $04
AE73: 28 C0       jr   z,$AE81
AE75: 21 D7 EA    ld   hl,$AE7D				; TABLE below
AE78: E7          rst	INDEX_A_PLUS_HL
AE79: DD 77 51    ld   (iy+TABLE_COUNTDOWN),a
AE7C: C9          ret

AE7D: 			DB 00,$28,$40,$40

AE81: DD 36 00 00 ld   (ix+TABLE_STATUS),$00
AE85: FD 36 20 00 ld   (iy+sprite_x),$00
AE89: FD 36 60 00 ld   (iy+sprite2_x),$00
AE8D: FD 36 A0 00 ld   (iy+sprite3_x),$00
AE91: CD 60 89    call $8906
AE94: C9          ret
AE95: 3A 20 0E    ld   a,(FRAME_SYNC)
AE98: E6 01       and  $01
AE9A: CA 23 EB    jp   z,$AF23
AE9D: CD 4F EA    call $AEE5
AEA0: C3 2B EA    jp   $AEA3		; jmp to next address! errrr Joey code!


AEA3: 3A 00 0F    ld   a,(PLAYER_DATA)
AEA6: 3C          inc  a
AEA7: C0          ret  nz
AEA8: DD 21 0C 2E ld   ix,ENEMY_BULLETS
AEAC: 3A 21 0F    ld   a,(PLAYER_X)
AEAF: 67          ld   h,a
AEB0: 3A 41 0F    ld   a,(PLAYER_Y)
AEB3: 6F          ld   l,a
AEB4: 06 80       ld   b,$08
AEB6: D9          exx
AEB7: 11 02 00    ld   de,$0020
AEBA: D9          exx
AEBB: 16 60       ld   d,$06
AEBD: 1E C1       ld   e,$0D
AEBF: DD 7E 00    ld   a,(ix+TABLE_STATUS)
AEC2: 3C          inc  a
AEC3: 20 91       jr   nz,$AEDE
AEC5: DD 7E 41    ld   a,(ix+TABLE_Y_coord)
AEC8: 95          sub  l
AEC9: BB          cp   e
AECA: 30 30       jr   nc,$AEDE
AECC: DD 7E 21    ld   a,(ix+TABLE_X_coord)
AECF: 94          sub  h
AED0: 82          add  a,d
AED1: BB          cp   e
AED2: 30 A0       jr   nc,$AEDE
AED4: 3E F3       ld   a,$3F
AED6: 32 00 0F    ld   (PLAYER_DATA),a
AED9: DD 36 00 01 ld   (ix+TABLE_STATUS),$01
AEDD: C9          ret

AEDE: D9          exx
AEDF: DD 19       add  ix,de
AEE1: D9          exx
AEE2: 10 BD       djnz $AEBF
AEE4: C9          ret

AEE5: 3A 00 0F    ld   a,(PLAYER_DATA)
AEE8: 3C          inc  a
AEE9: C0          ret  nz
AEEA: DD 21 00 6E ld   ix,ENEMY_SPRITES
AEEE: 3A 21 0F    ld   a,(PLAYER_X)
AEF1: 67          ld   h,a
AEF2: 3A 41 0F    ld   a,(PLAYER_Y)
AEF5: 6F          ld   l,a
AEF6: 06 80       ld   b,$08
AEF8: D9          exx
AEF9: 11 02 00    ld   de,$0020
AEFC: D9          exx
AEFD: 16 60       ld   d,$06
AEFF: 1E C1       ld   e,$0D
AF01: DD 7E 00    ld   a,(ix+TABLE_STATUS)
AF04: 3C          inc  a
AF05: 20 51       jr   nz,$AF1C
AF07: 7D          ld   a,l
AF08: DD 96 41    sub  (ix+TABLE_Y_coord)
AF0B: BB          cp   e
AF0C: 30 E0       jr   nc,$AF1C
AF0E: DD 7E 21    ld   a,(ix+TABLE_X_coord)
AF11: 94          sub  h
AF12: 82          add  a,d
AF13: BB          cp   e
AF14: 30 60       jr   nc,$AF1C
AF16: 3E F3       ld   a,$3F
AF18: 32 00 0F    ld   (PLAYER_DATA),a
AF1B: C9          ret
AF1C: D9          exx
AF1D: DD 19       add  ix,de
AF1F: D9          exx
AF20: 10 FD       djnz $AF01
AF22: C9          ret
AF23: 16 C0       ld   d,$0C
AF25: C3 92 00    jp   ADD_DE_TO_EVENT

AF28: DD 21 00 2E ld   ix,BULLET_SPRITES
AF2C: 0E 60       ld   c,$06
AF2E: D9          exx
AF2F: 01 02 00    ld   bc,$0020
AF32: D9          exx
AF33: 16 61       ld   d,$07
AF35: 1E E1       ld   e,$0F
AF37: DD 7E 00    ld   a,(ix+TABLE_STATUS)
AF3A: 3C          inc  a
AF3B: 20 52       jr   nz,$AF71
AF3D: DD 66 21    ld   h,(ix+TABLE_X_coord)
AF40: DD 6E 41    ld   l,(ix+TABLE_Y_coord)
AF43: FD 21 00 6E ld   iy,ENEMY_SPRITES
AF47: 06 80       ld   b,$08
AF49: FD 7E 00    ld   a,(iy+sprite_number)
AF4C: 3C          inc  a
AF4D: 20 D0       jr   nz,$AF6B
AF4F: 7D          ld   a,l
AF50: FD 96 41    sub  (iy+sprite2_flags)
AF53: C6 40       add  a,$04
AF55: FE 51       cp   $15
AF57: 30 30       jr   nc,$AF6B
AF59: FD 7E 21    ld   a,(iy+sprite_y)
AF5C: 94          sub  h
AF5D: 82          add  a,d
AF5E: BB          cp   e
AF5F: 30 A0       jr   nc,$AF6B
AF61: DD 36 00 01 ld   (ix+TABLE_STATUS),$01
AF65: FD 36 00 F3 ld   (iy+sprite_number),$3F
AF69: 18 60       jr   $AF71
AF6B: D9          exx
AF6C: FD 09       add  iy,bc
AF6E: D9          exx
AF6F: 10 9C       djnz $AF49
AF71: D9          exx
AF72: DD 09       add  ix,bc
AF74: D9          exx
AF75: 0D          dec  c
AF76: C8          ret  z
AF77: 18 FA       jr   $AF37
AF79: 3A 04 0F    ld   a,(grenade_TABLE)
AF7C: 3C          inc  a
AF7D: C0          ret  nz
AF7E: 3A 25 0F    ld   a,(grenade_X_coordinate)
AF81: 67          ld   h,a
AF82: 3A 45 0F    ld   a,(grenade_Y_coordinate)
AF85: 6F          ld   l,a
AF86: FD 21 00 6E ld   iy,ENEMY_SPRITES
AF8A: 06 80       ld   b,$08			; 8 sprites
AF8C: 11 02 00    ld   de,$0020			; table size / sprite
AF8F: FD 7E 00    ld   a,(iy+$00)		; is sprite active
AF92: 3C          inc  a
AF93: 20 71       jr   nz,$AFAC
AF95: 7D          ld   a,l
AF96: FD 96 41    sub  (iy+$04)
AF99: FE C0       cp   $0C			; withing 12 pixels in y
AF9B: 30 E1       jr   nc,$AFAC
AF9D: FD 7E 21    ld   a,(iy+$03)
AFA0: 94          sub  h
AFA1: C6 41       add  a,$05
AFA3: FE A1       cp   $0B			; and 11 pixels in x
AFA5: 30 41       jr   nc,$AFAC
AFA7: FD 36 00 F3 ld   (iy+$00),$3F		; set to kill
AFAB: C9          ret
AFAC: FD 19       add  iy,de
AFAE: 10 FD       djnz $AF8F
AFB0: C9          ret


AFB1: 
	dw	$0180,$b031	; Area Table 0
	dw	$0280,$b07c	; Area Table 1
	dw	$0438,$b0d2	; Area Table 2
	dw	$07ff,$b200	; Area Table 3
	dw	$0c38,$b11a	; Area Table 4
	dw	$0dc0,$b15e	; Area Table 5
	dw	$0fff,$b274	; Area Table 6
	dw	$1438,$b1ae	; Area Table 7
	dw	$17ff,$b2bb	; Area Table 8
	dw	$18b8,$b38d	; Area Table 9
	dw	$1938,$b3e8	; Area Table A
	dw	$19f8,$b447	; Area Table B
	dw	$1fff,$b329	; Area Table C
	dw	$4100,$b4a6	; Area Table D
	dw	$4180,$b4f8	; Area Table E
	dw	$4280,$b55d	; Area Table F
	dw	$4360,$b5b6	; Area Table 10
	dw	$4437,$b613	; Area Table 11
	dw	$47ff,$b2bb	; Area Table 12
	dw	$4aa0,$b661	; Area Table 13
	dw	$4ae0,$b661	; Area Table 14
	dw	$4b20,$b661	; Area Table 15
	dw	$4b60,$b661	; Area Table 16
	dw	$4ba0,$b6b5	; Area Table 17
	dw	$4c37,$b613	; Area Table 18
	dw	$4d80,$b6e8	; Area Table 19
	dw	$4f00,$b729	; Area Table 1A
	dw	$4fff,$b2bb	; Area Table 1B
	dw	$5437,$b613	; Area Table 1C
	dw	$57ff,$b2bb	; Area Table 1D
	dw	$58b8,$b76a	; Area Table 1E
	dw	$5fff,$b329	; Area Table 1F

b031:	dw	$b041
	dw	$b04d
	dw	$b05b
	dw	$b069
	dw	$b075
	dw	$b041
	dw	$b04d
	dw	$b05b
b041:	db	$f0, $00, $80, $20, $bf, $5f, $c0, $40, $7f, $20, $c0, $ff
b04d:	db	$f0, $10, $80, $10, $df, $40, $80, $20, $bf, $5f, $80, $20, $40, $ff
b05b:	db	$f0, $20, $80, $20, $bf, $5f, $90, $30, $f0, $20, $90, $10, $e0, $ff
b069:	db	$f0, $d1, $80, $30, $7f, $30, $7f, $30, $7f, $30, $40, $ff
b075:	db	$00, $01, $7f, $60, $7f, $60, $ff
b07c:	dw	$b08c
	dw	$b099
	dw	$b0a4
	dw	$b0b5
	dw	$b0c2
	dw	$b08c
	dw	$b099
	dw	$b0a4
b08c:	db	$f0, $01, $80, $30, $df, $30, $7f, $30, $7f, $30, $7f, $30, $ff
b099:	db	$00, $00, $00, $28, $bf, $5f, $7f, $70, $40, $20, $ff
b0a4:	db	$00, $10, $00, $20, $df, $40, $00, $08, $bf, $5f, $e0, $60, $7f, $50, $c0, $50, $ff
b0b5:	db	$f0, $11, $80, $30, $7f, $30, $7f, $30, $9f, $7f, $30, $40, $ff
b0c2:	db	$00, $20, $00, $28, $bf, $5f, $00, $30, $b0, $30, $c0, $50, $7f, $30, $40, $ff
b0d2:	dw	$b0e2
	dw	$b0ed
	dw	$b0fa
	dw	$b104
	dw	$b10d
	dw	$b0e2
	dw	$b0ed
	dw	$b0fa
b0e2:	db	$00, $1b, $00, $68, $c0, $60, $7f, $80, $c0, $ff
b0ed:	db	$00, $1b, $00, $70, $c0, $60, $80, $40, $e8, $80, $7f, $80, $ff
b0fa:	db	$f0, $1b, $80, $18, $9f, $9f, $9f, $9f, $00, $ff
b104:	db	$f0, $1b, $80, $70, $c0, $60, $7f, $80, $ff
b10d:	db	$f0, $00, $80, $60, $9f, $df, $20, $9f, $00, $20, $9f, $00, $ff
b11a:	dw	$b12a
	dw	$b134
	dw	$b13e
	dw	$b145
	dw	$b14c
	dw	$b155
	dw	$b134
	dw	$b14c
b12a:	db	$00, $00, $00, $28, $9f, $00, $20, $9f, $80, $ff
b134:	db	$f0, $00, $80, $28, $9f, $80, $20, $9f, $00, $ff
b13e:	db	$00, $10, $00, $38, $9f, $80, $ff
b145:	db	$f0, $10, $80, $38, $9f, $00, $ff
b14c:	db	$f0, $1b, $80, $68, $c0, $60, $7f, $80, $ff
b155:	db	$00, $1b, $00, $68, $c0, $60, $7f, $80, $ff
b15e:	dw	$b16e
	dw	$b179
	dw	$b182
	dw	$b18d
	dw	$b198
	dw	$b1a3
	dw	$b179
	dw	$b198
b16e:	db	$f0, $01, $80, $28, $9f, $80, $40, $df, $80, $c0, $ff
b179:	db	$f0, $01, $80, $70, $c0, $20, $7f, $80, $ff
b182:	db	$f0, $11, $80, $38, $9f, $9f, $9f, $9f, $9f, $00, $ff
b18d:	db	$f0, $01, $80, $80, $7f, $80, $7f, $80, $40, $30, $ff
b198:	db	$f0, $11, $70, $28, $9f, $9f, $9f, $9f, $9f, $00, $ff
b1a3:	db	$f0, $11, $68, $28, $9f, $9f, $9f, $9f, $9f, $00, $ff
b1ae:	dw	$b1be
	dw	$b1c9
	dw	$b1d4
	dw	$b1e1
	dw	$b1ec
	dw	$b1f7
	dw	$b1c9
	dw	$b1ec
b1be:	db	$00, $1b, $00, $68, $c0, $60, $7f, $80, $c0, $ff
b1c9:	db	$00, $1b, $00, $70, $c0, $60, $80, $40, $7f, $80, $ff
b1d4:	db	$f0, $1b, $80, $70, $c0, $60, $00, $40, $9f, $9f, $7f, $80, $ff
b1e1:	db	$f0, $00, $80, $30, $9f, $9f, $9f, $9f, $9f, $00, $ff
b1ec:	db	$00, $00, $00, $30, $9f, $9f, $9f, $9f, $9f, $80, $ff
b1f7:	db	$f0, $1b, $80, $68, $c0, $60, $7f, $80, $ff
b200:	dw	$b210
	dw	$b221
	dw	$b232
	dw	$b240
	dw	$b247
	dw	$b255
	dw	$b263
	dw	$b26d
b210:	db	$60, $e1, $1f, $df, $10, $c0, $20, $a0, $50, $9f, $df, $30, $f0, $80, $7f, $80, $ff
b221:	db	$90, $e1, $1f, $df, $10, $c0, $20, $e0, $50, $9f, $df, $30, $40, $18, $7f, $80, $ff
b232:	db	$78, $e1, $1f, $df, $10, $c0, $20, $a0, $28, $e0, $28, $7f, $80, $ff
b240:	db	$f0, $c1, $80, $30, $7f, $80, $ff
b247:	db	$60, $e1, $1f, $df, $10, $c0, $20, $a0, $50, $e0, $50, $7f, $80, $ff
b255:	db	$90, $e1, $1f, $df, $10, $c0, $20, $e0, $50, $a0, $50, $7f, $80, $ff
b263:	db	$78, $e1, $1f, $df, $10, $c0, $20, $7f, $f0, $ff
b26d:	db	$00, $c1, $00, $30, $7f, $80, $ff
b274:	dw	$b284
	dw	$b28e
	dw	$b296
	dw	$b2a0
	dw	$b2aa
	dw	$b2b4
	dw	$b284
	dw	$b28e
b284:	db	$20, $60, $00, $40, $9f, $00, $60, $9f, $00, $ff
b28e:	db	$20, $a0, $00, $60, $c0, $38, $80, $ff
b296:	db	$20, $a0, $00, $30, $d0, $84, $80, $40, $00, $ff
b2a0:	db	$e0, $a0, $80, $40, $9f, $80, $60, $9f, $80, $ff
b2aa:	db	$e0, $60, $80, $40, $40, $50, $a8, $60, $80, $ff
b2b4:	db	$20, $60, $80, $40, $9f, $a0, $ff
b2bb:	dw	$b2cb
	dw	$b2dc
	dw	$b2ed
	dw	$b2f7
	dw	$b301
	dw	$b30b
	dw	$b315
	dw	$b31f
b2cb:	db	$60, $e1, $1f, $df, $10, $c0, $20, $80, $30, $9f, $9f, $9f, $e0, $40, $7f, $80, $ff
b2dc:	db	$90, $e1, $1f, $df, $10, $c0, $20, $00, $30, $9f, $9f, $9f, $a0, $40, $7f, $80, $ff
b2ed:	db	$78, $e1, $1f, $df, $10, $c0, $20, $7f, $80, $ff
b2f7:	db	$f0, $c1, $80, $30, $9f, $9f, $9f, $7f, $80, $ff
b301:	db	$00, $c1, $00, $30, $9f, $9f, $9f, $7f, $80, $ff
b30b:	db	$60, $e1, $1f, $df, $10, $c0, $20, $7f, $80, $ff
b315:	db	$78, $e1, $1f, $df, $10, $c0, $20, $7f, $80, $ff
b31f:	db	$90, $e1, $1f, $df, $10, $c0, $20, $7f, $80, $ff
b329:	dw	$b339
	dw	$b34a
	dw	$b35b
	dw	$b367
	dw	$b373
	dw	$b367
	dw	$b373
	dw	$b383
b339:	db	$70, $a1, $1f, $df, $10, $c0, $20, $80, $30, $9f, $9f, $9f, $c0, $40, $7f, $80, $ff
b34a:	db	$80, $a1, $1f, $df, $10, $c0, $20, $00, $30, $9f, $9f, $9f, $c0, $40, $7f, $80, $ff
b35b:	db	$78, $a1, $1f, $df, $10, $c0, $20, $a0, $50, $7f, $80, $ff
b367:	db	$78, $a1, $1f, $df, $10, $c0, $20, $e0, $50, $7f, $80, $ff
b373:	db	$78, $a1, $1f, $df, $10, $c0, $20, $90, $60, $f0, $80, $40, $40, $7f, $80, $ff
b383:	db	$78, $a1, $1f, $df, $10, $c0, $60, $7f, $80, $ff
b38d:	dw	$b39d
	dw	$b3ab
	dw	$b3b9
	dw	$b3c4
	dw	$b3ce
	dw	$b3da
	dw	$b3ab
	dw	$b3b9
b39d:	db	$f0, $01, $80, $20, $9f, $80, $20, $c0, $40, $7f, $60, $c0, $ff
b3ab:	db	$f0, $01, $80, $50, $c0, $40, $9f, $a0, $40, $7f, $60, $80, $ff
b3b9:	db	$00, $01, $00, $80, $c0, $40, $9f, $7f, $60, $c0, $ff
b3c4:	db	$00, $01, $00, $80, $9f, $c0, $40, $7f, $90, $ff
b3ce:	db	$00, $41, $00, $28, $9f, $00, $40, $00, $28, $9f, $00, $40, $f0, $21, $80, $40, $9f, $50, $40, $df, $28, $7f, $80, $00, $40, $ff
b3da:	db	$f0, $21, $80, $40, $9f, $50, $40, $df, $28, $7f, $80, $00, $40, $ff
b3e8:	dw	$b3f8
	dw	$b404
	dw	$b417
	dw	$b424
	dw	$b42d
	dw	$b439
	dw	$b404
	dw	$b417
b3f8:	db	$f0, $01, $80, $60, $9f, $c0, $40, $7f, $60, $c0, $ff
b404:	db	$f0, $01, $80, $30, $df, $30, $80, $40, $9f, $c0, $40, $9f, $a0, $40, $7f, $60, $80, $ff
b417:	db	$00, $01, $00, $30, $9f, $00, $30, $c0, $40, $7f, $60, $c0, $ff
b424:	db	$00, $01, $00, $28, $9f, $df, $80, $80, $60, $00, $41, $00, $28, $9f, $00, $40, $00, $28, $9f, $00, $40, $f0, $21, $80, $40, $9f, $50, $40, $df, $28, $7f, $80, $00, $40, $ff
b42d:	db	$00, $41, $00, $28, $9f, $00, $40, $00, $28, $9f, $00, $40, $f0, $21, $80, $40, $9f, $50, $40, $df, $28, $7f, $80, $00, $40, $ff
b439:	db	$f0, $21, $80, $40, $9f, $50, $40, $df, $28, $7f, $80, $00, $40, $ff
b447:	dw	$b457
	dw	$b465
	dw	$b476
	dw	$b480
	dw	$b48c
	dw	$b498
	dw	$b465
	dw	$b476
b457:	db	$f0, $01, $80, $40, $9f, $80, $50, $c0, $40, $7f, $60, $c0, $ff
b465:	db	$f0, $01, $80, $70, $9f, $80, $30, $c0, $40, $9f, $a0, $40, $7f, $60, $80, $ff
b476:	db	$00, $01, $00, $40, $c0, $40, $7f, $60, $c0, $ff
b480:	db	$00, $01, $00, $32, $9f, $c0, $40, $40, $40, $9f, $00, $80, $00, $41, $00, $28, $9f, $00, $40, $00, $28, $9f, $00, $40, $f0, $21, $80, $28, $9f, $50, $40, $df, $28, $7f, $80, $00, $40, $ff
b48c:	db	$00, $41, $00, $28, $9f, $00, $40, $00, $28, $9f, $00, $40, $f0, $21, $80, $28, $9f, $50, $40, $df, $28, $7f, $80, $00, $40, $ff
b498:	db	$f0, $21, $80, $28, $9f, $50, $40, $df, $28, $7f, $80, $00, $40, $ff
b4a6:	dw	$b4b6
	dw	$b4c5
	dw	$b4d2
	dw	$b4e0
	dw	$b4ec
	dw	$b4b6
	dw	$b4c5
	dw	$b4d2
b4b6:	db	$f0, $00, $80, $10, $9f, $80, $10, $bf, $5f, $c0, $40, $7f, $20, $c0, $ff
b4c5:	db	$f0, $10, $80, $20, $bf, $5f, $80, $20, $9f, $df, $20, $40, $ff
b4d2:	db	$f0, $20, $80, $20, $bf, $5f, $90, $30, $f0, $20, $90, $10, $e0, $ff
b4e0:	db	$f0, $d1, $80, $30, $7f, $30, $7f, $30, $7f, $30, $40, $ff
b4ec:	db	$f0, $41, $80, $30, $b0, $30, $c0, $50, $7f, $30, $40, $ff
b4f8:	dw	$b508
	dw	$b51a
	dw	$b52b
	dw	$b53e
	dw	$b54a
	dw	$b508
	dw	$b51a
	dw	$b52b
b508:	db	$f0, $40, $80, $10, $9f, $df, $30, $80, $10, $bf, $5f, $7f, $30, $7f, $30, $7f, $30, $ff
b51a:	db	$00, $00, $00, $60, $bf, $5f, $7f, $30, $9f, $df, $20, $c0, $30, $60, $40, $20, $ff
b52b:	db	$00, $10, $00, $30, $9f, $df, $20, $00, $30, $bf, $5f, $40, $20, $7f, $50, $c0, $50, $d0, $ff
b53e:	db	$f0, $11, $80, $30, $7f, $30, $7f, $30, $7f, $30, $40, $ff
b54a:	db	$00, $20, $00, $60, $bf, $5f, $00, $30, $b0, $30, $9f, $df, $20, $c0, $50, $7f, $30, $40, $ff
b55d:	dw	$b56d
	dw	$b57e
	dw	$b58b
	dw	$b598
	dw	$b5a4
	dw	$b56d
	dw	$b57e
	dw	$b58b
b56d:	db	$f0, $20, $80, $10, $9f, $df, $20, $80, $10, $bf, $5f, $d0, $60, $7f, $80, $c0, $ff
b57e:	db	$f0, $10, $80, $20, $df, $90, $bf, $5f, $80, $70, $9f, $40, $ff
b58b:	db	$f0, $00, $80, $20, $bf, $5f, $e0, $20, $c0, $40, $7f, $40, $ff
b598:	db	$f0, $d1, $80, $30, $7f, $30, $7f, $30, $7f, $30, $40, $ff
b5a4:	db	$f0, $41, $80, $10, $9f, $df, $20, $9f, $df, $20, $9f, $df, $20, $9f, $df, $20, $00, $ff
b5b6:	dw	$b5c6
	dw	$b5d4
	dw	$b5e2
	dw	$b5f7
	dw	$b602
	dw	$b5c6
	dw	$b5d4
	dw	$b5e2
b5c6:	db	$00, $00, $00, $10, $df, $60, $00, $18, $bf, $5f, $7f, $20, $c0, $ff
b5d4:	db	$f0, $20, $80, $20, $9f, $80, $40, $bf, $5f, $80, $10, $7f, $80, $ff
b5e2:	db	$f0, $30, $80, $30, $9f, $80, $30, $bf, $5f, $78, $40, $9f, $df, $10, $9f, $df, $30, $9f, $df, $70, $ff
b5f7:	db	$f0, $40, $80, $30, $df, $60, $80, $20, $9f, $00, $ff
b602:	db	$00, $21, $00, $20, $df, $20, $9f, $df, $20, $9f, $df, $20, $9f, $df, $20, $80, $ff
b613:	dw	$b623
	dw	$b62e
	dw	$b63e
	dw	$b649
	dw	$b654
	dw	$b623
	dw	$b62e
	dw	$b63e
b623:	db	$00, $1b, $00, $68, $c0, $60, $7f, $80, $c0, $ff
b62e:	db	$00, $1b, $00, $30, $9f, $00, $40, $c0, $60, $80, $40, $e8, $80, $7f, $80, $ff
b63e:	db	$f0, $1b, $80, $68, $c0, $60, $e8, $40, $7f, $80, $ff
b649:	db	$f0, $1b, $80, $30, $80, $40, $c0, $60, $7f, $80, $ff
b654:	db	$f0, $00, $80, $60, $9f, $df, $20, $9f, $00, $20, $9f, $00, $ff
b661:	dw	$b671
	dw	$b6b1
	dw	$b6a7
	dw	$b68f
	dw	$b693
	dw	$b69e
	dw	$b685
	dw	$b67c
b671:	db	$00, $00, $00, $40, $7f, $40, $c0, $80, $40, $80, $ff
b67c:	db	$00, $00, $00, $40, $9f, $df, $20, $00, $ff
b685:	db	$f0, $00, $80, $68, $7f, $20, $9f, $7f, $80, $ff
b68f:	db	$f0, $00, $80, $ff
b693:	db	$00, $40, $00, $40, $7f, $40, $c0, $80, $40, $80, $ff
b69e:	db	$00, $40, $00, $40, $9f, $df, $20, $00, $ff
b6a7:	db	$f0, $40, $80, $68, $7f, $20, $9f, $7f, $80, $ff
b6b1:	db	$f0, $40, $80, $ff
b6b5:	dw	$b6c5
	dw	$b6d1
	dw	$b6da
	dw	$b6e4
	dw	$b6d1
	dw	$b6da
	dw	$b6c5
	dw	$b6e4
b6c5:	db	$00, $00, $00, $40, $5f, $7f, $40, $c0, $80, $40, $80, $ff
b6d1:	db	$00, $00, $00, $40, $9f, $df, $20, $00, $ff
b6da:	db	$f0, $00, $80, $68, $7f, $20, $9f, $7f, $80, $ff
b6e4:	db	$f0, $00, $80, $ff
b6e8:	dw	$b6f8
	dw	$b701
	dw	$b70c
	dw	$b716
	dw	$b720
	dw	$b70c
	dw	$b6f8
	dw	$b716
b6f8:	db	$f0, $01, $80, $40, $7f, $40, $c0, $80, $ff
b701:	db	$f0, $01, $80, $30, $9f, $c0, $60, $9f, $7f, $80, $ff
b70c:	db	$f0, $01, $80, $20, $c0, $40, $9f, $7f, $80, $ff
b716:	db	$f0, $01, $80, $50, $c0, $40, $7f, $80, $c0, $40, $00, $01, $00, $80, $c0, $70, $98, $80, $ff
b720:	db	$00, $01, $00, $80, $c0, $70, $98, $80, $ff
b729:	dw	$b739
	dw	$b742
	dw	$b74d
	dw	$b757
	dw	$b761
	dw	$b74d
	dw	$b739
	dw	$b757
b739:	db	$00, $01, $00, $08, $7f, $40, $c0, $80, $ff
b742:	db	$00, $01, $00, $18, $9f, $c0, $60, $9f, $7f, $80, $ff
b74d:	db	$00, $01, $00, $28, $c0, $40, $9f, $7f, $80, $ff
b757:	db	$00, $01, $00, $38, $c0, $40, $7f, $80, $c0, $40, $00, $01, $00, $28, $c0, $70, $98, $80, $ff
b761:	db	$00, $01, $00, $28, $c0, $70, $98, $80, $ff
b76a:	dw	$b77a
	dw	$b780
	dw	$b786
	dw	$b78f
	dw	$b798
	dw	$b7a5
	dw	$b7b8
	dw	$b780
b77a:	db	$00, $01, $00, $3f, $9f, $ff
b780:	db	$f0, $01, $80, $3f, $9f, $ff
b786:	db	$00, $41, $00, $40, $df, $30, $00, $ff
b78f:	db	$f0, $41, $80, $40, $df, $30, $80, $ff
b798:	db	$f0, $01, $80, $60, $c0, $38, $f0, $40, $7f, $80, $c0, $ff
b7a5:	db	$f0, $41, $80, $40, $c0, $38, $80, $30, $c0, $40, $80, $50, $c0, $30, $7f, $80, $c0, $ff
b7b8:	db	$00, $41, $00, $40, $c0, $38, $00, $30, $c0, $30, $9f, $40, $30, $9f, $80, $ff
b7c8:	dw	$b7d6
	dw	$b7d6
	dw	$b7d6
	dw	$b7d6
	dw	$b7d6
	dw	$b7d6
	dw	$b7d6
b7d6:	db	$05, $50, $f0, $37, $b8, $01, $68, $f0, $3e, $b8, $01, $80, $f0, $45, $b8, $01, $98, $f0, $3e, $b8, $01, $b0, $f0, $37, $b8, $01, $05, $10, $c0, $0a, $b8, $01, $10, $c0, $13, $b8, $01, $10, $c0, $1c, $b8, $01, $10, $c0, $25, $b8, $01, $10, $c0, $2e, $b8, $01, $df, $01, $00, $c0, $df, $30, $7f, $10, $ff

b813:	db	$df, $21, $00, $a0, $df, $30, $7f, $10, $ff, $df, $41, $00, $80, $df, $30, $7f
b823:	db	$10, $ff, $df, $61, $00, $60, $df, $30, $7f, $10, $ff, $df, $81, $00, $40, $df
b833:	db	$30, $7f, $10, $ff, $c0, $80, $df, $30, $7f, $10, $ff, $c0, $60, $df, $20, $7f
b843:	db	$10, $ff, $c0, $40, $df, $10, $7f, $10, $ff, $df, $61, $00, $60, $df, $30, $7f
b853:	db	$10, $ff, $df, $81, $00, $40, $df, $30, $7f, $10, $ff, $c0, $80, $df, $30, $7f
b863:	db	$10, $ff, $c0, $60, $df, $20, $7f, $10, $ff, $c0, $40, $df, $10, $7f, $10, $ff

