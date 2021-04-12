// Asteroid class

class Asteroid{
  float amplitude;
  float xPos = width;
  float radius;
  PShape asteroidSVG = loadShape("asteroid.svg");
  int rotation = 0;
  
  Asteroid(float a, float r){
    amplitude = a;
    radius = r;    
  }
  
  void drawAsteroid(){
    pushMatrix();
    translate(xPos, amplitude);
    rotate(0.05*rotation);
    shape(asteroidSVG, 0, 0, radius, radius);
    popMatrix();
  }
  
}
