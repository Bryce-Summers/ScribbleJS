/*
 * Example Core.js
 * Shared common functionality for my visual examples.
 * 
 * Written by Bryce Summers on 1 - 4 - 2017.
 */

function Canvas_Drawer()
{
    canvas = document.getElementById("theCanvas");
    ctx = canvas.getContext("2d");
    // Draw white Lines.
    ctx.strokeStyle = '#ffffff';

    // FIXME: Get the actual dimensions of the canvas.
    w = 500;
    h = 500;   
}

Canvas_Drawer.prototype =
{

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

        ctx.moveTo(x1, y1);
        ctx.lineTo(x2, y2);
        ctx.stroke();
    },

    // Draws a SCRIB.Polyline.
    drawPolyline(polyline)
    {
        var len = polyline.size();

        if(len < 2)
        {
            return;
        }

        var p0 = polyline.getPoint(0);
        ctx.moveTo(p0.x, p0.y);

        for(var i = 1; i < len; i++)
        {
            var p = polyline.getPoint(i);
            ctx.lineTo(p.x, p.y);
        }
        ctx.stroke();
    },

}