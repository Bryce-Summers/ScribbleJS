/*
 * faces bvh example.js
 * Written by Bryce Summers on 1 - 6 - 2017.
 *
 * Purpose: Demonstrates a vector fill bucket tool.
 */

// Small Example scope.
EX = {}

function main()
{
    setup();
    init_input(false);
    
    var controller = new Fill_Bucket_Controller();
    INPUT.add_universal_controller(controller);

    beginTime();
}

function setup()
{
    EX.G = new Canvas_Drawer();
    
    var p0 = new BDS.Point(0, 250);
    var p1 = new BDS.Point(500, 250);

    // Horizontal Line.
    var line1 = new BDS.Polyline(false, [p0, p1]);

    // -- Spiral.
    geom = new Geometry_Generator();
    var line2 = geom.spiral();
    var lines = [line1, line2]

    range = new BDS.Box(new BDS.Point(0,   0),
                        new BDS.Point(500, 500))
    
    line3 = new BDS.Polyline(true);
    for (var i = 0; i < 50; i++)
    {
        line3.addPoint(range.getRandomPointInBox());
    }
    var lines = []
    lines.push(line3)


    /* Testing Square.
    // FIXME: Handle problems with vertical line segments.
    var lines = [];

    var sq0 = new BDS.Point(50, 50);
    var sq1 = new BDS.Point(75, 75);
    var squares = [sq0, sq1];

    for(var i = 0; i < squares.length; i++)
    {
        var pt = squares[i];
        var x = pt.x;
        var y = pt.y;

        var s0 = new BDS.Point(x + 0,  y +  0);
        var s1 = new BDS.Point(x + 0,  y + 50);
        var s2 = new BDS.Point(x + 50, y + 50);
        var s3 = new BDS.Point(x + 50, y + 0);
        var line = new BDS.Polyline(true, [s0, s1, s2, s3]);
        lines.push(line);
    }

    //*/






    // Embed the polylines within a graph.
    var embedder = new SCRIB.PolylineGraphEmbedder();
    var graph    = embedder.embedPolylineArray(lines);

    // Now Use a Post Processor to derive easy to work with structures which may be drawn to the screen.
    EX.postProcessor = new SCRIB.PolylineGraphPostProcessor();

    EX.postProcessor.load_graph(graph);

    // Immediately write out the graph to face info structures.
    EX.faces = EX.postProcessor.convert_to_face_infos();

    // Generate a BVH.
    EX.BVH = new BDS.BVH2D(facesToUncomplementedPolylines(EX.faces));

    EX.box_lines = EX.BVH.toPolylines();

}

// Draws an array of SCRIB.Face_Info structures to the screen,
// using HTML5 Canvas2D.
function drawFaceInfoArray(G, face_info_array)
{
    var len = face_info_array.length;
    for(var i = 0; i < len; i++)
    {
        var face = face_info_array[i];

        // Note: We could put the color attribute in face.face.faceData.color,
        // But, I want to keep halfedge stuff out of my ScribbleJS user's mind...
        // Instead they should interact directly with the Face_Info objects.
        if (face.color === undefined)
        {
            face.color = G.randomColor();
        }

        var color = face.color;

        // Highlight the face that the mouse is currently in.
        /*
        if(face.polyline.containsPoint(new BDS.Point(EX.mouse.x, EX.mouse.y)))
        {
            color = 0xffffff;
        }
        */

        // Draw Non-complemented faces.
        if(!face.isComplemented())
        {
           G.fillColor(color);
           G.drawPolygon(face.polyline);
        }
    }
}

function drawPolyLine_Array(G, polylines)
{
    // Red Strokes.
    G.strokeColor(0xff0000);

    var len = polylines.length;
    for(var i = 0; i < len; i++)
    {
        G.drawPolyline(polylines[i]);
    }
}


function facesToUncomplementedPolylines(face_infos)
{
    return facesToPolylines(face_infos, false);
}

function facesToPolylines(face_infos, allow_complemented_faces)
{

    if(allow_complemented_faces === undefined)
    {
        allow_complemented_faces = false;
    }

    var output = [];

    var len = face_infos.length;
    for(var i = 0; i < len; i++)
    {
        var face_info = face_infos[i];
        var polyline = face_info.polyline;
        polyline.setAssociatedData(face_info);
        
        polyline.name = "index " + i;

        // Add non complemented faces and complemented faces if they are permitted.
        if(!polyline.isComplemented() || allow_complemented_faces)
        {
            output.push(polyline);
        }
    }

    return output;
}

function Fill_Bucket_Controller()
{
    // The circle that follows the mouse.
    this.mouse_circle = new BDS.Circle(new BDS.Point(0, 0), 3, true);
    this.faces_stored  = []
    this.colors_stored = []
}

Fill_Bucket_Controller.prototype =
{
    mouse_down(event)
    {
        
    },

    mouse_up(event)
    {

    },

    mouse_move(event)
    {

        this.mouse_circle.setPosition(event.x, event.y);
        var mouse_pos = this.mouse_circle.getPosition();

        // highlight the faces that the mouse is currently over.
        // FIXME: I will eventually want to perform this query on edges, rather than faces.
        var box = this.mouse_circle.generateBoundingBox();
        var polylines = EX.BVH.query_box_all(box);

        //EX.postProcessor.eraseEdgesInCircle(this.mouse_circle);

        // Revert all previous faces to their original colors.
        var len = this.faces_stored.length;
        for(var i = 0; i < len; i++)
        {
            face_stored       = this.faces_stored.pop();
            face_stored.color = this.colors_stored.pop();
        }

        // Don't do anything more if there are no polylines.
        if(polylines.length == 0)
        {
            return;
        }

        // Remember face and color and set the face that would be filled to white.
        var len = polylines.length;
        for(var i = 0; i < len; i++)
        {
            polyline  = polylines[i];
            face_info = polyline.getAssociatedData();
            this.faces_stored.push(face_info);
            this.colors_stored.push(face_info.color);

            // highlight the selected faces.
            face_info.color = EX.G.interpolateColor(face_info.color, 0xffffff, .75);

        }

        return;

    },

    // Difference in time between the previous call and this call.
    time(dt)
    {
        // Clear the screen for new drawing.
        EX.G.clearScreen();

        // Draw these faces to the screen.
        drawFaceInfoArray(EX.G, EX.faces);

        // Draw the BVH.
        //drawPolyLine_Array(EX.G, EX.box_lines);

        // Draw the mouse.
        EX.G.strokeColor(0xffffff);
        EX.G.fillColor(0x111111);
        EX.G.drawCircle(this.mouse_circle);
    },

    window_resize(event)
    {

    }

}



// Run Example.
main();