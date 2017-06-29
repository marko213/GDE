class Generation {

  static final int creaturesPerGen = 300; // Amount of creatures per generation (keep even)
  public Creature[] creatures;

  public Generation () {
    creatures = new Creature[creaturesPerGen];

    for (int i = 0; i < creaturesPerGen; i++) {
      creatures[i] = new Creature ();
      creatures[i].initRandomize ();
    }
  }

  public Generation (Creature[] c) {
    creatures = new Creature[creaturesPerGen];
    for (int i = 0; i < creaturesPerGen; i++) {

      creatures[i] = c[i].clone ();
    }
  }

  public void sortCreaturesAndCreateNew () {
    ArrayList<Creature> c = new ArrayList<Creature> (200);
    for (Creature cr : creatures) {
      c.add (cr);
    }
    
    // Randomize the list
    ArrayList<Creature> n = new ArrayList<Creature> (200);
    while (!c.isEmpty ()) {
      int a = (int) random (c.size ());
      n.add (c.get (a));
      c.remove (a);
    }
    
    n = quickSort (n);
    
    drawSingle (n);
    
    int[] t = new int[2];
    t[0] = n.get (0).fitness;
    t[1] = n.get (n.size () / 2).fitness;
    records.add (t);
    drawGens ();
    
    ArrayList<Creature> cr = new ArrayList<Creature> (100);
    
    // Killing code heavily inspired by evolutionMath2 by carykh
    for (int i = 0; i < creaturesPerGen / 2; i++) { // Kill half of the creatures (more slower ones, but not necessarily just slower ones)
      if (float (i) / creaturesPerGen <= (pow (random (-1, 1), 3) + 1) / 2) // Kill a slower creature
        cr.add (n.get (i));
      else // Kill a faster creature
        cr.add (n.get (creaturesPerGen - i - 1));
    }
    
    creatures = cr.toArray (creatures);
    
    for (int i = 0; i < creaturesPerGen / 2; i++) { // Clone and mutate said clones
      
      Creature m = creatures[i].clone ();
      
      m.nrmlRandomize ();
      
      creatures [creaturesPerGen / 2 + i] = m;
      
    }
  }

  ArrayList<Creature> quickSort (ArrayList<Creature> c) {
    
    if (c.size () <= 1) {
      return c;
    }

    int comp = c.get (0).fitness;
    ArrayList<Creature> g = new ArrayList<Creature> ();
    ArrayList<Creature> e = new ArrayList<Creature> ();
    ArrayList<Creature> l = new ArrayList<Creature> ();
    for (Creature cr : c) {
      if (cr.fitness < comp) {
        l.add (cr);
      } else if (cr.fitness > comp) {
        g.add (cr);
      } else {
        e.add (cr);
      }
    }
    
    
    
    e.addAll (quickSort (l));
    g = quickSort (g);
    g.addAll (e);
    return g;
  }
}

