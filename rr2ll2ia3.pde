boolean hasDrawnOnce = false; 

static final int GENE_MINIMUM = -18;
static final int GENE_MAXIMUM = 18;

int N = 512;  
int UNIVERSE = N - 1;
int GENERATIONS = 32;
int DRAW_CELL_WIDTH = 2; 
int DRAW_CELL_HEIGHT = 9; 
int[][] cells;

boolean drawGrid = true; 

void setup() { 
    DRAW_CELL_WIDTH = 1;
    DRAW_CELL_HEIGHT = 1; 
    N = 512;  //512
    UNIVERSE = N - 1;
    GENERATIONS = GENERATIONS *16;
    //size(UNIVERSE*DRAW_CELL_WIDTH, GENERATIONS*DRAW_CELL_HEIGHT); 
    size(511,512);
    cells = new int[UNIVERSE][GENERATIONS];
    noStroke();
    frameRate(20); 
} 

void draw(){
  if(!hasDrawnOnce) {
    hasDrawnOnce = !hasDrawnOnce;
    drawOnce();
  }
}

void mouseReleased() {
      drawOnce();
}

void drawOnce(){
  initCells();  
//  printCells();
  evolve(); 
  drawCells();
}

void evolve() {
  for (int i = 0; i < GENERATIONS-1; i++) {
    for (int j = 0; j < UNIVERSE; j++) {
      int X = cells[j][i];
      shift(X, j, i, X, 0);
    }
  }
}



static final int MAX_REPRODUCTIONS = 2;

void shift(int X, int Xa, int Xg, int delta_a, int number_of_reproductions) {
//  int X = cells[Xa][Xg];
//  println("int "+gene+" = cells["+a+"]["+g+"];");
  if(X == 0) return;
  
  int Na = wrapToUniverse(Xa + delta_a);
  int Ng = Xg + 1; //next generation
  int N = getCellValue(Na, Ng);
  
  //shift -- collision
  if((N != 0) && (X != N)) {
//    zeroNorm(Na, Ng);
//    shiftNorm(X, Na, Ng);

    int multipier = 2;

    //see page 155 of 1957 paper
    if(Na<=63*multipier) {
      bNorm(Na, Ng);      
    } else 
    if(Na<=255*multipier) {
      bNorm(Na, Ng);      
    } else 
    if(Na<=447*multipier) {
      aNorm(Na, Ng);      
    } else 
    {
      aNorm(Na, Ng);
    }
    
  //shift -- no collision  
  } else {
    shiftNorm(X, Na, Ng);
  }
  
  //reproduce
  number_of_reproductions++;
//  int Ya = wrapToUniverse(Xa + delta_a);
  
//  println("int "+Y+" = cells["+Ya+"]["+Xg+"];");
  int Y = getCellValue(Xa + delta_a, Xg);
  if((Y != 0) && (number_of_reproductions <= MAX_REPRODUCTIONS)) {
    shift(X, Xa, Xg, Y, number_of_reproductions);
  }
}

void drawCells() {
  background(255);
  for (int i = 0; i < GENERATIONS; i++) {
    for (int j = 0; j < UNIVERSE; j++) {
      drawCell(cells[j][i], DRAW_CELL_WIDTH*j, DRAW_CELL_HEIGHT*i);
    }
  }
}

//void draw() {
//
//}


void printCells() {
  //... Print array in rectangular form
  for (int i =0; i < GENERATIONS; i++) {
    for (int j = 0; j < UNIVERSE; j++) {
      String cellContents = "" + cells[j][i];
        System.out.print(padToWidth(cellContents, 4));
    }
    System.out.println("");
  }
}

String padToWidth(String s, int width) {
  while(s.length() < width) 
    s = " " + s;
  return s; 
}

void initGenerationWithRandom(int generation) {
    for (int j = 0; j < UNIVERSE; j++) 
      cells[j][generation] = randGene();
}

int randGene() {
  return int(random(GENE_MINIMUM, GENE_MAXIMUM+1));
//  return int(random(-10,10));
}

void initCells() {
  //... Print array in rectangular form
  for (int i =0; i < GENERATIONS; i++) {
    for (int j = 0; j < UNIVERSE; j++) 
      cells[j][i] = 0;
  }

  initGenerationWithRandom(0);
  
//  cells[20][0] = 5;
//  cells[21][0] = -3;
//  cells[22][0] = 1;
//  cells[23][0] = -3;
////  cells[24][0] = ;
//  cells[25][0] = -3;
//  cells[26][0] = 1;
////  cells[27][0] = ;
////  cells[28][0] = ;
////  cells[29][0] = ;

}


void keyPressed() {
  //if (key == 'g' || key == 'G') {
  //  drawGrid = !drawGrid;
  //  drawCells();
  //  
  //} else 
  //if(key == 's' || key == 'S') {
  //  save("image.png");
  //  
  //} else {
  //  drawOnce();
  //
  //}
}





void drawGene(int gene, int[] geneArray, int x, int y) {
  switch(gene) {
  case 1: stroke(#336633); break;
  case 2: stroke(#009900); break;
  case 3: stroke(#339933); break;
  case 4: stroke(#669966); break;
  case 5: stroke(#99CC99); break;
  case 6: stroke(#FFCCFF); break;
  case 7: stroke(#FF99FF); break;
  case 8: stroke(#FF66FF); break;
  case 9: stroke(#FF3300); break;
  case 10: stroke(#FF9900); break;
  case 11: stroke(#FF6600); break;
  case 12: stroke(#FF6600); break;
  case 13: stroke(#003300); break;
  case 14: stroke(#00CC33); break;
  case 15: stroke(#006633); break;
  case 16: stroke(#339966); break;
  case 17: stroke(#66CC99); break;
  case 18: stroke(#99FFCC); break;
  case -1: stroke(#CCFFFF); break;
  case -2: stroke(#3399FF); break;
  case -3: stroke(#99CCFF); break;
  case -4: stroke(#CCCCFF); break;
  case -5: stroke(#FFCC00); break;
  case -6: stroke(#FFCC00); break;
  case -7: stroke(#663399); break;
  case -8: stroke(#330066); break;
  case -9: stroke(#9900CC); break;
  case -10: stroke(#CC00CC); break;
  case -11: stroke(#00FF33); break;
  case -12: stroke(#33FF66); break;
  case -13: stroke(#009933); break;
  case -14: stroke(#00CC66); break;
  case -15: stroke(#33FF99); break;
  case -16: stroke(#99FFFF); break;
  case -17: stroke(#99CCCC); break;
  case -18: stroke(#0066CC); break;

        case 0: default: stroke(255); break;  
  }
  point(x, y);
}

//void drawGeneDebug(int gene, int[] geneArray, int x, int y) {
//  if(drawGrid) {
//    stroke(230);
//    noFill();
//    rect(x, y, DRAW_CELL_WIDTH, DRAW_CELL_HEIGHT);
//  }
//  
//  if(gene == 0) return; 
//  
//  fill(0);
//  noStroke();
//  textFont(font12);
//  textAlign(RIGHT);
//  text(gene+"", x + DRAW_CELL_WIDTH -2, y + DRAW_CELL_HEIGHT -3);
//}


void drawCell(int gene, int x, int y) {
  switch(gene) {
  case 1: drawGene(gene, GENE1, x, y); break;
  case 2: drawGene(gene, GENE2, x, y); break;
  case 3: drawGene(gene, GENE3, x, y); break;
  case 4: drawGene(gene, GENE4, x, y); break;
  case 5: drawGene(gene, GENE5, x, y); break;
  case 6: drawGene(gene, GENE6, x, y); break;
  case 7: drawGene(gene, GENE7, x, y); break;
  case 8: drawGene(gene, GENE8, x, y); break;
  case 9: drawGene(gene, GENE9, x, y); break;
  case 10: drawGene(gene, GENE10, x, y); break;
  case 11: drawGene(gene, GENE11, x, y); break;
  case 12: drawGene(gene, GENE12, x, y); break;
  case 13: drawGene(gene, GENE13, x, y); break;
  case 14: drawGene(gene, GENE14, x, y); break;
  case 15: drawGene(gene, GENE15, x, y); break;
  case 16: drawGene(gene, GENE16, x, y); break;
  case 17: drawGene(gene, GENE17, x, y); break;
  case 18: drawGene(gene, GENE18, x, y); break;
  case -1: drawGene(gene, GENEn1, x, y); break;
  case -2: drawGene(gene, GENEn2, x, y); break;
  case -3: drawGene(gene, GENEn3, x, y); break;
  case -4: drawGene(gene, GENEn4, x, y); break;
  case -5: drawGene(gene, GENEn5, x, y); break;
  case -6: drawGene(gene, GENEn6, x, y); break;
  case -7: drawGene(gene, GENEn7, x, y); break;
  case -8: drawGene(gene, GENEn8, x, y); break;
  case -9: drawGene(gene, GENEn9, x, y); break;
  case -10: drawGene(gene, GENEn10, x, y); break;
  case -11: drawGene(gene, GENEn11, x, y); break;
  case -12: drawGene(gene, GENEn12, x, y); break;
  case -13: drawGene(gene, GENEn13, x, y); break;
  case -14: drawGene(gene, GENEn14, x, y); break;
  case -15: drawGene(gene, GENEn15, x, y); break;
  case -16: drawGene(gene, GENEn16, x, y); break;
  case -17: drawGene(gene, GENEn17, x, y); break;
  case -18: drawGene(gene, GENEn18, x, y); break;
  case 0: default: drawGene(gene, GENE0, x, y); break;  
  }
}


int[] GENE0 = new int[] {0,0,0,0,0,0,0,0};

int[] GENE1   = new int[] {0,0,0,0,0,0,0,1};
int[] GENE2   = new int[] {0,0,0,0,0,0,1,0};
int[] GENE3   = new int[] {0,0,0,0,0,0,1,1};
int[] GENE4   = new int[] {0,0,0,0,0,1,0,0};
int[] GENE5   = new int[] {0,0,0,0,0,1,0,1};
int[] GENE6   = new int[] {0,0,0,0,0,1,1,0};
int[] GENE7   = new int[] {0,0,0,0,0,1,1,1};
int[] GENE8   = new int[] {0,0,0,0,1,0,0,0};
int[] GENE9   = new int[] {0,0,0,0,1,0,0,1};
int[] GENE10  = new int[] {0,0,0,0,1,0,1,0};
int[] GENE11  = new int[] {0,0,0,0,1,0,1,1};
int[] GENE12  = new int[] {0,0,0,0,1,1,0,0};
int[] GENE13  = new int[] {0,0,0,0,1,1,0,1};
int[] GENE14  = new int[] {0,0,0,0,1,1,1,0};
int[] GENE15  = new int[] {0,0,0,0,1,1,1,1};
int[] GENE16  = new int[] {0,0,0,1,0,0,0,0};
int[] GENE17  = new int[] {0,0,0,1,0,0,0,1};
int[] GENE18  = new int[] {0,0,0,1,0,0,1,0};

int[] GENEn1  = new int[] {1,1,1,1,1,1,1,0};
int[] GENEn2  = new int[] {1,1,1,1,1,1,0,1};
int[] GENEn3  = new int[] {1,1,1,1,1,1,0,0};
int[] GENEn4  = new int[] {1,1,1,1,1,0,1,1};
int[] GENEn5  = new int[] {1,1,1,1,1,0,1,0};
int[] GENEn6  = new int[] {1,1,1,1,1,0,0,1};
int[] GENEn7  = new int[] {1,1,1,1,1,0,0,0};
int[] GENEn8  = new int[] {1,1,1,1,0,1,1,1};
int[] GENEn9  = new int[] {1,1,1,1,0,1,1,0};
int[] GENEn10 = new int[] {1,1,1,1,0,1,0,1};
int[] GENEn11 = new int[] {1,1,1,1,0,1,0,0};
int[] GENEn12 = new int[] {1,1,1,1,0,0,1,1};
int[] GENEn13 = new int[] {1,1,1,1,0,0,1,0};
int[] GENEn14 = new int[] {1,1,1,1,0,0,0,1};
int[] GENEn15 = new int[] {1,1,1,1,0,0,0,0};
int[] GENEn16 = new int[] {1,1,1,0,1,1,1,1};
int[] GENEn17 = new int[] {1,1,1,0,1,1,1,0};
int[] GENEn18 = new int[] {1,1,1,0,1,1,0,1};
void shiftNorm(int gene, int a, int g) {
  cells[wrapToUniverse(a)][g] = gene;
}

void zeroNorm(int a, int g) {
  cells[a][g] = 0;
}

void aNorm(int a, int g) {
  if(!isBelowEmptyCell(a,g)) {  //collision under occupied cell
    zeroNorm(a,g);              //set to zero
    
  } else {
    int U = getUvalue(a,g);
    int V = getVvalue(a,g);
    int uv = getU(a,g) + getV(a,g);
    
    if(haveSameSign(U, V)) {    //U and V genes have same sign
      cells[a][g] = uv;         //u+v
      
    } else {                    //U and V genes have different sign
      cells[a][g] = -1 * uv;    //-(u+v)
    }
  }
}

void bNorm(int a, int g) {
  if(!isBelowEmptyCell(a,g)) {  //collision under occupied cell
    zeroNorm(a,g);              //set to zero
    
  } else {
    int U = getUvalue(a,g);
    int V = getVvalue(a,g);
    int uv1 = getU(a,g) + getV(a,g) - 1;
    
    if(haveSameSign(U, V)) {    //U and V genes have same sign
      cells[a][g] = uv1;        //u+v-1
      
    } else {                    //U and V genes have different sign
      cells[a][g] = -1 * uv1;   //-(u+v-1)
    }
  }
}

void cNorm(int a, int g) {
  if(!isBelowEmptyCell(a,g)) {  //collision under occupied cell
    zeroNorm(a,g);              //set to zero
    
  } else {                      //collision under empty cell
    int U = getUvalue(a,g);
    int V = getVvalue(a,g);
    cells[a][g] = V-U;          //V - U
  }
}

void dNorm(int a, int g) {
  int P = getCellValue(a, g-1); //note i'm assuming the "Xa,g+1" in the 1957 paper is a typo 
                                //since future generations are always empty; it should be "Xa,g-1" 
  int A = getCellValue(a+P, g-1);
  int B = getCellValue(a-P, g-1);
  
  if(A != B) {                  //collision if not equal
    zeroNorm(a,g);              //set to zero
    
  } else {
    cells[a][g] = (-1 * P) + (2 * A); //
  }
}

boolean haveSameSign(int A, int B) {
  if(A>0 && B>0) return true;
  if(A<0 && B<0) return true;
  return false;
}

//safe for universe wrapping
int getCellValue(int a, int g) {
  if(g < 0) return 0;
  a = wrapToUniverse(a);
//  println("cells["+a+"]["+g+"]");
//  println("\t" + cells[a][g]);
  return cells[a][g];
}

//positive distance to the RIGHT of first non empty cell
int getU(int a, int g) {
  int u = 0;
  while(getCellValue(a + u, g - 1) == 0) {
    u++;
    u = wrapToUniverse(u);
  }
  return u;
}

//positive distance to the LEFT of first non empty cell
int getV(int a, int g) {
  int v = 0;
  while(getCellValue(a-v, g-1) == 0) {
    v++;
    v = wrapToUniverse(v);
  }
  return v;
}

//value of U gene (which is to the right)
int getUvalue(int a, int g) {
  return getCellValue(a + getU(a,g), g-1);
}

//value of V gene (which is to the left)
int getVvalue(int a, int g) {
  return getCellValue(a - getV(a,g), g-1);
}

//int getValueAbove(int a, int g) {
//  return cells[a][g-1];
//}

boolean isBelowEmptyCell(int a, int g) {
  if(g == 0) return false; 
  return cells[a][g-1] == 0;
}

int wrapToUniverse(int i) {
  i = i % UNIVERSE;
  if(i < 0) i = UNIVERSE+i; //the universe wraps at left
  if(i >= UNIVERSE) i = i-UNIVERSE; //the universe wraps at right
  return i % UNIVERSE;
}

