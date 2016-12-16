Instructions for how to run the code:
1) Quit interpreter, boot interpreter
2) Boot the server
3) Make sure all of the files are in the same folder, and change the line:
("~/Desktop/CPSC-431-Final-Project/"++~fileName));
so that "~/Desktop/CPSC-431-Final-Project/" is replaced by the path to that folder on your computer. This is necessary to ensure that the .xml files can be read at that path.
4) Run the code, and the GUI should pop up
5) Make sure to choose the file you want to play and the version of it you want to hear. Otherwise, Nothing will play. Please note that when you select a file, it will take a few seconds for supercollider to analyze the data.
6) Press play to hear the music.
7) All the other options are optional. The presets give a few settings that are aesthetically pleasing, and you can also manually set options on the synths. 
8) For the "Manual Drum Rule" in particular, you can put in a binary string of ones and zeros to get a drum rule that most closely matches the one you input. The four spaces are for snare, bass, tom, and hat, and the strings must be the same length for the option to have any effect, though not identical. (i.e "110111" and "110010"). If these are set, then when play is pressed, you also need to allow a few seconds for the code to run. 
IMPORTANT: NOTE that putting in an array in normal array format will not work (i.e. [1,0,1,0,0]. It will only take a string of the form 1010101010)

If anything doesn't work after a run, repeat steps 1 and 2 before doing anything to make sure everything is completely reset.

Additionally we have the code for the harmony to take a seed, so with more time, we would add the UI component for that. For now though, we use a random one. (Line 1421 in the code)

Finally, please let us know if you run into any issues while trying to run this. If need be, we can also send you a demo from one of our computers. Thanks!
