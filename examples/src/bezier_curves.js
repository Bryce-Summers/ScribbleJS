/*
 * face_finding_example.js
 * Written by Bryce Summers on 1 - 4 - 2017.
 *
 * Purpose: Demonstrates and tests my Polyline Set to HalfedgeGraph Embedding code.
 */

function main()
{

    G = new Canvas_Drawer();

    lines = createBezierCurves();

    for(var i = 0; i < lines.length; i++)
    {
        line = lines[i];
        G.drawPolyline(line);
    }
    //return;
    
    // Embed the polylines within a graph.
    var embedder = new SCRIB.PolylineGraphEmbedder();
    var graph = embedder.embedPolylineArray(lines);

    // Now Use a Post Processor to derive easy to work with structures which may be drawn to the screen.
    var postProcessor = new SCRIB.PolylineGraphPostProcessor();

    postProcessor.load_graph(graph);

    // Immediately write out the graph to face info structures.
    faces = postProcessor.generate_faces_info();

    for(var i = 0; i < faces.length; i++)
    {
        var face = faces[i];
        curves = face.toCurves();
        console.log(curves);

        for(var j = 0; j < curves.length; j++)
        {
            var curve = curves[j];
            line = curve.toPolyline(10);
            //G.drawPolyline(line);
        }
    }

    // Draw these faces to the screen.
    drawFaceInfoArray(G, faces);

}

// Create the Bryce Data Structure's Brand of Bezier curves.
// To convert from absolute points, subtract control points from on curve points.
function createBezierCurves()
{
    p0 = new BDS.Point(0, 0);
    p1 = new BDS.Point(500, 500);

    // Tangent direction at pt0.
    tan0 = new BDS.Point(500, 0);

    // Tangent direction at pt1.
    tan1 = new BDS.Point(500, 100);

    curve1 = new BDS.Bezier_Curve(p0, tan0, p1, tan1);


    // --

    p0 = new BDS.Point(500, 0)
    p1 = new BDS.Point(0, 500)
    tan0 = new BDS.Point(-500, 0)
    tan1 = new BDS.Point(-500, 0)
    curve2 = new BDS.Bezier_Curve(p0, tan0, p1, tan1);


    // --

    p0 = new BDS.Point(0, 400)
    p1 = new BDS.Point(500, 400)
    tan0 = new BDS.Point(0, 500)
    tan1 = new BDS.Point(0, 500)
    curve3 = new BDS.Bezier_Curve(p0, tan0, p1, tan1);

    // Discretize the curve with a maximum resolution of 10 pixel units.
    times1 = []
    times2 = []
    times3 = []
    resolution = 10 // 10 pixel max_length for discretized segments.

    // Testing Curve Subsetting.
    /*
    console.log(curve1);
    console.log(curve1.position(1.0));
    curve2 = curve1.subCurve(.6, .7);
    curve3 = curve1.subCurve(.8, 1.0);
    curve1 = curve1.subCurve(0, .5);
    console.log(curve1);
    console.log(curve1.position(1.0));
    */

    line1 = curve1.toPolyline(10, times1);
    line2 = curve2.toPolyline(10, times2);
    line3 = curve3.toPolyline(10, times3);

    line1.setAssociatedData(curve1);
    line2.setAssociatedData(curve2);
    line3.setAssociatedData(curve3);

    line1.setTimes(times1);
    line2.setTimes(times2);
    line3.setTimes(times3);

    return [line1, line2, line3];
}

// Draws an array of SCRIB.Face_Info structures to the screen,
// using HTML5 Canvas2D.
function drawFaceInfoArray(G, face_info_array)
{
    var len = face_info_array.length;
    for(var i = 0; i < len; i++)
    {
        face = face_info_array[i];

        // Draw Non-complemented faces.
        if(!face.isComplemented())
        {

           G.fillColor(G.randomColor());
            G.drawPolygon(face.polyline);
        }
    }
}

// Run Example.
main();