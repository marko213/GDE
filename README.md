# GDE

Idea inspired by carykh's [evolutionMATH2](https://www.youtube.com/watch?v=5N7NYc7PPf8)

GDE (or "Project GDE", "Project: GDE" etc. (GDE is not an abbreviation in this project, just a name)) tries to simulate computer evolution in a simple platformer-like game. It uses "evolving" simple neural networks to do so.

A level editor for GDE can be found [here](https://github.com/marko213/GDE-level-editor).

<br><h3>The game</h3></br>

<p>GDE tries to simulate computer evolution in a simple platformer-like (2D) game. The game consists of a square (the player), which is moving to the right at a constant speed. The player only has one way of control over the cube: jumping. The cube can jump when it is on the ground or on a box. Every jump is always of the same height - attempting to jump (or hold the jump button etc.) while in the air has no effect on the trajectory of the player.</p>

<p>Obstructing the player's path there are two types of obstacles: boxes and triangles. Boxes act like platforms - the cube can slide freely on them and jump off them. However, colliding with the boxes from the side or from below will "kill" the cube. Triangles act like (very) deadly spikes. Coming into contact with them from any angle, at any velocity will "kill" the cube.
(<i>Passing below a (non-flipped) triangle or sliding from a box to the tip of a triangle will also kill the player. This may be changed.</i>)</p>
<br></br>


## GDE mechanics

<br><h3>Main goal</h3></br>

<p>GDE tries to learn to play this game. It uses a simple evolution structure: there are generations, which consist of creatures, which consist of nodes and connectors.</p>
<p>Each generation has a certain amount of creatures (currently 300). Each creature is simulated independently from the others in the same level. Based on how far (to the right) the  boxes make it, a fitness score is assigned to each creature (equal to the X position of the player when it died).</p>
<p>When all creatures in a generation have been simulated, they are sorted by fitness - from best to worst - and then "killed" randomly: the better fitness a creature has, the better is the chance that it survives and vice versa (this relies on a cube function that is taken from carykh's evolutionMATH2 (link at the top)). Creatures with equal fitness are ordered randomly to increase the variety of different creatures.</p>
<p>At the end of each generation, half of the creatures are "killed" to make room for new ones. The remaining half of the creatures is then cloned - one clone of each surviving creature - and the clones are randomly mutated. By repeating this process, the creatures (networks) often "evolve", making better progress in the level.</p>

<br><h3>Creature components</h3></br>

<p>The creatures in GDE are composed of nodes (small squares) and connectors (lines). Both have different varieties and can be mutated in diffirent ways.</p>

<b><h4>Nodes</h4></b>

<b><h5>Normal nodes</h5></b>

<p>Normal nodes are found in the main network area (with alternating light grey and dark grey columns). Each normal node has two inputs: top and bottom. The nodes act as boolean AND gates: if both of their inputs are on, the output will be on, otherwise the output wil be off (the node accordingly turns either green or red). The inputs of nodes act as boolean OR gates: if any of the connectors connected to that input are on, that input will be on.</p>
<p>An exception is the output node (the rightmost in the network graph), which needs at least one of its inputs to be on, acting as a boolean OR gate.</p>

<b><h5>Screen nodes</h5></b>

<p>Screen nodes are found in the game view. These have three types: box detectors (blue), triangle detectors (yellow) and multi detectors (green). Screen nodes are the "eyes" of the network: they can tell the network what is currently happening in the game. When a screen node is over an obstacle of the matching type, its output will turn on. Screen nodes can't have inputs.</p>
<p>Note that box and multi detectors will also activate if they are below ground level.</p>

<b><h4>Connectors</h4></b>

<p>The connectors connect the inputs and outputs of nodes. A normal connector (green line) will turn one of the inputs of its output node on, when its input node's output comes on.</p>
<p>A connection can also be inverted (red line): in that case, the connector will turn one of the inputs of its output node on if its input node's output is off.</p>
<p>As noted in the nodes section above, a connector can't turn off an input - each input acts as an OR gate.</p>
<br></br>

## Additional notes

<p>The creatures do not have any kind of memory - if any creature comes across identical sections of the level, it has to do the same for both of the sections. This can make some complicated levels impossible to beat by the GDE.</p>

<p>As this is a very early testing version of GDE, many bugs may occur. If GDE does not work properly or you come across any bugs (not mentioned in the issue tracker), please add that bug to the tracker.</p>

<p>Suggestions for a better distribution of mutations (see source) are welcome. (Any kind of suggestions are welcome, but the mutation system seems to be the most broken.)</p>

<br><b><i>Created with Processing 2.2.1 from www.processing.org</i></b></br>
