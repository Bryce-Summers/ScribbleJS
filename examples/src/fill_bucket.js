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

    /* Testing Square.
    var s0 = new BDS.Point(50, 50);
    var s1 = new BDS.Point(100, 50);
    var s2 = new BDS.Point(100, 100);
    var s3 = new BDS.Point(50, 100);

    var line2 = new BDS.Polyline(true, [s0, s1, s2, s3]);
    */

    /*
    EX.G.drawPolyline(line1);
    EX.G.drawPolyline(line2);
    */

    lines = [line1, line2]

    range = new BDS.Box(new BDS.Point(0,   0),
                        new BDS.Point(500, 500))

    line3 = new BDS.Polyline(true);
    for (var i = 0; i < 50; i++)
    {
        line3.addPoint(range.getRandomPointInBox());
    }
    lines.push(line3);

    // Embed the polylines within a graph.
    var embedder = new SCRIB.PolylineGraphEmbedder();
    var graph    = embedder.embedPolylineArray(lines);

    // Now Use a Post Processor to derive easy to work with structures which may be drawn to the screen.
    EX.postProcessor = new SCRIB.PolylineGraphPostProcessor();

    EX.postProcessor.load_graph(graph);

    // Immediately write out the graph to face info structures.
    EX.faces = EX.postProcessor.convert_to_face_infos();

    // Generate a BVH.
    EX.BVH = new BDS.BVH2D(facesToPolylines(EX.faces));

    EX.box_lines = EX.BVH.toPolylines();

    EX.mouse = {x:0, y:0};
}

// Draws an array of SCRIB.Face_Info structures to the screen,
// using HTML5 Canvas2D.
function drawFaceInfoArray(G, face_info_array, face_colors)
{
    var len = face_info_array.length;
    for(var i = 0; i < len; i++)
    {
        face = face_info_array[i];

        // Note: We could put the color attribute in face.face.faceData.color,
        // But, I want to keep halfedge stuff out of my ScribbleJS user's mind...
        // Instead they should interact directly with the Face_Info objects.
        if (face.color === undefined)
        {
            face.color = G.randomColor();
        }

        color = face.color;

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

function facesToPolylines(face_infos)
{
    var output = [];

    var len = face_infos.length;
    for(var i = 0; i < len; i++)
    {
        output.push(face_infos[i].polyline);
    }

    return output;
}

function Fill_Bucket_Controller()
{
    this.face_stored  = null
    this.color_stored = null
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
        EX.mouse.x = event.x;
        EX.mouse.y = event.y;

        // Highlight the face that the mouse is currently over.
        polyline = EX.BVH.query_point(new BDS.Point(EX.mouse.x, EX.mouse.y));

        // Revert previous color on previous face.
        if(this.face_stored != null)
        {
            this.face_stored.color = this.color_stored;
            this.face_stored = null;
        }

        // Don't do anything more if the polyline is null.
        if(polyline === null)
        {
            return
        }

        // Remeber face and color and set the face that would be filled to white.
        face_info = polyline.getAssociatedData()
        this.face_stored  = face_info;
        this.color_stored = face_info.color;
        face_info.color   = 0xffffff;//Whie.


    },

    // Difference in time between the previous call and this call.
    time(dt)
    {
        // Clear the screen for new drawing.
        EX.G.clearScreen();

        // Draw these faces to the screen.
        drawFaceInfoArray(EX.G, EX.faces);
        //drawPolyLine_Array(EX.G, EX.box_lines);

        // Draw the mouse.
        EX.G.strokeColor(0xffffff);
        EX.G.fillColor(0x111111);
        EX.G.drawCircle(EX.mouse.x, EX.mouse.y, 10);
    },

    window_resize(event)
    {

    }

}



// Run Example.
main();