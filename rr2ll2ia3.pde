// --- Constants and Parameters --- (These will be randomized on refresh)
int UNIVERSE_SIZE = 120;
float baseMutationRate = 5;
float mutationRateRange = 2;
float reproductionThreshold;
float interactionRadius = 20; // Initial value, will be randomized
int GENE_MIN = -18;
int GENE_MAX = 18;
float CELL_RADIUS = 10;       // Initial value, will be randomized
float minRadius = 2;           // Minimum cell radius
float maxRadius;           // Maximum cell radius
int BACKGROUND_COLOR;
float FRAME_RATE = 12;
float baseMaxSpeed = 0.2f; // Base max speed
float maxSpeedVariation = 5f; //  Variation in speed
float energyConsumptionRate = 0.58f;
float energyGainFromInteraction = 0.004f;
float minEnergyForReproduction = 8;

// --- Metaball Parameters ---
float THRESHOLD = 0.2f;
float metaballStrength = 0.02f;

// --- Environmental Factors ---
float foodDensity = 0.025f;
float foodEnergyValue = 5.0f;
ArrayList<PVector> foodParticles = new ArrayList<PVector>();

// --- Refresh Parameters ---
float minRefreshInterval = 6; // seconds
float maxRefreshInterval = 12; // seconds
float refreshInterval; // Current refresh interval
int lastRefreshTime;    // Time of the last refresh (in milliseconds)

// --- Speed Modification Zone ---
float slowDownRadius = 20;
float speedReductionFactor = 50.3f;

// --- Color Palette Change Parameters ---
// --- Available Colors ---
int[] availableBackgroundColors = {
  color(255),   // White
  color(0),     // Black
  color(255, 0, 0), // Red
  color(0, 255, 0), // Green
  color(0, 0, 255)  // Blue
};
int backgroundColorIndex = 0; // Start with white

int redColor;
int greenColor;
int blueColor;

// --- Color Transition Parameters ---
float colorTransitionSpeed = 0.6f; // Adjust for desired transition speed

int targetBackgroundColor;
int targetRedColor, targetGreenColor, targetBlueColor;

// --- Cell Representation ---
class Cell {
    PVector position;
    PVector velocity;
    int gene;
    boolean alive;
    float radius;
    float energy;
    float mutationRate;
    float maxSpeed; // Individual max speed

    Cell(float x, float y, int gene, float mutationRate) {
        this.position = new PVector(x, y);
        this.velocity = PVector.random2D();
        // Calculate individual maxSpeed using random()
        this.maxSpeed = baseMaxSpeed + random(-maxSpeedVariation, maxSpeedVariation);
        // Ensure maxSpeed is not negative
        this.maxSpeed = max(0, this.maxSpeed); // Important!
        this.velocity.mult(this.maxSpeed);
        this.gene = gene;
        this.alive = true;
        this.radius = CELL_RADIUS;
        this.energy = 12;
        this.mutationRate = mutationRate;
    }

    void update() {
        if (alive) {
            // Check if cell is near the mouse and reduce speed
            float distanceToMouse = dist(position.x, position.y, mouseX, mouseY);
            float speedModifier = 1.0f; // Default is no modification
            if (distanceToMouse < slowDownRadius) {
                speedModifier = speedReductionFactor; // Reduce speed
            }

            velocity.add(PVector.random2D().mult(0.2f * speedModifier));
            velocity.limit(this.maxSpeed * speedModifier); // Use individual maxSpeed
            position.add(velocity);

            // Wrap-around boundaries
            // position.x = (position.x + width) % width;
            // position.y = (position.y + height) % height;

            energy -= energyConsumptionRate;
            if (energy <= 0) {
                alive = false;
            }
            eatFood();
        }
    }

    void interact(Cell other) {
        if (this == other || !this.alive || !other.alive) return;

        float distance = PVector.dist(this.position, other.position);

        if (distance < interactionRadius) {
            float influence = map(distance, 0, interactionRadius, 1, 0);
            int geneChange = (int)(influence * (other.gene - this.gene) * 0.1);

            float energyTransfer = energyGainFromInteraction * influence * (1 - abs(this.gene - other.gene) / (float)(GENE_MAX - GENE_MIN));
            this.energy += energyTransfer;
            other.energy -= energyTransfer;

            this.gene = constrain(this.gene + geneChange, GENE_MIN, GENE_MAX);
            other.gene = constrain(other.gene - geneChange, GENE_MIN, GENE_MAX);

            if (distance < (this.radius + other.radius) && abs(this.gene - other.gene) < reproductionThreshold && this.energy > minEnergyForReproduction && other.energy > minEnergyForReproduction) {
                reproduce(other);
            }

            // Collision Response
            PVector collisionNormal = PVector.sub(other.position, this.position).normalize();
            float overlap = (this.radius + other.radius) - distance;
            float separationAmount = overlap * 0.5f;

            this.position.sub(PVector.mult(collisionNormal, separationAmount));
            other.position.add(PVector.mult(collisionNormal, separationAmount));

            PVector thisVelocity = this.velocity.copy();
            PVector otherVelocity = other.velocity.copy();
            float thisDot = thisVelocity.dot(collisionNormal);
            float otherDot = otherVelocity.dot(collisionNormal);
            thisVelocity.sub(PVector.mult(collisionNormal, 2 * thisDot));
            otherVelocity.sub(PVector.mult(collisionNormal, 2 * otherDot));
            this.velocity.lerp(thisVelocity, 0.8f);
            other.velocity.lerp(otherVelocity, 0.8f);
            this.velocity.add(PVector.random2D().mult(0.3f));
            other.velocity.add(PVector.random2D().mult(0.3f));
        }
    }

    void reproduce(Cell other) {
        if (cells.size() < UNIVERSE_SIZE * 4) {
            float energyCost = (minEnergyForReproduction / 2) + 1;
            this.energy -= energyCost;
            other.energy -= energyCost;

            int newGene = (this.gene + other.gene) / 2;
            if (random(100) < this.mutationRate) {
                newGene = mutateGene(newGene);
            }

            float newMutationRate = constrain(this.mutationRate + random(-mutationRateRange, mutationRateRange), 0.5f, 20);

            PVector newPosition = PVector.add(this.position, other.position).div(2);
            newPosition.add(PVector.random2D().mult(this.radius));

            cells.add(new Cell(newPosition.x, newPosition.y, newGene, newMutationRate));
        }
    }

    int mutateGene(int gene) {
        float mutationRoll = random(1);
        int mutationAmount;

        if (mutationRoll < 0.26) {
            mutationAmount = (random(1) < 0.5) ? -1 : 1;
        } else if (mutationRoll < 0.9) {
            mutationAmount = (random(1) < 0.5) ? -2 : 2;
        } else {
            mutationAmount = (random(1) < 0.5) ? -3 : 3;
        }
        int newGene = gene + mutationAmount;
        return constrain(newGene, GENE_MIN, GENE_MAX);
    }

    void checkSurvival() {
        if (gene <= GENE_MIN || gene >= GENE_MAX) {
            alive = false;
        }
        // Loneliness check
        int neighbors = 0;
        for (Cell other : cells) {
            if (other != this && other.alive && PVector.dist(this.position, other.position) < interactionRadius) {
                neighbors++;
            }
        }
        // Modify survival based on neighbors (example: more neighbors = longer lifespan)
        float lifespanBonus = neighbors * 0.5f;  // Example bonus
        if (energy < lifespanBonus) { // If energy is lower than bonus, it could die.
            alive = false;
        }

    }

    void eatFood() {
        for (int i = foodParticles.size() - 1; i >= 0; i--) {
            PVector food = foodParticles.get(i);
            if (PVector.dist(position, food) < radius) {
                energy += foodEnergyValue;
                foodParticles.remove(i);
            }     
        }
    }
}

ArrayList<Cell> cells;

// --- File Watching (Optional) ---
long lastModifiedTime;
String filePath = "rr2ll2ia.pde"; //CHANGE THIS

// --- Font ---
PFont monoFont;

boolean hoveringCell = false; // Track if the mouse is hovering over anything interactable

// --- Axis Line Parameters ---
float fixedGapSize = 36; // The desired fixed gap size.  Adjust as needed

void setup() {
    size(1680/3, 1020/3); // siğ  fullScreen(P2D);
    
    frameRate(FRAME_RATE);
    smooth();
    
    // Set initial values, randomization happens in randomizeSimulation()
    reproductionThreshold = (int) random(0.7, 7);
    maxRadius = (int) random(2, 200);
    BACKGROUND_COLOR = color(255);
    redColor = color(255, 0, 0);
    greenColor = color(0, 255, 0);
    blueColor = color(0, 0, 255);
    
    randomizeSimulation(); // Initialize and randomize parameters
    setNewRefreshInterval(); // Initialize the first refresh interval
    lastRefreshTime = millis(); // Initialize lastRefreshTime

    //lastModifiedTime = new File(filePath).lastModified(); // This doesn't work in core Processing
    println("File watching is not supported in core Processing.");

    // Load a monospaced font
    monoFont = createFont("Monospaced", 16); // Or "Monospaced", "Consolas", etc.

    cursor(); // Set a default cursor
    targetBackgroundColor = BACKGROUND_COLOR; // Init target values
    targetRedColor = redColor;
    targetGreenColor = greenColor;
    targetBlueColor = blueColor;
}

// --- New Function: Randomize Simulation Parameters ---
void randomizeSimulation() {
    cells = new ArrayList<Cell>();
    foodParticles.clear();

    // Randomize parameters
    UNIVERSE_SIZE = (int) random(2, random(2, 100));  // Vary the initial population size
    baseMutationRate = random(2, 8);
    mutationRateRange = random(1, 4);
    interactionRadius = random(10, 30);
    CELL_RADIUS = random(minRadius, maxRadius); // Randomize initial cell radius
    // Optionally randomize other parameters like energyConsumptionRate, etc.

    // Re-initialize cells with new parameters
    for (int i = 0; i < UNIVERSE_SIZE; i++) {
        float initialMutationRate = baseMutationRate + random(-mutationRateRange, mutationRateRange);
        cells.add(new Cell(random(width), random(height), (int)random(GENE_MIN, GENE_MAX + 1), initialMutationRate));
    }

    // Re-initialize food particles
    for (int i = 0; i < width * height * foodDensity / 2; i++) {
        foodParticles.add(new PVector(random(width), random(height)));
    }
}

void setNewRefreshInterval() {
    refreshInterval = random(minRefreshInterval, maxRefreshInterval);
    println("Next refresh in " + refreshInterval + " seconds.");
}

void draw() {
    /*long currentModifiedTime = new File(filePath).lastModified(); // This doesn't work in core Processing
    if (currentModifiedTime > lastModifiedTime) {
        println("File has changed. Restart is highly recommended.");
        lastModifiedTime = currentModifiedTime;
    }*/

    // Gradual Background Color Transition
    BACKGROUND_COLOR = lerpColor(BACKGROUND_COLOR, targetBackgroundColor, colorTransitionSpeed);

    background(BACKGROUND_COLOR);

    // Add food randomly
    if (random(1) < foodDensity) {
        foodParticles.add(new PVector(random(width), random(height)));
    }

    stroke(200, 100, 0);
    strokeWeight(1);
    for (PVector food : foodParticles) {
        point(food.x, food.y);
    }
    strokeWeight(12);
    noStroke();

    // Update, Interact and Clean up Cells
    hoveringCell = false; // Reset hovering state at the beginning of each frame

    for (int i = cells.size() - 1; i >= 0; i--) {
        Cell cell = cells.get(i);
        cell.update();
        cell.checkSurvival();

        // Check for hover *before* interaction to ensure correct cursor
        if (dist(mouseX, mouseY, cell.position.x, cell.position.y) < cell.radius) {
            hoveringCell = true;
            // Draw a highlight (optional)
            stroke(0); // Black outline
            strokeWeight(2);
            noFill();
            ellipse(cell.position.x, cell.position.y, cell.radius * 2, cell.radius * 2);
            noStroke(); // Reset stroke
        }

        for (int j = i - 1; j >= 0; j--) {
            cell.interact(cells.get(j));
        }

        if (!cell.alive) {
            cells.remove(i);
        }
    }

    // --- Metaball Rendering ---
    loadPixels();
    for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
            float sum = 0;
            float red = 0;
            float green = 0;
            float blue = 0;

            for (Cell cell : cells) {
                if (!cell.alive) continue;
                float d = dist(x, y, cell.position.x, cell.position.y);
                float influence = metaballStrength * (cell.radius * cell.radius) / (d * d + 0.0001f);
                sum += influence;

                // Sharpen the influence based on distance.  Key change!
                influence = pow(influence, 2); // Square the influence.  Experiment with this power.

                if (cell.gene > 2) { // Dominant
                    red += influence;
                } else if (cell.gene < -2) { // Recessive
                    green += influence;
                } else { // Neutral
                    blue += influence;
                }
            }

            if (sum > THRESHOLD) {
                // Normalize the color components (important for correct mixing)
                float totalColor = red + green + blue;
                if (totalColor > 0) {
                    red /= totalColor;
                    green /= totalColor;
                    blue /= totalColor;
                }

                // Create the color.  No change here.
                pixels[x + y * width] = color(red * 255, green * 255, blue * 255);
            } else {
                pixels[x + y * width] = BACKGROUND_COLOR;
            }
        }
    }
    updatePixels();

    // --- Timed Random Refresh ---
    if (millis() - lastRefreshTime > refreshInterval * 1000) {
        println("Random refresh!");
        randomizeSimulation();
        setNewRefreshInterval();  // Set a new random interval
        lastRefreshTime = millis(); // Update the last refresh time
    }

    // Gradual Color Transitions
    redColor = lerpColor(redColor, targetRedColor, colorTransitionSpeed);
    greenColor = lerpColor(greenColor, targetGreenColor, colorTransitionSpeed);
    blueColor = lerpColor(blueColor, targetBlueColor, colorTransitionSpeed);

    // --- Display Cell Count ---
    displayCellCount();
    displayCellCounts();
    displayMouseCoordinates(); // Display the mouse coordinates

    // --- Draw Axis Lines ---
    drawAxisLines();

    // --- Cursor Update ---
    updateCursor();
}

void drawAxisLines() {
  strokeWeight(1);

    // Calculate the width of the X coordinate string
    String mouseXString = "" + mouseX;
    float mouseXWidth = textWidth(mouseXString);
    String dcc2 = "" + cells.size();
    float dcc = textWidth(dcc2);

    // Calculate the new dynamic gaps
    float dynamicGapRight = max(fixedGapSize, mouseXWidth + 20);  // Gap for the left side
    float dynamicGapLeft = max(fixedGapSize, dcc + 20);   // Right side uses the fixed gap.
    float dynamicGapX = dynamicGapRight; // Use the left gap for x axis calculation

  
  // Create a temporary PGraphics to draw the lines and then invert the area
  PGraphics axisLines = createGraphics(width, height);
  axisLines.beginDraw();
  axisLines.stroke(0,0);  // Initial line color (doesn't matter, gets inverted)
  axisLines.line(dynamicGapLeft, axisLines.height / 2, axisLines.width - dynamicGapRight, axisLines.height / 2); // X axis
  axisLines.line(axisLines.width / 2, fixedGapSize, axisLines.width / 2, axisLines.height - fixedGapSize); // Y axis - FIXED

  axisLines.endDraw();
  axisLines.noFill();

  // Invert the colors in the area where the lines are drawn on PGraphics
  for (int x = 0; x < axisLines.width; x++) {
    for (int y = 0; y < axisLines.height; y++) {
      // Check if within gap range and line vicinity
      if (
        (y >= axisLines.height / 2 - 0.4 && y <= axisLines.height / 2 && x >= dynamicGapLeft && x <= axisLines.width - dynamicGapRight ) ||
        (x >= axisLines.width / 2 - 0.4 && x <= axisLines.width / 2 && y >= fixedGapSize && y <= axisLines.height - fixedGapSize)
      ){
      int currentColor = getInvertedColorArea(x, y);
          set(x, y, currentColor);
      }
    }
  }

  image(axisLines,0,0); // Draw the axis lines
}

// Count TOTAL cells
void displayCellCount() {
    fill(200); // White color
    textFont(monoFont); // Set the monospaced font
    textAlign(LEFT, CENTER);
    text("" + cells.size(), 12, height / 2 );
}


void displayCellCounts() {
    textFont(monoFont);

    // Count cells of each type
    int redCount = 0;
    int greenCount = 0;
    int blueCount = 0;
    for (Cell cell : cells) {
        if (cell.gene > 2) {
            redCount++;
        } else if (cell.gene < -2) {
            greenCount++;
        } else {
            blueCount++;
        }
    }

    // Display Red Count (Left-Bottom)
    fill(0,0,255);
    textAlign(RIGHT, BOTTOM);
    text("" + blueCount, width -12 , height - 10);

    // Display Green Count (Center-Bottom)
    fill(255,0,0);
    textAlign(LEFT, BOTTOM);
    text("" + redCount, 12 , height - 10);
    
    // Display Green Count (Center-Bottom)
    fill(0,255,0);
    textAlign(CENTER, BOTTOM);
    text("" + greenCount, width / 2, height - 10);

    // LL²
    fill(0, 0, 0); // Black 
    textAlign(LEFT, TOP);
    text("CELLULAR", 10, 10);

    // RR²
    fill(0, 0, 0); // Black 
    textAlign(RIGHT, TOP);
    text("AUTOMATA", width - 10, 10);
}

void displayMouseCoordinates() {
    textFont(monoFont);

    // Set the same color for both "X" and "mouseX"
    int coordinateTextColor = getInvertedColor(mouseX, mouseY); // Get the inverted color

    fill(coordinateTextColor);
    textAlign(CENTER, TOP);
    // text(mouseX, 12, height / 2.02 - textAscent()); // Top
    text(""+mouseY, width / 2, 10);   // Bottom .  + textDescent()

    // Set the same color for both "Y" and "mouseY"
    fill(coordinateTextColor);
    textAlign(RIGHT, CENTER);
    // text(mouseY, width - 12, height / 2.02 - textAscent());   // Top
    text(mouseX+"", width - 12, height / 2); // Bottom
}

void shiftColors() {
    // Set Target Cell Colors for Gradual Transition
    int tempRed = targetRedColor;
    targetRedColor = targetGreenColor;
    targetGreenColor = targetBlueColor;
    targetBlueColor = tempRed;

    println("Cell colors shifting.");
}

void randomizeColors() {
    // Set Target Cell Colors for Gradual Transition
    targetRedColor = color(random(255), random(255), random(255));
    targetGreenColor = color(random(255), random(255), random(255));
    targetBlueColor = color(random(255), random(255), random(255));
    println("Randomized cell colors.");
}

void mouseClicked() {
    // Randomly choose an action
    int action = (int) random(0, 9); // Increase the number of actions
    switch (action) {
        case 0:
            createNewCell();
            break;
        case 1:
            changeRefreshInterval();
            break;
        case 2:
            changeInteractionRadius();
            break;
        case 3:
            randomizeSingleParameter();
            break;
        case 4:
            killCellsNearMouse(); // New action
            break;
        case 9:
             cycleBackgroundColor();
            break;
        case 6:
            shiftColors();
            break;
        case 7:
            randomizeSimulation();
            break;
        case 8:
            randomizeColors();
            break;
    }
}

void createNewCell() {
    float initialMutationRate = baseMutationRate + random(-mutationRateRange, mutationRateRange);
    cells.add(new Cell(mouseX, mouseY, (int)random(GENE_MIN, GENE_MAX + 1), initialMutationRate));
    println("New cell created at mouse position.");
}

void changeRefreshInterval() {
    setNewRefreshInterval(); // Sets a new random refresh interval
    lastRefreshTime = millis();  //Resets the timer
    println("Refresh interval changed by click.");
}

void changeInteractionRadius() {
    interactionRadius = random(10, 50); // Or any desired range
    println("Interaction radius changed to: " + interactionRadius);
}

void randomizeSingleParameter() {
    int parameterToChange = (int) random(0, 5); // Add more as you add more parameters

    switch (parameterToChange) {
        case 0:
            baseMutationRate = random(2, 8);
            println("Base Mutation Rate changed to: " + baseMutationRate);
            break;
        case 1:
            mutationRateRange = random(1, 4);
            println("Mutation Rate Range changed to: " + mutationRateRange);
            break;
        case 2:
            CELL_RADIUS = random(minRadius, maxRadius);
            println("Cell Radius changed to: " + CELL_RADIUS);
            break;
        case 3:
            baseMaxSpeed = random(1, 2);
             println("Base Max Speed changed to: " + baseMaxSpeed);
            break;
        case 4:
             foodDensity = random(0.01f, 0.05f);
             println("Food Density changed to: " + foodDensity);
             break;
    }
}

void killCellsNearMouse() {
    float killRadius = 100;
    for (int i = cells.size() - 1; i >= 0; i--) {
        Cell cell = cells.get(i);
        if (dist(mouseX, mouseY, cell.position.x, cell.position.y) < killRadius) {
            cells.remove(i);
        }
    }
    println("Killed cells near the mouse.");
}

void cycleBackgroundColor() {
    backgroundColorIndex = (backgroundColorIndex + 1) % availableBackgroundColors.length;
    targetBackgroundColor = availableBackgroundColors[backgroundColorIndex];
}

int lerpColor(int c1, int c2, float amt) {
  float r1 = red(c1);
  float g1 = green(c1);
  float b1 = blue(c1);
  float a1 = alpha(c1);

  float r2 = red(c2);
  float g2 = green(c2);
  float b2 = blue(c2);
  float a2 = alpha(c2);

  return color(lerp(r1, r2, amt), lerp(g1, g2, amt), lerp(b1, b2, amt), lerp(a1, a2, amt));
}

// Helper function to get the average inverted color in a 3x3 area
int getInvertedColorArea(int x, int y) {
    int sumRed = 0;
    int sumGreen = 0;
    int sumBlue = 0;
    int sampleCount = 0;

    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            int sampleX = x + i;
            int sampleY = y + j;

            // Check if the sample coordinates are within the screen bounds
            if (sampleX >= 0 && sampleX < width && sampleY >= 0 && sampleY < height) {
                int currentColor = get(sampleX, sampleY);
                sumRed += red(currentColor);
                sumGreen += green(currentColor);
                sumBlue += blue(currentColor);
                sampleCount++;
            }
        }
    }

    // Calculate the average color
    int avgRed = (sampleCount > 0) ? 255 - (sumRed / sampleCount) : 0;
    int avgGreen = (sampleCount > 0) ? 255 - (sumGreen / sampleCount) : 0;
    int avgBlue = (sampleCount > 0) ? 255 - (sumBlue / sampleCount) : 0;

    return color(avgRed, avgGreen, avgBlue);
}

int getInvertedColor(int x, int y) {
    int currentColor = get(x, y); // Get the color at the mouse position
    return color(255 - red(currentColor), 255 - green(currentColor), 255 - blue(currentColor)); // Invert the color
}

// --- Cursor Handling ---
PGraphics cursorImage; // Declare cursorImage globally
float lastCellRadius = -4; //Track

void updateCursor() {
    if (CELL_RADIUS != lastCellRadius) {
        //Re-initialize cursor image only if cell_radius changed
        lastCellRadius = CELL_RADIUS;
        int cellDiameter = (int)CELL_RADIUS * 2; // Diameter of the cell
        cursorImage = createGraphics(cellDiameter, cellDiameter);
    }

    if (hoveringCell) {
        int cellDiameter = (int)CELL_RADIUS * 2;
        cursorImage.beginDraw();
        cursorImage.background(0, 0); // Make the background transparent
        cursorImage.noFill(); // Make fill transparent
        cursorImage.strokeWeight(1);

        cursorImage.loadPixels();

        for (int x = 0; x < cellDiameter; x++) {
            for (int y = 0; y < cellDiameter; y++) {
                // Calculate distance from the pixel to the center of the ellipse
                float d = dist(x, y, cellDiameter / 2, cellDiameter / 2);

                // If the pixel is within the circle, invert the color
                if (d <= cellDiameter / 5 && d > cellDiameter/ 5 - 0.9) { //Only if d <= celldiameter and d in ring of stroke
                    int currentColor = getInvertedColorArea(mouseX - cellDiameter / 2 + x, mouseY - cellDiameter / 2 + y); // Sample the color area
                    cursorImage.pixels[x + y * cellDiameter] = currentColor; // Set inverted color to cursor image
                } else {
                    cursorImage.pixels[x + y * cellDiameter] = color(0, 0); // Make background transparent
                }
            }
        }

        cursorImage.updatePixels();
        cursorImage.endDraw();

        cursor(cursorImage.get()); // Set the custom cursor
    } else {
        cursor();  //Revert to original
    }
}
