class ScreenNode extends Node {
  
  public boolean triangle;
  public int x, y;
  
  public ScreenNode (int x, int y, boolean triangle) {
    super (-1);
    this.x = x;
    this.y = y;
    this.triangle = triangle;
  }
  
  public ScreenNode clone () {
    return new ScreenNode (x, y, triangle);
  }
  
  @Override
  public void iterate () {
    
      if (!triangle && y - (sizeY - floorLevel) + camY <= 0) {
        lastVal = true; 
        iterateOutputs (true);
        return;
      }
    
    for (Obstacle ob : obstacles) {
      
      if (pointInBoxIn (x + camX, y + camY - (height - floorLevel), ob.x - obstacleSize / 2, ob.y, ob.x + obstacleSize / 2, ob.y + obstacleSize) && ob.triangle == triangle) {
        lastVal = true;
        iterateOutputs (true);
        return;
      }
    }
    
    lastVal = false;
    iterateOutputs (false);
  }
  
  @Override
  public void draw (PGraphics img) {
    stroke (0);
    strokeWeight (3);
    switch ((triangle? 2 : 0) + (lastVal? 1 : 0)) {
      case 0: // Box detector & last value false
        fill (0, 0, 100);
        break;
        
      case 1: // Box detector & last value true
        fill (50, 50, 200);
        break;
        
      case 2: // Triangle detector & last value false
        fill (100, 100, 0);
        break;
        
      case 3: // Triangle detector & last value true
        fill (200, 200, 50);
        break;
    }
    
    rect (x - nodeSize / 2, (height - y) - nodeSize / 2, nodeSize, nodeSize);
  }
}
