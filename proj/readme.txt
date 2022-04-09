ENSE 352 Final Project
Greg Sveinbjornson
200427591
Dec 1, 2021

1. What is the game?

This a the final project for ENSE 352 using assembly code to make a whack-a-mole game.
There are 4 LEDs with 4 corresponding buttons. The player has to wait until a random LED lights up,
then press the correct button before the time runs out. If the player presses the button before
time runs out then they get a point added to their score, so with 15 rounds the possible scores are
0-15. For each point, the timer is reduced, making the game get progressivly harder.

2. How to play?
	
The LEDs will flash in sequence when waiting for the user to start. The game starts when the user 
presses any of the 4 buttons. The user then presses the corresponding button as the LEDs light up.
The game gets faster as the player gets more points, if any buttons are missed the timer stays the same 
and no points are added. After 15 rounds the game is over and the players score is displayed on the 
LEDs in binary (1 point = 0001, 15 points = 1111).

3. The biggest problem for me was the time constraint. I have 3 large projects all due at the end of the 
semester so that made prioritising my time very difficult. There was also a lot that I didn't understand
when I started this project so I had to take extra time to teach myself the required knowledge. I failed to
implement WinningSignalTime and LosingSignalTime as I just have to focus on my other projects or they wont
get done. Possible future expansions could include better score display using the 7 segment display

4. a) PrelimWait - Change the value of PRELIM_WAIT 
   b) ReactTime - Change the value of REACT_TIME
   c) NumCycles - Change the value loaded into register R1 on line 233
   d) WinningSignalTime and LosingSignalTime are not in my game  The delay after a game ends can be adjusted
      by changing SCORE_DISPLAY