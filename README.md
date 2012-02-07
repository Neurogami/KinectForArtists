# Kinect for Artists Presentation Code #

On Feburary 1, 2012, I gave a talk at "Tiny Army":http://www.tinyarmy.com about using the XBox 360 Kinect to control visual applications.

You can read the expanded notes "here":http://neurogami.com/presentations/KinectForArtists

I put together assorted code for different applications.  These are those.


## TouchOSC Proxy ##

I gave a demo of controlling Animata using Kinect, wth "OSCeleton":https://github.com/Sensebloom/OSCeleton.

OSCeleton only sends (surprise!) skeleton data, but Animata can handle OSC for a few other things, such as layer visibilty and opacity.

To show this I decided to use "TouchOSC":http://hexler.net/software/touchosc to send additional OSC commands for some layer animation.

The TouchOSC messages were not what Animata would recognize so I created a proxy in Processing to convert the message.


## Blob Detection OSC ##

An example that only seemed ot work for me at home was to use depth data to create blobs and use those blobs to generate OSC commands.

The resulting OSC could be used in tow ways: either directly, sent to an app that could respond to OSC, or indirectly, by using the OSC to drive yet another intermediary that in turn generated mouse and keyboard events.

For the former I had a SketchUp plugin that listended for OSC messages; for the latter I was using AutoIt to in turn control LightUp Player va keyboard commands.


## SketchUp OSC Plugin ##

SketchUp comes with an old, and bare, Ruby runtime.  By default it does not have the standard library.  But there's neat hack whereby you push the path to proper set of Ruby libs into `$:` which then gives you a fuller (albeit still dated) Ruby to work with.

Once that was in place I was able to use the `socket` library with some code taken from the `osc-ruby` library's `Server` class as part of a SketchUp OSC plugin.  

I also defined a set of message handlers to manipulate a camera eye based on the blob detection OSC.  

It's sort of clunky but demonstrates the principles.


## AutoIt OSC for LightUp Player ##

I wanted to use LightUp Player as an example of a program that knows nothing of OSC and has no scripting options.

I found an example AutoIt script that could process OSC messages and hacked it up to generate keyboard arrow commands that were directed at the LightUp Player window.


