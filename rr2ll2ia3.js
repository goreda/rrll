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
    this.position = new PVector(x, y);
    this.velocity = PVector.random2D();
    this.maxSpeed = baseMaxSpeed + random(-maxSpeedVariation, maxSpeedVariation);
    this.maxSpeed = Math.max(0, this.maxSpeed);
    this.velocity.mult(this.maxSpeed);
    this.gene = gene;
    this.alive = true;
    this.radius = CELL_RADIUS;
    this.energy = 12;
    this.mutationRate = mutationRate;
}

Cell.prototype.update = function() {
    if (this.alive) {
        var distanceToMouse = dist(this.position.x, this.position.y, mouseX, mouseY);
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
        var geneChange = parseInt(influence * (other.gene - this.gene) * 0.1);

        var energyTransfer = energyGainFromInteraction * influence * (1 - Math.abs(this.gene - other.gene) / (GENE_MAX - GENE_MIN));
        this.energy += energyTransfer;
        other.energy -= energyTransfer;

        this.gene = constrain(this.gene + geneChange, GENE_MIN, GENE_MAX);
        other.gene = constrain(other.gene - geneChange, GENE_MIN, GENE_MAX);

        if (distance < (this.radius + other.radius) && Math.abs(this.gene - other.gene) < reproductionThreshold && this.energy > minEnergyForReproduction && other.energy > minEnergyForReproduction) {
            this.reproduce(other);
        }

        // Collision Response
        var collisionNormal = PVector.sub(other.position, this.position).normalize();
        var overlap = (this.radius + other.radius) - distance;
        var separationAmount = overlap * 0.5;

        this.position.sub(PVector.mult(collisionNormal, separationAmount));
        other.position.add(PVector.mult(collisionNormal, separationAmount));

        var thisVelocity = this.velocity.copy();
        var otherVelocity = other.velocity.copy();
        var thisDot = thisVelocity.dot(collisionNormal);
        var otherDot = otherVelocity.dot(collisionNormal);
        thisVelocity.sub(PVector.mult(collisionNormal, 2 * thisDot));
        otherVelocity.sub(PVector.mult(collisionNormal, 2 * otherDot));
        this.velocity.lerp(thisVelocity, 0.8);
        other.velocity.lerp(otherVelocity, 0.8);
        this.velocity.add(PVector.random2D().mult(0.3));
        other.velocity.add(PVector.random2D().mult(0.3));
    }
}

Cell.prototype.reproduce = function(other) {
    if (cells.length < UNIVERSE_SIZE * 4) {
        var energyCost = (minEnergyForReproduction / 2) + 1;
        this.energy -= energyCost;
        other.energy -= energyCost;

        var newGene = (this.gene + other.gene) / 2;
        if (random(100) < this.mutationRate) {
            newGene = this.mutateGene(newGene);
        }

        var newMutationRate = constrain(this.mutationRate + random(-mutationRateRange, mutationRateRange), 0.5, 20);

        var newPosition = PVector.add(this.position, other.position).div(2);
        newPosition.add(PVector.random2D().mult(this.radius));

        cells.push(new Cell(newPosition.x, newPosition.y, newGene, newMutationRate));
    }
}

Cell.prototype.mutateGene = function() {
    var mutationRoll = random(1);
    var mutationAmount;

    if (mutationRoll < 0.26) {
        mutationAmount = (random(1) < 0.5) ? -1 : 1;
    } else if (mutationRoll < 0.9) {
        mutationAmount = (random(1) < 0.5) ? -2 : 2;
    } else {
        mutationAmount = (random(1) < 0.5) ? -3 : 3;
    }
    var newGene = gene + mutationAmount;
    return constrain(newGene, GENE_MIN, GENE_MAX);
}

Cell.prototype.checkSurvival = function() {
    if (this.gene <= GENE_MIN || this.gene >= GENE_MAX) {
        this.alive = false;
    }
    var neighbors = 0;
    for (var i = 0; i < cells.length; i++) {
        var other = cells[i];
        if (other !== this && other.alive && PVector.dist(this.position, other.position) < interactionRadius) {
            neighbors++;
        }
    }
    var lifespanBonus = neighbors * 0.5;
    if (this.energy < lifespanBonus) {
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

function setup() {
    size(560, 340);
    frameRate(FRAME_RATE);
    smooth();

    maxRadius = random(2, 200);
    BACKGROUND_COLOR = (255 << 16) | (255 << 8) | 255;
    redColor = (255 << 16) | (0 << 8) | 0;
    greenColor = (0 << 16) | (255 << 8) | 0;
    blueColor = (0 << 16) | (0 << 8) | 255;
    reproductionThreshold = random(0.7, 7);
    randomizeSimulation();
    setNewRefreshInterval();
    lastRefreshTime = millis();
    monoFont = createFont("Arial", 12); // A basic default font for Processing.js

    cursor();
    targetBackgroundColor = BACKGROUND_COLOR;
    targetRedColor = redColor;
    targetGreenColor = greenColor;
    targetBlueColor = blueColor;
}

function randomizeSimulation() {
    cells = [];
    foodParticles = [];

    UNIVERSE_SIZE = parseInt(random(2, random(2, 100)));
    baseMutationRate = random(2, 8);
    mutationRateRange = random(1, 4);
    interactionRadius = random(10, 30);
    CELL_RADIUS = random(minRadius, maxRadius);

    for (var i = 0; i < UNIVERSE_SIZE; i++) {
        var initialMutationRate = baseMutationRate + random(-mutationRateRange, mutationRateRange);
        cells.push(new Cell(random(width), random(height), parseInt(random(GENE_MIN, GENE_MAX + 1)), initialMutationRate));
    }

    for (var i = 0; i < width * height * foodDensity / 2; i++) {
        foodParticles.push(new PVector(random(width), random(height)));
    }
}

function setNewRefreshInterval() {
    refreshInterval = random(minRefreshInterval, maxRefreshInterval);
    println("Next refresh in " + refreshInterval + " seconds.");
}

function draw() {
    BACKGROUND_COLOR = lerpColor(BACKGROUND_COLOR, targetBackgroundColor, colorTransitionSpeed);
    background(BACKGROUND_COLOR);

    if (random(1) < foodDensity) {
        foodParticles.push(new PVector(random(width), random(height)));
    }

    stroke((200 << 16) | (100 << 8) | 0);
    strokeWeight(1);
    for (var i = 0; i < foodParticles.length; i++) {
        var food = foodParticles[i];
        point(food.x, food.y);
    }
    strokeWeight(12);
    noStroke();

    hoveringCell = false;

    for (var i = cells.length - 1; i >= 0; i--) {
        var cell = cells[i];
        cell.update();
        cell.checkSurvival();

        var distanceToCell = dist(mouseX, mouseY, cell.position.x, cell.position.y);
        if (distanceToCell < cell.radius) {
            hoveringCell = true;
            stroke(0);
            strokeWeight(2);
            noFill();
            ellipse(cell.position.x, cell.position.y, cell.radius * 2, cell.radius * 2);
            noStroke();
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
            fill(cell.gene > 2 ? redColor : (cell.gene < -2 ? greenColor : blueColor));
            ellipse(cell.position.x, cell.position.y, cell.radius * 2, cell.radius * 2);
        }
    }
}

function constrain(value, minVal, maxVal) {
    return Math.min(Math.max(value, minVal), maxVal);
}

function lerpColor(c1, c2, amt) {
    var r1 = (c1 >> 16) & 0xFF;
    var g1 = (c1 >> 8) & 0xFF;
    var b1 = c1 & 0xFF;

    var r2 = (c2 >> 16) & 0xFF;
    var g2 = (c2 >> 8) & 0xFF;
    var b2 = c2 & 0xFF;

    var r = lerp(r1, r2, amt);
    var g = lerp(g1, g2, amt);
    var b = lerp(b1, b2, amt);

    return (parseInt(r) << 16) | (parseInt(g) << 8) | parseInt(b);
}

function displayCellCount() {
    fill(200);
    textFont(monoFont);
    textAlign(LEFT, CENTER);
    text(String(cells.length), 12, height / 2);
}

function displayCellCounts() {
    textFont(monoFont);

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

    fill(0, 0, 255);
    textAlign(RIGHT, BOTTOM);
    text(String(blueCount), width - 12, height - 10);

    fill(255, 0, 0);
    textAlign(LEFT, BOTTOM);
    text(String(redCount), 12, height - 10);

    fill(0, 255, 0);
    textAlign(CENTER, BOTTOM);
    text(String(greenCount), width / 2, height - 10);

    fill(0, 0, 0);
    textAlign(LEFT, TOP);
    text("CELLULAR", 10, 10);

    fill(0, 0, 0);
    textAlign(RIGHT, TOP);
    text("AUTOMATA", width - 10, 10);
}

function displayMouseCoordinates() {
    textFont(monoFont);
    var coordinateTextColor = getInvertedColor(mouseX, mouseY);
    fill(coordinateTextColor);
    textAlign(CENTER, TOP);
    text(String(mouseY), width / 2, 10);
    fill(coordinateTextColor);
    textAlign(RIGHT, CENTER);
    text(String(mouseX), width - 12, height / 2);
}

function shiftColors() {
    var tempRed = targetRedColor;
    targetRedColor = targetGreenColor;
    targetGreenColor = targetBlueColor;
    targetBlueColor = tempRed;

    println("Cell colors shifting.");
}

function randomizeColors() {
    targetRedColor = (parseInt(random(255)) << 16) | (parseInt(random(255)) << 8) | parseInt(random(255));
    targetGreenColor = (parseInt(random(255)) << 16) | (parseInt(random(255)) << 8) | parseInt(random(255));
    targetBlueColor = (parseInt(random(255)) << 16) | (parseInt(random(255)) << 8) | parseInt(random(255));
    println("Randomized cell colors.");
}

function mouseClicked() {
    var action = parseInt(random(0, 9));
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
    var initialMutationRate = baseMutationRate + random(-mutationRateRange, mutationRateRange);
    cells.push(new Cell(mouseX, mouseY, parseInt(random(GENE_MIN, GENE_MAX + 1)), initialMutationRate));
    println("New cell created at mouse position.");
}

function changeRefreshInterval() {
    setNewRefreshInterval();
    lastRefreshTime = millis();
    println("Refresh interval changed by click.");
}

function changeInteractionRadius() {
    interactionRadius = random(10, 50);
    println("Interaction radius changed to: " + interactionRadius);
}

function randomizeSingleParameter() {
    var parameterToChange = parseInt(random(0, 5));

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
            foodDensity = random(0.01, 0.05);
            println("Food Density changed to: " + foodDensity);
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
