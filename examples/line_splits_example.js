/*
 * Line Splits Example.
 * Written by Bryce Summers on 1 - 3 - 2017.
 * 
 * Purpose: Demonstrate a scribble formed from a collection of line segments and how it is cut into non-intersecting lines.
 */

function main()
{
    canvas = document.getElementById("theCanvas");
    ctx = canvas.getContext("2d");
    // Draw white Lines.
    ctx.strokeStyle = '#ffffff';

    var w = 500
    var h = 500

    p0 = new SCRIB.Point(0, 140);
    p1 = new SCRIB.Point(500, 250);

    p2 = new SCRIB.Point(0, 360);
    p3 = new SCRIB.Point(500, 360);

    points = [p0, p1, p2, p3]

    var len = 10;
    for(var i = 0; i < len; i++)
    {
        var x = i*w/len;
        var y = 250 + 200*Math.cos(i*w/len*5);

        points.push(new SCRIB.Point(x, y))

    }

    var lines = []
    lines.push(new SCRIB.Line(0, 1, points));
    lines.push(new SCRIB.Line(1, 2, points));
    lines.push(new SCRIB.Line(2, 3, points));

    for(var i = 4; i < points.length - 1; i++)
    {
        lines.push(new SCRIB.Line(i, i + 1, points));
    }

    var intersector = new SCRIB.Intersector();
    intersector.intersect(lines);

    var split_lines = []

    len = lines.length
    for(var i = 0; i < len; i++)
    {
        lines[i].getSplitLines(split_lines)
    }

    for(var i = 0; i < split_lines.length; i++)
    {
        line = split_lines[i];
        drawArrow(line, 25);
    }

}

// Input: SCRIB.Line
function drawArrow(line, size)
{

    drawScribLine(line)

    var p1 = line.p1
    var p2 = line.p2

    var len = line.offset.norm();
        
    var par_x = (p1.x - p2.x)/len
    var par_y = (p1.y - p2.y)/len
    
    // /2 provides slant.
    var perp_x = -par_y*size/3
    var perp_y =  par_x*size/3
    
    par_x *= size
    par_y *= size
            
    // Arrow head.
    drawLine(p2.x, p2.y, p2.x + par_x + perp_x, p2.y + par_y + perp_y)
    drawLine(p2.x, p2.y, p2.x + par_x - perp_x, p2.y + par_y - perp_y)

}
 
// Input: SCRIB.Line
function drawScribLine(line)
{
    
    p1 = line.p1
    p2 = line.p2

    drawLine(p1.x, p1.y, p2.x, p2.y);
}

function drawLine(x1, y1, x2, y2)
{

    ctx.moveTo(x1, y1);
    ctx.lineTo(x2, y2);
    ctx.stroke();
}


// Run Example.
main();
