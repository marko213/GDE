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
int drawIndex = 0;

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

void setup (){
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
}

void endGeneration () {
  generations.add (new Generation (generations.get (generations.size () - 1).creatures));
  generations.get (generations.size () - 1).sortCreaturesAndCreateNew ();
  genId ++;
  if (generations.size () > 2) {
    generations.remove (0);
  }
}

void draw () {
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

void iterate () {
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

void doGenASAP () {
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

void mouseClicked () {
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

void drawPlayer () {
  noStroke ();
  fill (0, 0, 0);
  rect (playerX - obstacleSize / 2, floorLevel - (playerY + obstacleSize), obstacleSize, obstacleSize);
  fill (255, 255, 255);
  rect (playerX - obstacleSize / 2 + boundingWidth, floorLevel - (playerY + obstacleSize - boundingWidth), obstacleSize - boundingWidth * 2, obstacleSize - boundingWidth * 2);
}

void drawSingle (ArrayList<Creature> creatures) {
  singleGraphics.beginDraw ();
  singleGraphics.noStroke ();
  singleGraphics.fill (200);
  singleGraphics.rect (0, 0, sidebarWidth / 2 - 1, 300);
  if (creatures.size () == 0) {
    
  }
  
  singleGraphics.endDraw ();
}

void loadLevel () {
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
