/*
 * Line Splits Example.
 * Written by Bryce Summers on 1 - 3 - 2017.
 * 
 * Purpose: Demonstrate a scribble formed from a collection of line segments and how it is cut into non-intersecting lines.
 */

function main()
{

    G = new Canvas_Drawer()

    p0 = new BDS.Point(0, 140);
    p1 = new BDS.Point(500, 250);

    p2 = new BDS.Point(0, 360);
    p3 = new BDS.Point(500, 360);

    points = [p0, p1, p2, p3]

    var len = 10;
    var w = window.innerWidth;
    for(var i = 0; i < len; i++)
    {
        var x = i*w/len;
        var y = 250 + 200*Math.cos(i*w/len*5);

        points.push(new BDS.Point(x, y))

    }

    var lines = []
    lines.push(new BDS.Line(0, 1, points));
    lines.push(new BDS.Line(1, 2, points));
    lines.push(new BDS.Line(2, 3, points));

    for(var i = 4; i < points.length - 1; i++)
    {
        lines.push(new BDS.Line(i, i + 1, points));
    }

    var intersector = new BDS.Intersector();
    intersector.intersectLineSegments(lines);

    var split_lines = []

    len = lines.length
    for(var i = 0; i < len; i++)
    {
        lines[i].getSplitLines(split_lines)
    }

    for(var i = 0; i < split_lines.length; i++)
    {
        line = split_lines[i];
        G.drawArrow(line, 25);
    }

}


// Run Example.
main();
