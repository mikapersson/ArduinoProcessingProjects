// Spaceship class

class Spaceship{
 float xPos;
 float yPos;
 int ssWidth;
 int ssHeight;
 int score = 0;
 
 ArrayList<Asteroid> pastAsteroids = new ArrayList<Asteroid>();
 
 Spaceship(float x, float y, int w, int h){
   xPos = x;
   yPos = y;
   ssWidth = w;
   ssHeight = h;
 }
 
 void drawSpaceship(){
   pushMatrix();
   translate(xPos, yPos);
   rotate(3*PI/2-0.1);
   shape(spaceshipSVG, 0, 0, ssWidth, ssHeight);
   popMatrix();
 } 
}
