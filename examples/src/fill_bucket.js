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
    //*/

    
    EX.G.drawPolyline(line1);
    EX.G.drawPolyline(line2);


    var lines = [line1, line2]

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
    EX.faces = EX.postProcessor.generate_faces_info();

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
    this.mouse_circle = new BDS.Circle(new BDS.Point(0, 0), 3, true);
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
        this.mouse_circle.setPosition(event.x, event.y);

        var mouse_pos = this.mouse_circle.getPosition();

        // Highlight the face that the mouse is currently over.
        var polylines = EX.BVH.query_point_all(new BDS.Point(mouse_pos.x, mouse_pos.y));
        var polyline = null;

        if (polylines.length > 0)
        {
            polyline = polylines[0];
        }

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
        face_info.color   = 0xffffff;//White.
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
        EX.G.drawCircle(this.mouse_circle);
    },

    window_resize(event)
    {

    }

}



// Run Example.
main();