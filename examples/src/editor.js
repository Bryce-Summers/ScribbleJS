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
    var graph    = embedder.embedPolylineArray([line1, line2]);
     //new SCRIB.Graph();

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
    var controller_click_line = new Controller_clickLine(postProcessor, graph_G);
    controller_click_line.setActive(false);
    var controller_drag_line  = new Controller_dragLine(postProcessor, graph_G);
    controller_drag_line.setActive(true);


    // -- Tools UI.
    var b1 = new BDS.Box(new BDS.Point(0,   0),
                         new BDS.Point(64, 64));

    var b2 = new BDS.Box(new BDS.Point(64,   0),
                         new BDS.Point(128, 64));

    var b3 = new BDS.Box(new BDS.Point(128,   0),
                         new BDS.Point(192, 64));

    var b4 = new BDS.Box(new BDS.Point(192,   0),
                         new BDS.Point(256, 64));

    var b5 = new BDS.Box(new BDS.Point(256,   0),
                         new BDS.Point(320, 64));

    var p1 = b1.toPolyline();
    var p2 = b2.toPolyline();
    var p3 = b3.toPolyline();
    var p4 = b4.toPolyline();
    var p5 = b5.toPolyline();

    var header       = document.getElementById("header");
    var instructions = document.getElementById("instructions");

    function deactivate()
    {
        controller_eraser.setActive(false);
        controller_click_line.setActive(false);
        controller_drag_line.setActive(false);   
    }

    function func_click_line_tool()
    {
        deactivate();

        controller_click_line.setActive(true);

        header.innerHTML       = "Tool: Rigid Polyline Tool"
        instructions.innerHTML = "Click your mouse at positions to draw a line. Click two times at the same position to finish the line.";
    }

    function func_drag_line_tool()
    {
        deactivate();

        controller_drag_line.setActive(true);

        header.innerHTML   = "Tool: Freeform Lines"
        instructions.innerHTML = "Click and move your mouse to draw lines. Double click to end a line.";
    }

    function func_eraser_tool()
    {
        deactivate();

        controller_eraser.setActive(true);

        header.innerHTML   = "Tool: Eraser"
        instructions.innerHTML = "Click and Drag your mouse to delete elements.";
    }

    // http://stackoverflow.com/questions/2897619/using-html5-javascript-to-generate-and-save-a-file
    function func_save_svg()
    {
        deactivate();

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

    function func_save_png()
    {
        deactivate();

        // Don't draw any of the UI elements,
        // so that we don't cloud the output with buttons.
        controller_draw.drawOnlyIllustration();

        var canvas = document.getElementById("theCanvas");
        url = canvas.toDataURL();

        saver = new svg_saver();
        saver.downloadURL("scribble.png", url);

    }

    var img_eraser     = document.getElementById("eraser_tool");
    var img_click_line = document.getElementById("click_line_tool");
    var img_drag_line  = document.getElementById("drag_line_tool");
    var img_save_svg   = document.getElementById("save_svg_tool");
    var img_save_png   = document.getElementById("save_png_tool");

    // We put the line drawing button first to encourage people to use it.
    controller_ui.createButton(p1, func_click_line_tool, img_click_line);
    controller_ui.createButton(p2, func_drag_line_tool, img_drag_line);
    controller_ui.createButton(p3, func_eraser_tool, img_eraser);
    controller_ui.createButton(p4, func_save_svg, img_save_svg);
    controller_ui.createButton(p5, func_save_png, img_save_png);

    // Layer 1: Clear the screen and draw the graph.
    root_input.add_universal_controller(controller_draw);

    // Layer 2: Tool's
    root_input.add_universal_controller(controller_eraser);
    root_input.add_universal_controller(controller_click_line);
    root_input.add_universal_controller(controller_drag_line);

    // Layer 3: User Interface.
    root_input.add_universal_controller(controller_ui);

    // Start in Drag line mode!
    func_drag_line_tool()

    // Begin the Amazing Experience!
    beginTime();
}

// Run Example.
window.onload = function()
{
    main();
}