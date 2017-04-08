# GDE level editor

<b>Note: this program should only read / write the files in its directory. But as this is an early version, if you want to be safe(r), don't place important files in the same directory as the program</b>

<br></br>

The GDE level editor is intended for level creation to GDE. To get the modified level to appear in GDE, follow these steps:

1 Create and save your level (see INSTRUCTIONS.md).

2 Locate the main folder for the application (should be the folder in which the application is in) and find the data file in data/level.gdat.

3 Replace the file "level.gdat" in GDE's data folder (where the application is, in the "data" folder). Any other files in the data folders should be ignored by either application.

<br></br>

Both GDE and the GDE level editor come with two similar levels: level.gdat and level_old.gdat. You can use them as a template or start from scratch (see INSTRUCTIONS.md).

<br></br>

# Level corruption / recovery

The level files (level.gdat) can be read and modified as normal text files. If your level corrupts, here are some options to what you can do about it:

a) Redownload / -extract the (path to the main folder)/data/level.gdat file (or all the files)

b) Delete the (path to the main folder)/data/level.gdat file (you need to save the level to get a new file)

c) Modify the (path to the main folder)/data/level.gdat file with a text editor. The first line should read "x,y,triangle,flipped" (without the quotes) and all the other lines should be two integers seperated by commas, a comma and two other integers either with a value of one or zero, also seperated by commas from each other and the previous integers. This method is suggested only if a big level got corrupted.

<br></br>

Created with Processing 2.2.1 from www.processing.org
