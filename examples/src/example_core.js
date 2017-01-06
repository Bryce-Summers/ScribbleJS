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
}

Canvas_Drawer.prototype =
{

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