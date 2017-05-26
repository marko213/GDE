# INSTRUCTIONS

<b>These instructions apply to the GDE. The instructions for the GDE level editor can be found in the respective folder</b>

<br>
<p>Pressing the SPACE or 'P' key will pause / unpause the simulation (does not affect ASAP mode).</p>

<p>Pressing the 'R' key will restart the current run.</p>

<p>Pressing the 'L' key will open a prompt for the user to select a level file, load that level and restart the level. This is also done when launching the application (the level.gdat file in the data folder will be loaded).</p>

<p>Pressing the 'N' key will cycle trough the network draw modes: draw all, draw normal nodes & output and only draw output.</p>

<p>Pressing the '+' and '-' keys will allow you to change the speed of the simulation from half (0.5x) speed up to 512x speed.

<b>Note: a maximum of 60 creatures per second (1 creature per frame) can be drawn, the lower limit depends on the system.</b>

<b>Note 2: when simulating at 0.5x speed, a maximum of <u><i>30</i></u> creatures can be drawn and up to <u><i>30</i></u> generations can be processed per second.</b></p>

<p>Pressing the 'O' key will trigger a debug output to be printed to the java standard output (can usually be seen from a command prompt window / terminal / etc. if executed from it).</p>

<p>Pressing the 'E' key will toggle the lazy evaluation mode on / off. Lazy evaluation skips about half of the creatures from generation 2 onwards. This option should only be disabled if you wish to also see the middle creatures (from 2 to n / 2 - 1, from the second generation on) simulated.

<b>Note: this has a big impact on ASAP mode. Keep this option enabled if not needed otherwise.</b></p>

<p>Pressing the 'A' key or the button "Do generations ASAP" will enable ASAP mode, which processes generations faster, but gives little visual output. The speed limit for this mode is 60 generations / second (1 generation / frame), but this speed relies on the system hardware. This is practically the same as the "Do the rest of this generation ASAP" button ('G') (see below).

<b>Note: when using this mode, it is best to enable lazy evaluation mode and to set the speed to 1x - 4x. The simulation speed DOES NOT affect the ASAP mode much (if at all), but gives a better visual on each frame.</b></p>

<p>Pressing the 'G' key or the button "Do the rest of this generation ASAP" will complete the current generation ASAP. It will not show any following creatures in that generation and will insted process them in the background. The screen may freeze in the process, but this is normal.

<b>Note: when using this mode, it is best to enable lazy evaluation.</b></p>

<br></br>
<p>Here are some definitions for the things stated above:</p>

<p><b><i>Network draw modes</i></b> control how much of the network is drawn onto the screen. There are three settings: <i>draw all</i>, which draws the entire network, <i>draw normal nodes</i>, which draws everything apart from the screen nodes and <i>output only</i>, which only draws the output node.</p>

<p><b><i>Simulation speed</i></b> is the speed at which creatures are evaluated. This is done by doing more iterations per frame and reducing the "dead" time. This speed ranges from 0.5x (1 iteration per frame (30 fps); normal dead time) to 512x (up to 512 iterations per frame (60 fps); 512 times shorter "dead" time (almost instant)).</p>
