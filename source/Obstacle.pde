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
  
  int[] getTrianglePoints () {
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
  
  boolean inDrawingRegion () {
    return betweenIn (x, camX - obstacleSize / 2, camX + sizeX + obstacleSize / 2) && betweenIn (y, camY - height / 2 - obstacleSize / 2, camY + height / 2 + obstacleSize / 2); 
  }
  
  boolean inCollisionRegion () {
    return betweenEx (x, playerX - obstacleSize / 2 - playerSize / 2, playerX + obstacleSize / 2 + playerSize / 2) && betweenEx (y, playerY - obstacleSize / 2 - playerSize / 2, playerY + obstacleSize / 2 + playerSize / 2);
  }
}
