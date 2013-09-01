
#define leftCenterSensor   3
#define leftNearSensor     4
#define leftFarSensor      5
#define rightCenterSensor  2
#define rightNearSensor    1
#define rightFarSensor     0

int leftCenterReading;
int leftNearReading;
int leftFarReading;
int rightCenterReading;
int rightNearReading;
int rightFarReading;

int leftNudge;
int replaystage;
int rightNudge;

#define threshHold 150
#define leapTime 85
#define turnSpeed 140
#define forwardSpeed 180
#define correctionSpeed 35
#define turnSoftner 80

#define leftMotor1  2
#define leftMotor2  7
#define rightMotor1 4
#define rightMotor2 6
#define leftEnable  3
#define rightEnable 5

#define led 13

char path[30] = {};
int pathLength;
int readLength;

void setup(){
  
  pinMode(leftCenterSensor, INPUT);
  pinMode(leftNearSensor, INPUT);
  pinMode(leftFarSensor, INPUT);
  pinMode(rightCenterSensor, INPUT);
  pinMode(rightNearSensor, INPUT);
  pinMode(rightFarSensor, INPUT);
    
  pinMode(leftMotor1, OUTPUT);
  pinMode(leftMotor2, OUTPUT);
  pinMode(rightMotor1, OUTPUT);
  pinMode(rightMotor2, OUTPUT);
  pinMode(leftEnable, OUTPUT);
  pinMode(rightEnable, OUTPUT);
  
  pinMode(led, OUTPUT);
  //Serial.begin(115200);
  digitalWrite(led, HIGH);
  digitalWrite(leftEnable, HIGH);
  digitalWrite(rightEnable, HIGH);
  delay(1000);
}


void loop(){
  
 readSensors();                                                                                     
 
 if(leftFarReading<threshHold && rightFarReading<threshHold && //If we do not see a left or right turn
   (leftCenterReading>threshHold || rightCenterReading>threshHold) ){  // and at least 1 center sensor sees the black line
    straight();                                                       //keep driving straight                               
  }
  else{                                                                                              
    leftHandWall();      //else we must make a decision                                                                             
  }

}

void readSensors(){
  
  leftCenterReading  = analogRead(leftCenterSensor);
  leftNearReading    = analogRead(leftNearSensor);
  leftFarReading     = analogRead(leftFarSensor);
  rightCenterReading = analogRead(rightCenterSensor);
  rightNearReading   = analogRead(rightNearSensor);
  rightFarReading    = analogRead(rightFarSensor);  

// serial printing below for debugging purposes

// Serial.print("leftCenterReading: ");
// Serial.println(leftCenterReading);
// Serial.print("leftNearReading: ");
// Serial.println(leftNearReading);
// Serial.print("leftFarReading: ");
// Serial.println(leftFarReading);
  
// Serial.print("rightCenterReading: ");
// Serial.println(rightCenterReading);
// Serial.print("rightNearReading: ");
// Serial.println(rightNearReading);
// Serial.print("rightFarReading: ");
// Serial.println(rightFarReading);
// delay(200);
  

}


void leftHandWall(){
  analogWrite(leftEnable, 255);           //full speed ahead for leap
  analogWrite(rightEnable, 255);          // full speed ahed for leap
  
  digitalWrite(leftMotor1, HIGH);
  digitalWrite(leftMotor2, LOW);
  digitalWrite(rightMotor1, HIGH);
  digitalWrite(rightMotor2, LOW);

  if( leftFarReading>threshHold && rightFarReading>threshHold){ //both sensors on black
    delay(leapTime);                     //leap
    readSensors();                      //recheck sensors after leap
    if(leftFarReading>threshHold || rightFarReading>threshHold){  // if both are still on black then we are done
      done();  // we are done solving
    }
    if(leftFarReading<threshHold && rightFarReading<threshHold){ //both are on white which means we need to turn left now
      turnLeft();     //turn left
    }
  }
  
  if(leftFarReading>threshHold){ // if you can turn left then turn left
    delay(leapTime);                   //leap
    readSensors();                     //recheck sensors after leap
    if(leftFarReading<threshHold && rightFarReading<threshHold){ // both are one white so turn left
      turnLeft();  // turn left
    }
    else{
      done(); // one sees black? then we are done
    }
  }
   
  if(rightFarReading>threshHold){  //no left turn, maybe we need to turn right then
    delay(10);                   // drive forward a hair
    readSensors();              //recheck sensors
    if(leftFarReading>threshHold){ // are we positive we can't turn left
      delay(leapTime-10);     // leap
      readSensors();          //read sensors
      if(rightFarReading>threshHold && leftFarReading>threshHold){ // if all are black
        done(); // we are done
      }
      else{ 
        turnLeft(); //else we need to turn left
        return;
      }
    }
    delay(leapTime-10); //leap
    readSensors();      // rechekc sensors
    if(leftFarReading<threshHold && leftCenterReading<threshHold &&
      rightCenterReading<threshHold && rightFarReading<threshHold){ //all are white meaning this is a required right turn
      turnRight();  // turn right
      return;
    }
    // all was not white so we can continue driving forward
    path[pathLength]='S';
    pathLength++;
    if(path[pathLength-2]=='B'){
      shortPath();
    }
    straight();
  }
  
  readSensors();
  if(leftFarReading<threshHold && leftCenterReading<threshHold && rightCenterReading<threshHold 
    && rightFarReading<threshHold && leftNearReading<threshHold && rightNearReading<threshHold){ // all is white, turn around.
    turnAround();
  }
}


void done(){
  digitalWrite(leftMotor1, LOW);
  digitalWrite(leftMotor2, LOW);
  digitalWrite(rightMotor1, LOW);
  digitalWrite(rightMotor2, LOW);
  replaystage=1;
  path[pathLength]='D';
  pathLength++;
 while(analogRead(leftFarSensor)>threshHold){
   digitalWrite(led, LOW);
   delay(150);
   digitalWrite(led, HIGH);
   delay(150);
 }
 delay(1000);
  replay();
}

void turnLeft(){
  while(analogRead(rightCenterSensor)>threshHold || analogRead(leftCenterSensor)>threshHold){
    digitalWrite(leftMotor1, LOW);
    digitalWrite(leftMotor2, HIGH);
    digitalWrite(rightMotor1, HIGH);
    digitalWrite(rightMotor2, LOW);
    analogWrite(leftEnable, turnSpeed);
    analogWrite(rightEnable, turnSpeed);
  }
    
  while(analogRead(leftFarSensor)<threshHold){
    digitalWrite(leftMotor1, LOW);
    digitalWrite(leftMotor2, HIGH);
    digitalWrite(rightMotor1, HIGH);
    digitalWrite(rightMotor2, LOW);
    analogWrite(leftEnable, turnSpeed);
    analogWrite(rightEnable, turnSpeed);
  }
  while(analogRead(leftCenterSensor)<threshHold){
    digitalWrite(leftMotor1, LOW);
    digitalWrite(leftMotor2, HIGH);
    digitalWrite(rightMotor1, HIGH);
    digitalWrite(rightMotor2, LOW);
    analogWrite(leftEnable, turnSpeed-(turnSoftner));
    analogWrite(rightEnable, turnSpeed-(turnSoftner));
  }    
  if(replaystage==0){
    path[pathLength]='L';
    pathLength++;
    if(path[pathLength-2]=='B'){
      shortPath();
    }
  }
  straight();
}

void turnRight(){
   while(analogRead(rightFarSensor)<threshHold){
     digitalWrite(leftMotor1, HIGH);
    digitalWrite(leftMotor2, LOW);
    digitalWrite(rightMotor1, LOW);
    digitalWrite(rightMotor2, HIGH);
    analogWrite(leftEnable, turnSpeed);
    analogWrite(rightEnable, turnSpeed);
  }
   while(analogRead(rightCenterSensor)<threshHold){
     digitalWrite(leftMotor1, HIGH);
    digitalWrite(leftMotor2, LOW);
    digitalWrite(rightMotor1, LOW);
    digitalWrite(rightMotor2, HIGH);
    analogWrite(leftEnable, turnSpeed-(turnSoftner));
    analogWrite(rightEnable, turnSpeed-(turnSoftner));
  }  

  if(replaystage==0){
    path[pathLength]='R';
    pathLength++;
    if(path[pathLength-2]=='B'){
      shortPath();
    }
  }
  straight();
}

void straight(){
  if( analogRead(leftCenterSensor)<threshHold){
    digitalWrite(leftMotor1, HIGH);
    digitalWrite(leftMotor2, LOW);
    digitalWrite(rightMotor1, HIGH);
    digitalWrite(rightMotor2, LOW);
    analogWrite(leftEnable, 255);
    analogWrite(rightEnable, correctionSpeed);
    return;
  }
  else if(analogRead(rightCenterSensor)<threshHold){
    digitalWrite(leftMotor1, HIGH);
    digitalWrite(leftMotor2, LOW);
    digitalWrite(rightMotor1, HIGH);
    digitalWrite(rightMotor2, LOW);
    analogWrite(leftEnable, correctionSpeed);
    analogWrite(rightEnable, 255);
    return;
  }
  else{
    digitalWrite(leftMotor1, HIGH);
    digitalWrite(leftMotor2, LOW);
    digitalWrite(rightMotor1, HIGH);
    digitalWrite(rightMotor2, LOW);
    analogWrite(leftEnable, forwardSpeed);
    analogWrite(rightEnable, forwardSpeed);
  }
}

void turnAround(){
   analogWrite(leftEnable, 255);
   analogWrite(rightEnable, 255);
   digitalWrite(leftMotor1, HIGH);
   digitalWrite(leftMotor2, LOW);
   digitalWrite(rightMotor1, HIGH);
   digitalWrite(rightMotor2, LOW);
   delay(leapTime);
   
   while(analogRead(leftFarSensor)<threshHold){
    digitalWrite(leftMotor1, LOW);
    digitalWrite(leftMotor2, HIGH);
    digitalWrite(rightMotor1, HIGH);
    digitalWrite(rightMotor2, LOW);
    analogWrite(leftEnable, turnSpeed);
    analogWrite(rightEnable, turnSpeed);
   }
   while(analogRead(leftCenterSensor)<threshHold){
     digitalWrite(leftMotor1, LOW);
     digitalWrite(leftMotor2, HIGH);
     digitalWrite(rightMotor1, HIGH);
     digitalWrite(rightMotor2, LOW);
     analogWrite(leftEnable, turnSpeed-(turnSoftner+50));
     analogWrite(rightEnable, turnSpeed-(turnSoftner+50));
   }

  path[pathLength]='B';
  pathLength++;
  straight();
}

void shortPath(){
  int shortDone=0;
  if(path[pathLength-3]=='L' && path[pathLength-1]=='R'){
    pathLength-=3;
    path[pathLength]='B';
    shortDone=1;
  }
  if(path[pathLength-3]=='L' && path[pathLength-1]=='S' && shortDone==0){
    pathLength-=3;
    path[pathLength]='R';
    shortDone=1;
  }  
  if(path[pathLength-3]=='R' && path[pathLength-1]=='L' && shortDone==0){
    pathLength-=3;
    path[pathLength]='B';
    shortDone=1;
  }
  if(path[pathLength-3]=='S' && path[pathLength-1]=='L' && shortDone==0){
    pathLength-=3;
    path[pathLength]='R';
    shortDone=1;
  }  
  if(path[pathLength-3]=='S' && path[pathLength-1]=='S' && shortDone==0){
    pathLength-=3;
    path[pathLength]='B';
    shortDone=1;
  }
  if(path[pathLength-3]=='L' && path[pathLength-1]=='L' && shortDone==0){
    pathLength-=3;
    path[pathLength]='S';
    shortDone=1;
  }
  path[pathLength+1]='D';
  path[pathLength+2]='D';
  pathLength++;
}




void replay(){
  readSensors();
  if(leftFarReading<threshHold && rightFarReading<threshHold){
    straight();
  }
  else{
    analogWrite(leftEnable, 255);
    analogWrite(rightEnable, 255);
    if(path[readLength]=='D'){
      digitalWrite(leftMotor1, HIGH);
      digitalWrite(leftMotor2, LOW);
      digitalWrite(rightMotor1, HIGH);
      digitalWrite(rightMotor2, LOW);
      delay(100);
      digitalWrite(leftMotor1, LOW);
      digitalWrite(leftMotor2, LOW);
      digitalWrite(rightMotor1, LOW);
      digitalWrite(rightMotor2, LOW);
      endMotion();
    }
    if(path[readLength]=='L'){
      digitalWrite(leftMotor1, HIGH);
      digitalWrite(leftMotor2, LOW);
      digitalWrite(rightMotor1, HIGH);
      digitalWrite(rightMotor2, LOW);
      delay(leapTime);
      turnLeft();
    }
    if(path[readLength]=='R'){
      digitalWrite(leftMotor1, HIGH);
      digitalWrite(leftMotor2, LOW);
      digitalWrite(rightMotor1, HIGH);
      digitalWrite(rightMotor2, LOW);
      delay(leapTime);
      turnRight();
    }
    if(path[readLength]=='S'){
      digitalWrite(leftMotor1, HIGH);
      digitalWrite(leftMotor2, LOW);
      digitalWrite(rightMotor1, HIGH);
      digitalWrite(rightMotor2, LOW);
      delay(leapTime);
      straight();
    }
    readLength++;
  }  
  replay();
}

void endMotion(){
  digitalWrite(leftMotor1, LOW);
  digitalWrite(leftMotor2, LOW);
  digitalWrite(rightMotor1, LOW);
  digitalWrite(rightMotor2, LOW);  
  digitalWrite(led, LOW);
  delay(500);
  digitalWrite(led, HIGH);
  delay(200);
  digitalWrite(led, LOW);
  delay(200);
  digitalWrite(led, HIGH);
  delay(500);
  endMotion();
}
