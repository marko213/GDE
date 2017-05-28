class Node {
  public boolean in1, in2;
  public boolean lastVal, unused;
  public ArrayList<Connector> o;
  public int layer;
  public int yOffset;
  
  boolean baseSet;
  boolean checkVal;
  
  public Node (int layer, boolean unused) {
    reset ();
    this.layer = layer;
    this.unused = unused;
    o = new ArrayList<Connector> ();
  }
  
  public Node (int layer) {
    this (layer, false);
  }
  
  public Node clone () {
    return new Node (layer, unused);
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
    
    checkUnused ();
  }
  
  void checkUnused () {
    if (!unused)
      return;
    
    if (baseSet && (checkVal ^ lastVal)) {
      unused = false;
    } else if (!baseSet) {
      baseSet = true;
      checkVal = lastVal;
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
  
  public void preRunReset () {
    baseSet = false;
    if (layer != 10)
      unused = true;
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
