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
  
  public void draw (PGraphics img) {
    img.stroke (0);
    img.strokeWeight (3);
    if (lastVal) {
      img.fill (100, 200, 100);
    } else {
      img.fill (200, 60, 60);
    }
    
    img.rect (layer * sidebarWidth / 11 + 10, yOffset, nodeSize, nodeSize);
  }
}
