// ====================== Virtual Aquarium (Processing) =======================
// Main driver code: globals, setup/draw loop, controls, UI, background, helpers
// ===========================================================================

// ---- Global variables ----
boolean isNight = false;
ArrayList<Fish> fish;
ArrayList<Food> foods;

// ---- Config (visible to Entities.pde) ----
final int NUM_FISH = 20;          // >= 15 as per assignment
final float WALL_MARGIN = 60;
final float WALL_PUSH   = 0.30f;
final float MAX_FORCE   = 0.15f;
final float WANDER_JITTER = 0.15f;
final float FRICTION    = 0.98f;

final float PREDATOR_RADIUS   = 220;   // mouse scares fish within this range
final float FOOD_SENSE_RADIUS = 160;   // fish detect food within this range
final float EAT_RADIUS        = 12;

final int   FOOD_PER_CLICK = 5;
final float FOOD_SINK_SPEED = 0.5f;
final float FOOD_LIFETIME   = 18_000;  // ms

void setup() {
  size(1280, 720, P2D);
  frameRate(60);
  smooth(4);

  fish  = new ArrayList<Fish>();
  foods = new ArrayList<Food>();
  spawnSchool();
}

void draw() {
  drawBackground();  // environment
  updateFish();      // fish animation & behavior
  updateFood();      // food animation
  drawUI();          // overlay (HUD)
}

// ---------------- Simulation  ----------------
void updateFish() {
  PVector predator = new PVector(mouseX, mouseY);

  for (Fish f : fish) {
    f.Behaviors(foods, predator);
    f.update();
    f.render();
  }
}

void updateFood() {
  for (int i = foods.size()-1; i >= 0; i--) {
    Food fp = foods.get(i);
    fp.update();
    fp.render();
    if (fp.isDead()) foods.remove(i);
  }
}

// ---------------- Controls ----------------
// Left click: drop food; D: Day/Night; F: Feed all; R: Reset
void mousePressed() {
  for (int i = 0; i < FOOD_PER_CLICK; i++) {
    float r  = random(0, 20);
    float a  = random(TWO_PI);
    float fx = mouseX + cos(a)*r;
    float fy = mouseY + sin(a)*r;
    foods.add(new Food(fx, fy));
  }
}

void keyPressed() {
  if (key == 'd' || key == 'D') {
    isNight = !isNight;
  } else if (key == 'f' || key == 'F') {
    for (Fish f : fish) {
      f.hunger = min(100, f.hunger + 40); // feed all fish
    }
  } else if (key == 'r' || key == 'R') {
    fish.clear();
    foods.clear();
    spawnSchool();
  }
}

void spawnSchool() {
  for (int i = 0; i < NUM_FISH; i++) {
    fish.add(new Fish(
      new PVector(random(width), random(height)),
      PVector.random2D().mult(random(0.5f, 2.5f)),
      randomFishColor()
    ));
  }
}

// ---------------- Background  ----------------
void drawBackground() {
  // Day and night color palettes
  color topDay = color(80, 180, 250);
  color bottomDay = color(180, 230, 255);
  color topNight = color(15, 40, 80);
  color bottomNight = color(30, 60, 100);

  // Pick based on day/night mode
  color topColor = isNight ? topNight : topDay;
  color bottomColor = isNight ? bottomNight : bottomDay;

  // Vertical gradient background
  for (int y = 0; y < height; y++) {
    float t = map(y, 0, height, 0, 1);
    stroke(lerpColor(topColor, bottomColor, t));
    line(0, y, width, y);
  }

  // Light rays / ambient strips
  noStroke();
  fill(255, isNight ? 15 : 40);
  float lightY = (sin(millis() * 0.0015f) * 0.5f + 0.5f) * height;
  rect(0, lightY, width, 10);
  rect(0, lightY * 0.7f + 40, width, 8);

  // Subtle bubble effect
  for (int i = 0; i < 6; i++) {
    float bx = (frameCount * 2 + i * 150) % width;
    float by = (millis() * 0.04f + i * 60) % height;
    fill(255, 255, 255, isNight ? 40 : 80);
    ellipse(bx, height - (by % height), 6, 6);
  }
}

// ---------------- UI / HUD  ----------------
void drawUI() {
  // Panel
  fill(0, 120);
  noStroke();
  rect(10, 10, 320, 95, 10);

  // Text
  fill(255);
  textSize(14);
  textAlign(LEFT, TOP);

  text("Virtual Aquarium", 20, 18);
  text("Fish: " + fish.size(), 20, 40);
  text("Food: " + foods.size(), 120, 40);
  text("FPS: " + nf(frameRate, 1, 1), 220, 40);

  textSize(12);
  text("Controls:", 20, 62);
  text("Click = Drop food", 100, 62);
  text("Move mouse = Scare fish", 100, 76);
  text("D = Day/Night | F = Feed all | R = Reset", 100, 90);

  textAlign(RIGHT, TOP);
  text(isNight ? "Night Mode" : "Day Mode", width - 20, 20);
}

// ---------------- Helpers ----------------
int randomFishColor() {
  if (!isNight) {
    return color(random(180,255), random(120,220), random(80,200));
  } else {
    return color(random(100,200), random(80,160), random(60,160));
  }
}
