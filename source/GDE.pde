// This project / code inspired by carykh's evolutionMATH2
// https://www.youtube.com/watch?v=5N7NYc7PPf8

int obstacleSize = 50;     // Size of obstacle collision / drawing box (should be 50 for compat reasons)
int playerSize = 50;         // Size of player collision / drawing box
int boundingWidth = 4;       // Width of the border around obstacles
int fadePrecision = 3;       // Precision to draw obstacle color fade with (1 is the smoothest)

float gravity = 0.7f;        // Simulation gravity (pixels per second per 1/60 of a second)
float termVel = 30f;         // Terminal velocity for the player (Y axis)
float jumpVel = 14.9f;       // Jump velocity for player
int delayTime = 60;          // Amount of frames to wait for on death / win

int restartTime = 0;         // Time for when to start new run
boolean won = false;         // Has the player won (on the current run)?
int sizeX = 800;             // Size of the play area (X axis)
int sizeY = 750;             // Size of the window (Y axis)
int sidebarWidth = 750;      // Width of the sidebar

int playerX;                 // Current position of the player (X axis)
int playerY;                 // Current position of the player (Y axis)
int playerVelX;              // Velocity of player (X axis) (pixels/ (1/60-th of a second))
float playerVelY;            // Velocity of player (Y axis) (pixels/ (1/60-th of a second))
boolean paused = false;      // Is the game currently paused? 
int endX;                    // X position that needs to be reached to win

int camX = 0;                // Position of the camera (X axis)
int camY = 0;                // Position of the camera (Y axis)
int drawIndex = 0;           // Index in obstacles to begin drawing / checking collision from 

int genId = 1;               // Id of the generation (1 - ...)

int floorLevel;              // Y coordinate for the floor to be drawn from

boolean lazyEval = true;     // Should the simulation skip already-evaluated creatures? 
boolean gASAP = false;       // Should the generations be done ASAP?
boolean autoRestart = false; // Should the generations be automatically restarted?
boolean hasWon = false;      // Has this evolution won the level?

Obstacle[] obstacles;
PGraphics boxGraphics, triangleGraphics, flippedTriangleGraphics, networkBgGraphics, singleGraphics, genGraphics;

Generation currentGen;       // Reference to current generation
ArrayList<int[]> records = new ArrayList<int[]> ();

int creatureId = 0;
int networkDrawMode = 1; // 0 - normal, draw normal nodes & connectors; 1 - extended, also draw screen nodes; 2 - hidden, only draw output
int nodeSize = 25;
int processSpeed = 1; // How many iterations to do for each frame
int restartThreshold = 100; // How many inactive (no progress made in the level) generations to wait before restarting
int inactiveGens = 0; // How many inactive generations have already happened after last progress?

final int restartThresholdMin = 10, restartThresholdMax = 5000; // Minimum and maximum for the restart threshold

void keyPressed () {
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
      // loadLevel ();
      selectInput ("Select a level file", "afterSelect");
      break;
      
    case 'n':
      networkDrawMode = (networkDrawMode + 1) % 3;
      break;
      
    case '+':
      if (processSpeed == 0) {
        frameRate (60);
        processSpeed = 1;
        break;
      }
      
      processSpeed = min (processSpeed * 2, 512);
      break;
      
    case '-':
      if (processSpeed == 1) {
        frameRate (30);
        processSpeed = 0;
      } else if (processSpeed > 1)
        processSpeed = max (processSpeed / 2, 1);
      break;
      
    case 'o':
      currentGen.creatures[creatureId].printDebugOutput (); // Output printed to java standard output, can be seen via command prompt / terminal etc.
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
    
    case 'x':
      if (restartThreshold > inactiveGens || autoRestart)
        autoRestart = !autoRestart;
      break;
    
    case 'c':
      int t = max (restartThreshold - (restartThreshold <= 50 ? 10 : (50 * (int) pow (2, max (log10 ((restartThreshold - 1) / 5) - 1, 0)) * (int) pow (5, max (log10 (restartThreshold - 1) - 2, 0)))), restartThresholdMin); // Formula used to create the sequence 10; 20; 30; 40; 50; 100; 150; ...; 450; 500; 600 ...
      if (t > inactiveGens || !autoRestart)
        restartThreshold = t; 
      break;
    
    case 'v':
      restartThreshold = min (restartThreshold + (restartThreshold < 50 ? 10 : (50 * (int) pow (2, max (log10 (restartThreshold / 5) - 1, 0)) * (int) pow (5, max (log10 (restartThreshold) - 2, 0)))), restartThresholdMax); // Formula used to create the sequence 10; 20; 30; 40; 50; 100; 150; ...; 450; 500; 600 ...
      break;
  }
}

void afterSelect (File sel) {
  if (sel == null || !sel.getName ().endsWith (".gdat") || !sel.exists ())
    return;
  loadLevel (sel);
}

void setup (){
  frameRate (60);
  randomSeed (213);
  boxGraphics = createGraphics (obstacleSize, obstacleSize);
  triangleGraphics = createGraphics (obstacleSize, obstacleSize);
  flippedTriangleGraphics = createGraphics (obstacleSize, obstacleSize);
  networkBgGraphics = createGraphics (sidebarWidth, 349);
  
  singleGraphics = createGraphics (sidebarWidth / 2, 300);
  genGraphics = createGraphics (sidebarWidth / 2, 300);
  
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
  loadLevel (new File (dataPath ("level.gdat")));
}

void initRun () {
  drawIndex = 0;
  playerX = 40;
  playerY = 0;
  playerVelY = 0f;
  playerVelX = 5;
  camX = 0;
  camY = 0;
  gravity = abs (gravity);
  restartTime = 0;
  won = false;
  camX = max (playerX - sizeX / 2, 0);
  camY = max (playerY - (height - floorLevel), 0);
  currentGen.creatures[creatureId].preRunReset ();
}

void endGeneration () {
  currentGen.sortCreaturesAndCreateNew ();
  genId ++;
  if (autoRestart && inactiveGens > restartThreshold && !hasWon) {
    restartAll ();
    return;
  }
}

void draw () {
  if (gASAP && !paused) {
    doGenASAP ();
  }
  
  background (100, 230, 100);
  if (restartTime == 0 && !paused) {
    for (int i = 0; i < max (processSpeed, 1); i++) {
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
  
  boolean a = false;
  
  for(int i = (paused ? 0 : drawIndex); i < obstacles.length; i ++) { 
    
    Obstacle o = obstacles[i];
    
    if(betweenIn(o.x, camX - obstacleSize / 2, camX + width + obstacleSize / 2)) {
      a = true;
      if (betweenIn(o.y, camY - height / 2 - obstacleSize / 2, camY + height + obstacleSize / 2))
        o.draw();
    } else if (a) {
      break;
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

      currentGen.creatures[creatureId].fitness = playerX;
      
      /*
        if (creatureId < Generation.creaturesPerGen - 1) {
      */
      do {
        creatureId ++;
      } while (lazyEval && creatureId < Generation.creaturesPerGen && currentGen.creatures[creatureId].fitness != 0);
      
      if (creatureId > Generation.creaturesPerGen - 1) {
        endGeneration ();
        creatureId = 0;
      }

      initRun ();
    }
  }
  drawSidebar ();
}

void drawSidebar () {
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
  text ("Restart / generate new first gen", sizeX + 200, 60);
  
  // "Do the rest of this generation" button
  if (pointInBoxEx (mouseX, mouseY, sizeX + 30, 130, width - 30, 90)) { // Mouse on the button
    fill (170, 30, 30);
  } else { // Mouse not on the button
    fill (200, 60, 60);
  }
  rect (sizeX + 30, 90, sidebarWidth - 60, 40);
  fill (0);
  textSize (24);
  text ("Do the rest of this generation ASAP", sizeX + 180, 120);
  
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
  text ("Do generations ASAP", sizeX + 262, 180);
  
  // Background for network map
  image (networkBgGraphics, sizeX + 1, 100);
  // Draw network
  currentGen.creatures[creatureId].draw ();
  
  image (singleGraphics, sizeX + 1, 449);
  image (genGraphics, sizeX + sidebarWidth / 2 + 1, 449);
  
  // The information text
  textSize (24);
  
  if (!hasWon) {
    if (inactiveGens < restartThreshold)
      fill (180);
    else
      fill (180, 40, 40);
      
    text ("Automatic restarting " + (autoRestart? "en" : "dis") + "abled   " + inactiveGens + " inactive gen" + (inactiveGens == 1 ? "" : "s") + " out of " + restartThreshold, 10, height - 55, 900, 30);
  }
  
  fill (180);
  text ("Gen " + genId + "   creature " + (creatureId + 1) + "   " + (processSpeed == 0 ? "0.5" : processSpeed) + "x speed   lazy evaluation " + (lazyEval? "en" : "dis") + "abled" + (hasWon? "   win" : ""), 10, height - 30, 900, 30);
}

void iterate () {
  currentGen.creatures[creatureId].iterate ();
  playerX += playerVelX;
  playerY += playerVelY;
  
  checkColl ();
  
  if (checkOnSomething ()) {
    //if (mousePressed){ // Manual mode
    if (currentGen.creatures[creatureId].outputNode.lastVal) {
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

void doGenASAP () {
  if (restartTime > 0) {
    currentGen.creatures[creatureId].fitness = playerX;
    if (creatureId < Generation.creaturesPerGen - 1) {
      do {
        creatureId ++;
      } while (lazyEval && currentGen.creatures[creatureId].fitness != 0 && creatureId < Generation.creaturesPerGen - 1);
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
    
    currentGen.creatures[creatureId].fitness = playerX;
    do {
      creatureId ++;
    } while (lazyEval && creatureId <= Generation.creaturesPerGen - 1 && currentGen.creatures[creatureId].fitness != 0);
    
    if (creatureId <= Generation.creaturesPerGen - 1) {
      initRun();
    }
  }
  endGeneration ();
  creatureId = 0;
  initRun();
}

void mouseClicked () {
  if (pointInBoxEx (mouseX, mouseY, sizeX + 30, 70, width - 30, 30)) { // Mouse on restart / new gen button
    restartAll ();
  } else if (pointInBoxEx (mouseX, mouseY, sizeX + 30, 130, width - 30, 90)) {
    doGenASAP ();
  } else if (pointInBoxEx (mouseX, mouseY, sizeX + 30, 190, width - 30, 150)) {
    gASAP = !gASAP;
  }
}

void restartAll () {
  currentGen = new Generation ();
  genId = 1;
  creatureId = 0;
  inactiveGens = 0;
  hasWon = false;
  drawSingle (new ArrayList<Creature> ());
  records.clear ();
  int[] t = {0, 0};
  records.add (t);
  drawGens ();
  initRun ();
}

void checkColl () {
  
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
  
  boolean a = false;
  
  for (int i = drawIndex; i < obstacles.length; i ++) {
    Obstacle o = obstacles[i];
    
    if (betweenIn(o.x, camX - obstacleSize / 2, camX + width + obstacleSize / 2)) {
      if (!a) {
        a = true;
        drawIndex = i;
      }
      if (!betweenIn(o.y, camY - height / 2 - obstacleSize / 2, camY + height + obstacleSize / 2))
        continue;
    } else {
      if (a)
        break;
      continue;
    }
    
    if (!o.triangle) {
      boxes.add (o);
    } else {
      triangles.add (o);
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

void kill () {
  restartTime = delayTime;
}

boolean pointInBoxIn (int x, int y, int left, int top, int right, int bottom) {
  return betweenIn (x, left, right) && betweenIn (y, top, bottom);
}

boolean pointInBoxEx (int x, int y, int left, int top, int right, int bottom) {
  return betweenEx (x, left, right) && betweenEx (y, bottom, top);
}

float HP (int p1x, int p1y, int p2x, int p2y, int p3x, int p3y) {
  return (p1x - p3x) * (p2y - p3y) - (p2x - p3x) * (p1y - p3y);
}

boolean pointInTriangle (int x, int y, int[] points) {
  boolean b1, b2, b3;
  
  b1 = HP (x, y, points[0], points[1], points[4], points[5]) < 0.0f;
  b2 = HP (x, y, points[4], points[5], points[2], points[3]) < 0.0f;
  b3 = HP (x, y, points[2], points[3], points[0], points[1]) < 0.0f;
  
  return ((b1 == b2) && (b2 == b3));
}

boolean checkOnSomething () {
  if (playerY == 0)
    return true;
    
  for (Obstacle o : obstacles) {
    if (!o.triangle && betweenEx (playerX, o.x - obstacleSize / 2 - playerSize / 2, o.x + obstacleSize / 2 + playerSize / 2) && playerY == o.y + obstacleSize / 2 + playerSize / 2) {
      return true;
    }
  }
  
  return false;
}

boolean betweenEx (int value, int min, int max) {
  return value < max && value > min;
}

boolean betweenEx (float value, int min, int max) {
  return value < max && value > min;
}

boolean betweenIn (int value, int min, int max) {
  return value <= max && value >= min;
}

boolean betweenIn (float value, int min, int max) {
  return value <= max && value >= min;
}

int clamp (int value, int min, int max) {
  return min (max (value, min), max);
}

int log10 (int n) {
  return (int) (log (n) / log (10));
}

void drawPlayer () {
  noStroke ();
  fill (0, 0, 0);
  rect (playerX - obstacleSize / 2, floorLevel - (playerY + obstacleSize), obstacleSize, obstacleSize);
  fill (255, 255, 255);
  rect (playerX - obstacleSize / 2 + boundingWidth, floorLevel - (playerY + obstacleSize - boundingWidth), obstacleSize - boundingWidth * 2, obstacleSize - boundingWidth * 2);
}

void drawSingle (ArrayList<Creature> creatures) {
  singleGraphics.beginDraw ();
  singleGraphics.noSmooth ();
  singleGraphics.noStroke ();
  singleGraphics.background (200);
  singleGraphics.fill (255);
  singleGraphics.rect (20, 20, sidebarWidth / 2 - 41, 260);
  singleGraphics.textSize (15);
  singleGraphics.smooth ();
  singleGraphics.fill (0);
  singleGraphics.text ("Amount of level completed (last generation)", 25, 16);
  singleGraphics.noSmooth ();
  
  if (creatures.size () == 0) {
    singleGraphics.endDraw ();
    return;
  }
  
  int max = ceil (((float) creatures.get (0).fitness) / ((float) endX) * 100f);
  int min = floor (((float) creatures.get (creatures.size () - 1).fitness) / ((float) endX) * 100f);
  
  int density = (max - min <= 10) ? 10 : (max - min <= 20) ? 5 : 2;
  
  singleGraphics.stroke (200);
  singleGraphics.strokeCap (RECT);
  singleGraphics.strokeWeight (1);
  singleGraphics.fill (0);
  singleGraphics.textSize (8);
  
  for (int i = density; i <= 100; i += density) {
    if (i % (10 / density) == 0) {
      singleGraphics.smooth ();
      singleGraphics.text ((max - (100 - i) / density) + "%", 0, 284 - i * 260 / 100);
      singleGraphics.noSmooth ();
    }
    
    if ((max - (100 - i) / density) % 50 == 0) {
        singleGraphics.stroke (100);
        if ((max - (100 - i) / density) == 0)
          singleGraphics.strokeWeight (2);
        singleGraphics.line (20, 280 - i * 260 / 100, sidebarWidth / 2 - 22, 280 - i * 260 / 100);
        singleGraphics.stroke (200);
        singleGraphics.strokeWeight (1);
        continue;
      }
    
    singleGraphics.line (20, 280 - i * 260 / 100, sidebarWidth / 2 - 22, 280 - i * 260 / 100);
  }
  
  for (float i = 20f + 0.05f * ((float) (sidebarWidth / 2 - 42)); i < sidebarWidth / 2 - 22; i += 0.05f * ((float) (sidebarWidth / 2 - 42))) {
    if (round (i * 10) == round((0.5f * ((float) (sidebarWidth / 2 - 42)) + 20f) * 10)) {
      singleGraphics.stroke (100);
      singleGraphics.line (round (i), 20, round (i), 280);
      singleGraphics.stroke (200);
      continue;
    }
    singleGraphics.line (round (i), 20, round (i), 280);
  }
  
  singleGraphics.stroke (0);
  
  
  // Alternative graph
  /*int j = 280 - round (2.6f * (((float) creatures.get (0).fitness) / ((float) endX) * 100f - ((float) (max - 100 / density))) * density);
  
  for (int i = 20; i < sidebarWidth / 2 - 21; i ++) {
    int k = 280 - round (2.6f * (((float) creatures.get (round ((((float) i) - 20f) / ((float) (sidebarWidth / 2 - 21)) * ((float)(creatures.size () - 1)))).fitness) / ((float) endX) * 100f - ((float) (max - 100 / density))) * density);
    
    if (k > 280) {
      singleGraphics.line (i, j, i, 280);
      break;
    }
      
    singleGraphics.line (i, j, i, k);
    j = k;
  }*/
  
  singleGraphics.strokeWeight (2);
  singleGraphics.smooth ();
  
  int j = 280 - round (2.6f * (((float) creatures.get (0).fitness) / ((float) endX) * 100f - ((float) (max - 100 / density))) * density);
  int px = 20;
  
  for(int i = 0; i < creatures.size (); i ++) {
    int k = 280 - round (2.6f * (((float) creatures.get (i).fitness) / ((float) endX) * 100f - ((float) (max - 100 / density))) * density);
    
    int x = round((((float) i) / ((float) (creatures.size () - 1)) * ((float)(sidebarWidth / 2 - 41)))) + 20;
    if (k > 280) {
      singleGraphics.line (px, j, x, 280);
      break;
    }
      
    singleGraphics.line (px, j, x, k);
    j = k;
    px = x;
  }
  
  singleGraphics.endDraw ();
}

void drawGens () {
  genGraphics.beginDraw ();
  
  genGraphics.noSmooth ();
  genGraphics.noStroke ();
  genGraphics.background (200);
  genGraphics.fill (255);
  genGraphics.rect (20, 20, sidebarWidth / 2 - 41, 260);
  genGraphics.textSize (15);
  genGraphics.fill (0);
  genGraphics.smooth ();
  genGraphics.text ("Amount of level completed (each generation)", 25, 16);
  
  int max = records.get (records.size () - 1)[0];
  
  genGraphics.stroke (200);
  genGraphics.strokeWeight (1);
  genGraphics.textSize (8);
  
  int density = (max * 100 / endX > 25 ? (max * 100 / endX > 50 ? 4 : 2) : 1);
  
  for (int i = density; i <= max * 100 / endX; i += density) {
    int h = 280 - ceil (((float) i) * 260f / ((float)(max * 100 / endX)));
    genGraphics.line (20, h, sidebarWidth / 2 - 21, h);
    
    genGraphics.text (i + "%", 0, h + 4);
  }
  
  genGraphics.stroke (200, 100, 100);
  genGraphics.strokeWeight (2);
  int py = 280 - round (((float) records.get (0)[1]) * 260f / ((float) max));
  int px = 20;
  for (int i = 0; i < records.size (); i++) {
    int x = 20 + round (((float) i) * (((float) sidebarWidth) / 2f - 41f) / ((float) records.size () - 1f));
    int y = 280 - round (((float) records.get (i)[1]) * 260f / ((float) max));
    genGraphics.line (px, py, x, y);
    
    py = y;
    px = x;
  }
  
  genGraphics.line (85, 290, 95, 290);
  genGraphics.textSize (12);
  genGraphics.text ("Median", 100, 295);
  genGraphics.textSize (8);
  
  genGraphics.stroke (0);
  
  py = 280 - round (((float) records.get (0)[1]) * 260f / ((float) max));
  px = 20;
  int pProgress = -1;
  for (int i = 0; i < records.size (); i++) {
    if (records.get (i)[0] == pProgress)
      inactiveGens ++;
    else {
      pProgress = records.get (i)[0];
      inactiveGens = 0;
    }
    int x = 20 + round (((float) i) * (((float) sidebarWidth) / 2f - 41f) / ((float) records.size () - 1f));
    int y = 280 - round (((float) records.get (i)[0]) * 260f / ((float) max));
    genGraphics.line (px, py, x, y);
    
    py = y;
    px = x;
  }
  
  genGraphics.line (205, 290, 215, 290);
  genGraphics.textSize (12);
  genGraphics.text ("Best", 220, 295);
  
  genGraphics.endDraw ();
}

void loadLevel (File f) {
  if (!f.exists ()) { // Failsafe
    obstacles = new Obstacle[0];
  } else {
    try {
      Table table = loadTable (f.getCanonicalPath (), "header, csv"); // Gets stuck somewhere if loaded file isn't an expected table. Refer to GDE level editor/README.md on GitHub for some solutions
      
      obstacles = new Obstacle[table.getRowCount ()];
      endX = 0;
      for (int i = 0; i < table.getRowCount (); i++) {
        TableRow row = table.getRow (i);
        obstacles[i] = new Obstacle (row.getInt ("x"), row.getInt ("y"), row.getInt ("triangle") == 1, row.getInt ("flipped") == 1);
        if (obstacles[i].x > endX - 300) {
          endX = obstacles[i].x + 300;
        }
      }
    } catch (IOException e) {
      println (e.getStackTrace ());
    }
  }
  f = null;
  restartAll ();
}
