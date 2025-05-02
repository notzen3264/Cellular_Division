int NUM_PARTICLES = 6500;
int GRID_SIZE = 50;
float TRAIL_ALPHA = 50;
float ALPHA = 180;
float BETA = 17;
float GAMMA = 13.4;
float RADIUS = 15;

Species[] species;
ArrayList<Particle> particles;
ArrayList<Particle>[][] grid;
int cols, rows;
int startMillis;

int DENSITY_THRESHOLD = 20;
ArrayList<Integer> cellHistory;
int CELLS_INTERVAL = 25;
int frameCounter = 0;
int lastCellCount = 0;

void setup() {
   try {
      size(screenWidth, screenHeight, P2D);
      frameRate(60);
      
      species = new Species[1];
      species[0] = new Species(ALPHA, BETA, GAMMA, RADIUS);
      
      particles = new ArrayList<Particle>();
      for (int i = 0; i < NUM_PARTICLES; i++) {
         particles.add(new Particle(i));
      }
      
      cols = ceil(width / GRID_SIZE);
      rows = ceil(height / GRID_SIZE);
      grid = new ArrayList[cols][rows];
      for (int i = 0; i < cols; i++) {
         for (int j = 0; j < rows; j++) {
            grid[i][j] = new ArrayList<Particle>();
         }
      }
      
      background(0);
      startMillis = millis();
      cellHistory = new ArrayList<Integer>();
   } catch (Exception e) {
      println("Error in setup(): " + e);
   }
}

void draw() {
   try {
      frameCounter++;
      noStroke();
      fill(0, TRAIL_ALPHA);
      rect(0, 0, width, height);
      
      for (int i = 0; i < cols; i++) {
         for (int j = 0; j < rows; j++) {
            grid[i][j].clear();
         }
      }
      
      for (Particle p : particles) {
         int gx = constrain(floor(p.x / GRID_SIZE), 0, cols - 1);
         int gy = constrain(floor(p.y / GRID_SIZE), 0, rows - 1);
         grid[gx][gy].add(p);
         p.visited = false;
      }
      
      strokeWeight(2);
      for (Particle p : particles) {
         p.countNeighbors();
         p.highDensity = (p.N >= DENSITY_THRESHOLD);
         p.move();
         p.display();
      }
      
      if (frameCounter % CELLS_INTERVAL == 0) {
         lastCellCount = computeCells();
      }
      
      cellHistory.add(lastCellCount);
      if (cellHistory.size() > width) {
         cellHistory.remove(0);
      }
      
      fill(255);
      textSize(13);
      textAlign(LEFT, BASELINE);
      text("FPS: " + nf(frameRate, 1, 1), 10, 30);
      int elapsed = (millis() - startMillis) / 1000;
      text("Time: " + round(elapsed % 60) + "s", 10, 60);
      text("Estimated Cell Count: " + lastCellCount, 10, 90);
      
      textAlign(RIGHT, BASELINE);
      text("GREEN particles are nutrients", width - 10, 30);
      text("BROWN particles are premature spores", width - 10, 60);
      text("MAGENTA particles are matured spores", width - 10, 90);
      text("BLUE particles are cell membrane", width - 10, 120);
      text("YELLOW particles are cell nuclei", width - 10, 150);
      text("This particle simulation framework replicates the entire cell cycle of a virtual cell, including interphase, mitosis, and cytokinesis. These natural phases within the model occur organically without being explicitly hardcoded. Instead, these specific phases arise from the interaction of simple parameters governing the behaviors of particles, " +
      "thus giving birth to these emergent 'protocell organisms.' An expansive, multidimensional space of potential organisms is probable due to the model's parametrization. In summary, the concept described by the explanation of this ecosystem is ultimately emergence: the process of coming into existence or prominence. Within this context, " +
      "one may refer to this phenomenon as 'abiogenesis.' (the process by which living organisms evolve from inanimate or dead matter).", width - 310, 180, 300, 1000);
      
      drawGraph();
   } catch (Exception e) {
      println("Error in draw(): " + e);
   }
}

int computeCells() {
   try {
      int count = 0;
      for (Particle p : particles) {
         if (p.highDensity && !p.visited) {
            floodFill(p);
            count++;
         }
      }
      for (Particle p : particles) {
         p.visited = false;
      }
      return count;
   } catch (Exception e) {
      println("Error in computeCells(): " + e);
      return 0;
   }
}

void drawGraph() {
   try {
      int gh = 150, x0 = 50, y0 = height - gh - 40;
      int gw = width / 3 - x0 - 10;
      noStroke();
      fill(0, 100);
      rect(x0, y0, gw, gh);
      
      int hs = cellHistory.size();
      int denom = max(1, hs - 1);
      
      // Manual max computation in cellHistory.
      int rawMax = 0;
      for (int i = 0; i < cellHistory.size(); i++) {
         rawMax = max(rawMax, cellHistory.get(i));
      }
      int maxC = max(1, rawMax);
      
      stroke(255);
      line(x0, y0, x0, y0 + gh);
      line(x0, y0 + gh, x0 + gw, y0 + gh);
      
      textSize(12);
      fill(255);
      textAlign(CENTER, CENTER);
      text("Frame Index", x0 + gw/2, y0 + gh + 20);
      pushMatrix();
      translate(x0 - 30, y0 + gh/2);
      rotate(-HALF_PI);
      text("Estimated Cell Count", 0, 0);
      popMatrix();
      
      stroke(255, 0, 0);
      noFill();
      beginShape();
      for (int i = 0; i < hs; i++) {
         float x = map(i, 0, denom, x0, x0 + gw);
         float y = map(cellHistory.get(i), 0, maxC, y0 + gh, y0);
         vertex(x, y);
      }
      endShape();
      
      fill(255);
      textAlign(RIGHT, CENTER);
      text("0", x0 - 5, y0 + gh);
      text(str(maxC), x0 - 5, y0);
   } catch (Exception e) {
      println("Error in drawGraph(): " + e);
   }
}

void floodFill(Particle seed) {
   try {
      ArrayList<Particle> stack = new ArrayList<Particle>();
      seed.visited = true;
      stack.add(seed);
      while (!stack.isEmpty()) {
         Particle cur = stack.remove(stack.size() - 1);
         int gx = floor(cur.x / GRID_SIZE), gy = floor(cur.y / GRID_SIZE);
         for (int i = -1; i <= 1; i++) {
            for (int j = -1; j <= 1; j++) {
               int nx = (gx + i + cols) % cols, ny = (gy + j + rows) % rows;
               for (Particle q : grid[nx][ny]) {
                  if (!q.visited && q.highDensity) {
                     float dx = q.x - cur.x, dy = q.y - cur.y;
                     if (dx > width / 2)
                     dx -= width;
                     if (dx < -width / 2)
                     dx += width;
                     if (dy > height / 2)
                     dy -= height;
                     if (dy < -height / 2)
                     dy += height;
                     if (dx * dx + dy * dy <= species[cur.speciesIdx].r2) {
                        q.visited = true;
                        stack.add(q);
                     }
                  }
               }
            }
         }
      }
   } catch (Exception e) {
      println("Error in floodFill(): " + e);
   }
}

class Species {
   float alphaRad, betaRad, v, r2;
   Species(float a, float b, float g, float r) {
      try {
         alphaRad = radians(a);
         betaRad = radians(b);
         v = r * g / 100;
         r2 = sq(r);
      } catch (Exception e) {
         println("Error in Species constructor: " + e);
      }
   }
}

class Particle {
   float x, y, phi, phiSin, phiCos;
   int N, L, R, N_small;
   boolean highDensity, visited;
   int speciesIdx;
   
   Particle(int idx) {
      try {
         x = random(width);
         y = random(height);
         phi = random(TWO_PI);
         phiSin = sin(phi);
         phiCos = cos(phi);
         speciesIdx = idx % species.length;
         visited = false;
      } catch (Exception e) {
         println("Error in Particle constructor: " + e);
      }
   }
   
   void countNeighbors() {
      try {
         N = L = R = N_small = 0;
         int gx = floor(x / GRID_SIZE), gy = floor(y / GRID_SIZE);
         for (int i = -1; i <= 1; i++) {
            for (int j = -1; j <= 1; j++) {
               int nx = (gx + i + cols) % cols, ny = (gy + j + rows) % rows;
               for (Particle q : grid[nx][ny]) {
                  if (q == this)
                  continue;
                  float dx = q.x - x, dy = q.y - y;
                  if (dx > width / 2)
                  dx -= width;
                  if (dx < -width / 2)
                  dx += width;
                  if (dy > height / 2)
                  dy -= height;
                  if (dy < -height / 2)
                  dy += height;
                  float d2 = dx * dx + dy * dy;
                  if (d2 <= species[speciesIdx].r2) {
                     if (dx * phiSin - dy * phiCos > 0)
                     L++;
                     else
                     R++;
                     N++;
                  }
                  if (d2 <= sq(3.9))
                  N_small++;
               }
            }
         }
      } catch (Exception e) {
         println("Error in Particle.countNeighbors() for particle idx " + speciesIdx + ": " + e);
      }
   }
   
   void move() {
      try {
         Species sp = species[speciesIdx];
         float turn = sp.alphaRad + sp.betaRad * N * (R > L ? 1 : (R < L ? -1 : 0));
         phi = (phi + turn) % TWO_PI;
         phiSin = sin(phi);
         phiCos = cos(phi);
         x = (x + sp.v * phiCos + width) % width;
         y = (y + sp.v * phiSin + height) % height;
      } catch (Exception e) {
         println("Error in Particle.move() for particle idx " + speciesIdx + ": " + e);
      }
   }
   
   void display() {
      try {
         colorMode(RGB, 255);
         strokeWeight(2);
         if (N_small > 15)
         stroke(255, 0, 255);
         else if (N > 15 && N <= 35)
         stroke(0, 0, 255);
         else if (N > 35)
         stroke(255, 255, 0);
         else if (N >= 13 && N <= 15)
         stroke(139, 69, 19);
         else
         stroke(0, 255, 0);
         
         point(x, y);
      } catch (Exception e) {
         println("Error in Particle.display() for particle idx " + speciesIdx + ": " + e);
      }
   }
}