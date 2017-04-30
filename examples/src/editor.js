/*
 * Vector Graphics Editor example
 * Written by Bryce Summers on 4 - 3 - 2017.
 * Purpose: Demonstrates Combining Tools with a Graphic User Interface.
 */

// Small Example scope.
function main()
{
    var canvas = document.getElementById("theCanvas");
    var canvas_G = new BDS.G_Canvas(canvas);
    var graph_G  = new SCRIB.G_Graphs(canvas_G);

    // Embed the polylines within a graph.
    var embedder = new SCRIB.PolylineGraphEmbedder();

    var line1 = new BDS.Polyline(false,
         [
            new BDS.Point(150, 150),
            new BDS.Point(350, 152),
            new BDS.Point(320, 352),
            new BDS.Point(150, 350),
            new BDS.Point(170, 120)
         ],
         true);

    var line2 = new BDS.Polyline(false,
         [
            new BDS.Point(250, 230),
            new BDS.Point(450, 231),
            new BDS.Point(420, 432),
            new BDS.Point(250, 430),
            new BDS.Point(270, 200)
         ],
         true);

    // We start with an empty graph.
    var graph    = new SCRIB.Graph();//embedder.embedPolylineArray([line1, line2]);

    // The Post Processor eats graphs for breakfast and provides
    // algorithmic modification function that will be used in the various editor tools.
    var postProcessor = new SCRIB.PolylineGraphPostProcessor();
    postProcessor.load_graph(graph);
    postProcessor.generateBVH();

    // FIXME: Think about optimizing the generation of face data structures across tools.

    // -- User Input.

    // Initialize the root Input controller.
    var root_input = init_input(false);


    var controller_draw         = new Controller_Draw(postProcessor, graph_G);
    var controller_ui           = new BDS.Controller_UI(canvas_G);

    // -- Tools Controllers.
    var controller_eraser       = new Controller_Eraser(postProcessor, graph_G);
    controller_eraser.setActive(false);
    var controller_line_drawing = new Controller_NewLine(postProcessor, graph_G);


    // -- Tools UI.
    var b1 = new BDS.Box(new BDS.Point(0,   0),
                         new BDS.Point(64, 64));

    var b2 = new BDS.Box(new BDS.Point(64,   0),
                         new BDS.Point(128, 64));

    var b3 = new BDS.Box(new BDS.Point(128,   0),
                         new BDS.Point(192, 64));

    var p1 = b1.toPolyline();
    var p2 = b2.toPolyline();
    var p3 = b3.toPolyline();

    var header       = document.getElementById("header");
    var instructions = document.getElementById("instructions");

    function func_line_tool()
    {
        controller_eraser.setActive(false);
        controller_line_drawing.setActive(false);

        controller_line_drawing.setActive(true);

        header.innerHTML   = "Tool Selected - Line Creation Tool Selected"
        instructions.innerHTML = "Eraser Tool: Click and move your mouse to draw lines. Double click to end a line.";
    }

    function func_eraser_tool()
    {
        controller_eraser.setActive(false);
        controller_line_drawing.setActive(false);

        controller_eraser.setActive(true);

        header.innerHTML   = "Tool Selected - Eraser Tool"
        instructions.innerHTML = "Line Tool: Click and Drag your mouse to delete elements.";
    }

    // http://stackoverflow.com/questions/2897619/using-html5-javascript-to-generate-and-save-a-file
    function func_save()
    {
        controller_eraser.setActive(false);
        controller_line_drawing.setActive(false);

        var saver = new svg_saver();
        saver.start_svg();

        var canvas = document.getElementById("theCanvas");
        var bb = new BDS.Box(new BDS.Point(0,   0),
                             new BDS.Point(canvas.width - 1, canvas.height - 1));

        saver.setBoundingBox(bb);

        // Add a black background to the exported image.
        var screen_pline = canvas_G.getScreenBoundsPolyline();
        saver.addPath(screen_pline, 0x000000, 0xffffff);

        // Now add all of the faces to the saver.
        var faces = postProcessor.generate_faces_info();
        var comp_faces = [];
        for(var i = 0; i < faces.length; i++)
        {
            var face_info  = faces[i];
            var pline      = face_info.polyline;
            var stroke;
            var fill;

            if(face_info.isComplemented())
            {
                comp_faces.push({geom:pline, fill: null, stroke:0xffffff});
                continue;

                // White.
                stroke = 0xffffff;
                fill   = null; // None.
            }
            else
            {
                // Black.
                stroke = 0x000000;
                fill   = face_info.color;
            }
            saver.addPath(pline, fill, stroke);
        }

        // Now push the complemented Faces, so that ther are on top.
        for(var i = 0; i < comp_faces.length; i++)
        {
            face = comp_faces[i];
            saver.addPath(face.geom, face.fill, face.stroke);
        }

        // White polygon with black outline.
        

        saver.generate_svg("scribble");
    }

    var img_eraser = document.getElementById("eraser_tool");
    var img_line   = document.getElementById("line_tool");
    var img_save   = document.getElementById("save_tool");

    // We put the line drawing button first to encourage people to use it.
    controller_ui.createButton(p1, func_line_tool, img_line);
    controller_ui.createButton(p2, func_eraser_tool, img_eraser);
    controller_ui.createButton(p3, func_save, img_save);

    // Layer 1: Clear the screen and draw the graph.
    root_input.add_universal_controller(controller_draw);

    // Layer 2: Tool's
    root_input.add_universal_controller(controller_eraser);
    root_input.add_universal_controller(controller_line_drawing);

    // Layer 3: User Interface.
    root_input.add_universal_controller(controller_ui);

    // Begin the Amazing Experience!
    beginTime();
}

// Run Example.
window.onload = function()
{
    main();
}