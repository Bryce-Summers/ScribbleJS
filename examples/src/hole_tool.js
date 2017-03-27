/*
 * faces bvh example.js
 * Written by Bryce Summers on 1 - 6 - 2017.
 *
 * Purpose: Demonstrates a vector area erase tool with proper topology relinking.
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

    // All of the non-hole lines.
    var lines = [];
    EX.holes = [];

    var filePath;

    // -- Load the outlines as normal scribble lines.
    var filePaths = 
        ["./point_curve_files/outline_B.txt",
         "./point_curve_files/outline_R.txt",
         "./point_curve_files/outline_Y.txt",
         "./point_curve_files/outline_C.txt",
         "./point_curve_files/outline_E.txt",
        ];

    for(let path of filePaths)
    {
        lines.push(loadPolylineFromFile(path));
    }

    lines[4].reverse();

    // -- Load the holes as hole paths.
    var filePaths = 
        ["./point_curve_files/hole_B_0.txt",
         "./point_curve_files/hole_B_1.txt",
         "./point_curve_files/hole_E.txt",
         "./point_curve_files/hole_R.txt"
        ];

    for(let path of filePaths)
    {
        EX.holes.push(loadPolylineFromFile(path));
    }

    /*
    var p0 = lines[0];
    var p1 = lines[1];
    var first_point = p1.getFirstPoint();
    var point = p1.getPoint(4);
    console.log(p0.containsPoint(point))
    debugger;
    */

    //* Testing Square.
    // FIXME: Handle problems with vertical line segments.
    // We currently can't handle inputs with lines that are perfectly on top of each other or collinear.
    /*
    var line;

    var sq0 = new BDS.Point(50, 50, 100);
    var sq1 = new BDS.Point(75, 75, 50);
    var squares = [sq0, sq1];
    //lines = []
    for(var i = 0; i < squares.length; i++)
    {
        var pt = squares[i];
        var x = pt.x;
        var y = pt.y;
        var diameter = pt.z;

        var s0 = new BDS.Point(x + 0,        y +  0);
        var s1 = new BDS.Point(x + 0,        y + diameter);
        var s2 = new BDS.Point(x + diameter, y + diameter);
        var s3 = new BDS.Point(x + diameter, y + 0);
        line = new BDS.Polyline(true, [s0, s1, s2, s3]);
        lines.push(line);
    }

    // The second line is a hole.
    EX.hole = lines[1];

    // The first line is a face.
    lines = [lines[0]];
    */

    /* Even - Odd svg filling.
    // Test out even - odd svg filling.
    var G = EX.G;
    G.fillColor(0xffffff);
    G.strokeColor(0xff0000);
    G.drawPolygonsEvenOdd(lines);
    return;
    */


    // Embed the polylines within a graph.
    var embedder = new SCRIB.PolylineGraphEmbedder();
    //var graph    = embedder.embedPolyline(line);
    EX.graph    = embedder.embedPolylineArray(lines);

    // Now Use a Post Processor to derive easy to work with structures which may be drawn to the screen.
    EX.postProcessor = new SCRIB.PolylineGraphPostProcessor();

    EX.postProcessor.load_graph(EX.graph);

    // Immediately write out the graph to face info structures.
    EX.faces = EX.postProcessor.generate_faces_info();
    EX.postProcessor.generateBVH();

    colorGraph(EX.faces);

    // Embed the holes.
    for(let hole of EX.holes)
    {
        EX.postProcessor.embedHole(hole);
    }
}

function loadPolylineFromFile(filePath)
{
    //filePath = "./point_curve_files/line_0.txt";
    var text = FileHelper.readStringFromFileAtPath ( filePath );

    // Split the lines according to line breaks.
    text = text.split('\n');
    console.log(filePath);

    var points = []
    var len = text.length
    for(var i = 0; i < len/2 - 1; i++)
    {
        var x = parseFloat(text[i*2 + 0]) + Math.random();
        var y = parseFloat(text[i*2 + 1]) + Math.random();

        var point = new BDS.Point(x, y);
        points.push(point);
    }
    pline = new BDS.Polyline(true, points);

    return pline;
}

function colorGraph(face_infos)
{
    var graph = EX.graph;

    var faceGraph = new SCRIB.FaceGraph(graph);
    var coloring = faceGraph.autoColor();

    colors = [0xbae3ff,
              0xffbae3,
              0xe3ffba,
              0xffd6ba,
              0xbac1ff,
              0xbafff9]

    for (var i = 0; i < face_infos.length; i++)
    {
        var face_info = face_infos[i];

        var color_id = parseInt(coloring[face_info.id]);

        // Assign colors based on coloring.
        if(color_id >= colors.length)
        {
            face_info.color = EX.G.newColor(100, 100, 100);
        }
        else
        {
            face_info.color = colors[color_id];
        }
    }
}

// Draws an array of SCRIB.Face_Info structures to the screen,
// using HTML5 Canvas2D.
function drawFaceInfoArray(G, face_info_array)
{

    var uncomp_faces = [];
    var comp_faces = [];

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

        // Highlight the face that the mouse is currently in.
        /*
        if(face.polyline.containsPoint(new BDS.Point(EX.mouse.x, EX.mouse.y)))
        {
            color = 0xffffff;
        }
        */

        // Draw Non-complemented faces.
        if(!face.isExterior())
        {
            uncomp_faces.push(face);
        }
        else
        {
            // Draw complemented faces later.
            comp_faces.push(face);
        }
    }

    var len = uncomp_faces.length;
    for(var i = 0; i < len; i++)
    {
        var face = uncomp_faces[i];
        var color = face.color;
        G.fillColor(color);
        var subpaths = [];
        subpaths.push(face.polyline);
        
        // Get a list of polylines representing holes.
        holes = face.getHoles();
        subpaths = subpaths.concat(holes);

        G.drawPolygonsEvenOdd(subpaths);

        //G.drawPolygon(face.polyline);
        G.strokeColor(0x000000);
        G.drawPolyline(face.polyline);

        G.strokeColor(0xffffff);

        // Draw every hole as a white border line.
        for (let hole of holes)
        {
            G.drawPolyline(hole);
        }            
    }

    // Draw all of the complemented faces.
    while(comp_faces.length > 0)
    {
        face = comp_faces.pop();

        // White.    
        G.strokeColor(0xffffff);

        // Outline.
        G.drawPolyline(face.polyline);
    }

    // Input a list of polylines.
    // Embed holes.
}

function drawEdgeInfoArray(G, edge_info_array)
{
    // Red Strokes.
    G.strokeColor(0xff0000);

    var len = edge_info_array.length;
    for(var i = 0; i < len; i++)
    {
        edge_info = edge_info_array[i];
        G.drawPolyline(edge_info.polyline);
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
    this.radius = .5;
    this.mouse_circle = new BDS.Circle(new BDS.Point(0, 0), this.radius, true);
    this.faces_stored  = []
    this.colors_stored = []

    this.mouse_pressed = false;

    this.faces = EX.faces;
    this.halfedges = [];
}

Fill_Bucket_Controller.prototype =
{
    mouse_down(event)
    {
        this.mouse_pressed = true;
        this.mouse_move(event);
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
        // if the circle is within a hole, then the containing face will not be returned.
        var faces = EX.postProcessor.query_faces_in_circle(this.mouse_circle);

        //EX.postProcessor.eraseEdgesInCircle(this.mouse_circle);

        // Revert all previous faces to their original colors.
        var len = this.faces_stored.length;
        for(var i = 0; i < len; i++)
        {
            face_stored       = this.faces_stored.pop();
            face_stored.color = this.colors_stored.pop();
        }

        this.halfedges = [];

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

        // List all intersected edges.
        for(var i = 0; i < len; i++)
        {
            face_info = faces[i];

            // NOTE: outputs into this.halfedges.
            face_info.query_halfedges_in_circle(this.mouse_circle, this.halfedges);
        }

        // Drag and erase elements.
        if(this.halfedges.length > 0 && this.mouse_pressed)
        {
            // We only want to erase each edge once,
            // So we convert the array of halfedges_info's into an array of full edge_info's.
            var edge_infos = EX.postProcessor.halfedgesToEdges(this.halfedges);

            // Erase every edge and any trivial elements that arise.
            params = {erase_lonely_vertices: true}
            EX.postProcessor.eraseEdges(edge_infos, params);
            this.faces = EX.postProcessor.generate_faces_info();
            colorGraph(this.faces);
        }

        return;

    },

    // Difference in time between the previous call and this call.
    time(dt)
    {
        // Clear the screen for new drawing.
        EX.G.clearScreen();

        this.sortFaces(this.faces);

        // Draw the faces to the screen.
        drawFaceInfoArray(EX.G, this.faces);

        // Draw the set of edges that the user is threatening to delete.
        drawEdgeInfoArray(EX.G, this.halfedges);

        // Draw the BVH.
        //drawPolyLine_Array(EX.G, EX.box_lines);

        // Draw the mouse.
        EX.G.strokeColor(0xffffff);
        EX.G.fillColor(0x111111);
        EX.G.drawCircle(this.mouse_circle);
    },

    window_resize(event)
    {

    },

    // Sorts faces from greatest to least area.
    sortFaces(faces)
    {
        var array = [];
        for(var i = 0; i < faces.length; i++)
        {
            var face = faces[i];
            var polyline = face.polyline;
            var area = polyline.computeArea();

            associated_tuple = {key: face, value:-area};
            array.push(associated_tuple);
        }

        // Sorts a list of objects with .value defined by .value in asending order.
        BDS.Arrays.sortByValue(array);

        this.faces = [];

        for(var i = 0; i < array.length; i++)
        {
            this.faces.push(array[i].key);
        }

    },

}

// Run Example.
main();