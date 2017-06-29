class ScreenNode extends Node {
  
  public int type; // 0 - box; 1 - triangle; 2 - both
  public int x, y;
  
  public ScreenNode (int x, int y, int type, boolean unused) {
    super (-1, unused);
    this.x = x;
    this.y = y;
    this.type = type;
  }
  
  public ScreenNode (int x, int y, int type) {
    this (x, y, type, false);
  }
  
  public ScreenNode clone () {
    return new ScreenNode (x, y, type, unused);
  }
  
  @Override
  public void iterate () {
    screenIterate ();
    checkUnused ();
  }
  
  void screenIterate () {
    if (type != 1 && y - (sizeY - floorLevel) + camY <= 0) {
      lastVal = true; 
      iterateOutputs (true);
      return;
    }
    
    boolean a = false;
    
    for (int i = drawIndex; i < obstacles.length; i ++) {
      
      Obstacle ob = obstacles[i];
      
      if (betweenIn (ob.x, camX - obstacleSize / 2, camX + width + obstacleSize / 2)) {
        a = true;
        
        if (pointInBoxIn (x + camX, y + camY - (height - floorLevel), ob.x - obstacleSize / 2, ob.y, ob.x + obstacleSize / 2, ob.y + obstacleSize) && ((type == 2)? true : ob.triangle == (type == 1))) {
          lastVal = true;
          iterateOutputs (true);
          return;
        }
      } else if (a) {
        break;
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
        fill (0, 100, 0);
        break;
      
      case 5: // Both detector & last value true
        fill (0, 200, 0);
        break;
    }
    
    rect (x - nodeSize / 2, (height - y) - nodeSize / 2, nodeSize, nodeSize);
  }
}
