/*
 ADXL362_SimpleRead.ino -  Simple XYZ axis reading example
 for Analog Devices ADXL362 - Micropower 3-axis accelerometer
 go to http://www.analog.com/ADXL362 for datasheet
 
 
 License: CC BY-SA 3.0: Creative Commons Share-alike 3.0. Feel free 
 to use and abuse this code however you'd like. If you find it useful
 please attribute, and SHARE-ALIKE!
 
 Created June 2012
 by Anne Mahaffey - hosted on http://annem.github.com/ADXL362

Connect SCLK, MISO, MOSI, and CSB of ADXL362 to
SCLK, MISO, MOSI, and DP 10 of Arduino 
(check http://arduino.cc/en/Reference/SPI for details)
 
*/ 

#include <SPI.h>
#include <ADXL362.h>


ADXL362 xl;

int temp;
int XValue, YValue, ZValue, Temperature;
int xdata, ydata;

int up=4, down = 5, left = 6, right = 7;

void setup(){
    Serial.begin(9600);
    xl.begin();                   // Setup SPI protocol, issue device soft reset
    xl.beginMeasure();            // Switch ADXL362 to measure mode  
    xl.checkAllControlRegs();     // Burst Read all Control Registers, to check for proper setup
	
    pinMode(up, OUTPUT);
    pinMode(down, OUTPUT);
    pinMode (left, OUTPUT);
    pinMode (right, OUTPUT);
    
    
    Serial.print("\n\nBegin Loop Function:\n");
}

void loop(){
    
    // read all three axis in burst to ensure all measurements correspond to same sample time
   // xl.readXYZTData(XValue, YValue, ZValue, Temperature);  	 
    delay(200);                // Arbitrary delay to make serial monitor easier to observe
    
    xdata = xl.readXData();
    ydata = xl.readYData();
    
    
    if(xdata<-750)
    {
      digitalWrite(down, HIGH);  
      digitalWrite(up, LOW);
      Serial.print("Down\n");
    }
    else if (xdata>=750)
    {
      digitalWrite(down, LOW);  
      digitalWrite(up, HIGH);
      Serial.print("Up\n");
    }
    else
    {
      digitalWrite(down, LOW);  
      digitalWrite(up, LOW);
    }
    
    if(ydata< -750)
    {
      digitalWrite(left, HIGH);  
      digitalWrite(right, LOW);
      Serial.print("Left\n");
    }
    else if( ydata>=750)
    {
      digitalWrite(left, LOW);  
      digitalWrite(right, HIGH);
      Serial.print("Right\n");
    }
    
    
    
}

