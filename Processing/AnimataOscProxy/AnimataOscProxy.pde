// Code used in the Kinect for Artists presentation 
//
// James Britt / Neurogami 2012  - james@neurogami.com

// Animata can handle OSC messages for joints and layers
// OSCeleton sends OSC for skeleon joints.  To manipulate the layers
// you need another OSC source.
// The TouchOSC app, available for both Android and iOS devices,
// provides assorted touchscreens for sending OSC commands, but the
// commands are not, by default, what Animata will process.
//
// This code is a proxy.  It takes some stock TouchOSC messages and
// rebroadcasrs them as Animata-friendly commands.
// Note that you'll have to change thr layer name used here in the OSC.

int SCREEN_WIDTH  = 600;
int SCREEN_HEIGHT = 300;

import oscP5.*;
import netP5.*;

OscP5 oscP5;


int thisPort      = 7111;
int animataPort   = 7110;

// This code assumes a sinlge layer is being controlled.
// Change `layerName` to the name of layer in your Animata project
// you want to control.
String layerName  = "fade";

// Change these.  
// thisAddy is what TouchOSC (or whatever is initiating the layer OSC) should broadcast to.
// And use the thisPort.
//
// animataAddy is the address where Animata is running
String thisAddy    = "192.168.43.187";
String animataAddy = "192.168.43.252";

NetAddress  thisMachine     = new NetAddress(thisAddy,    thisPort);
NetAddress  animataMachine  = new NetAddress(animataAddy, animataPort);

void setup() {
  oscP5 = new OscP5(this, thisPort);

  size(SCREEN_WIDTH, SCREEN_HEIGHT);

  // plugs intercept commands that come in on the third parameter and 
  // send them to the function that has the name of the second parameter

  // TouchOSC simple screen 1 sends toggle and fader messages.
  // Here they are mapped to handlers
  oscP5.plug(this,  "toggle_visible", "/1/toggle1");
  oscP5.plug(this,  "set_alpha",      "/1/fader1");
}

void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
}

// This code assumes a single layer, named 'fade'
// Since this was for a simple layer it is
void set_alpha(float val) {
  OscMessage myMessage = new OscMessage("/layeralpha");
  myMessage.add(layerName);
  myMessage.add(val);

  println("Send alpha msg ...");
  oscP5.send(myMessage, animataMachine); 
}

void toggle_visible(float vis) {
  println("Create visibility msg ...");
  OscMessage myMessage = new OscMessage("/layervis");
  myMessage.add(layerName);
  if (vis > 0.0 ) {
    myMessage.add(1);
  } else {
    myMessage.add(0);
  }

  println("Send visibility msg ...");
  oscP5.send(myMessage, animataMachine); 
}


void draw() {

}

void keyPressed() {
  if (key == 'x') {
    stop();
  } 
}

void stop() {
  super.stop();
  super.exit();
}
