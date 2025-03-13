// --- Constants and Parameters ---
var UNIVERSE_SIZE = 120;
var baseMutationRate = 5;
var mutationRateRange = 2;
var reproductionThreshold;
var interactionRadius = 20;
var GENE_MIN = -18;
var GENE_MAX = 18;
var CELL_RADIUS = 10;
var minRadius = 2;
var maxRadius;
var BACKGROUND_COLOR;
var FRAME_RATE = 12;
var baseMaxSpeed = 0.2;
var maxSpeedVariation = 5;
var energyConsumptionRate = 0.58;
var energyGainFromInteraction = 0.004;
var minEnergyForReproduction = 8;

// --- Metaball Parameters ---
var THRESHOLD = 0.2;
var metaballStrength = 0.02;

// --- Environmental Factors ---
var foodDensity = 0.025;
var foodEnergyValue = 5.0;
var foodParticles = [];

// --- Refresh Parameters ---
var minRefreshInterval = 6;
var maxRefreshInterval = 12;
var refreshInterval;
var lastRefreshTime;

// --- Speed Modification Zone ---
var slowDownRadius = 20;
var speedReductionFactor = 50.3;

// --- Color Palette Change Parameters ---
var availableBackgroundColors = [
  (255 << 16) | (255 << 8) | 255,
  (0 << 16) | (0 << 8) | 0,
  (255 << 16) | (0 << 8) | 0,
  (0 << 16) | (255 << 8) | 0,
  (0 << 16) | (0 << 8) | 255
];
var backgroundColorIndex = 0;

var redColor;
var greenColor;
var blueColor;

// --- Color Transition Parameters ---
var colorTransitionSpeed = 0.6;

var targetBackgroundColor;
var targetRedColor, targetGreenColor, targetBlueColor;

// --- Cell Representation ---
var Cell = function(x, y, gene, mutationRate) {
    console.log("Created cell at:", x, y, gene, mutationRate); // Check creation
    this.position = new PVector(x, y);
    this.velocity = PVector.random2D();
    var randomVector = PVector.random2D();
        console.log("Random vector:", randomVector.x, randomVector.y);
    this.maxSpeed = baseMaxSpeed + processing.random(-maxSpeedVariation, maxSpeedVariation);
    this.maxSpeed = Math.max(0, this.maxSpeed);
        console.log("maxSpeed", this.maxSpeed);
    this.velocity.mult(this.maxSpeed);
    this.gene = gene;
    this.alive = true;
    this.radius = CELL_RADIUS;
    this.energy = 12;
    this.mutationRate = mutationRate;
}

Cell.prototype.update = function() {
    console.log("Cell update called");
    if (this.alive) {
           console.log("Cell is alive, position:", this.position.x, this.position.y); // Check position
        var distanceToMouse = processing.dist(this.position.x, this.position.y, mouseX, mouseY);
        var speedModifier = 1.0;
        if (distanceToMouse < slowDownRadius) {
            speedModifier = speedReductionFactor;
        }

        this.velocity.add(PVector.random2D().mult(0.2 * speedModifier));
        this.velocity.limit(this.maxSpeed * speedModifier);
        this.position.add(this.velocity);

        this.energy -= energyConsumptionRate;
        if (this.energy <= 0) {
            this.alive = false;
        }
        this.eatFood();
    }
}

Cell.prototype.interact = function(other) {
    if (this === other || !this.alive || !other.alive) return;

    var distance = PVector.dist(this.position, other.position);

    if (distance < interactionRadius) {
        var influence = map(distance, 0, interactionRadius, 1, 0);
        var geneChange = int(influence * (other.gene - this.gene) * 0.1);

        var energyTransfer = energyGainFromInteraction * influence * (1 - abs(this.gene - other.gene) / float(GENE_MAX - GENE_MIN));
        this.energy += energyTransfer;
        other.energy -= energyTransfer;

        this.gene = constrain(this.gene + geneChange, GENE_MIN, GENE_MAX);
        other.gene = constrain(other.gene - geneChange, GENE_MIN, GENE_MAX);

        if (distance < (this.radius + other.radius) && abs(this.gene - other.gene) < reproductionThreshold && this.energy > minEnergyForReproduction && other.energy > minEnergyForReproduction) {
            this.reproduce(other);
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

Cell.prototype.reproduce = function(other) {
    if (cells.length < UNIVERSE_SIZE * 4) {
        float energyCost = (minEnergyForReproduction / 2) + 1;
        this.energy -= energyCost;
        other.energy -= energyCost;

        var newGene = (this.gene + other.gene) / 2;
        if (processing.random(100) < this.mutationRate) {
            newGene = this.mutateGene(newGene);
        }

        var newMutationRate = constrain(this.mutationRate + processing.random(-mutationRateRange, mutationRateRange), 0.5f, 20);

        PVector newPosition = PVector.add(this.position, other.position).div(2);
        newPosition.add(PVector.random2D().mult(this.radius));

        cells.push(new Cell(processing.random(width), processing.random(height), int(processing.random(GENE_MIN, GENE_MAX + 1)), newMutationRate));
    }
}

Cell.prototype.mutateGene = function(gene) {
    float mutationRoll = processing.random(1);
    var mutationAmount;

    if (mutationRoll < 0.26) {
        mutationAmount = (processing.random(1) < 0.5) ? -1 : 1;
    } else if (mutationRoll < 0.9) {
        mutationAmount = (processing.random(1) < 0.5) ? -2 : 2;
    } else {
        mutationAmount = (processing.random(1) < 0.5) ? -3 : 3;
    }
    var newGene = gene + mutationAmount;
    return constrain(newGene, GENE_MIN, GENE_MAX);
}

Cell.prototype.checkSurvival = function() {
    if (this.gene <= GENE_MIN || this.gene >= GENE_MAX) {
        this.alive = false;
    }
    // Loneliness check
    var neighbors = 0;
    for (var i = 0; i < cells.length; i++) {
        if (PVector.dist(this.position, other.position) < interactionRadius) {
            neighbors++;
        }
    }
    // Modify survival based on neighbors (example: more neighbors = longer lifespan)
    float lifespanBonus = neighbors * 0.5f;  // Example bonus
    if (energy < lifespanBonus) { // If energy is lower than bonus, it could die.
        this.alive = false;
    }

}

Cell.prototype.eatFood = function() {
    for (var i = foodParticles.length - 1; i >= 0; i--) {
        var food = foodParticles[i];
        if (PVector.dist(this.position, food) < this.radius) {
            this.energy += foodEnergyValue;
            foodParticles.splice(i, 1);
        }
    }
}

var cells = [];
var monoFont;
var hoveringCell = false;
var fixedGapSize = 36;
var processing;

function setup() {
    processing.size(560, 340);
    processing.frameRate(12);
    processing.smooth();

    maxRadius = processing.random(2, 200);
    BACKGROUND_COLOR = (255 << 16) | (255 << 8) | 255;
    redColor = (255 << 16) | (0 << 8) | 0;
    greenColor = (0 << 16) | (255 << 8) | 0;
    blueColor = (0 << 16) | (0 << 8) | 255;
    reproductionThreshold = processing.random(0.7, 7);
    randomizeSimulation();
    setNewRefreshInterval();
    lastRefreshTime = millis();
  
    monoFont = processing.createFont("Arial", 12);
  processing.textFont(monoFont);

    processing.cursor();
    targetBackgroundColor = BACKGROUND_COLOR;
    targetRedColor = redColor;
    targetGreenColor = greenColor;
    targetBlueColor = blueColor;
}

function randomizeSimulation() {
    cells = [];
    foodParticles = [];

    UNIVERSE_SIZE = int(processing.random(2, int(processing.random(2, 100))));
    baseMutationRate = processing.random(2, 8);
    mutationRateRange = processing.random(1, 4);
    interactionRadius = processing.random(10, 30);
    CELL_RADIUS = processing.random(minRadius, maxRadius);

    for (var i = 0; i < UNIVERSE_SIZE; i++) {
        var initialMutationRate = baseMutationRate + processing.random(-mutationRateRange, mutationRateRange);
        cells.push(new Cell(processing.random(width), processing.random(height), int(processing.random(GENE_MIN, GENE_MAX + 1)), initialMutationRate));
    }

    for (var i = 0; i < width * height * foodDensity / 2; i++) {
        foodParticles.push(new PVector(processing.random(width), processing.random(height)));
    }
}

function setNewRefreshInterval() {
    refreshInterval = processing.random(minRefreshInterval, maxRefreshInterval);
    println("Next refresh in " + refreshInterval + " seconds.");
}

function draw() {
    BACKGROUND_COLOR = lerpColor(BACKGROUND_COLOR, targetBackgroundColor, colorTransitionSpeed);
    processing.background(BACKGROUND_COLOR);

    if (processing.random(1) < foodDensity) {
        foodParticles.push(new PVector(processing.random(width), processing.random(height)));
    }

    processing.stroke((200 << 16) | (100 << 8) | 0);
    processing.strokeWeight(1);
    for (var i = 0; i < foodParticles.length; i++) {
        var food = foodParticles[i];
        processing.point(food.x, food.y);
    }
    processing.strokeWeight(12);
    processing.noStroke();

    hoveringCell = false;

    for (var i = cells.length - 1; i >= 0; i--) {
        var cell = cells[i];
        cell.update();
        cell.checkSurvival();

        var distanceToCell = processing.dist(mouseX, mouseY, cell.position.x, cell.position.y);
        if (distanceToCell < cell.radius) {
            hoveringCell = true;
            processing.stroke(0);
            processing.strokeWeight(2);
            processing.noFill();
            processing.ellipse(cell.position.x, cell.position.y, cell.radius * 2, cell.radius * 2);
            processing.noStroke();
        }

        for (var j = i - 1; j >= 0; j--) {
            cell.interact(cells[j]);
        }

        if (!cell.alive) {
            cells.splice(i, 1);
        }
    }

    renderCellEllipses();

    if (millis() - lastRefreshTime > refreshInterval * 1000) {
        println("Random refresh!");
        randomizeSimulation();
        setNewRefreshInterval();
        lastRefreshTime = millis();
    }

    redColor = lerpColor(redColor, targetRedColor, colorTransitionSpeed);
    greenColor = lerpColor(greenColor, targetGreenColor, colorTransitionSpeed);
    blueColor = lerpColor(blueColor, targetBlueColor, colorTransitionSpeed);

    displayCellCount();
    displayCellCounts();
    displayMouseCoordinates();

    updateCursor();
}

function renderCellEllipses() {
    for (var i = 0; i < cells.length; i++) {
        var cell = cells[i];
        if (cell.alive) {
            processing.fill(cell.gene > 2 ? redColor : (cell.gene < -2 ? greenColor : blueColor));
            processing.ellipse(cell.position.x, cell.position.y, cell.radius * 2, cell.radius * 2);
        }
    }
}

function constrain(val, minVal, maxVal) {
  return Math.max(minVal, Math.min(maxVal, val));
}

function lerpColor(c1, c2, amt) {
    var r1 = (c1 >> 16) & 0xFF;
    var g1 = (c1 >> 8) & 0xFF;
    var b1 = c1 & 0xFF;

    var r2 = (c2 >> 16) & 0xFF;
    var g2 = (c2 >> 8) & 0xFF;
    var b2 = c2 & 0xFF;

    var r = processing.lerp(r1, r2, amt);
    var g = processing.lerp(g1, g2, amt);
    var b = processing.lerp(b1, b2, amt);

    return (int(r) << 16) | (int(g) << 8) | int(b);
}

function displayCellCount() {
    processing.fill(200);
    processing.textFont(monoFont);
    textAlign(LEFT, CENTER);
    processing.text(String(cells.length), 12, height / 2);
}

function displayCellCounts() {
    processing.textFont(monoFont);

    var redCount = 0;
    var greenCount = 0;
    var blueCount = 0;

    for (var i = 0; i < cells.length; i++) {
        var cell = cells[i];
        if (cell.gene > 2) {
            redCount++;
        } else if (cell.gene < -2) {
            greenCount++;
        } else {
            blueCount++;
        }
    }

    processing.fill(0, 0, 255);
    textAlign(RIGHT, BOTTOM);
    processing.text(String(blueCount), width - 12, height - 10);

    processing.fill(255, 0, 0);
    textAlign(LEFT, BOTTOM);
    processing.text(String(redCount), 12, height - 10);

    processing.fill(0, 255, 0);
    textAlign(CENTER, BOTTOM);
    processing.text(String(greenCount), width / 2, height - 10);

    processing.fill(0, 0, 0);
    textAlign(LEFT, TOP);
    processing.text("CELLULAR", 10, 10);

    processing.fill(0, 0, 0);
    textAlign(RIGHT, TOP);
    processing.text("AUTOMATA", width - 10, 10);
}

function displayMouseCoordinates() {
    processing.textFont(monoFont);
    var coordinateTextColor = getInvertedColor(mouseX, mouseY);
    processing.fill(coordinateTextColor);
    textAlign(CENTER, TOP);
    processing.text(String(mouseY), width / 2, 10);
    processing.fill(coordinateTextColor);
    textAlign(RIGHT, CENTER);
    processing.text(String(mouseX), width - 12, height / 2);
}

function shiftColors() {
    var tempRed = targetRedColor;
    targetRedColor = targetGreenColor;
    targetGreenColor = targetBlueColor;
    targetBlueColor = tempRed;

    println("Cell colors shifting.");
}

function randomizeColors() {
    targetRedColor = (int(processing.random(255)) << 16) | (int(processing.random(255)) << 8) | int(processing.random(255));
    targetGreenColor = (int(processing.random(255)) << 16) | (int(processing.random(255)) << 8) | int(processing.random(255));
    targetBlueColor = (int(processing.random(255)) << 16) | (int(processing.random(255)) << 8) | int(processing.random(255));
    println("Randomized cell colors.");
}

function mouseClicked() {
    var action = int(processing.random(0, 9));
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
            killCellsNearMouse();
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

function createNewCell() {
    var initialMutationRate = baseMutationRate + processing.random(-mutationRateRange, mutationRateRange);
    cells.push(new Cell(mouseX, mouseY, int(processing.random(GENE_MIN, GENE_MAX + 1)), initialMutationRate));
    println("New cell created at mouse position.");
}

function changeRefreshInterval() {
    setNewRefreshInterval();
    lastRefreshTime = millis();
    println("Refresh interval changed by click.");
}

function changeInteractionRadius() {
    interactionRadius = processing.random(10, 50);
    println("Interaction radius changed to: " + interactionRadius);
}

function randomizeSingleParameter() {
    var parameterToChange = int(processing.random(0, 5));

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
            killCellsNearMouse();
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

function killCellsNearMouse() {
    var killRadius = 100;
    for (var i = cells.length - 1; i >= 0; i--) {
        var cell = cells[i];
        if (dist(mouseX, mouseY, cell.position.x, cell.position.y) < killRadius) {
            cells.splice(i, 1);
        }
    }
    println("Killed cells near the mouse.");
}

function cycleBackgroundColor() {
    backgroundColorIndex = (backgroundColorIndex + 1) % availableBackgroundColors.length;
    targetBackgroundColor = availableBackgroundColors[backgroundColorIndex];
}

function getInvertedColor(x, y) {
    var currentColor = get(x, y);
    var r = (currentColor >> 16) & 0xFF;
    var g = (currentColor >> 8) & 0xFF;
    var b = currentColor & 0xFF;
    return ((255 - r) << 16) | ((255 - g) << 8) | (255 - b);
}

function updateCursor() {
    cursor(hoveringCell ? CROSS : ARROW);
}

function constrain(val, minVal, maxVal) {
  return Math.max(minVal, Math.min(maxVal, val));
}
