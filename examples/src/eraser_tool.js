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
    EX.faces = EX.postProcessor.generate_faces_info();
    EX.postProcessor.generateBVH();
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

function Fill_Bucket_Controller()
{
    // The circle that follows the mouse.
    this.mouse_circle = new BDS.Circle(new BDS.Point(0, 0), 20, true);
    this.faces_stored  = []
    this.colors_stored = []

    this.mouse_pressed = false;
}

Fill_Bucket_Controller.prototype =
{
    mouse_down(event)
    {
        this.mouse_pressed = true;
    },

    mouse_up(event)
    {
        this.mouse_pressed = false;
    },

    mouse_move(event)
    {

        // Move the circle centered on the new mouse position.
        this.mouse_circle.setPosition(event.x, event.y);


        // -- highlight the faces that the mouse is currently over.

        // get a SCRIB.Face_Info[] containing all faces the mouse is currently over.
        var faces = EX.postProcessor.query_faces_in_circle(this.mouse_circle);

        //EX.postProcessor.eraseEdgesInCircle(this.mouse_circle);

        // Revert all previous faces to their original colors.
        var len = this.faces_stored.length;
        for(var i = 0; i < len; i++)
        {
            face_stored       = this.faces_stored.pop();
            face_stored.color = this.colors_stored.pop();
        }

        // We are done if the mouse is not currently over any faces.
        if(faces.length == 0)
        {
            return;
        }

        // Remember face and color and set the face that would be filled to white.
        var len = faces.length;
        for(var i = 0; i < len; i++)
        {
            face_info = faces[i];
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