// =============================== Fish ===============================
class Fish {
  PVector pos, vel, acc;
  float angle;
  float size;
  int bodyColor;

  // Hunger/Energy: 0..100 affects speed & color
  float hunger = random(50, 100);
  float hungerDrain = random(0.01f, 0.03f);
  float baseMaxSpeed = random(2.2f, 3.2f);

  Fish(PVector p, PVector v, int c) {
    pos = p.copy();
    vel = v.copy();
    acc = new PVector(0, 0);
    size = random(16, 26);
    bodyColor = c;
  }

  void Behaviors(ArrayList<Food> foods, PVector predator) {
    acc.mult(0);

    // Wander (random drift)
    PVector wander = PVector.random2D().mult(WANDER_JITTER);

    // Wall avoidance (stronger)
    PVector Boundry = wallAvoidance();

    // Seek nearest food if within sense radius; eat when close
    PVector seekFood = new PVector(0, 0);
    Food nearest = foodnearby(foods);
    if (nearest != null) {
      float d = PVector.dist(pos, nearest.pos);
      float seekWeight = map(hunger, 0, 100, 1.5f, 0.5f);
      seekWeight += map(constrain(d, 0, FOOD_SENSE_RADIUS), FOOD_SENSE_RADIUS, 0, 0, 1.2f);
      seekFood = steer(nearest.pos).mult(1.1f * seekWeight);

      if (d < EAT_RADIUS + size*0.3f) {
        hunger = min(100, hunger + nearest.nutrition);
        nearest.consume();
      }
    }

    // Flee predator (mouse)
    PVector flee = new PVector(0, 0);
    if (predator != null) {
      float d = PVector.dist(pos, predator);
      if (d < PREDATOR_RADIUS) {
        PVector away = PVector.sub(pos, predator).normalize();
        away.mult(map(d, 0, PREDATOR_RADIUS, 3.0f, 0.4f));
        flee.add(away);
      }
    }

    // Combine weighted forces
    acc.add(wander);
    acc.add(Boundry.mult(1.0f));
    acc.add(seekFood);
    acc.add(flee.mult(1.6f));

    if (acc.mag() > MAX_FORCE) acc.setMag(MAX_FORCE);
  }

  void update() {
    hunger = max(0, hunger - hungerDrain);

    float maxSpeed = map(hunger, 0, 100, baseMaxSpeed*0.55f, baseMaxSpeed);
    vel.add(acc);
    if (vel.mag() > maxSpeed) vel.setMag(maxSpeed);
    vel.mult(FRICTION);
    pos.add(vel);

    // Stay inside bounds with gentle bounce
    pos.x = constrain(pos.x, 2, width - 2);
    pos.y = constrain(pos.y, 2, height - 2);
    if (pos.x <= 2 && vel.x < 0) vel.x *= -0.4f;
    if (pos.x >= width - 2 && vel.x > 0) vel.x *= -0.4f;
    if (pos.y <= 2 && vel.y < 0) vel.y *= -0.4f;
    if (pos.y >= height - 2 && vel.y > 0) vel.y *= -0.4f;

    angle = atan2(vel.y, vel.x);
  }

  void render() {
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(angle);

    noStroke();
    int c = (hunger < 20) ? lerpColor(bodyColor, color(60), 0.5f) : bodyColor;
    fill(c);
    float b = size;
    ellipse(0, 0, b*1.6, b);
    triangle(b*0.6, 0, b*1.15, -b*0.4, b*1.15, b*0.4);
    fill(255);
    ellipse(-b*0.55, -b*0.2, b*0.25, b*0.25);
    fill(0);
    ellipse(-b*0.55, -b*0.2, b*0.12, b*0.12);
    popMatrix();

    // Hunger bar
    float barW = 36;
    float barH = 5;
    float x = pos.x - barW/2;
    float y = pos.y - size*0.9f - 10;
    stroke(0, 100);
    fill(255, 60);
    rect(x, y, barW, barH, 3);
    float pct = hunger / 100.0f;
    int barCol = (pct > 0.6) ? color(80, 200, 80) :
                 (pct > 0.3) ? color(240, 200, 60) :
                                color(220, 70, 70);
    noStroke();
    fill(barCol);
    rect(x, y, barW*pct, barH, 3);
  }

  // ---------- internal helpers ----------
  PVector wallAvoidance() {
    PVector steer = new PVector(0, 0);
    float left = pos.x;
    float right = width - pos.x;
    float top = pos.y;
    float bottom = height - pos.y;

    if (left < WALL_MARGIN) steer.x += WALL_PUSH * (1 - left / WALL_MARGIN);
    if (right < WALL_MARGIN) steer.x -= WALL_PUSH * (1 - right / WALL_MARGIN);
    if (top < WALL_MARGIN) steer.y += WALL_PUSH * (1 - top / WALL_MARGIN);
    if (bottom < WALL_MARGIN) steer.y -= WALL_PUSH * (1 - bottom / WALL_MARGIN);

    if (steer.mag() > MAX_FORCE) steer.setMag(MAX_FORCE);
    return steer;
  }

  Food foodnearby(ArrayList<Food> foods) {
    Food best = null;
    float bestD = FOOD_SENSE_RADIUS;
    for (Food f : foods) {
      if (f.dead) continue;
      float d = PVector.dist(pos, f.pos);
      if (d < bestD) {
        bestD = d;
        best = f;
      }
    }
    return best;
  }

  PVector steer(PVector target) {
    PVector desired = PVector.sub(target, pos);
    float d = desired.mag();
    if (d == 0) return new PVector(0, 0);
    desired.normalize();
    float maxSpeed = map(hunger, 0, 100, baseMaxSpeed*0.55f, baseMaxSpeed);
    if (d < 120) desired.mult(map(d, 0, 120, 0, maxSpeed));
    else desired.mult(maxSpeed);
    PVector steer = PVector.sub(desired, vel);
    if (steer.mag() > MAX_FORCE) steer.setMag(MAX_FORCE);
    return steer;
  }
}

// =============================== Food ===============================
class Food {
  PVector pos;
  float createdAt;
  boolean dead = false;
  float nutrition = random(20, 40); // hunger restored when eaten

  Food(float x, float y) {
    pos = new PVector(x, y);
    createdAt = millis();
  }

  void update() {
    pos.y += FOOD_SINK_SPEED;
    pos.x += sin((millis() + createdAt) * 0.002f) * 0.2f;

    pos.x = constrain(pos.x, 5, width - 5);
    pos.y = constrain(pos.y, 5, height - 5);
  }

  void render() {
    float age = millis() - createdAt;
    float lifeT = constrain(map(age, 0, FOOD_LIFETIME, 1, 0), 0, 1);
    noStroke();
    fill(255, 220, 90, 220 * lifeT + 25);
    ellipse(pos.x, pos.y, 8, 8);
  }

  void consume() {
    dead = true;
  }

  boolean isDead() {
    return dead || (millis() - createdAt) > FOOD_LIFETIME;
  }
}
