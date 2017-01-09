/*
 * Example Core.js
 * Shared common functionality for my visual examples.
 * 
 * Written by Bryce Summers on 1 - 4 - 2017.
 */

function Canvas_Drawer()
{
    canvas = document.getElementById("theCanvas");
    this.ctx = canvas.getContext("2d");
    // Draw white Lines.
    this.ctx.strokeStyle = '#ffffff';

    // FIXME: Get the actual dimensions of the canvas.
    w = 500;
    h = 500;

    // Black color.
    this._background_color = 0x000000;
}

Canvas_Drawer.prototype =
{

    clearScreen()
    {
        ctx = this.ctx;

        // Store the current transformation matrix
        ctx.save();

        // Use the identity matrix while clearing the canvas
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        this.fillColor(this._background_color);
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Restore the transform
        ctx.restore();
    },

    // #rrggbb (number)
    strokeColor(color)
    {
        str = color.toString(16);
        this.ctx.strokeStyle = '#' + str;
    },

    // #rrggbb (number)
    fillColor(color)
    {
        str = color.toString(16);
        this.ctx.fillStyle = '#' + str;
    },

    lineWidth(width)
    {
        this.ctx.lineWidth = width;
    },

    randomColor()
    {
        red   = Math.random()*256
        green = Math.random()*256
        blue  = Math.random()*256

        red   = Math.floor(red)
        green = Math.floor(green)
        blue  = Math.floor(blue)

        // Pack the red, green, and blue components into a hex integer color.
        red   = red   << 16
        green = green << 8

        return red + green + blue
    },

    newColor(red, green, blue)
    {
        red   = red << 16;
        green = green << 8;

        return red + green + blue;
    },

    // Interpolates between color 1 and color 2 in each of the red, green, and blue channels.
    // Percentage marks how what percent of color 2.
    interpolateColor(c1, c2, percentage)
    {
        p1 = 1 - percentage;
        p2 = percentage;

        red   = this.getRed(c1)*p1   + this.getRed(c2)*p2;
        green = this.getGreen(c1)*p1 + this.getGreen(c2)*p2;
        blue  = this.getBlue(c1)*p1  + this.getBlue(c2)*p2;

        red = Math.floor(red);
        green = Math.floor(green);
        blue = Math.floor(blue);

        return this.newColor(red, green, blue);
    },

    getRed(color)
    {
        return color >> 16;
    },

    getGreen(color)
    {
        return (color >> 8) & 0xff;
    },

    getBlue(color)
    {
        return (color >> 0) & 0xff;
    },

    // Input: SCRIB.Line
    drawArrow(line, size)
    {

        this.drawScribLine(line);

        var p1 = line.p1;
        var p2 = line.p2;

        var len = line.offset.norm();
            
        var par_x = (p1.x - p2.x)/len;
        var par_y = (p1.y - p2.y)/len;
        
        // /2 provides slant.
        var perp_x = -par_y*size/3;
        var perp_y =  par_x*size/3;
        
        par_x *= size;
        par_y *= size;
                
        // Arrow head.
        this.drawLine(p2.x, p2.y, p2.x + par_x + perp_x, p2.y + par_y + perp_y);
        this.drawLine(p2.x, p2.y, p2.x + par_x - perp_x, p2.y + par_y - perp_y);

    },

    // Input: SCRIB.Line
    drawScribLine(line)
    {
    
        p1 = line.p1
        p2 = line.p2

        this.drawLine(p1.x, p1.y, p2.x, p2.y);
    },

    drawLine(x1, y1, x2, y2)
    {
        ctx = this.ctx;
        ctx.moveTo(x1, y1);
        ctx.lineTo(x2, y2);
        ctx.stroke();
    },

    // Draws a SCRIB.Polyline.
    drawPolyline(polyline)
    {
        this.drawPolygon(polyline, true, false);
    },

    drawPolygon(polyline, drawStroke, drawFill)
    {

        if(drawFill === undefined)
        {
            drawFill = true;
        }

        if(drawStroke === undefined)
        {
            drawStroke = true;
        }

        var len = polyline.size();

        if(len < 2)
        {
            return;
        }

        ctx = this.ctx;

        ctx.beginPath();

        var p0 = polyline.getPoint(0);
        ctx.moveTo(p0.x, p0.y);

        for(var i = 1; i < len; i++)
        {
            var p = polyline.getPoint(i);
            ctx.lineTo(p.x, p.y);
        }

        if(polyline.isClosed())
        {
            ctx.closePath();
        }

        if(drawStroke)
        {
           ctx.stroke();
        }

        if(drawFill)
        {
            ctx.fill();
        }
  
    },

    drawCircle(circle)
    {
        var position = circle.getPosition();
        var cx = position.x;
        var cy = position.y;
        var radius = circle.getRadius();


        ctx = this.ctx;
        ctx.beginPath();
        ctx.arc(cx, cy, radius, 0, 2 * Math.PI, false);
        ctx.closePath();

        // fill in the circle if it is filled.
        if(circle.isFilled())
        {
            ctx.fill();
        }
        ctx.stroke();
    }

}

function Geometry_Generator()
{

}

Geometry_Generator.prototype =
{
    spiral()
    {
        line = new BDS.Polyline(false);
        var len = 100;
        var max_radius = 200;
        var revolutions = 3;
        for(var i = 0; i <= len; i++)
        {
            var r = i*max_radius/len;
            var angle = i*Math.PI*2*revolutions/len + .01;
            var x = 250 + r*Math.cos(angle);
            var y = 250 + r*Math.sin(angle);
            line.addPoint(new BDS.Point(x, y));
        }

        return line;
    },
}

// -- Root Input functions.
var INPUT; // The global Input Controller than handles time, mouse, keyboard, etc inputs.
function init_input(start_time)
{
    // Initialize the root of the input specification tree.
    INPUT = new Input_Controller();

    window.addEventListener( 'resize', onWindowResize, false);

    //window.addEventListener("keypress", onKeyPress);
    window.addEventListener("keydown", onKeyPress);

    window.addEventListener("mousemove", onMouseMove);
    window.addEventListener("mousedown", onMouseDown);
    window.addEventListener("mouseup",   onMouseUp);


    // The current system time, used to correctly pass time deltas.
    TIMESTAMP = performance.now();

    // Initialize Time input.
    if(start_time)
    {
        beginTime();
    }
}

// Events.
function onWindowResize( event )
{
    
}

// FIXME: ReWire these input events.
function onKeyPress( event )
{
    // Key codes for event.which.
    var LEFT  = 37
    var RIGHT = 39
}

function onMouseMove( event )
{
    event = {x: event.x, y: event.y};
    translateEvent(event);
    INPUT.mouse_move(event);
}

function onMouseDown( e )//event
{
    //http://stackoverflow.com/questions/2405771/is-right-click-a-javascript-event
    var isRightMB;
    e = e || window.event;

    if ("which" in e)  // Gecko (Firefox), WebKit (Safari/Chrome) & Opera
        isRightMB = e.which == 3; 
    else if ("button" in e)  // IE, Opera 
        isRightMB = e.button == 2; 

    if(isRightMB)
        return

    event = {x: event.x, y: event.y};
    translateEvent(e);
    INPUT.mouse_down(e);
}

function onMouseUp( event )
{
    event = {x: event.x, y: event.y};
    translateEvent(event);
    INPUT.mouse_up(event);
}

function translateEvent(event)
{
    var rect = canvas.getBoundingClientRect();  

    event.x = event.x - rect.left;
    event.y = event.y - rect.top;
}

function beginTime()
{
    TIMESTAMP = performance.now();
    INPUT.time_on = true;
    timestep();
}

function timestep()
{
    if(INPUT.time_on)
    {
        requestAnimationFrame(timestep);
    }
    else
    {
        return;
    }

    time_new = performance.now();
    var dt = time_new - TIMESTAMP;
    TIMESTAMP = time_new;

    try
    {
        INPUT.time(dt);
    }
    catch(err) { // Stop time on error.
        INPUT.time_on = false;
        throw err;
    }

}

/*
 * 
 *
 */

function Input_Controller()
{
    this._mouse_input_controllers    = [];
    this._keyboard_input_controllers = [];
    this._time_input_controllers     = [];

    // Things like window resize.
    this._system_controllers          = [];

    this.time_on = false;
}

// FIXME: Should I make the implementation of each of these methods optional?
Input_Controller.prototype =
{  

    // Adds a controller that handles all inputs.
    add_universal_controller(controller)
    {
        // Add this controller to all controller categories.
        this._mouse_input_controllers.push(controller);
        this._keyboard_input_controllers.push(controller);
        this._time_input_controllers.push(controller);
        this._system_controllers.push(controller);
    },

    add_mouse_input_controller(controller)
    {
        this._mouse_input_controllers.push(controller);
    },

    add_keyboard_input_controller(controller)
    {
        this._keyboard_input_controllers.push(controller);
    },

    add_time_input_controller(controller)
    {
        this._time_input_controllers.push(controller);
    },

    add_system_controller(controller)
    {
        this._system_controllers.push(controller);
    },

    mouse_down(event)
    {
        // event.x, event.y are the coordinates for the mouse button.
        // They are originally piped in from screeen space from [0, screen_w] x [0, screen_h]
        len = this._mouse_input_controllers.length;
        for (var i = 0; i < len; i++)
        {
            controller = this._mouse_input_controllers[i];
            controller.mouse_down(event);
        }
    },

    mouse_up(event)
    {
        len = this._mouse_input_controllers.length;
        for (var i = 0; i < len; i++)
        {
            controller = this._mouse_input_controllers[i];
            controller.mouse_up(event);
        }
    },

    mouse_move(event)
    {
        len = this._mouse_input_controllers.length;
        for (var i = 0; i < len; i++)
        {
            controller = this._mouse_input_controllers[i];
            controller.mouse_move(event);
        }
    },

    // Difference in time between the previous call and this call.
    time(dt)
    {
        len = this._time_input_controllers.length;
        for (var i = 0; i < len; i++)
        {
            controller = this._time_input_controllers[i];
            controller.time(dt);
        }
    },

    window_resize(event)
    {
        len = this._system_controllers.length
        for(var i = 0; i < len; i++)
        {
            controller = this._system_controllers[i];
            controller.window_resize();
        }
    }

}

/*
#
# Here is the Interface for constructing mouse controller classes.
#
# Written by Bryce Summers on 11/22/2016
# Abstracted on 12 - 18 - 2016.
#

class CORE.I_Mouse_Interface

    # Input: THREE.js Scene. Used to add GUI elements to the screen and modify the persistent state.
    # THREE.js
    constructor: (@scene, @camera) ->

    mouse_down: (event) ->

    # event.x, event.y are the coordinates for the mouse button.
    # They are originally piped in from screeen space from [0, screen_w] x [0, screen_h]

    mouse_up:   (event) ->

    mouse_move: (event) ->


class Core.Time_Interface
    // Difference in time between the previous call and this call.
    time: (dt) ->
*/
