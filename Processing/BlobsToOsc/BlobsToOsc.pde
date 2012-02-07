// This code was to be used to take Kinect blob data and emit OSC
// commands to drive SketchUp and LightUp Player
//
//    James Britt /  Neurogami 2012
//
// Initially swiped from:

// Daniel Shiffman
// Tracking the average location beyond a given depth threshold
// Thanks to Dan O'Sullivan
// http://www.shiffman.net
// https://github.com/shiffman/libfreenect/tree/master/wrappers/java/processing


// Also stealing code from Antonio Molinaro's Blobscanner examples
// Find centroids X, Y.

// What this code does: Send OSC commands for centroid values and blob weight.
// The code assumes there will be zero, one, or two blobs detected
// Single blobs are converted into left/right commands, dual blobs are
// converted into forward/back, and in each case it depends on the screen quadrants
// where the blobs appear

import org.openkinect.*;
import org.openkinect.processing.*;
import hypermedia.video.*;
import processing.video.*;
import java.awt.*;

import oscP5.*;
import netP5.*;

OscP5 oscP5;

NetAddress oscReceiver;

//  You may want to chagnge these values to something that works for you.

static int LISTENING_PORT = 7199;
static int SEND_TO_PORT   = 7114;
static String SEND_TO_IP  = "192.168.43.252";  

int w = 640;
int h = 480;
int oCVthreshold = 5;
int numBox = 4;

int depthThreshold = 800;

int minimumWeight = 400;
int thickness = 3;

int[] depth;


//--
import Blobscanner.*;

Detector bd;

PImage img;
PFont f = createFont("", 10);
//--



// Showing how we can farm all the kinect stuff out to a separate class
KinectTracker tracker;
// Kinect Library object
Kinect kinect;



void setup() {
  size(w,h);
  kinect = new Kinect(this);
  tracker = new KinectTracker();

  bd = new Detector( this, 0, 0, w, h, 255 );

  oscP5 = new OscP5(this, LISTENING_PORT);
  oscReceiver = new NetAddress(SEND_TO_IP, SEND_TO_PORT);
}

int scaleX(float x) {
  return int( norm(x, 0.0, w) * 100 );
}

int scaleY(float y) {
  return int( norm(y, 0.0, h) * 100 );
}

void sendNavigationOsc(ArrayList blobs) {
  String command = "undefined";
  float weight = 0.0; // Change base on command calculation

  if(blobs.size() < 1 ) {
    return;
  }

  // We need  way to convert the blob-point set  into a single OSC
  // command.  Suppose we add the quadrant numbers.
  if(blobs.size() == 1 ) {
    Point b = (Point) blobs.get(0);
    int quad = b.quadrant();

    // With a single blob, we'll just do left and right, and pass along
    // the offset fom the the middle X location
    // That is, q1 or q3 means left, and the more to the left of middle X,
    // the more left it goes.

    if ( (quad == 1) || (quad == 3 ) ) {
      float offset = (scaleX(w)/2) - scaleX(b.getX());
      println("LEFT Have single blob in quadrant " + quad + "; offset " + offset );
      command = "left";
      weight = offset;
    } else {
      float offset = scaleX(b.getX()) - (scaleX(w)/2);
      println("RIGHT Have single blob in quadrant " + quad + "; offset " + offset );
      command = "right";
      weight = offset;
    }
  }

  if(blobs.size() == 2 ) {
    Point b1 = (Point) blobs.get(0);
    int quad1 = b1.quadrant();

    Point b2 = (Point) blobs.get(1);
    int quad2 = b2.quadrant();

    println("Have 2 blobs in quadrants " + quad1 + " + " + quad2 );

    int qsum = quad1 + quad2;

    // You may want to change what values are assigned to `command`
    // based on what the recieving app understands
    switch (qsum) {
      case 3: 
        command = "forward";
        break;
      case 4: 
        command = "noop4";
        break;
      case 5: 
        command = "noop5";
        break;
      case 6: 
        command = "noop6";
        break;
      case 7: 
        command = "back";
        break;
    }
  }

  OscMessage msg= new OscMessage("/" + command);
  msg.add(weight); 
  oscP5.send(msg, oscReceiver); 
}  

void sendCentroidOsc(String target, float x, float y, int weight, int blobIndex) {

  OscMessage msg= new OscMessage("/" + target);

  msg.add(scaleX(x)); 
  msg.add(scaleY(y)); 
  msg.add(blobIndex); 
  msg.add(weight); 

  oscP5.send(msg, oscReceiver); 

}

void draw() {
  background(128);

  // Run the tracking analysis
  tracker.track();
  // Note that *tracker.display()* is doing the rendering, and then
  // processBlobs will write over that.
  processBlobs(tracker.display());
  drawGrid();
  println("Zone: " + tracker.getZone() + "; " ); 

}


// Simple way to adjust some values.  Change these if they don't
// work a swell as you would like.
void keyPressed() {
  if (key == 'u') {
    tracker.setThreshold(tracker.getThreshold() + 20 );
  } 
  else if (key == 'd') {
    tracker.setThreshold(tracker.getThreshold() - 20 );
  }
  else if (key == 'U') {
    tracker.setZone(tracker.getZone() + 5 );
  }
  else if (key == 'D') {
    tracker.setZone(tracker.getZone() - 5 );
  }
  else if (key == 'x') {
    stop();
  }
}

void processBlobs(PImage img) {
  img.filter(BLUR); // From 'selective_blob_detection'
  img.filter(THRESHOLD);
  bd.imageFindBlobs(img);
  bd.loadBlobsFeatures();

  //This methods needs to be called before the call 
  //findCentroids(booleaan, boolean) methods.
  bd.weightBlobs(false); // What happens? Nothing, it seems.
  // docs say 'boolean printsConsoleIfZero'


  //Computes the blob center of mass. If the first argument is true, 
  //prints the center of mass coordinates x y to the console. If the 
  //second argument is true, draws a point at the center of mass coordinates.
  bd.findCentroids(false, false);


  stroke(255, 100, 0); 
  float cX;
  float cY;
  int cWeight;

  int minWeight = 2000; //  Even finger-tip blobs seem to have notable weight

  ArrayList notableBlobs = new ArrayList();

  for(int i = 0; i < bd.getBlobsNumber(); i++) {
    /*

       What can we know about these blobs? 
       If we have blobs for left and right hands, can we reliably indicate this in the OSC message?

       a) No, because if you crossed you arms you'd half the hands on the what are usually
       the other segament of the plane.

       b) Yes if could identify hand-ness.

       c) Yes if just assume that crossing your arms would be stupid. :)

       Do the blobs iterate in a known order?  IOW, do blobs in one section of the plane
       (upper left) always get listed before blobs in another section (lower left, or upper right?)

       We should pass along the blob index with the OSC. 


       Should we send a *single* message that combines all blob data?

       Reasons for: The reciever may want to know the total number of blobs at a given
       instant, and act based on that.  That is, if the receive gets a message for
       blob 0, it has to see if then gets  a message for blob 1 (and 2, etc) before knowing
       if there is a single blob or if this is a multi-blob condition.

       It can always split out the details if it wants to treat them as disjoint
       events.

     */
    cWeight = bd.getBlobWeight(i);
    if (cWeight  > minWeight) { 


      cX = bd.getCentroidX(i);
      cY = bd.getCentroidY(i); 

      // We need to be adding points, not blobs. 
      notableBlobs.add(new Point(cX, cY) );

      // sendCentroidOsc("blob", cX, cY, cWeight, i);  

      stroke(0, 255, 0);
      strokeWeight(5);

      //...computes and prints the centroid coordinates x y to the console...
      println("BLOB " + (i+1) + " CENTROID X COORDINATE IS " + cX);
      println("BLOB " + (i+1) + " CENTROID Y COORDINATE IS " + cY);
      println("BLOB " + (i+1) + " Weight is  " + cWeight );
      println("\n");

      //...and draws a point to their location. 
      point(cX, cY);

      //Write coordinate to the screen.
      fill(255, 0, 0);
      text("x-> " + cX + "\n" + "y-> " + cY, cX, cY-7);
    } else {
      // println("Blob " + i + " has low weight: " + cWeight );
    }
  }


  /////

  //--

  if(notableBlobs.size() > 0 ) {
    sendNavigationOsc(notableBlobs);
  }
}

// x= width, y = height

void drawGrid() {
  stroke(240, 200, 100);
  strokeWeight(1);
  // from middle of y, across
  line(0, h/2, w, h/2);
  // from middle of x, and down
  line( w/2, 0, w/2, h);
} 


void stop() {
  tracker.quit();
  super.stop();
  super.exit();
}


class KinectTracker {

  // Size of kinect image
  int kw = 640;
  int kh = 480;
  int threshold = depthThreshold;
  int zone = 185; // The area beyond the threshold for detection.

  // Raw location
  PVector loc;

  // Interpolated location
  PVector lerpedLoc;

  // Depth data
  int[] depth;


  PImage display;

  KinectTracker() {
    kinect.start();
    kinect.enableDepth(true);

    // We could skip processing the grayscale image for efficiency
    // but this example is just demonstrating everything
    //kinect.processDepthImage(true);
    kinect.processDepthImage(false);

    display = createImage(kw, kh, PConstants.RGB);

    loc = new PVector(0, 0);
    lerpedLoc = new PVector(0, 0);
  }

  void track() {

    // Get the raw depth as array of integers
    depth = kinect.getRawDepth();

    // Being overly cautious here
    if (depth == null) return;

    float sumX = 0;
    float sumY = 0;
    float count = 0;

    for (int x = 0; x < kw; x++) {
      for (int y = 0; y < kh; y++) {
        // Mirroring the image
        int offset = kw-x-1+y*kw;
        // Grabbing the raw depth
        int rawDepth = depth[offset];

        // Testing against threshold and zone
        if ( (rawDepth < threshold) && (rawDepth > threshold - zone) ) {
          sumX += x;
          sumY += y;
          count++;
        }
      }
    }
    // As long as we found something
    if (count != 0) {
      loc = new PVector(sumX/count, sumY/count);
    }

    // Interpolating the location, doing it arbitrarily for now
    lerpedLoc.x = PApplet.lerp(lerpedLoc.x, loc.x, 0.3f);
    lerpedLoc.y = PApplet.lerp(lerpedLoc.y, loc.y, 0.3f);
  }

  PVector getLerpedPos() {
    return lerpedLoc;
  }

  PVector getPos() {
    return loc;
  }

  PImage display() {
    PImage img = kinect.getDepthImage();

    if (depth == null || img == null) return(img);

    display.loadPixels();

    for (int x = 0; x < kw; x++) {
      for (int y = 0; y < kh; y++) {
        // mirroring image
        int offset = kw-x-1+y*kw;
        // Raw depth
        int rawDepth = depth[offset];

        int pix = x+y*display.width;
        if ( (rawDepth < threshold) && (rawDepth > threshold - zone ) ) {
          // A red color instead
          display.pixels[pix] = color(150, 50, 50);
        }
        else {
          display.pixels[pix] = img.pixels[offset];
        }
      }
    }
    display.updatePixels();
    image(display, 0, 0);
    return display;
  }


  PImage getDepthImage() {
    PImage img = kinect.getDepthImage();
    return img;
  }

  void quit() {
    kinect.quit();
  }

  int getThreshold() {
    return threshold;
  }

  void setThreshold(int t) {
    threshold =  t;
  }

  int getZone() {
    return zone;
  }

  void setZone(int z) {
    zone = z;
  }
}



public class Point {

  public float xLoc, yLoc;
  public float midX = w/2.0;
  public float midY = h/2.0;

  Point(float x, float y) {
    xLoc = x;
    yLoc = y;
  }

  float getX() {
    return xLoc;
  }

  float getY() {
    return yLoc;
  }


  int quadrant() {
    if (xLoc < midX) {
      // In 1 or 3
      if (yLoc < midY) {
        return 1;
      }else {
        return 3;
      }

    } else {
      // in 2 or 4
      if (yLoc < midY) {
        return 2;
      }else {
        return 4;
      }
    }
  }
}

