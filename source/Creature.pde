class Creature {
  ArrayList<Node> nodes;
  public Node outputNode;
  ArrayList<Connector> connectors;
  public int fitness;
  
  public Creature () {
    nodes = new ArrayList<Node> ();
    connectors = new ArrayList<Connector> ();
    nodes.add (new Node (10));
    outputNode = nodes.get (0);
    fitness = 0;
  }
  
  public Creature clone () { // Heavily documented for possible later reverse engineering
  
    /** This algorithm is based on three facts:
      * 1) Each connector has exactly one input and output
      * 2) Each node must have an input / output connector (at least one)
      * 3) Each connector and node is unique
      * Therefore, by looping trough all of the connectors, each node and connector can be cloned correctly
    **/
    
    Creature cr = new Creature (); // Return creature creation
    cr.nodes.clear (); // Clear the list of nodes (remove the automatic output Node)
    cr.nodes.ensureCapacity (nodes.size ()); // Size safety, maybe preventing crashes?
    cr.connectors.ensureCapacity (connectors.size ()); // --,,--
    cr.fitness = fitness; // Clone the fitness for skipping
    
    ArrayList<Node> dl = new ArrayList<Node> (nodes.size ()); // List of nodes already copied (local). Matching cloned nodes will be stored in cr.nodes
    
    for (Connector c : connectors) { // Loop trough every connector
      Connector co = c.clone (); // Clone connector
      
      int a = dl.indexOf (c.input); // Get index of input node (-1 if not there yet)
      
      
      if (a == -1) { // Node hasn't been cloned yet
        Node i = c.input.clone (); // Clone node
        i.o.add (co); // Add the connector to the node's outputs
        co.input = i; // Set the cloned connector's iput to the cloned node
        dl.add (c.input); // Add the original node to the list for check
        cr.nodes.add (i); // Add the cloned node to the list
      } else { // Node has already been cloned
        cr.nodes.get (a).o.add (co); // Add the connector to the (already) cloned node's outputs
        co.input = cr.nodes.get (a); // Set the cloned connector's input to the node
      }
      
      a = dl.indexOf (c.output); // Get index of output node (-1 if not there yet)
      
      if (a == -1) { // Node hasn't been cloned yet
        Node i = c.output.clone (); // Clone node
        co.output = i; // Set the connector's output to the cloned node
        dl.add (c.output); // Add the original node to the list for check
        cr.nodes.add (i); // Add the cloned node to the list
        if (i.layer == 10)
          cr.outputNode = i; // Set the output node
      } else { // Node has already been cloned
        co.output = cr.nodes.get (a); // Set the cloned connector's output to the node
      }
      
      cr.connectors.add (co); // Finally add the cloned connector to the list
    }
    
    if (cr.nodes.indexOf (cr.outputNode) == -1) {
      println ("Output node not cloned correctly:");
      int a = 0;
      for (Node n : cr.nodes) {
        if (n.layer == 10) {
          a++;
        }
      }
      
      switch (a) {
        case 0:
          println ("Output node not in the list of nodes. Fixing...");
          cr.nodes.add (cr.outputNode);
          break;
          
        case 1:
          println ("Output node does not match the one in the list");
          break;
          
        default:
          println ("More than one output node (none match)");
          break;
      }
      
      println ("Printing original creature info:");
      println ();
      printDebugOutput ();
      
      println ();
      println ("Printing cloned creature info");
      println ();
      cr.printDebugOutput ();
      println ();
    }
    
    cr.calculateNodeOffsets ();
    return cr;
  }
  
  public void reset () {
    for (Node n : nodes) {
      n.reset ();
    }
  }
  
  public void iterate () {
    reset ();
    for (int i = -1; i < 11; i++) {
      for (Node n : nodes) {
        if (n.layer != i) {
          continue;
        }
        n.iterate ();
      }
    }
  }
  
  public void initRandomize () {
    int a = (int) random (6);
    for (a = (a <= 2)? 1 : (a <= 4)? 2 : 3; a > 0; a--) { // Weighted random: add (1/2 => 1 node; 1/3 => 2 nodes; 1/6 => 3 nodes)
      addNode ();
    }
    
  }
  
  public void nrmlRandomize () {
    fitness = 0; // Reset the fitness, marks the creature to be re-evaluated
    float p = random (1);
    int b = (p < 0.75f)? 1 : (p < 0.9f)? 2 : 3; // Weighted random: do (3/4 => 1 mutation; 3/20 => 2 mutations; 2/20 => 3 mutations)
    for (; b > 0; b--) {
      p = random (9); // Weighted random:
      if (p < 0.45f) { // 1/20 add a new Node
        addNode ();
      } else if (p < 0.9f) { // 1/20 add a new Node in a Connector
        addNodeInConn ();
      } else if (p < 2f) { // 11/90 remove a Node
        removeNode ();
      } else if (p < 3f) { // 1/9 change the layer of a Node
        changeNodeLayer ();
      } else if (p < 4f) { // 1/9 move a ScreenNode
        moveScreenNode ();
      } else if (p < 5f) { // 1/9 change the type of a screenNode
        changeScreenNode ();
      } else if (p < 6f) { // 1/9 change the type of a Connector
        changeConnectorType ();
      } else if (p < 7f) { // 1/9 change the output side of a Connector
        changeConnectorSide ();
      } else if (p < 8f) { // 1/9 add a new Connector
        addConnector ();
      } else { // 1/9 remove a connector
        removeConnector ();
      }
    }
    cleanup();
  }
  
  void addNode () { // Add a random node
    float p = random (1);
    Node no;
    
    if (p < 0.6f) { // ScreenNode (~3/5 chance)
      no = new ScreenNode (((int) random (sizeX / 50 - 1)) * 50 + 25, ((int) random (height / 50 - 1)) * 50 + 25, random (3) < 1f);
    } else { // Regular Node (~2/5 chance)
      no = new Node (0);
    }
    
    Node o;
    
    // Weighted random weighed towards nodes with 0 inputs
    
    ArrayList<Node> sel = new ArrayList<Node> ();
    
    // Do a semi-weighted random select of the nodes, favoring the ones with 0 inputs
    for (Node n : nodes) { // Iterate trough all of the Nodes
      if (n.layer == -1) // We don't want any ScreenNodes
        continue;
      boolean a = true;
      for (Connector c : connectors) { // Check the if there are incoming connections
        if (c.output == n) {
          a = false;
          break;
        }
      }
      
      if (a) {
        sel.add(n);
      }
      sel.add(n);
    }
    
    do {
      o = sel.get ((int) random (sel.size ()));
    } while (!(no instanceof ScreenNode) && o.layer == 0); // Generate a new node, if the new Node is a regular Node and the layer of o is 0 (so that the new regular Node can be put between layer 0 (inclusive) and the output Node's layer (exclusive))
    
    if (!(no instanceof ScreenNode)) {
      no.layer = (int) random (o.layer); // Set the layer for the new node
    }
    
    Connector c = new Connector (o, random (1) > 0.5f);
    no.o.add (c);
    c.input = no;
    // c.outputOne = (c.output instanceof ScreenNode) ? true : random (1) > 0.5f; // ??? The output can't be a ScreenNode, so........
    c.outputOne = random (1) > 0.5f;
    connectors.add (c);
    nodes.add (no);
  }
  
  void addNodeInConn () { // Add a random node inside a connection
    if (connectors.size () == 0)
      return;
    for (int i = 0; i < 10; i++) { // Do at most 10 times.
      Connector c = connectors.get((int) random (connectors.size()));
      if (c.output.layer - c.input.layer > 1) { // There is room between the two nodes.
        Node n = new Node ((int) random (c.input.layer + 1, c.output.layer)); // Create a new Node between the two other Nodes.
        nodes.add (n);
        Connector c2 = new Connector (c.output, false); // Create the connector between the new node and the output node
        
        if (c.inverted) { // We only want one of the Connectors to be inverted.
          if (random (1) < 0.5f) { // Switch the new and old Connector (the inverted boolean) randomly
            c.inverted = false;
            c2.inverted = true;
          }
        }
        
        c2.input = n; // Set the input to be the new Node
        c2.outputOne = c.outputOne; // Set the output side to be the same as the original
        n.o.add (c2); // Add the new connector to the output list of the new Node
        connectors.add (c2); // Add the new connector to the list of all connectors
        c.output = n; // Set the output for the old connector to be the new Node;
        
        if (c.output.layer <= c.input.layer)
          println ("Original connector fail");
        else if (c2.output.layer <= c2.input.layer)
          println ("New connector fail");
        
        break; // We want this done (at most) once, so break out of the loop.
      }
    }
  }
  
  void removeNode () {
    if (nodes.size () == 2) // If only the output Node and a single other Node remains, don't remove the other Node
      return;
    
    Node n = null;
    int i;
    for (i = 0; i < 10; i++) {
      n = nodes.get ((int) random (nodes.size ()));
      if (n.layer != 10)
        break;
    }
    
    if (i == 10)
      return;
    
    ArrayList<Connector> c = new ArrayList<Connector> ();
    
    for (Connector co : connectors) { // List the Connectors connected to this node
      if (co.output == n)
        c.add (co);
    }
    
    if (c.size () == 0) { // No incoming connections - remove the node and any connectors coming out of it
    
      for (Connector co : n.o) // Remove all Connectors coming from this Node from the list of Connectors
        connectors.remove (connectors.indexOf (co));
      
      nodes.remove(nodes.indexOf (n)); // Remove the Node from the list of all Nodes
      
    } else if (c.size () == 1) { // Some incoming Connectors: transfer all of the output Connectors to a random Connector's input (or the only one's, if there is only one), delete the other inputs
      
      Connector conn = c.get ((int) random (c.size ())); // The chosen Connector
      
      for (Connector co : n.o) { // Move the Connectors to the other Node
        co.input = conn.input;
        co.inverted = (co.inverted != conn.inverted);
        conn.input.o.add (co);
      }
      
      // Remove the original Connectors to the removed Node
      for (Connector co : c) {
        connectors.remove (connectors.indexOf (co));
        co.input.o.remove (co.input.o.indexOf (co));
      }
      
      nodes.remove(nodes.indexOf (n)); // Remove the removed Node from the list of all Nodes
    }
  }
  
  void changeNodeLayer () {
    Node n = null;
    
    for (int i = 0; i < 10; i++) { // Try at most 10 times
      n = nodes.get ((int) random (nodes.size ()));
      
      if (n.layer != 10 && n.layer != -1) // Accept any Node that isn't a ScreenNode nor the output Node
        break;
      else if (i == 9) // Return if all tries failed
        return;
    }
    
    // Find the minimal layer for the Node
    int a = -1;
    for (Connector c : connectors) {
      if (c.output == n && c.input.layer > a)
        a = c.input.layer;
    }
    a++;
    
    // Find the maximum layer for the Node
    int b = 9;
    for (Connector c : n.o) {
      if (c.output.layer < b)
        b = c.output.layer;
    }
    
    n.layer = (int) random (a, b);
  }
  
  void moveScreenNode () {
    ArrayList<ScreenNode> scn = new ArrayList<ScreenNode> ();
    
    for (Node n : nodes) { // Find all ScreenNodes
      if (n instanceof ScreenNode)
        scn.add ((ScreenNode) n);
    }
    
    if (scn.size () == 0)
      return;
    
    ScreenNode sn = scn.get ((int) random (scn.size ()));
    
    // Move the ScreenNode
    sn.x = ((int) random (sizeX / 50 - 1)) * 50 + 25;
    sn.y = ((int) random (height / 50 - 1)) * 50 + 25;
  }
  
  void changeScreenNode () {
    ArrayList<ScreenNode> scn = new ArrayList<ScreenNode> ();
    
    for (Node n : nodes) { // Find all ScreenNodes
      if (n instanceof ScreenNode)
        scn.add ((ScreenNode) n);
    }
    
    if (scn.size () == 0)
      return;
      
    ScreenNode sn = scn.get ((int) random (scn.size ()));
    
    sn.triangle = !sn.triangle;
  }
  
  void changeConnectorType () {
    if (connectors.size () == 0)
      return;
    Connector c = connectors.get ((int) random (connectors.size ()));
    c.inverted = !c.inverted;
  }
  
  void changeConnectorSide () {
    if (connectors.size () == 0)
      return;
    Connector c = connectors.get ((int) random (connectors.size ()));
    c.outputOne = !c.outputOne;
  }
  
  void addConnector () {
    for (int i = 0; i < 10; i++) { // Try at most 10 times
      Node a = nodes.get ((int) random (nodes.size ()));
      Node b = nodes.get ((int) random (nodes.size ()));
      
      if (a.layer != b.layer) {
        if (a.layer > b.layer) { // Switch a and b
          Node t = a;
          a = b;
          b = t;
        }
        
        boolean c = false;
        
        for (Connector co : a.o) {
          if (co.output == b) {
            c = true;
            break;
          }
        }
        
        if (c)
          continue;
          
        Connector co = new Connector (b, random (1) < 0.5f);
        co.input = a;
        co.outputOne = (random (1) < 0.5f);
        connectors.add (co);
        a.o.add (co);
        break;
      }
    }
  }
  
  void removeConnector() {
    if (connectors.size () == 0)
      return;
    Connector c = connectors.get ((int) random (connectors.size ()));
    c.input.o.remove (c.input.o.indexOf (c));
    connectors.remove (c);
  }
  
  void cleanup () { // Cleanup to do after mutating. We don't want any creatures crashing the testing environment.
    boolean c; // Should cleanup be repeated?
    int j = 0; // Loop counter
    
    do {
      c = false;
      j ++;
      
      if (nodes.indexOf (outputNode) == -1) {
        println ("OUTPUT NODE DELETED! fixing...");
        printDebugOutput ();
        nodes.add (outputNode);
      }
      
      for (Node n : nodes) { // Cycle trough all Nodes
        if (n.layer == 10) { // Output node
          boolean a = false;
          for (Connector co : connectors) {
             if (co.output != null && co.output == n) {
               a = true;
               break;
             }
          }
          
          if (!a) { // The output Node has no inputs! Create a random connection for that.
            int b = 0;
            
            do {
              b = (int) random (nodes.size ());
            } while (nodes.get (b).layer == 10);
            
            Connector co = new Connector(n, random (1) < 0.5f);
            co.input = nodes.get (b);
            co.outputOne = random (1) < 0.5f;
            nodes.get (b).o.add (co);
            connectors.add (co);
            c = true;
          }
          
          continue;
        }
        
        if (n.o.size () == 0) { // This Node has no outputs! Create a random connection for that.
          c = true;
          boolean a = true;
          while (a) {
            Node b = nodes.get((int) random (nodes.size ()));
            if (b.layer > n.layer) {
              a = false;
              Connector co = new Connector (b, random (1) < 0.5f);
              co.input = n;
              co.outputOne = random (1) < 0.5f;
              n.o.add (co);
              connectors.add (co);
            }
          }
        } else { // Check for deleted connectors on output
          for (int i = n.o.size () - 1; i >= 0; i--) { // Check for broken connectors
            Connector co = n.o.get (i);
            if (co == null || co.output == null) {
              c = true;
              n.o.remove(i);
            } else if (co.input != n) { // Connector isn't referencing itself back to the Node (or is referencing to another Node, which is much worse). Also, this shouldn't happen.
              c = true;
              int a = 0;
              for (Node no : nodes) { // Count the references just to be sure.
                if (no.o.indexOf(co) != -1) // Connector is marked in the output list of the node
                  a++;
              }
              
              if (a == 0) { // Ughhhhhh - There should be at least one reference (the current iterating Node n)
                println("Warning: code not working properly in dereferenced connectors (0 references to a detected faulty connector). Deleting connector.");
                if (connectors.indexOf (co) != -1) { // Can't trust this connector any more - maybe it was deleted??
                  connectors.remove (connectors.indexOf (co)); // Remove the Connecor
                }
              } else if (a == 1) { // Ok, there is just a random dereference. We can work around it here
                println("Warning: connector / node dereference: connector does not reference the only node that has it as its output. Fixing.");
                co.input = n; // Fix the reference
              } else { // More than one reference?? Let's just delete the connector and let the cleanup figure this out
                println("Warning: connector / node dereference: connector referenced by " + a + " nodes (forgot to remove output reference from Node?). Deleting connector.");
                for (Node no : nodes) {
                  if (no.o.indexOf(co) != -1) // Connector is marked in the output list of the node
                    no.o.remove (no.o.indexOf (co)); // Remove the connector from the list
                }
                
                if (connectors.indexOf (co) != -1) { // Can't trust this connector any more - maybe it was deleted??
                  connectors.remove (connectors.indexOf (co)); // Remove the Connecor
                }
              }
            }
          }
        }
      }
      
      for (int i = connectors.size () - 1; i >= 0; i--) { // Check for broken Connectors
        Connector co = connectors.get (i);
        if (co == null || co.output == null || co.input == null) { // Invalid Connector (after main Node / Connector fixing)
          c = true;
          connectors.remove(i);
        } else if (co.input.layer >= co.output.layer) {
          println ("Warning: invalid connector: connector not following feed-forward. Deleting connector...");
          throw new NullPointerException ();
          //connectors.remove (i);
        } else {
          boolean a = true;
          for (Node n : nodes) { // See if this Connector is referenced
            if (n.o.indexOf(co) != -1) {
              a = false;
              break;
            }
          }
          
          if (a) { // Connector isn't referenced by any Nodes, yet it has a valid input Node. Connect the two, I guess?
            c = true;
            println("Warning: connector / node dereference: valid connector not referenced by any nodes. Fixing.");
            co.input.o.add(co);
          }
        }
      }
    } while (c && j < 100);
    
    if (j == 100) {
      println ("Too many iterations for cleanup. Printing end result");
      printDebugOutput ();
    }
    
    calculateNodeOffsets();
  }
  
  void calculateNodeOffsets () {
    int[] layerCounts = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    for (Node n : nodes) {
      if (n.layer < 10) { // Normal Node
        n.yOffset = layerCounts[n.layer + 1] * (nodeSize + 10) + 10;
        layerCounts[n.layer + 1] ++;
      } else if (n.layer == 10){ // Output node
        n.yOffset = 10;
      }
    }
  }
  
  public void printDebugOutput () {
    println ("Begin debug output" + (creatureId == 200 ? "" : (" for generation id " + (generations.size () - 1) + " creature id " + creatureId + ":")));
      
      println ("Nodes:");
      for (Node n : nodes) {
        if (n instanceof ScreenNode) {
          println ("Screen node (" + ((ScreenNode) n).x + ", " + ((ScreenNode) n).y + "): type: " + (((ScreenNode) n).triangle ? "triangle" : "box") + "; outputs to layer" + (n.o.size () > 1 ? "s:" : ((n.o.size () == 1)? " " + n.o.get (0).output.layer : " -")));
        } else {
          println ((n.layer == 10 ? "Output" : "Regular") + " node on layer " + n.layer + (n.layer == 10 ? "" : ", outputs to layer" + (n.o.size () > 1 ? "s:" : ((n.o.size () == 1)? " " + n.o.get (0).output.layer : " -"))));
        }
        
        if (n.o.size () > 1) {
          for (Connector c : n.o) {
            println (c.output.layer);
          }
        }
      }
      
      println ("Connectors:");
      for (Connector c : connectors) {
        println ("Connector connecting nodes from layer " + c.input.layer + " to layer " + c.output.layer);
        if (c.output.layer <= c.input.layer) {
          println ("Invalid connector layering detected: printing node info");
          println ("Input:");
          if (c.input instanceof ScreenNode) {
            println ("Screen node (" + ((ScreenNode) c.input).x + ", " + ((ScreenNode) c.input).y + "): type: " + (((ScreenNode) c.input).triangle ? "triangle" : "box") + "; outputs to layer" + (c.input.o.size () > 1 ? "s:" : " " + c.input.o.get (0).output.layer));
          } else {
            println ((c.input.layer == 10 ? "Output" : "Regular") + " node on layer " + c.input.layer + (c.input.layer == 10 ? "" : ", outputs to layer" + (c.input.o.size () > 1 ? "s:" : " " + c.input.o.get (0).output.layer)));
          }
          
          println ("Output:");
          if (c.output instanceof ScreenNode) {
            println ("Screen node (" + ((ScreenNode) c.output).x + ", " + ((ScreenNode) c.output).y + "): type: " + (((ScreenNode) c.output).triangle ? "triangle" : "box") + "; outputs to layer" + (c.output.o.size () > 1 ? "s:" : " " + c.output.o.get (0).output.layer));
          } else {
            println ((c.output.layer == 10 ? "Output" : "Regular") + " node on layer " + c.output.layer + (c.output.layer == 10 ? "" : ", outputs to layer" + (c.output.o.size () > 1 ? "s:" : " " + c.output.o.get (0).output.layer)));
          }
          
        }
        
      }
  }
  
  public void draw () {
    
    PGraphics nodeGraphics = createGraphics (sidebarWidth, 350);
    
    nodeGraphics.beginDraw ();
    for (Node n : nodes) {
      if (n.layer == -1 && networkDrawMode == 1) { // Draw a ScreenNode
        n.draw (null);
        for (Connector c : n.o) {
          c.draw ();
        }
      } else if (n.layer < 10 && n.layer > -1 && networkDrawMode != 2) { // Draw a normal Node
        n.draw (nodeGraphics);
        for (Connector c : n.o) {
          c.draw ();
        }
      } else if (n.layer == 10){ // Draw the output node
        n.draw (nodeGraphics);
      }
    }
    nodeGraphics.endDraw ();
    image (nodeGraphics, sizeX + 1, 200);
  }
}
