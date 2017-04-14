import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class GDE extends PApplet {

 // This project / code inspired by carykh's evolutionMATH2
// https://www.youtube.com/watch?v=5N7NYc7PPf8

int obstacleSize = 50;     // Size of obstacle collision / drawing box (should be 50 for compat reasons)
int playerSize = 50;       // Size of player collision / drawing box
int boundingWidth = 4;     // Width of the border around obstacles
int fadePrecision = 3;     // Precision to draw obstacle color fade with (1 is the smoothest)

float gravity = 0.7f;      // Simulation gravity (pixels per second per 1/60 of a second)
float termVel = 30f;       // Terminal velocity for the player (Y axis)
float jumpVel = 14.9f;     // Jump velocity for player
int delayTime = 60;        // Amount of frames to wait for on death / win

int restartTime = 0;       // Time for when to start new run
boolean won = false;       // Has the player won (on the current run)?
int sizeX = 800;           // Size of the play area (X axis)
int sizeY = 750;           // Size of the window (Y axis)
int sidebarWidth = 500;    // Width of the sidebar

int playerX;               // Current position of the player (X axis)
int playerY;               // Current position of the player (Y axis)
int playerVelX;            // Velocity of player (X axis) (pixels/ (1/60-th of a second))
float playerVelY;          // Velocity of player (Y axis) (pixels/ (1/60-th of a second))
boolean paused = false;    // Is the game currently paused? 
int endX;                  // X position that needs to be reached to win

int camX = 0;              // Position of the camera (X axis)
int camY = 0;              // Position of the camera (Y axis)

int genId = 1;             // Id of the generation (1 - ...)

int floorLevel;            // Y coordinate for the floor to be drawn from

boolean lazyEval = true;   // Should the simulation skip already-evaluated creatures? 
boolean gASAP = false;     // Should the generations be done ASAP?
boolean hasWon = false;    // Has this evolution won the level?

Obstacle[] obstacles;
PGraphics boxGraphics, triangleGraphics, flippedTriangleGraphics, networkBgGraphics, singleGraphics, fullGraphics;

ArrayList<Generation> generations = new ArrayList<Generation> ();
ArrayList<Record> records = new ArrayList<Record> ();

int creatureId = 0;
int networkDrawMode = 1; // 0 - normal, draw normal nodes & connectors; 1 - extended, also draw screen nodes; 2 - hidden, only draw output
int nodeSize = sidebarWidth / 11 - 20;
int processSpeed = 1; // How many iterations to do for each frame

public void keyPressed () {
  char k = Character.toLowerCase (key);
  switch (k){
    case 'r':
      initRun ();
      break;
    
    case ' ':
      paused = !paused;
      break;
      
    case 'p':
      paused = !paused;
      break;
      
    case 'l':
      loadLevel ();
      break;
      
    case 'n':
      networkDrawMode = (networkDrawMode + 1) % 3;
      break;
      
    case '+':
      processSpeed = min (processSpeed * 2, 512);
      break;
      
    case '-':
      processSpeed = max (processSpeed / 2, 1);
      break;
      
    case 'o':
      generations.get (generations.size () - 1).creatures[creatureId].printDebugOutput (); // Output printed to java standard output, can be seen via command prompt / terminal etc.
      break;
      
    case 'e':
      lazyEval = !lazyEval;
      break;
      
    case 'a':
      gASAP = !gASAP;
      break;
    
    case 'g':
      doGenASAP ();
      break;
  }
}

public void setup (){
  frameRate (60);
  randomSeed (213);
  
  boxGraphics = createGraphics (obstacleSize, obstacleSize);
  triangleGraphics = createGraphics (obstacleSize, obstacleSize);
  flippedTriangleGraphics = createGraphics (obstacleSize, obstacleSize);
  networkBgGraphics = createGraphics (sidebarWidth, 349);
  
  singleGraphics = createGraphics (sidebarWidth / 2, 300);
  drawSingle (new ArrayList<Creature> ());
  
  boxGraphics.beginDraw ();
  boxGraphics.noStroke ();
  for (int i = 0; i < obstacleSize / 2; i+=fadePrecision) {
    int c = (int) (((float) (i + 1)) / (((float) obstacleSize) / 2f) * 255f);
    boxGraphics.fill (c, c, c);
    boxGraphics.rect (i, i, obstacleSize - i * 2, obstacleSize - i * 2);
  }
  boxGraphics.endDraw ();
  
  triangleGraphics.beginDraw ();
  triangleGraphics.noStroke ();
  for (int i = 0; i < obstacleSize / 2; i+=fadePrecision) {
    int c = (int) (((float) (i + 1)) / (((float) obstacleSize) / 2f) * 255f);
    triangleGraphics.fill (c, c, c);
    triangleGraphics.triangle (i, obstacleSize - i, obstacleSize / 2, i, obstacleSize - i, obstacleSize - i);
  }
  triangleGraphics.endDraw ();
  
  flippedTriangleGraphics.beginDraw ();
  flippedTriangleGraphics.noStroke ();
  for (int i = 0; i < obstacleSize / 2; i+=fadePrecision) {
    int c = (int) (((float) (i + 1)) / (((float) obstacleSize) / 2f) * 255f);
    flippedTriangleGraphics.fill (c, c, c);
    flippedTriangleGraphics.triangle (i, i, obstacleSize / 2, obstacleSize - i, obstacleSize - i, i);
  }
  flippedTriangleGraphics.endDraw ();
  
  networkBgGraphics.beginDraw ();
  networkBgGraphics.noStroke ();
  for (int x = 0; x < 11; x++) {
    if (x % 2 == 0) {
      networkBgGraphics.fill (130);
    } else {
      networkBgGraphics.fill (160);
    }
    
    networkBgGraphics.rect (x * sidebarWidth / 11, 100, sidebarWidth / 11 + 1, 350);
  }
  networkBgGraphics.endDraw ();
  
  size (sizeX + sidebarWidth, sizeY);
  floorLevel = 550;
  loadLevel ();
  generations.add (new Generation ());
  
  initRun ();
}

public void initRun () {
  playerX = 40;
  playerY = 0;
  playerVelY = 0f;
  playerVelX = 5;
  gravity = abs (gravity);
  restartTime = 0;
  won = false;
  camX = max (playerX - sizeX / 2, 0);
  camY = max (playerY - (height - floorLevel), 0);
}

public void endGeneration () {
  generations.add (new Generation (generations.get (generations.size () - 1).creatures));
  generations.get (generations.size () - 1).sortCreaturesAndCreateNew ();
  if (generations.size () > 2) {
    generations.remove (0);
    genId++;
  }
}

public void draw () {
  if (gASAP) {
    doGenASAP ();
  }
  
  background (100, 230, 100);
  if (restartTime == 0 && !paused) {
    for (int i = 0; i < processSpeed; i++) {
      iterate ();
      camX = max (playerX - sizeX / 2, 0);
      camY = max (playerY - (height - floorLevel), 0);
      
      if (restartTime > 0)
        break;
    }
  }
  

  
  pushMatrix ();
  translate (-camX, camY);
  
  if (restartTime == 0) {
    drawPlayer ();
  }
  
  for (Obstacle o : obstacles) {
    if (o.inDrawingRegion ()) {
      o.draw ();
    }
  }
  
  noStroke ();
  fill (70, 70, 60);
  rect (camX, floorLevel, sizeX, height - floorLevel);
  
  popMatrix ();
  
  if (restartTime > 0) {
    textSize (40);
    fill (0);
    text (won ? "Win" : "Dead", sizeX / 2 - 60, height / 2 - 30, 100, 50);
    
    if (won && !hasWon) {
      paused = true;
      hasWon = true;
    }
    
    if (!paused) {
      restartTime = max (restartTime - processSpeed, 0);
    }
    
    if (restartTime == 0) {

      generations.get (generations.size () - 1).creatures[creatureId].fitness = playerX;
      
      /*
        if (creatureId < Generation.creaturesPerGen - 1) {
      */
      do {
        creatureId ++;
      } while (lazyEval && creatureId < Generation.creaturesPerGen && generations.get (generations.size () - 1).creatures[creatureId].fitness != 0);
      
      if (creatureId > Generation.creaturesPerGen - 1) {
        endGeneration ();
        creatureId = 0;
      }

      initRun ();
    }
  }
  drawSidebar ();
}

public void drawSidebar () {
  // Sidebar background
  stroke (0);
  fill (180);
  rect (sizeX, 0, sidebarWidth, height);
  
  // "Restart" button
  if (pointInBoxEx (mouseX, mouseY, sizeX + 30, 70, width - 30, 30)) { // Mouse on the button
    fill (170, 30, 30);
  } else { // Mouse not on the button
    fill (200, 60, 60);
  }
  rect (sizeX + 30, 30, sidebarWidth - 60, 40);
  fill (0);
  textSize (24);
  text ("Restart / generate new first gen", sizeX + 70, 60);
  
  // "Do the rest of this generation" button
  if (pointInBoxEx (mouseX, mouseY, sizeX + 30, 130, width - 30, 90)) { // Mouse on the button
    fill (170, 30, 30);
  } else { // Mouse not on the button
    fill (200, 60, 60);
  }
  rect (sizeX + 30, 90, sidebarWidth - 60, 40);
  fill (0);
  textSize (24);
  text ("Do the rest of this generation ASAP", sizeX + 50, 120);
  
  // "Do generations ASAP" button
  if (pointInBoxEx (mouseX, mouseY, sizeX + 30, 190, width - 30, 150)) { // Mouse on the button
    if (gASAP) {
      fill (60, 170, 60);
    } else {
      fill (170, 30, 30);
    }
  } else { // Mouse not on the button
    if (gASAP) {
      fill (90, 200, 90);
    } else {
      fill (200, 60, 60);
    }
  }
  rect (sizeX + 30, 150, sidebarWidth - 60, 40);
  fill (0);
  textSize (24);
  text ("Do generations ASAP", sizeX + 140, 180);
  
  // Background for network map
  image (networkBgGraphics, sizeX + 1, 100);
  // Draw network
  generations.get (generations.size () - 1).creatures[creatureId].draw ();
  
  image (singleGraphics, sizeX + 1, 449);
  
  // The information text
  textSize (24);
  fill (180);
  text ("Gen " + genId + "   creature " + (creatureId + 1) + "   " + processSpeed + "x speed   lazy evaluation " + (lazyEval? "en" : "dis") + "abled" + (hasWon? "   win" : ""), 10, height - 30, 900, 30);
}

public void iterate () {
  generations.get (generations.size () - 1).creatures[creatureId].iterate ();
  playerX += playerVelX;
  playerY += playerVelY;
  
  checkColl ();
  
  if (checkOnSomething ()) {
    //if (mousePressed){ // Manual mode
    if (generations.get (generations.size () - 1).creatures[creatureId].outputNode.lastVal) {
      playerVelY = jumpVel;
    } else {
      playerVelY = 0f;
    }
  } else {
    playerVelY = max (playerVelY - gravity, -termVel);
  }
  
  if (restartTime == 0) {
    if (playerX >= endX) {
      won = true;
      restartTime = delayTime;
    }
  }
}

public void doGenASAP () {
  if (restartTime > 0) {
    generations.get (generations.size () - 1).creatures[creatureId].fitness = playerX;
    if (creatureId < Generation.creaturesPerGen - 1) {
      do {
        creatureId ++;
      } while (lazyEval && generations.get (generations.size () - 1).creatures[creatureId].fitness != 0 && creatureId < Generation.creaturesPerGen - 1);
      initRun ();
    }
  }
  while (creatureId <= Generation.creaturesPerGen - 1) {
    restartTime = 0;
    while (restartTime == 0) {
      iterate ();
      camX = max (playerX - sizeX / 2, 0);
      camY = max (playerY - (height - floorLevel), 0);
    }
    
    if (won && !hasWon) {
      hasWon = true;
      restartTime = 0;
      initRun ();
      paused = true;
      gASAP = false;
      return;
    }
    
    generations.get (generations.size () - 1).creatures[creatureId].fitness = playerX;
    do {
      creatureId ++;
    } while (lazyEval && creatureId <= Generation.creaturesPerGen - 1 && generations.get (generations.size () - 1).creatures[creatureId].fitness != 0);
    
    if (creatureId <= Generation.creaturesPerGen - 1) {
      initRun();
    }
  }
  endGeneration ();
  creatureId = 0;
  initRun();
}

public void mouseClicked () {
  if (pointInBoxEx (mouseX, mouseY, sizeX + 30, 70, width - 30, 30)) { // Mouse on restart / new gen button
    generations.clear ();
    generations.add (new Generation ());
    genId = 1;
    creatureId = 0;
    hasWon = false;
    records.clear ();
    initRun ();
  } else if (pointInBoxEx (mouseX, mouseY, sizeX + 30, 130, width - 30, 90)) {
    doGenASAP ();
  } else if (pointInBoxEx (mouseX, mouseY, sizeX + 30, 190, width - 30, 150)) {
    gASAP = !gASAP;
  }
}

public void checkColl () {
  
  if (playerY < 0) {
    playerY = 0;
  }
  
  //Old code revamped for better load (triangles take a bit more computing power)
  /*for (Obstacle o : obstacles) { 
    if (!o.inDrawingRegion ()) {
      continue;
    }
    if (o.triangle) {
      int[] points = {o.x - obstacleSize / 2, o.flipped? o.y + obstacleSize : o.y, o.x, o.flipped? o.y : o.y + obstacleSize, o.x + obstacleSize / 2, o.flipped? o.y + obstacleSize : o.y};
      if (pointInBox (o.x - obstacleSize / 2, o.y, playerX - playerSize / 2, playerY + playerSize, playerX + playerSize / 2, playerY) || 
         pointInBox (o.x + obstacleSize / 2, o.y, playerX - playerSize / 2, playerY + playerSize, playerX + playerSize / 2, playerY) ||
         pointInBox (o.x, o.y + obstacleSize, playerX - playerSize / 2, playerY + playerSize, playerX + playerSize / 2, playerY)) { // Player definitely clips the triangle (some point of the triangle is in the player)
         
        kill ();
        break;
       }
      if (pointInTriangle (playerX - playerSize / 2, playerY, points) ||
         pointInTriangle (playerX + playerSize / 2, playerY, points) ||
         pointInTriangle (playerX - playerSize / 2, playerY + playerSize, points) ||
         pointInTriangle (playerX + playerSize / 2, playerY + playerSize, points)) { // Player clips the triangle
        
        kill ();
        break;
        
      }
    } else {
      if (betweenEx (playerX, o.x - obstacleSize / 2 - playerSize / 2, o.x + obstacleSize / 2 + playerSize / 2) && betweenEx (playerY, o.y - obstacleSize / 2 - playerSize / 2, o.y + obstacleSize / 2 + playerSize / 2)) { // Player clips the obstacle
        if (abs (playerX - o.x) > abs (playerY - o.y)) { // Player (probably) approached from the side
          kill ();
          break;
        } else { // Player (probably) approached from the Y axis
          int sgn = (gravity < 0)? -1 : 1;
          if (playerY - o.y > 0 && sgn == 1 || playerY - o.y < 0 && sgn == -1) { // Player collided on the correct side
            playerY = o.y + (obstacleSize / 2 + playerSize / 2) * sgn;
          } else {
            kill ();
            break;
          }
        }
      }
    }
  }*/
  
  ArrayList<Obstacle> triangles = new ArrayList<Obstacle> ();
  ArrayList<Obstacle> boxes = new ArrayList<Obstacle> ();
  
  float prevY = playerY - playerVelY, prevX = playerX - playerVelX; // Get previous position
  
  for (Obstacle o : obstacles) {
    if (!o.triangle) {
      boxes.add (o);
    } else {
      triangles.add (o);
      continue;
    }
  }
  if (playerVelY <= 0f) { // Player can only be raised if it's moving down
  
    int tempY = playerY; // Store Y value to be raised to
    
    for (Obstacle o : boxes) { // First check to raise the player     
      
      if (!o.inCollisionRegion ()) {
        continue;
      }
      
      /*
      // if (betweenEx (playerX, o.x - obstacleSize / 2 - playerSize / 2, o.x + obstacleSize / 2 + playerSize / 2) && betweenEx (playerY, o.y - obstacleSize / 2 - playerSize / 2, o.y + obstacleSize / 2 + playerSize / 2)) { // Player clips the obstacle
      if (abs (playerX - o.x) > abs (playerY - o.y)) { // Player (probably) approached from the side (defaults to y axis if equal!!!)
          //kill ();
          //return;
      } else { // Player (probably) approached from the Y axis
        int sgn = (gravity < 0)? -1 : 1;
        if (playerY - o.y > 0 && sgn == 1 || playerY - o.y < 0 && sgn == -1) { // Player collided on the correct side
          playerY = o.y + (obstacleSize / 2 + playerSize / 2) * sgn;
        //} else {
        //  kill ();
        //  return;
        }
      }
      */
      
      if (prevY >= o.y + obstacleSize / 2 + playerSize / 2 && o.y + obstacleSize / 2 + playerSize / 2 > tempY) { // Only raise the player if the player was above the box and the current raise is below that of the obstacle
        if (betweenIn(playerVelX * (abs (max(prevY, o.y) - min(prevY, o.y)) - playerSize / 2 - obstacleSize / 2) / playerVelY + prevX, o.x - obstacleSize / 2 - playerSize / 2, o.x + obstacleSize / 2 + playerSize / 2)) { // Check whether the player landed on top of the box
          tempY = o.y + obstacleSize / 2 + playerSize / 2; // Raise the player
        }
      }
    }
    playerY = tempY; // Apply the raising
  }
  
  for (Obstacle o : boxes) { // Second check to kill the player (if needed)
    if (!o.inCollisionRegion ()) {
      continue;
    }
    
    /*if (abs (playerX - o.x) > abs (playerY - o.y)) { // Player (probably) approached from the side (defaults to y axis if equal!!!)
        kill ();
        return;
    } else { // Player (probably) approached from the Y axis
      int sgn = (gravity < 0)? -1 : 1;
      if (! (playerY - o.y > 0 && sgn == 1 || playerY - o.y < 0 && sgn == -1)) { // Player collided on the incorrect side
        kill ();
        return;
      }
    }*/
    
    if (betweenIn(playerY - (playerY - prevY) * (abs (max(o.x, prevX) - min(o.x, prevX)) - obstacleSize / 2 - playerSize / 2) / playerVelX, o.y - obstacleSize / 2 - playerSize / 2, o.y + obstacleSize / 2 + playerSize / 2)) { // Check whether the player landed on the side of the box
      kill ();
      return;
    }
  }
  
  for (Obstacle o : triangles) { // Finally check the triangles (most load (??))
    int[] points = {o.x - obstacleSize / 2, o.flipped? o.y + obstacleSize : o.y, o.x, o.flipped? o.y : o.y + obstacleSize, o.x + obstacleSize / 2, o.flipped? o.y + obstacleSize : o.y};
    
    if (pointInBoxEx (o.x - obstacleSize / 2, o.y, playerX - playerSize / 2, playerY + playerSize, playerX + playerSize / 2, playerY) || 
       pointInBoxEx (o.x + obstacleSize / 2, o.y, playerX - playerSize / 2, playerY + playerSize, playerX + playerSize / 2, playerY) ||
       pointInBoxEx (o.x, o.y + obstacleSize, playerX - playerSize / 2, playerY + playerSize, playerX + playerSize / 2, playerY)) { // Player definately clips the triangle (some point of the triangle is in the player)
       
      kill ();
      return;
      
    }
       
    if (pointInTriangle (playerX - playerSize / 2, playerY, points) ||
       pointInTriangle (playerX + playerSize / 2, playerY, points) ||
       pointInTriangle (playerX - playerSize / 2, playerY + playerSize, points) ||
       pointInTriangle (playerX + playerSize / 2, playerY + playerSize, points)) { // Player clips the triangle
      
      kill ();
      return;
    
    }
  }
}

public void kill () {
  restartTime = delayTime;
}

public boolean pointInBoxIn (int x, int y, int left, int top, int right, int bottom) {
  return betweenIn (x, left, right) && betweenIn (y, top, bottom);
}

public boolean pointInBoxEx (int x, int y, int left, int top, int right, int bottom) {
  return betweenEx (x, left, right) && betweenEx (y, bottom, top);
}

public float HP (int p1x, int p1y, int p2x, int p2y, int p3x, int p3y) {
  return (p1x - p3x) * (p2y - p3y) - (p2x - p3x) * (p1y - p3y);
}

public boolean pointInTriangle (int x, int y, int[] points) {
  boolean b1, b2, b3;
  
  b1 = HP (x, y, points[0], points[1], points[4], points[5]) < 0.0f;
  b2 = HP (x, y, points[4], points[5], points[2], points[3]) < 0.0f;
  b3 = HP (x, y, points[2], points[3], points[0], points[1]) < 0.0f;
  
  return ((b1 == b2) && (b2 == b3));
}

public boolean checkOnSomething () {
  if (playerY == 0)
    return true;
    
  for (Obstacle o : obstacles) {
    if (!o.triangle && betweenEx (playerX, o.x - obstacleSize / 2 - playerSize / 2, o.x + obstacleSize / 2 + playerSize / 2) && playerY == o.y + obstacleSize / 2 + playerSize / 2) {
      return true;
    }
  }
  
  return false;
}

public boolean betweenEx (int value, int min, int max) {
  return value < max && value > min;
}

public boolean betweenEx (float value, int min, int max) {
  return value < max && value > min;
}

public boolean betweenIn (int value, int min, int max) {
  return value <= max && value >= min;
}

public boolean betweenIn (float value, int min, int max) {
  return value <= max && value >= min;
}

public void drawPlayer () {
  noStroke ();
  fill (0, 0, 0);
  rect (playerX - obstacleSize / 2, floorLevel - (playerY + obstacleSize), obstacleSize, obstacleSize);
  fill (255, 255, 255);
  rect (playerX - obstacleSize / 2 + boundingWidth, floorLevel - (playerY + obstacleSize - boundingWidth), obstacleSize - boundingWidth * 2, obstacleSize - boundingWidth * 2);
}

public void drawSingle (ArrayList<Creature> creatures) {
  singleGraphics.beginDraw ();
  singleGraphics.noStroke ();
  singleGraphics.fill (200);
  singleGraphics.rect (0, 0, sidebarWidth / 2 - 1, 300);
  if (creatures.size () == 0) {
    
  }
  
  singleGraphics.endDraw ();
}

public void loadLevel () {
  File f = new File (dataPath ("level.gdat")); // !!! File hardcoded !!!, needs to be done here, not in the beginning definitions (otherwise the path is incorrect)
  if (!f.exists ()) {
    obstacles = new Obstacle[0];
  } else {
    Table table = loadTable (dataPath ("level.gdat"), "header, csv"); // Gets stuck somewhere if loaded file isn't an expected table. Refer to instructions.txt for some solutions
    obstacles = new Obstacle[table.getRowCount ()];
    endX = 0;
    for (int i = 0; i < table.getRowCount (); i++) {
      TableRow row = table.getRow (i);
      obstacles[i] = new Obstacle (row.getInt ("x"), row.getInt ("y"), row.getInt ("triangle") == 1, row.getInt ("flipped") == 1);
      if (obstacles[i].x > endX - 300) {
        endX = obstacles[i].x + 300;
      }
    }
    initRun ();
  }
  f = null;
}
class Connector {
  
  public Node input;
  public Node output;
  public boolean outputOne;
  public boolean inverted;
  
  public Connector (Node out, boolean inv) {
    output = out;
    inverted = inv;
  }
  
  public Connector clone () {
    Connector co = new Connector (null, inverted);
    co.outputOne = outputOne; 
    return co;
  }
  
  public void iterate (boolean i) {
    if (i != inverted) {
      if (outputOne) {
        output.in1 = true;
      } else {
        output.in2 = true;
      }
    }
  }
  
  public void draw () {
    strokeWeight (2);
    
    switch ((inverted ? 2 : 0) + (input.lastVal ? 1 : 0)) {
      
      case 0: // Normal conector & last value false
        stroke (50, 100, 50);
        break;
      
      case 1: // Normal connector & last value true
        stroke (100, 200, 100);
        break;
      
      case 2: // Inverted connector & last value false
        stroke (200, 60, 60);
        break;
      
      case 3: // Inverted connector & last value true
        stroke (100, 30, 30);
        break;
    }
    
    if (input instanceof ScreenNode) {
      line ((float) (((ScreenNode) input).x + nodeSize / 2), (float) (height - ((ScreenNode)input).y), (float) (sizeX + output.layer * sidebarWidth / 11 + 10), (float) (output.yOffset + nodeSize / 2 + 200 + (outputOne ? -6 : 6)));
    } else {
      line ((float) (sizeX + input.layer * sidebarWidth / 11 + nodeSize + 10), (float) (input.yOffset + nodeSize / 2 + 200), (float) (sizeX + output.layer * sidebarWidth / 11 + 10), (float) (output.yOffset + nodeSize / 2 + 200 + (outputOne ? -6 : 6)));
    }
  }
}
class Creature {
  ArrayList<Node> nodes;
  public Node outputNode;
  ArrayList<Connector> connectors;
  public int fitness;
  
  public Creature () {
    nodes = new ArrayList<Node> ();
    connectors = new ArrayList<Connector> ();
    nodes.add (new Node (10));
    outputNode = nodes.get (0);
    fitness = 0;
  }
  
  public Creature clone () { // Heavily documented for possible later reverse engineering
  
    /** This algorithm is based on three facts:
      * 1) Each connector has exactly one input and output
      * 2) Each node must have an input / output connector (at least one)
      * 3) Each connector and node is unique
      * Therefore, by looping trough all of the connectors, each node and connector can be cloned correctly
    **/
    
    Creature cr = new Creature (); // Return creature creation
    cr.nodes.clear (); // Clear the list of nodes (remove the automatic output Node)
    cr.nodes.ensureCapacity (nodes.size ()); // Size safety, maybe preventing crashes?
    cr.connectors.ensureCapacity (connectors.size ()); // --,,--
    cr.fitness = fitness; // Clone the fitness for skipping
    
    ArrayList<Node> dl = new ArrayList<Node> (nodes.size ()); // List of nodes already copied (local). Matching cloned nodes will be stored in cr.nodes
    
    for (Connector c : connectors) { // Loop trough every connector
      Connector co = c.clone (); // Clone connector
      
      int a = dl.indexOf (c.input); // Get index of input node (-1 if not there yet)
      
      
      if (a == -1) { // Node hasn't been cloned yet
        Node i = c.input.clone (); // Clone node
        i.o.add (co); // Add the connector to the node's outputs
        co.input = i; // Set the cloned connector's iput to the cloned node
        dl.add (c.input); // Add the original node to the list for check
        cr.nodes.add (i); // Add the cloned node to the list
      } else { // Node has already been cloned
        cr.nodes.get (a).o.add (co); // Add the connector to the (already) cloned node's outputs
        co.input = cr.nodes.get (a); // Set the cloned connector's input to the node
      }
      
      a = dl.indexOf (c.output); // Get index of output node (-1 if not there yet)
      
      if (a == -1) { // Node hasn't been cloned yet
        Node i = c.output.clone (); // Clone node
        co.output = i; // Set the connector's output to the cloned node
        dl.add (c.output); // Add the original node to the list for check
        cr.nodes.add (i); // Add the cloned node to the list
        if (i.layer == 10)
          cr.outputNode = i; // Set the output node
      } else { // Node has already been cloned
        co.output = cr.nodes.get (a); // Set the cloned connector's output to the node
      }
      
      cr.connectors.add (co); // Finally add the cloned connector to the list
    }
    
    if (cr.nodes.indexOf (cr.outputNode) == -1) {
      println ("Output node not cloned correctly:");
      int a = 0;
      for (Node n : cr.nodes) {
        if (n.layer == 10) {
          a++;
        }
      }
      
      switch (a) {
        case 0:
          println ("Output node not in the list of nodes. Fixing...");
          cr.nodes.add (cr.outputNode);
          break;
          
        case 1:
          println ("Output node does not match the one in the list");
          break;
          
        default:
          println ("More than one output node (none match)");
          break;
      }
      
      println ("Printing original creature info:");
      println ();
      printDebugOutput ();
      
      println ();
      println ("Printing cloned creature info");
      println ();
      cr.printDebugOutput ();
      println ();
    }
    
    cr.calculateNodeOffsets ();
    return cr;
  }
  
  public void reset () {
    for (Node n : nodes) {
      n.reset ();
    }
  }
  
  public void iterate () {
    reset ();
    for (int i = -1; i < 11; i++) {
      for (Node n : nodes) {
        if (n.layer != i) {
          continue;
        }
        n.iterate ();
      }
    }
  }
  
  public void initRandomize () {
    int a = (int) random (6);
    for (a = (a <= 2)? 1 : (a <= 4)? 2 : 3; a > 0; a--) { // Weighted random: add (1/2 => 1 node; 1/3 => 2 nodes; 1/6 => 3 nodes)
      addNode ();
    }
    
  }
  
  public void nrmlRandomize () {
    fitness = 0; // Reset the fitness, marks the creature to be re-evaluated
    
    float p = random (1);
    
    int b = 6;
    
    for (int i = 1; i < 6; i++) {
      if (p > pow (2, -i)) {
        b = i;
        break;
      }
    }
    
    for (; b > 0; b--) {
      p = random (9); // Weighted random:
      if (p < 0.45f) { // 1/20 add a new Node
        addNode ();
      } else if (p < 0.9f) { // 1/20 add a new Node in a Connector
        addNodeInConn ();
      } else if (p < 2f) { // 11/90 remove a Node
        removeNode ();
      } else if (p < 3f) { // 1/9 change the layer of a Node
        changeNodeLayer ();
      } else if (p < 4f) { // 1/9 move a ScreenNode
        moveScreenNode ();
      } else if (p < 5f) { // 1/9 change the type of a screenNode
        changeScreenNode ();
      } else if (p < 6f) { // 1/9 change the type of a Connector
        changeConnectorType ();
      } else if (p < 7f) { // 1/9 change the output side of a Connector
        changeConnectorSide ();
      } else if (p < 8f) { // 1/9 add a new Connector
        addConnector ();
      } else { // 1/9 remove a connector
        removeConnector ();
      }
    }
    cleanup();
  }
  
  public void addNode () { // Add a random node
    if (nodes.size () > 25 && random (1) < 0.6f)
        return;
    float p = random (1);
    Node no;
    
    if (p < 0.6f) { // ScreenNode (~3/5 chance)
      no = new ScreenNode (((int) random (sizeX / 50 - 1)) * 50 + 25, ((int) random (height / 50 - 1)) * 50 + 25, (random (1) < 0.2f)? 2 : (int) random (2));
      for (Node n : nodes) {
        if (n instanceof ScreenNode) {
          if (((ScreenNode) n).x == ((ScreenNode) no).x && ((ScreenNode) n).y == ((ScreenNode) no).y) {
            if ((((ScreenNode) no).type + ((ScreenNode) n).type == 1) && random (1) < 0.5f) {
              ((ScreenNode) n).type = 2;
            }
            return;
          }
        }
      }
    } else { // Regular Node (~2/5 chance)
      no = new Node (0);
    }
    
    Node o;
    
    // Weighted random weighed towards nodes with 0 inputs
    
    ArrayList<Node> sel = new ArrayList<Node> ();
    
    // Do a semi-weighted random select of the nodes, favoring the ones with 0 inputs
    for (Node n : nodes) { // Iterate trough all of the Nodes
      if (n.layer == -1) // We don't want any ScreenNodes
        continue;
      boolean a = true;
      for (Connector c : connectors) { // Check the if there are incoming connections
        if (c.output == n) {
          a = false;
          break;
        }
      }
      
      if (a) {
        sel.add(n);
      }
      sel.add(n);
    }
    
    do {
      o = sel.get ((int) random (sel.size ()));
    } while (o.layer == 0); // Generate a new node if the layer of o is 0 (so that the new regular Node can be put between layer 0 (inclusive) and the output Node's layer (exclusive))
    
    if (!(no instanceof ScreenNode)) {
      no.layer = (int) random (o.layer); // Set the layer for the new node
      int i = 0;
      for (Node n : nodes) {
        if (n.layer == no.layer)
          i++;
      }
      if (i >= 6)
        return;
    }
    
    Connector c = new Connector (o, random (1) > 0.5f);
    no.o.add (c);
    c.input = no;
    // c.outputOne = (c.output instanceof ScreenNode) ? true : random (1) > 0.5f; // ??? The output can't be a ScreenNode, so........
    c.outputOne = random (1) > 0.5f;
    connectors.add (c);
    nodes.add (no);
  }
  
  public void addNodeInConn () { // Add a random node inside a connection
    if (nodes.size () > 25 && random (1) < 0.6f)
      return;
    if (connectors.size () == 0)
      return;
    for (int i = 0; i < 10; i++) { // Do at most 10 times.
      Connector c = connectors.get((int) random (connectors.size()));
      if (c.output.layer - c.input.layer > 1) { // There is room between the two nodes.
        Node n = new Node ((int) random (c.input.layer + 1, c.output.layer)); // Create a new Node between the two other Nodes.
        nodes.add (n);
        Connector c2 = new Connector (c.output, false); // Create the connector between the new node and the output node
        
        if (c.inverted) { // We only want one of the Connectors to be inverted.
          if (random (1) < 0.5f) { // Switch the new and old Connector (the inverted boolean) randomly
            c.inverted = false;
            c2.inverted = true;
          }
        }
        
        c2.input = n; // Set the input to be the new Node
        c2.outputOne = c.outputOne; // Set the output side to be the same as the original
        n.o.add (c2); // Add the new connector to the output list of the new Node
        connectors.add (c2); // Add the new connector to the list of all connectors
        c.output = n; // Set the output for the old connector to be the new Node;
        
        if (c.output.layer <= c.input.layer)
          println ("Original connector fail");
        else if (c2.output.layer <= c2.input.layer)
          println ("New connector fail");
        
        break; // We want this done (at most) once, so break out of the loop.
      }
    }
  }
  
  public void removeNode () {
    if (nodes.size () == 2) // If only the output Node and a single other Node remains, don't remove the other Node
      return;
    
    Node n = null;
    int i;
    for (i = 0; i < 10; i++) {
      n = nodes.get ((int) random (nodes.size ()));
      if (n.layer != 10)
        break;
    }
    
    if (i == 10)
      return;
    
    ArrayList<Connector> c = new ArrayList<Connector> ();
    
    for (Connector co : connectors) { // List the Connectors connected to this node
      if (co.output == n)
        c.add (co);
    }
    
    if (c.size () == 0) { // No incoming connections - remove the node and any connectors coming out of it
    
      for (Connector co : n.o) // Remove all Connectors coming from this Node from the list of Connectors
        connectors.remove (connectors.indexOf (co));
      
      nodes.remove(nodes.indexOf (n)); // Remove the Node from the list of all Nodes
      
    } else if (c.size () == 1) { // Some incoming Connectors: transfer all of the output Connectors to a random Connector's input (or the only one's, if there is only one), delete the other inputs
      
      Connector conn = c.get ((int) random (c.size ())); // The chosen Connector
      
      for (Connector co : n.o) { // Move the Connectors to the other Node
        co.input = conn.input;
        co.inverted = (co.inverted != conn.inverted);
        conn.input.o.add (co);
      }
      
      // Remove the original Connectors to the removed Node
      for (Connector co : c) {
        connectors.remove (connectors.indexOf (co));
        co.input.o.remove (co.input.o.indexOf (co));
      }
      
      nodes.remove(nodes.indexOf (n)); // Remove the removed Node from the list of all Nodes
    }
  }
  
  public void changeNodeLayer () {
    Node n = null;
    
    for (int i = 0; i < 10; i++) { // Try at most 10 times
      n = nodes.get ((int) random (nodes.size ()));
      
      if (n.layer != 10 && n.layer != -1) // Accept any Node that isn't a ScreenNode nor the output Node
        break;
      else if (i == 9) // Return if all tries failed
        return;
    }
    
    // Find the minimal layer for the Node
    int a = -1;
    for (Connector c : connectors) {
      if (c.output == n && c.input.layer > a)
        a = c.input.layer;
    }
    a++;
    
    // Find the maximum layer for the Node
    int b = 9;
    for (Connector c : n.o) {
      if (c.output.layer < b)
        b = c.output.layer;
    }
    
    n.layer = (int) random (a, b);
  }
  
  public void moveScreenNode () {
    ArrayList<ScreenNode> scn = new ArrayList<ScreenNode> ();
    
    for (Node n : nodes) { // Find all ScreenNodes
      if (n instanceof ScreenNode)
        scn.add ((ScreenNode) n);
    }
    
    if (scn.size () == 0)
      return;
    
    ScreenNode sn = scn.get ((int) random (scn.size ()));
    
    // Move the ScreenNode
    int px = sn.x, py = sn.y;
    sn.x = ((int) random (sizeX / 50 - 1)) * 50 + 25;
    sn.y = ((int) random (height / 50 - 1)) * 50 + 25;
    
    for (Node n : scn) {
      if (n instanceof ScreenNode && ((ScreenNode) n) != sn) {
        if (((ScreenNode)n).x == sn.x && ((ScreenNode) n).y == sn.y) {
          if ((((ScreenNode) n).type + sn.type == 1) && random (1) < 0.5f) {
            ((ScreenNode) n).type = 2;
            ArrayList<Node> r = new ArrayList<Node> (); // Which nodes are already connected to by this node
            for (Connector c : n.o) {
              r.add (c.output);
            }
            
            for (Connector c : sn.o) {
              if (r.indexOf (c.output) == -1) {
                n.o.add (c);
                c.input = n;
              } else {
                connectors.remove (connectors.indexOf (c));
              }
            }
            sn.o.clear ();
            nodes.remove (nodes.indexOf (sn));
          } else {
            sn.x = px;
            sn.y = py;
          }
          break;
        }
      }
    }
  }
  
  public void changeScreenNode () {
    ArrayList<ScreenNode> scn = new ArrayList<ScreenNode> ();
    
    for (Node n : nodes) { // Find all ScreenNodes
      if (n instanceof ScreenNode)
        scn.add ((ScreenNode) n);
    }
    
    if (scn.size () == 0)
      return;
      
    ScreenNode sn = scn.get ((int) random (scn.size ()));
    
    if (sn.type == 2)
      sn.type = (int) random(2);
    else
      sn.type = (random(3) < 2f)? 1 - sn.type : 2;
  }
  
  public void changeConnectorType () {
    if (connectors.size () == 0)
      return;
    Connector c = connectors.get ((int) random (connectors.size ()));
    c.inverted = !c.inverted;
  }
  
  public void changeConnectorSide () {
    if (connectors.size () == 0)
      return;
    Connector c = connectors.get ((int) random (connectors.size ()));
    c.outputOne = !c.outputOne;
  }
  
  public void addConnector () {
    for (int i = 0; i < 10; i++) { // Try at most 10 times
      Node a = nodes.get ((int) random (nodes.size ()));
      Node b = nodes.get ((int) random (nodes.size ()));
      
      if (a.layer != b.layer) {
        if (a.layer > b.layer) { // Switch a and b
          Node t = a;
          a = b;
          b = t;
        }
        
        boolean c = false;
        
        for (Connector co : a.o) {
          if (co.output == b) {
            c = true;
            break;
          }
        }
        
        if (c)
          continue;
          
        Connector co = new Connector (b, random (1) < 0.5f);
        co.input = a;
        co.outputOne = (random (1) < 0.5f);
        connectors.add (co);
        a.o.add (co);
        break;
      }
    }
  }
  
  public void removeConnector() {
    if (connectors.size () == 0)
      return;
    Connector c = connectors.get ((int) random (connectors.size ()));
    c.input.o.remove (c.input.o.indexOf (c));
    connectors.remove (c);
  }
  
  public void cleanup () { // Cleanup to do after mutating. We don't want any creatures crashing the testing environment.
    boolean c; // Should cleanup be repeated?
    int j = 0; // Loop counter
    
    do {
      c = false;
      j ++;
      
      if (nodes.indexOf (outputNode) == -1) {
        println ("OUTPUT NODE DELETED! fixing...");
        printDebugOutput ();
        nodes.add (outputNode);
      }
      
      for (Node n : nodes) { // Cycle trough all Nodes
        if (n.layer == 10) { // Output node
          boolean a = false;
          for (Connector co : connectors) {
             if (co.output != null && co.output == n) {
               a = true;
               break;
             }
          }
          
          if (!a) { // The output Node has no inputs! Create a random connection for that.
            int b = 0;
            
            do {
              b = (int) random (nodes.size ());
            } while (nodes.get (b).layer == 10);
            
            Connector co = new Connector(n, random (1) < 0.5f);
            co.input = nodes.get (b);
            co.outputOne = random (1) < 0.5f;
            nodes.get (b).o.add (co);
            connectors.add (co);
            c = true;
          }
          
          continue;
        }
        
        if (n.o.size () == 0) { // This Node has no outputs! Create a random connection for that.
          c = true;
          boolean a = true;
          while (a) {
            Node b = nodes.get((int) random (nodes.size ()));
            if (b.layer > n.layer) {
              a = false;
              Connector co = new Connector (b, random (1) < 0.5f);
              co.input = n;
              co.outputOne = random (1) < 0.5f;
              n.o.add (co);
              connectors.add (co);
            }
          }
        } else { // Check for deleted connectors on output
          for (int i = n.o.size () - 1; i >= 0; i--) { // Check for broken connectors
            Connector co = n.o.get (i);
            if (co == null || co.output == null) {
              c = true;
              n.o.remove(i);
            } else if (co.input != n) { // Connector isn't referencing itself back to the Node (or is referencing to another Node, which is much worse). Also, this shouldn't happen.
              c = true;
              int a = 0;
              for (Node no : nodes) { // Count the references just to be sure.
                if (no.o.indexOf(co) != -1) // Connector is marked in the output list of the node
                  a++;
              }
              
              if (a == 0) { // Ughhhhhh - There should be at least one reference (the current iterating Node n)
                println("Warning: code not working properly in dereferenced connectors (0 references to a detected faulty connector). Deleting connector.");
                if (connectors.indexOf (co) != -1) { // Can't trust this connector any more - maybe it was deleted??
                  connectors.remove (connectors.indexOf (co)); // Remove the Connecor
                }
              } else if (a == 1) { // Ok, there is just a random dereference. We can work around it here
                println("Warning: connector / node dereference: connector does not reference the only node that has it as its output. Fixing.");
                co.input = n; // Fix the reference
              } else { // More than one reference?? Let's just delete the connector and let the cleanup figure this out
                println("Warning: connector / node dereference: connector referenced by " + a + " nodes (forgot to remove output reference from Node?). Deleting connector.");
                for (Node no : nodes) {
                  if (no.o.indexOf(co) != -1) // Connector is marked in the output list of the node
                    no.o.remove (no.o.indexOf (co)); // Remove the connector from the list
                }
                
                if (connectors.indexOf (co) != -1) { // Can't trust this connector any more - maybe it was deleted??
                  connectors.remove (connectors.indexOf (co)); // Remove the Connecor
                }
              }
            }
          }
        }
      }
      
      for (int i = connectors.size () - 1; i >= 0; i--) { // Check for broken Connectors
        Connector co = connectors.get (i);
        if (co == null || co.output == null || co.input == null) { // Invalid Connector (after main Node / Connector fixing)
          c = true;
          connectors.remove(i);
        } else if (co.input.layer >= co.output.layer) {
          println ("Warning: invalid connector: connector not following feed-forward. Deleting connector...");
          throw new NullPointerException ();
          //connectors.remove (i);
        } else {
          boolean a = true;
          for (Node n : nodes) { // See if this Connector is referenced
            if (n.o.indexOf(co) != -1) {
              a = false;
              break;
            }
          }
          
          if (a) { // Connector isn't referenced by any Nodes, yet it has a valid input Node. Connect the two, I guess?
            c = true;
            println("Warning: connector / node dereference: valid connector not referenced by any nodes. Fixing.");
            co.input.o.add(co);
          }
        }
      }
    } while (c && j < 100);
    
    if (j == 100) {
      println ("Too many iterations for cleanup. Printing end result");
      printDebugOutput ();
    }
    
    calculateNodeOffsets();
  }
  
  public void calculateNodeOffsets () {
    int[] layerCounts = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    for (Node n : nodes) {
      if (n.layer < 10) { // Normal Node
        n.yOffset = layerCounts[n.layer + 1] * (nodeSize + 10) + 10;
        layerCounts[n.layer + 1] ++;
      } else if (n.layer == 10){ // Output node
        n.yOffset = 10;
      }
    }
  }
  
  public void printDebugOutput () {
    println ("Begin debug output" + (creatureId == 200 ? "" : (" for generation id " + (generations.size () - 1) + " creature id " + creatureId + ":")));
      
      println ("Nodes:");
      for (Node n : nodes) {
        print (nodes.indexOf(n) + " ");
        if (n instanceof ScreenNode) {
          println ("Screen node (" + ((ScreenNode) n).x + ", " + ((ScreenNode) n).y + "): type: " + ((ScreenNode) n).type + "; outputs to layer" + (n.o.size () > 1 ? "s:" : ((n.o.size () == 1)? " " + n.o.get (0).output.layer : " -")));
        } else {
          println ((n.layer == 10 ? "Output" : "Regular") + " node on layer " + n.layer + (n.layer == 10 ? "" : ", outputs to layer" + (n.o.size () > 1 ? "s:" : ((n.o.size () == 1)? " " + n.o.get (0).output.layer : " -"))));
        }
        
        if (n.o.size () > 1) {
          for (Connector c : n.o) {
            println (c.output.layer);
          }
        }
      }
      
      println ("Connectors:");
      for (Connector c : connectors) {
        println ("Connector connecting nodes from layer " + c.input.layer + " (id "+ nodes.indexOf (c.input) +") to layer " + c.output.layer + " (id " + nodes.indexOf (c.output) + ")");
        if (c.output.layer <= c.input.layer) {
          println ("Invalid connector layering detected: printing node info");
          println ("Input:");
          if (c.input instanceof ScreenNode) {
            println ("Screen node (" + ((ScreenNode) c.input).x + ", " + ((ScreenNode) c.input).y + "): type: " + ((ScreenNode) c.input).type + "; outputs to layer" + (c.input.o.size () > 1 ? "s:" : " " + c.input.o.get (0).output.layer));
          } else {
            println ((c.input.layer == 10 ? "Output" : "Regular") + " node on layer " + c.input.layer + (c.input.layer == 10 ? "" : ", outputs to layer" + (c.input.o.size () > 1 ? "s:" : " " + c.input.o.get (0).output.layer)));
          }
          
          println ("Output:");
          if (c.output instanceof ScreenNode) {
            println ("Screen node (" + ((ScreenNode) c.output).x + ", " + ((ScreenNode) c.output).y + "): type: " + ((ScreenNode) c.output).type + "; outputs to layer" + (c.output.o.size () > 1 ? "s:" : " " + c.output.o.get (0).output.layer));
          } else {
            println ((c.output.layer == 10 ? "Output" : "Regular") + " node on layer " + c.output.layer + (c.output.layer == 10 ? "" : ", outputs to layer" + (c.output.o.size () > 1 ? "s:" : " " + c.output.o.get (0).output.layer)));
          }
          
        }
        
      }
  }
  
  public void draw () {

    for (Node n : nodes) {
      if (n.layer == -1 && networkDrawMode == 1) { // Draw a ScreenNode
        n.draw ();
        for (Connector c : n.o) {
          c.draw ();
        }
      } else if (n.layer < 10 && n.layer > -1 && networkDrawMode != 2) { // Draw a normal Node
        n.draw ();
        for (Connector c : n.o) {
          c.draw ();
        }
      } else if (n.layer == 10){ // Draw the output node
        n.draw ();
      }
    }
  }
}
class Generation {

  static final int creaturesPerGen = 200; // Amount of creatures per generation (keep even just in case)
  public Creature[] creatures;

  public Generation () {
    creatures = new Creature[creaturesPerGen];

    for (int i = 0; i < creaturesPerGen; i++) {
      creatures[i] = new Creature ();
      creatures[i].initRandomize ();
    }
  }

  public Generation (Creature[] c) {
    creatures = new Creature[creaturesPerGen];
    for (int i = 0; i < creaturesPerGen; i++) {

      creatures[i] = c[i].clone ();
    }
  }

  public void sortCreaturesAndCreateNew () {
    ArrayList<Creature> c = new ArrayList<Creature> (200);
    for (Creature cr : creatures) {
      c.add (cr);
    }
    
    // Randomize the list
    ArrayList<Creature> n = new ArrayList<Creature> (200);
    while (!c.isEmpty()) {
      int a = (int) random (c.size ());
      n.add (c.get (a));
      c.remove (a);
    }
    
    n = quickSort (n);
    
    ArrayList<Creature> cr = new ArrayList<Creature> (100);
    
    // Killing code heavily inspired by evolutionMath2 by carykh
    for (int i = 0; i < creaturesPerGen / 2; i++) { // Kill half of the creatures (more slower ones, but not necessarily just slower ones)
      if (PApplet.parseFloat(i) / creaturesPerGen <= (pow (random (-1, 1), 3) + 1) / 2) // Kill a slower creature
        cr.add (n.get (i));
      else // Kill a faster creature
        cr.add (n.get (creaturesPerGen - i - 1));
    }
    
    creatures = cr.toArray (creatures);
    
    for (int i = 0; i < creaturesPerGen / 2; i++) { // Clone and mutate said clones
      
      Creature m = creatures[i].clone ();
      
      m.nrmlRandomize ();
      
      creatures [creaturesPerGen / 2 + i] = m;
      
    }
  }

  public ArrayList<Creature> quickSort (ArrayList<Creature> c) {
    
    if (c.size () <= 1) {
      return c;
    }

    int comp = c.get (0).fitness;
    ArrayList<Creature> g = new ArrayList<Creature> ();
    ArrayList<Creature> e = new ArrayList<Creature> ();
    ArrayList<Creature> l = new ArrayList<Creature> ();
    for (Creature cr : c) {
      if (cr.fitness < comp) {
        l.add (cr);
      } else if (cr.fitness > comp) {
        g.add (cr);
      } else {
        e.add (cr);
      }
    }
    
    
    
    e.addAll (quickSort (l));
    g = quickSort (g);
    g.addAll (e);
    return g;
  }
}

class Node {
  public boolean in1, in2;
  public boolean lastVal;
  public ArrayList<Connector> o;
  public int layer;
  public int yOffset;
  
  public Node (int layer) {
    reset ();
    this.layer = layer;
    o = new ArrayList<Connector> ();
  }
  
  public Node clone () {
    return new Node (layer);
  }
  
  public void iterate () {
    if (layer == 10) {
      lastVal = in1 || in2;
    } else {
      lastVal = in1 && in2;
      for (Connector c : o){
        iterateOutputs (lastVal);
      }
    }
  }
  
  public void iterateOutputs (boolean value) {
    for (Connector c : o) {
      c.iterate (value);
    }
  }
  
  public void reset () {
    in1 = in2 = lastVal = false;
  }
  
  public void draw () {
    stroke (0);
    strokeWeight (3);
    if (lastVal) {
      fill (100, 200, 100);
    } else {
      fill (200, 60, 60);
    }
    
    rect (layer * sidebarWidth / 11 + 10 + sizeX + 1, yOffset + 200, nodeSize, nodeSize);
  }
}
class Obstacle {
  
  int x, y;
  boolean triangle, flipped;
  
  public Obstacle (int x, int y, boolean triangle, boolean flipped) {
    this.x = x;
    this.y = y;
    this.triangle = triangle;
    this.flipped = flipped;
  }
  
  public void draw () {
    noStroke ();
    if (triangle){
      /*fill (0, 0, 0);
      triangle (x - obstacleSize / 2, floorLevel - y, x, floorLevel - (y + obstacleSize), x + obstacleSize / 2, floorLevel - y);
      fill (255, 255, 255);
      triangle (x - obstacleSize / 2 + boundingWidth * 2, floorLevel - (y + boundingWidth), x, floorLevel - (y + obstacleSize - boundingWidth), x + obstacleSize / 2 - boundingWidth * 2, floorLevel - (y + boundingWidth));*/
      /*int[] points = getTrianglePoints ();
      
      for (int i = 0; i < obstacleSize / 2; i+=fadePrecision) {
        int c = (int) (((float) (i + 1)) / (((float) obstacleSize) / 2f) * 255f);
        fill (c, c, c);
        triangle (points[0] + i, points[1] + (flipped? i : -i), points[2], points[3] + (flipped? -i : i), points[4] - i, points[5] + (flipped? i : -i));
      }*/
      
      image (flipped? flippedTriangleGraphics : triangleGraphics, x - obstacleSize / 2, floorLevel - y - obstacleSize);

    } else {
      /*fill (0, 0, 0);
      rect (x - obstacleSize / 2, floorLevel - (y + obstacleSize), obstacleSize, obstacleSize);
      fill (255, 255, 255);
      rect (x - obstacleSize / 2 + boundingWidth, floorLevel - (y + obstacleSize - boundingWidth), obstacleSize - boundingWidth * 2, obstacleSize - boundingWidth * 2);*/
      
      /*for (int i = 0; i < obstacleSize / 2; i+=fadePrecision) {
        int c = (int) (((float) (i + 1)) / (((float) obstacleSize) / 2f) * 255f);
        fill (c, c, c);
        rect (x - obstacleSize / 2 + i, floorLevel - (y + obstacleSize - i), obstacleSize - i * 2, obstacleSize - i * 2);
      }*/
      
      image (boxGraphics, x - obstacleSize / 2, floorLevel - y - obstacleSize);
    }
  }
  
  public int[] getTrianglePoints () {
    int[] ret = new int[6];
    if (flipped) {
      
      ret[0] = x - obstacleSize / 2;
      ret[1] = floorLevel - (y + obstacleSize);
      
      ret[2] = x;
      ret[3] = floorLevel - y;
      
      ret[4] = x + obstacleSize / 2;
      ret[5] = floorLevel - (y + obstacleSize);
      
    } else {
      
      ret[0] = x - obstacleSize / 2;
      ret[1] = floorLevel - y;
      
      ret[2] = x;
      ret[3] = floorLevel - (y + obstacleSize);
      
      ret[4] = x + obstacleSize / 2;
      ret[5] = floorLevel - y;
      
    }
    
    return ret;
  }
  
  public boolean inDrawingRegion () {
    return betweenIn (x, camX - obstacleSize / 2, camX + sizeX + obstacleSize / 2) && betweenIn (y, camY - height / 2 - obstacleSize / 2, camY + height + obstacleSize / 2); 
  }
  
  public boolean inCollisionRegion () {
    return betweenEx (x, playerX - obstacleSize / 2 - playerSize / 2, playerX + obstacleSize / 2 + playerSize / 2) && betweenEx (y, playerY - obstacleSize / 2 - playerSize / 2, playerY + obstacleSize / 2 + playerSize / 2);
  }
}
class Record {
  
}
class ScreenNode extends Node {
  
  public int type; // 0 - box; 1 - triangle; 2 - both
  public int x, y;
  
  public ScreenNode (int x, int y, int type) {
    super (-1);
    this.x = x;
    this.y = y;
    this.type = type;
  }
  
  public ScreenNode clone () {
    return new ScreenNode (x, y, type);
  }
  
  @Override
  public void iterate () {
    
      if (type != 1 && y - (sizeY - floorLevel) + camY <= 0) {
        lastVal = true; 
        iterateOutputs (true);
        return;
      }
    
    for (Obstacle ob : obstacles) {
      
      if (pointInBoxIn (x + camX, y + camY - (height - floorLevel), ob.x - obstacleSize / 2, ob.y, ob.x + obstacleSize / 2, ob.y + obstacleSize) && ((type == 2)? true : ob.triangle == (type == 1))) {
        lastVal = true;
        iterateOutputs (true);
        return;
      }
    }
    
    lastVal = false;
    iterateOutputs (false);
  }
  
  @Override
  public void draw () {
    stroke (0);
    strokeWeight (3);
    switch (type + (lastVal? 3 : 0)) {
      case 0: // Box detector & last value false
        fill (0, 0, 100);
        break;
        
      case 3: // Box detector & last value true
        fill (50, 50, 200);
        break;
        
      case 1: // Triangle detector & last value false
        fill (100, 100, 0);
        break;
        
      case 4: // Triangle detector & last value true
        fill (200, 200, 50);
        break;
        
      case 2: // Both detector & last value false
        fill (0, 100,0);
        break;
      
      case 5: // Both detector & last value true
        fill (0, 200, 0);
        break;
    }
    
    rect (x - nodeSize / 2, (height - y) - nodeSize / 2, nodeSize, nodeSize);
  }
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "GDE" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
