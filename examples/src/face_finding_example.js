/*
 * face_finding_example.js
 * Written by Bryce Summers on 1 - 4 - 2017.
 *
 * Purpose: Demonstrates and tests my Polyline Set to HalfedgeGraph Embedding code.
 */

function main()
{

    G = new Canvas_Drawer();

    
    p0 = new BDS.Point(0, 250);
    p1 = new BDS.Point(500, 250);

    // Horizontal Line.
    var line1 = new BDS.Polyline(false, [p0, p1]);

    // -- Spiral.
    geom = new Geometry_Generator();
    var line2 = geom.spiral();

    G.drawPolyline(line1);
    G.drawPolyline(line2);  

    // Embed the polylines within a graph.
    var embedder = new SCRIB.PolylineGraphEmbedder();
    var graph = embedder.embedPolylineArray([line1, line2]);

    // Now Use a Post Processor to derive easy to work with structures which may be drawn to the screen.
    var postProcessor = new SCRIB.PolylineGraphPostProcessor();

    postProcessor.load_graph(graph);

    // Immediately write out the graph to face info structures.
    faces = postProcessor.generate_faces_info();

    // Draw these faces to the screen.
    drawFaceInfoArray(G, faces);

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