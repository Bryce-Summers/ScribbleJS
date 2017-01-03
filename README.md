# ScribbleJS
A library for doing useful geometric things from collections of scribbles.

# License
This work is dedicated to the public domain.


# Installation
Run 'npm install' in a command promt or terminal.

# Building
1. Open up two terminals.
2. Navigate each of them to the folder containing this README.
   It should also contain the index.html file and the Gruntfile.js
   For easy navigation, try shift+click on this fold in windows then choose open command promt here.
   On Linux it is not too difficult. On a map, try dragging the file into the terminal or something of that nature.

3. Automatically compile the coffeescript code to javascript in one terminal:
 coffee -o lib/ -cw src/
4. In the other you can automatically inject all of the source code links into the html file:
 npm install
 grunt
 
 
It may be useful to install python 3 and run python -m http.server in a command prompt to run a local server.