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
