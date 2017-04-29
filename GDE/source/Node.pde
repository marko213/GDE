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
  
  void iterateOutputs (boolean value) {
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
    
    rect (layer * sidebarWidth / 11 + sidebarWidth / 22 - nodeSize / 2 + sizeX + 1, yOffset + 205, nodeSize, nodeSize);
  }
}
