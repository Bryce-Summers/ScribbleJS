/*
 * face_finding_example.js
 * Written by Bryce Summers on 1 - 4 - 2017.
 *
 * Purpose: Demonstrates and tests my Polyline Set to HalfedgeGraph Embedding code.
 */

function main()
{

    G = new Canvas_Drawer()

    
    p0 = new SCRIB.Point(0, 250);
    p1 = new SCRIB.Point(500, 250);

    // Horizontal Line.
    var line1 = new SCRIB.Polyline(false, [p0, p1])

    // -- Spiral.
    var line2 = new SCRIB.Polyline(true)

    var len = 100;
    var max_radius = 200;
    var revolutions = 3;
    for(var i = 0; i <= len; i++)
    {
        var r = i*max_radius/len;
        var angle = i*Math.PI*2*revolutions/len;
        var x = 250 + r*Math.cos(angle);
        var y = 250 + r*Math.sin(angle);
        line2.addPoint(new SCRIB.Point(x, y));
    }

    G.drawPolyline(line1);
    G.drawPolyline(line2);
    return;


    // Embed the polylines within a graph.
    var embedder = new SCRIB.PolylineGraphEmbedder();
    var graph = embedder.embedPolylineArray([line1, line2]);

    // Now Use a Post Processor to derive easy to work with structures which may be drawn to the screen.
    var postProcessor = new SCRIB.PolylineGraphPostProcessor();

    postProcessor.load_graph(graph);

    // Immediately write out the graph to face info structures.
    faces = postProcessor.convert_to_face_infos();

    // Draw these faces to the screen.
    drawFaceInfoArray(faces);

}

// Draws an array of SCRIB.Face_Info structures to the screen,
// using HTML5 Canvas2D.
function drawFaceInfoArray(G, face_info_array)
{
    var len = face_info_array.length;
    for(var i = 0; i < len; i++)
    {
        face = face_info_array[i];
        drawPolyline(G, face.polyline);
    }
}



// Run Example.
main();
