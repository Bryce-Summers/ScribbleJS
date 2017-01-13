# ScribbleJS
A library for doing useful geometric things from collections of scribbles.

# Official Website Site with live examples.
https://bryce-summers.github.io/ScribbleJS/

![ScribbleJS example image of eraser tool in action.](https://github.com/Bryce-Summers/ScribbleJS/blob/master/screenshots/Eraser_Tool4.png "ScribbleJS Eraser Tool Example Image")

# License
This work is dedicated to the public domain.

# Installation
Run 'npm install' in a command prompt or terminal.

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

<h2> Dependancies </h2>
<p>
This project was developed concurrently with a centralized repository for my javascript data structures. This project therefore requires the <a = href"https://github.com/Bryce-Summers/BDS.js" target="_blank">Bryce Data Structures</a> submodule. This means that after you clone the repository from github, you may have to run the following commands in your favorite terminal:
<pre>
git submodule init
git submodule update
</pre>
