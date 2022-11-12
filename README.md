# Python app

A animated image player for the Pimoroni Ubercorn

Displays 16x16 bitmaps - either a zip containing multiple images (numberic sequence named - e.g 1.bmp, 1.bmp, etc)
   or a single bitmap where the  width is 16px and the height is a multiple of 16 and the 16x16 frames are animated.

OR supports a gif or animated gif of any size - and will downsample it to 16x16

Also now exposes two servers: 
   A websocket that a remote client (see companion iOS App)  can attach to and dynamically update the screen either whole screen or individual pixels

   A webserver running on port 8080 that you can select an image to display


# iOS App

A companion app to the Ubercorn player.  Can load and edit animated gifs (large ones are downsampled to 16x16).
Also, connects and communicates with Python app over websockets 

Can import images via Copy/Paste.  If a pasted image is a square and the sides are exactly divisible by 16, it assumes that its a large pixel image and rather than downsampling, takes the image colors at a stride that matches the image width / 16. 

The ColorPickerViewController is a modified version of Christian Zimmermann's iOS_Swift_ColorPicker (https://github.com/Christian1313/iOS_Swift_ColorPicker)

Connects to the Ubercorn (running the above Python app) over Websockets - powered by the Starscream sockets library (https://github.com/daltoniam/Starscream)

# Mounted
This looks really neat when mounted in a cheap IKEA frame - similar to the GameFrame (https://ledseq.com/)

For a description of how to create one, see https://johnmccabe.net/technology/projects/ubercorn-gameframe-pt1/<br>
Also includes links to 3D Printer STL Files.
