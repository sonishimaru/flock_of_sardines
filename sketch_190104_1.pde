public void settings(){
  size(1200,800);
}

//ArrayList<Sardine> sardines;
//FlowField flow;

PVector target;
Flock flock;
//ArrayList<ArrayList<Flock>> grid;

Flock[][] grid;

int resolution = 50;
int cols = width / resolution;
int rows = height / resolution;

void setup(){
//flow = new FlowField(20);
  /*
  sardines = new ArrayList<Sardine>();
  for(int i = 0; i< 1; i++){
    sardines.add(new Vehicle(random(width),random(height),random(0.1,2),random(0.1,2)));
  }
  */
  grid = new Flock[cols][rows];

  flock = new Flock();
  /*
  grid = new ArrayList<ArrayList<Flock>>();
  for(int i = 0; i < cols; i++){
    ArrayList<Flock> temp = new ArrayList<Flock>();
    for(int j = 0; j < rows; j++){
      temp.add(new Flock());
    }
    grid.add(temp);
  }
  */
  /*
  grid = new Flock[cols][rows];
  for(int i = 0; i < cols; i++){
    for(int j = 0; j < rows; j++){
      grid[i][j] = new Flock();
    }
  }
  */
  for(int i = 0; i < 100; i++){
    Sardine s = new Sardine(width/2,height/2,random(0.1,2),random(0.1,2));
    flock.addSardine(s);
  }
}

void mouseDragged(){
  Sardine s = new Sardine(mouseX,mouseY,random(0.1,2),random(0.1,2));
  flock.addSardine(s);
}

void draw(){
  grid = new Flock[cols][rows];
  for(int i = 0; i < cols; i++){
    for(int j = 0; j < rows; j++){
      grid[i][j] = new Flock();
    }
  }
  background(255);
  stroke(0);
  fill(180);

  flock.run();

   saveFrame("line-######.png");

}

class Sardine{
  PVector location;
  PVector velocity;
  PVector acceleration;
  float r;
  float maxforce;
  float maxspeed;

  PVector target;

  Sardine(float x, float y, float vx,float vy){
    acceleration = new PVector(0,0);
    velocity = new PVector(vx,vy);
    location = new PVector(x,y);
    r = 5.0;
    maxspeed = 3;
    maxforce = 0.3;
  }

  void run(ArrayList<Sardine> sardines){
    flock(sardines);
    update();
    checkEdeges();
    display();
  }

  void update(){
    velocity.add(acceleration);
    velocity.normalize();
    velocity.mult(maxspeed);
    velocity.limit(maxspeed);
    location.add(velocity);
    acceleration.mult(0);
  }

  void applyForce(PVector force){
    acceleration.add(force);
  }

  /*
  void seek(PVector _target){
    PVector desired = PVector.sub(_target,location);

    float d = desired.mag();
    desired.normalize();

    if(d < 100){
      float m = map(d,0,100,0,maxspeed);
      desired.mult(m);
    } else {
      desired.mult(maxspeed);
    }

    PVector steer = PVector.sub(desired,velocity);
    steer.limit(maxforce);
    applyForce(steer);
  }
  */
  PVector seek(PVector _target){
    PVector desired = PVector.sub(_target,location);

    float d = desired.mag();
    desired.normalize();

    if(d < 100){
      float m = map(d,0,100,0,maxspeed);
      desired.mult(m);
    } else {
      desired.mult(maxspeed);
    }

    PVector steer = PVector.sub(desired,velocity);
    steer.limit(maxforce);
    return steer;
  }



  void follow(FlowField flow){
    PVector desired = flow.lookup(location);
    desired.mult(maxspeed);

    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxforce);
    applyForce(steer);
  }


  void follow(Path p){
    PVector predict = velocity.get();
    predict.normalize();
    predict.mult(25);
    PVector predictLoc = PVector.add(location, predict);

    PVector a = p.start;
    PVector b = p.end;
    PVector normalPoint = getNormalPoint(predictLoc,a,b);

    PVector dir = PVector.sub(b,a);
    dir.normalize();
    dir.mult(10);
    target = PVector.add(normalPoint,dir);

    float distance = PVector.dist(normalPoint, predictLoc);
    if(distance > p.radius){
      seek(target);
    }
  }

  //code for flocking:separation, alignment, cohesion
  void flock(ArrayList<Sardine> sardines){
    PVector sep = separate(sardines,20);
    PVector ali = alignment(sardines,30);
    PVector coh = cohesion(sardines,30);

    sep.mult(1.0);
    ali.mult(1.0);
    coh.mult(2.0);

    applyForce(sep);
    applyForce(ali);
    applyForce(coh);
  }


  /*
  void separate(ArrayList<Sardine> sardines){
    float desiredseparation = 30;

    PVector sum = new PVector();
    int count = 0;

    for(Sardine other: sardines){
      float d = PVector.dist(location, other.location);

      if((d>0) && (d < desiredseparation)){
        PVector diff = PVector.sub(location, other.location);
        diff.normalize();
        diff.div(d);
        sum.add(diff);
        count++;
      }
    }

    if(count > 0){
      sum.div(count);

      sum.setMag(maxspeed);

      PVector steer = PVector.sub(sum,velocity);
      steer.limit(maxforce);

      applyForce(steer);
    }
  }
  */

  PVector separate(ArrayList<Sardine> sardines, float _desiredseparation){
    float desiredseparation = _desiredseparation;

    PVector sum = new PVector();
    int count = 0;

    for(Sardine other: sardines){
      float d = PVector.dist(location, other.location);

      if((d>0) && (d < desiredseparation)){
        PVector diff = PVector.sub(location, other.location);
        diff.normalize();
        diff.div(d);
        sum.add(diff);
        count++;
      }
    }

    if(count > 0){
      sum.div(count);

      sum.setMag(maxspeed);

      PVector steer = PVector.sub(sum,velocity);
      steer.limit(maxforce);
      return steer;
    }else{
      return new PVector(0,0);
    }
  }

  PVector alignment(ArrayList<Sardine> sardines, float _neighbordist){
    float neighbordist = _neighbordist;
    PVector sum = new PVector(0,0);
    int count = 0;
    for(Sardine other: sardines){
      float d = PVector.dist(location,other.location);
      if((d > 0) && (d < neighbordist)){
        sum.add(other.velocity);
        count++;
      }
    }

    if(count > 0){
      sum.div(count);
      sum.normalize();
      sum.mult(maxspeed);
      PVector steer = PVector.sub(sum,velocity);
      steer.limit(maxforce);
      return steer;
    }else{
      return new PVector(0,0);
    }
  }

  PVector cohesion(ArrayList<Sardine> sardines, float _neighbordist){
    float neighbordist = _neighbordist;
    PVector sum = new PVector(0,0);
    int count = 0;
    for(Sardine other: sardines){
      float d = PVector.dist(location,other.location);
      if((d > 0) && (d < neighbordist)){
        sum.add(other.location);
        count++;
      }
    }

    if(count > 0){
      sum.div(count);
      return seek(sum);
    } else {
      return new PVector(0,0);
    }
  }

  void display(){
    float theta = velocity.heading() + PI/2;
    fill(175);
    stroke(0);
    //ellipse(location.x,location.y,16,16);
    pushMatrix();
    translate(location.x,location.y);
    rotate(theta);
    beginShape();
    vertex(0,-r*2);
    vertex(-r,r*2);
    vertex(r,r*2);
    endShape(CLOSE);
    popMatrix();
  }

  void checkEdeges(){
    if(location.x < 50){
      PVector desired = new PVector(maxspeed,velocity.y);
      PVector steer = PVector.sub(desired,velocity);
      steer.limit(maxforce);
      applyForce(steer);
    } else if(location.x > width - 50){
      PVector desired = new PVector(-maxspeed,velocity.y);
      PVector steer = PVector.sub(desired,velocity);
      steer.limit(maxforce);
      applyForce(steer);
    }

    if(location.y < 50){
      PVector desired = new PVector(velocity.x,maxspeed);
      PVector steer = PVector.sub(desired,velocity);
      steer.limit(maxforce);
      applyForce(steer);
    }else if(location.y > height - 50){
      PVector desired = new PVector(velocity.x,-maxspeed);
      PVector steer = PVector.sub(desired,velocity);
      steer.limit(maxforce);
      applyForce(steer);
    }

    if(location.x < 20){
      PVector desired = new PVector(maxspeed,velocity.y);
      PVector steer = PVector.sub(desired,velocity);
      steer.limit(maxforce*2.5);
      applyForce(steer);
    } else if(location.x > width - 20){
      PVector desired = new PVector(-maxspeed,velocity.y);
      PVector steer = PVector.sub(desired,velocity);
      steer.limit(maxforce*2.5);
      applyForce(steer);
    }
/*
    if(location.y < 20){
      PVector desired = new PVector(velocity.x,maxspeed);
      PVector steer = PVector.sub(desired,velocity);
      steer.limit(maxforce*2.5);
      applyForce(steer);
    }else if(location.y > height - 20){
      PVector desired = new PVector(velocity.x,-maxspeed);
      PVector steer = PVector.sub(desired,velocity);
      steer.limit(maxforce*2.5);
      applyForce(steer);
    }
*/

    if(location.x < 0){
      PVector desired = new PVector(maxspeed,velocity.y);
      PVector steer = PVector.sub(desired,velocity);
      steer.limit(maxforce*5);
      applyForce(steer);
    } else if(location.x > width ){
      PVector desired = new PVector(-maxspeed,velocity.y);
      PVector steer = PVector.sub(desired,velocity);
      steer.limit(maxforce*5);
      applyForce(steer);
    }

    if(location.y < 0){
      PVector desired = new PVector(velocity.x,maxspeed);
      PVector steer = PVector.sub(desired,velocity);
      steer.limit(maxforce*5);
      applyForce(steer);
    } else if(location.y > height ){
      PVector desired = new PVector(velocity.x,-maxspeed);
      PVector steer = PVector.sub(desired,velocity);
      steer.limit(maxforce*5);
      applyForce(steer);
    }

  }


  PVector getNormalPoint(PVector p, PVector a, PVector b){
    PVector ap = PVector.sub(p,a);
    PVector ab = PVector.sub(b,a);

    ab.normalize();
    ab.mult(ap.dot(ab));
    PVector normalPoint = PVector.add(a,ab);

    return normalPoint;
  }
}

class Flock{
  ArrayList<Sardine> sardines;

  Flock(){
    sardines = new ArrayList<Sardine>();
  }

  void run(){
    for(Sardine s: sardines){
      int column = int(s.location.x) / resolution;
      int row = int(s.location.y) /resolution;
      column = constrain(column,0,cols-1);
      row = constrain(row,0,rows-1);
      grid[column][row].addSardine(s);
      }

    for(Sardine s:sardines){
        int column = int(s.location.x) / resolution;
        int row = int(s.location.y) /resolution;
        column = constrain(column,0,cols-1);
        row = constrain(row,0,rows-1);
        s.run(grid[column][row].sardines);
      }
    }

  void addSardine(Sardine s){
    sardines.add(s);
  }
}


class FlowField{
  PVector[][] field;
  int cols, rows;
  int resolution;

  FlowField(int r){
    resolution = r;
    cols = width/resolution;
    rows = height/resolution;
    field = new PVector[cols][rows];
    init();
  }

  void init(){
    float xoff = 0;
    for(int i = 0; i < cols; i++){
      float yoff = 0;
      for(int j = 0; j < rows; j++){
        float theta = map(noise(xoff,yoff),0,1,0,TWO_PI);
        field[i][j] = new PVector(cos(theta),sin(theta));
        yoff += 0.1;
      }
      xoff+= 0.1;
    }
  }

  PVector lookup(PVector lookup){
    int column = int(constrain(lookup.x/resolution,0,cols-1));
    int row = int(constrain(lookup.y/resolution,0,rows-1));
    return field[column][row].get();
  }

}

class Path{
  PVector start;
  PVector end;

  float radius;

  Path(){
    radius = 20;
    start = new PVector(0,height/3);
    end = new PVector(width,2*height/3);
  }

  void display(){
    strokeWeight(radius*2);
    stroke(0,100);
    line(start.x,start.y,end.x,end.y);
    strokeWeight(1);
    stroke(0);
    line(start.x,start.y,end.x,end.y);
  }
}
