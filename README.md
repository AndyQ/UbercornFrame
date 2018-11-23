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
