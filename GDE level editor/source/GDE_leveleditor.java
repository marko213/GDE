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

public class GDE_leveleditor extends PApplet {

int obstacleSize = 50;     // Size of obstacle collision / drawing box (should be 50 for compat reasons)
int playerSize = 50;       // Size of player collision / drawing box
int boundingWidth = 4;     // Width of the border around obstacles
int fadePrecision = 3;     // Precision to draw obstacle color fade with (1 is the smoothest)

float gravity = 0.7f;      // Simulation gravity (pixels per second per 1/60 of a second)
float termVel = 30f;       // Terminal velocity for the player (Y axis)
float jumpVel = 14.9f;     // Jump velocity for player
int deadTime = 60;         // Amount of frames to be dead for

int restartTime = 0;       // Time for when to start new run after death 

int sizeX = 800;           // Size of the window (X axis)
int sizeY = 750;           // Size of the window (Y axis)

int playerX;               // Current position of the player (X axis)
int playerY;               // Current position of the player (Y axis)
int playerVelX;            // Velocity of player (X axis) (pixels/(1/60-th of a second))
float playerVelY;          // Velocity of player (Y axis) (pixels/(1/60-th of a second))
boolean paused = false;    // Is the game currently paused (in edit mode)? 
int endX = 1000;           // X position that needs to be reached to win

int camX = 0;              // Position of the camera (X axis)
int camY = 0;              // Position of the camera (Y axis)

int floorLevel;            // Y coordinate for the floor to be drawn from
boolean shiftDown = false; // Is the shift key held down?
int camXVel = 0;           // How much to move the camera in edit mode (x axis)
int camYVel = 0;           // How much to move the camera in edit mode (y axis)
int camMoveVel = 6;        // Speed to apply to the camera (pixels per one 60-th of a second)
int drawIndex = 0;

ArrayList<Obstacle> obstacles = new ArrayList<Obstacle>();
Obstacle tempObstacle = new Obstacle(100, 100, false, false);

String saveFileLocation;
PGraphics boxGraphics, triangleGraphics, flippedTriangleGraphics;


class Obstacle {
  
  int x, y;
  boolean triangle, flipped;
  
  public Obstacle (int x, int y, boolean triangle, boolean flipped) {
    this.x = x;
    this.y = y;
    this.triangle = triangle;
    this.flipped = flipped;
  }
  
  public Obstacle clone () {
    return new Obstacle (x, y, triangle, flipped);
  }
  
  public void draw () {
    noStroke();
    if(triangle){
      /*fill(0, 0, 0);
      triangle(x - obstacleSize / 2, floorLevel - y, x, floorLevel - (y + obstacleSize), x + obstacleSize / 2, floorLevel - y);
      fill(255, 255, 255);
      triangle(x - obstacleSize / 2 + boundingWidth * 2, floorLevel - (y + boundingWidth), x, floorLevel - (y + obstacleSize - boundingWidth), x + obstacleSize / 2 - boundingWidth * 2, floorLevel - (y + boundingWidth));*/
      
      /*int[] points = getTrianglePoints();
      
      for (int i = 0; i < obstacleSize / 2; i+=fadePrecision) {
        int c = (int)(((float)(i + 1)) / (((float) obstacleSize) / 2f) * 255f);
        fill(c, c, c);
        triangle(points[0] + i, points[1] + (flipped? i : -i), points[2], points[3] + (flipped? -i : i), points[4] - i, points[5] + (flipped? i : -i));
      }*/
      
    image(flipped? flippedTriangleGraphics : triangleGraphics, x - obstacleSize / 2, floorLevel - y - obstacleSize);
    } else {
      /*fill(0, 0, 0);
      rect(x - obstacleSize / 2, floorLevel - (y + obstacleSize), obstacleSize, obstacleSize);
      fill(255, 255, 255);
      rect(x - obstacleSize / 2 + boundingWidth, floorLevel - (y + obstacleSize - boundingWidth), obstacleSize - boundingWidth * 2, obstacleSize - boundingWidth * 2);*/
      
      /*for (int i = 0; i < obstacleSize / 2; i+=fadePrecision) {
        int c = (int)(((float)(i + 1)) / (((float) obstacleSize) / 2f) * 255f);
        fill(c, c, c);
        rect(x - obstacleSize / 2 + i, floorLevel - (y + obstacleSize - i), obstacleSize - i * 2, obstacleSize - i * 2);
      }*/
      
      image(boxGraphics, x - obstacleSize / 2, floorLevel - y - obstacleSize);
    }
  }
  
  public int[] getTrianglePoints() {
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
  
  /*boolean inDrawingRegion () {
    return betweenIn(x, camX - obstacleSize / 2, camX + width + obstacleSize / 2) && betweenIn(y, camY - height / 2 - obstacleSize / 2, camY + height + obstacleSize / 2); 
  }*/
  
  public boolean inCollisionRegion() {
    return betweenEx(x, playerX - obstacleSize / 2 - playerSize / 2, playerX + obstacleSize / 2 + playerSize / 2) && betweenEx(y, playerY - obstacleSize / 2 - playerSize / 2, playerY + obstacleSize / 2 + playerSize / 2);
  }
  
}

public void keyPressed() {
  char k = Character.toLowerCase(key);
  switch(k){
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
      loadLevel();
      break;
    
    case 's':
      saveLevel();
      break;
    
    case 'c':
      obstacles.clear();
      break;
    
    case 'f':
      tempObstacle.flipped = !tempObstacle.flipped;
      break;
    
    case 't':
      tempObstacle.triangle = !tempObstacle.triangle;
      break; 
    
    case 'm':
      for (Obstacle o : obstacles)
        o.x += 50;
      break;
      
    case 'n':
      for (Obstacle o : obstacles)
        o.x -= 50;
      break;
    
    case 'x':
      obstacles = quickSort (obstacles);
      break;
        
    default:
      if (key == CODED) {
        switch (keyCode) {
          case SHIFT:
            shiftDown = true;
            break;
          
          case DOWN:
            camYVel = max(camYVel - camMoveVel, -camMoveVel);
            break;
            
          case UP:
            camYVel = min(camYVel + camMoveVel, camMoveVel);
            break;
            
          case RIGHT:
            camXVel = min(camXVel + camMoveVel, camMoveVel);
            break;
            
          case LEFT:
            camXVel = max(camXVel - camMoveVel, -camMoveVel);
            break;
        }
      }
      break;
  }
}

public ArrayList<Obstacle> quickSort (ArrayList<Obstacle> i) {
  if (i.size () <= 1)
    return i;
  
  ArrayList<Obstacle> g = new ArrayList<Obstacle> ();
  ArrayList<Obstacle> e = new ArrayList<Obstacle> ();
  ArrayList<Obstacle> l = new ArrayList<Obstacle> ();
  
  int c = i.get (0).x;
  
  for (Obstacle o : i) {
    if (o.x > c)
      g.add (o);
    else if (o.x == c)
      e.add (o);
    else
      l.add (o);
  }
  
  l = quickSort (l);
  l.addAll (e);
  l.addAll (quickSort (g));
  
  return l;
  
}

public void keyReleased() {
  
  if (key == CODED) {
    switch (keyCode) {
          case SHIFT:
            shiftDown = false;
            break;
          
          case DOWN:
            camYVel = min(camYVel + camMoveVel, camMoveVel);
            break;
            
          case UP:
            camYVel = max(camYVel - camMoveVel, -camMoveVel);
            break;
            
          case RIGHT:
            camXVel = max(camXVel - camMoveVel, -camMoveVel);
            break;
            
          case LEFT:
            camXVel = min(camXVel + camMoveVel, camMoveVel);
            break;
        }
  }
  
  /*if (!keyPressed) {
    camXVel = 0;
    camYVel = 0;
  }*/
  
}

public void setup(){
  saveFileLocation = dataPath("level.gdat"); // Needs to be done here, otherwise points somewhere else
  boxGraphics = createGraphics(obstacleSize, obstacleSize);
  triangleGraphics = createGraphics(obstacleSize, obstacleSize);
  flippedTriangleGraphics = createGraphics(obstacleSize, obstacleSize);
  boxGraphics.beginDraw();
  boxGraphics.noStroke();
  for (int i = 0; i < obstacleSize / 2; i+=fadePrecision) {
    int c = (int)(((float)(i + 1)) / (((float) obstacleSize) / 2f) * 255f);
    boxGraphics.fill(c, c, c);
    boxGraphics.rect(i, i, obstacleSize - i * 2, obstacleSize - i * 2);
  }
  boxGraphics.endDraw();
  
  triangleGraphics.beginDraw();
  triangleGraphics.noStroke();
  for (int i = 0; i < obstacleSize / 2; i+=fadePrecision) {
    int c = (int)(((float)(i + 1)) / (((float) obstacleSize) / 2f) * 255f);
    triangleGraphics.fill(c, c, c);
    triangleGraphics.triangle(i, obstacleSize - i, obstacleSize / 2, i, obstacleSize - i, obstacleSize - i);
  }
  triangleGraphics.endDraw();
  
  flippedTriangleGraphics.beginDraw();
  flippedTriangleGraphics.noStroke();
  for (int i = 0; i < obstacleSize / 2; i+=fadePrecision) {
    int c = (int)(((float)(i + 1)) / (((float) obstacleSize) / 2f) * 255f);
    flippedTriangleGraphics.fill(c, c, c);
    flippedTriangleGraphics.triangle(i, i, obstacleSize / 2, obstacleSize - i, obstacleSize - i, i);
  }
  flippedTriangleGraphics.endDraw();
  
  frameRate(60);
  size(sizeX,sizeY);
  floorLevel = height - 200;
  loadLevel();
  initRun ();
}

public void initRun () {
  drawIndex = 0;
  playerX = 40;
  playerY = 0;
  playerVelY = 0f;
  playerVelX = 5;
  camX = 0;
  camY = 0;
  gravity = abs(gravity);
  restartTime = 0;
}

public void draw() {
  
  if (paused && mousePressed) {
    if (mouseButton == LEFT && !shiftDown) // Add current object to world
      placeObject ();
    else if (mouseButton == RIGHT) // Remove all obstacles behind the mouse
      removeBehind ();
  }
  
  background(100, 230, 100);
  
  if(restartTime == 0 && !paused) {
    iterate();
  }

  if(!paused) {
    camX = max(playerX - width / 2, 0);
    camY = max(playerY - (height - floorLevel), 0);
  } else {
    camX = max(camX + (shiftDown? camXVel / 2 : camXVel), 0);
    camY = max(camY + (shiftDown? camYVel / 2 : camYVel), 0);
  }
  
  pushMatrix();
  translate(-camX, camY);
  
  if (restartTime == 0) {
    drawPlayer();
  }
  
  boolean a = false;
  
  for(int i = (paused ? 0 : drawIndex); i < obstacles.size (); i ++) { 
    
    Obstacle o = obstacles.get (i);
    
    if(betweenIn(o.x, camX - obstacleSize / 2, camX + width + obstacleSize / 2)) {
      a = true;
      if (betweenIn(o.y, camY - height / 2 - obstacleSize / 2, camY + height + obstacleSize / 2))
        o.draw();
    } else if (a) {
      break;
    }
  }
  
  noStroke();
  fill(70, 70, 60);
  rect(camX, floorLevel, width, height - floorLevel);
  
  if(paused) {
    int x = mouseX + camX;
    int y = -mouseY + camY;
    if(shiftDown) {
      tempObstacle.x = x;
      tempObstacle.y = max(y + floorLevel - obstacleSize / 2, 0);
    } else {
      tempObstacle.x = x - (x % obstacleSize) + obstacleSize / 2;
      tempObstacle.y = max(y + floorLevel - (y % obstacleSize) - (y < 0? obstacleSize : 0), 0);
    }
    tempObstacle.draw();
  }
  
  popMatrix();
  
  if (restartTime > 0 && !paused) {
    textSize(40);
    fill(0, 0, 0);
    text("Dead", width / 2 - 60, height / 2 - 30, 100, 50);
    restartTime --;
    if (restartTime == 0) {
      initRun ();
    }
  }
}

public void mousePressed() {
  if (paused) {
    if (mouseButton == LEFT) // Add current object to world
      placeObject ();
    else if (mouseButton == RIGHT) // Remove all obstacles behind the mouse
      removeBehind ();
    else { // Clone the first (drawn on top) obstacle to tempObstacle
      
      int x = mouseX + camX;
      int y = floorLevel - mouseY + camY;
      
      for (int i = obstacles.size() - 1; i >= 0; i--) {
        
        Obstacle o = obstacles.get(i);
        
        if (pointInBoxEx(x, y, o.x - obstacleSize / 2, o.y + obstacleSize, o.x + obstacleSize / 2, o.y)) {
          tempObstacle = o.clone();
          break;
        }
      }
    }
  }
}

public void placeObject () {
  if(!shiftDown) {
    removeFromPos(tempObstacle.x, tempObstacle.y + 1);
  }
  
  for (int i = 0; i < obstacles.size (); i++) {
    if (obstacles.get (i).x > tempObstacle.x) {
      obstacles.add (i, tempObstacle);
      break;
    }
  }
  
  if (obstacles.indexOf (tempObstacle) == -1)
    obstacles.add(tempObstacle);
  
  tempObstacle = tempObstacle.clone();
}

public void removeBehind () {
  removeFromPos(mouseX + camX, floorLevel - mouseY + camY);
}

public void removeFromPos(int x, int y) {
  
  for (int i = obstacles.size() - 1; i >= 0; i--) {
      
      Obstacle o = obstacles.get(i);
      
      if (pointInBoxIn(x, y, o.x - obstacleSize / 2, o.y, o.x + obstacleSize / 2, o.y + obstacleSize)) {
        obstacles.remove(i);
      }
      
  }
  
}

public void iterate() {
  playerX += playerVelX;
  playerY += playerVelY;
  
  checkColl();
  
  if(checkOnSomething()) {
    if(mousePressed){
      playerVelY = jumpVel;
    } else {
      playerVelY = 0f;
    }
  } else {
    playerVelY = max(playerVelY - gravity, -termVel);
  }
}

public void checkColl () {
  
  if (playerY < 0) {
    playerY = 0;
  }
  
  //Old code revamped for better load (triangles take a bit more computing power) (might be untrue as trigonometric functions are now used for boxes)
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
  
  for (int i = drawIndex; i < obstacles.size (); i ++) {
    Obstacle o = obstacles.get (i);
    
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

public void kill() {
  restartTime = deadTime;
}

public boolean pointInBoxIn(int x, int y, int left, int top, int right, int bottom) {
  return betweenIn(x, left, right) && betweenIn(y, top, bottom);
}

public boolean pointInBoxEx(int x, int y, int left, int top, int right, int bottom) {
  return betweenEx(x, left, right) && betweenEx(y, bottom, top);
}

public float HP (int p1x, int p1y, int p2x, int p2y, int p3x, int p3y) {
  return (p1x - p3x) * (p2y - p3y) - (p2x - p3x) * (p1y - p3y);
}

public boolean pointInTriangle (int x, int y, int[] points) {
  boolean b1, b2, b3;
  
  b1 = HP(x, y, points[0], points[1], points[4], points[5]) < 0.0f;
  b2 = HP(x, y, points[4], points[5], points[2], points[3]) < 0.0f;
  b3 = HP(x, y, points[2], points[3], points[0], points[1]) < 0.0f;
  
  return ((b1 == b2) && (b2 == b3));
}

public boolean checkOnSomething() {
  if (playerY == 0)
    return true;
    
  for (Obstacle o : obstacles) {
    if (!o.triangle && betweenEx(playerX, o.x - obstacleSize / 2 - playerSize / 2, o.x + obstacleSize / 2 + playerSize / 2) && playerY == o.y + obstacleSize / 2 + playerSize / 2) {
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
  noStroke();
  fill(0, 0, 0);
  rect(playerX - obstacleSize / 2, floorLevel - (playerY + obstacleSize), obstacleSize, obstacleSize);
  fill(255, 255, 255);
  rect(playerX - obstacleSize / 2 + boundingWidth, floorLevel - (playerY + obstacleSize - boundingWidth), obstacleSize - boundingWidth * 2, obstacleSize - boundingWidth * 2);
}

public void loadLevel() {
  File f = new File(saveFileLocation);
  if (!f.exists()) {
    obstacles.clear();
  } else {
    Table table = loadTable(saveFileLocation, "header,csv");
    obstacles.clear();
    for (int i = 0; i < table.getRowCount(); i++) {
      TableRow row = table.getRow(i);
      obstacles.add(new Obstacle(row.getInt("x"), row.getInt("y"), row.getInt("triangle") == 1, row.getInt("flipped") == 1));
    }
    initRun ();
  }
  f = null;
}

public void saveLevel() {
  Table t = new Table();
  t.addColumn("x");
  t.addColumn("y");
  t.addColumn("triangle");
  t.addColumn("flipped");
  
  for (Obstacle o : obstacles) {
    TableRow r = t.addRow();
    r.setInt("x", o.x);
    r.setInt("y", o.y);
    r.setInt("triangle", o.triangle? 1 : 0);
    r.setInt("flipped", o.flipped? 1 : 0);
  }
  
  saveTable(t, saveFileLocation, "csv");
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "GDE_leveleditor" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
