/*
 * Vector Graphics Editor example
 * Written by Bryce Summers on 4 - 3 - 2017.
 * Purpose: Demonstrates Combining Tools with a Graphic User Interface.
 */

// Small Example scope.
EX = {}

function main()
{
    setup();
    init_input(false);
    
    // FIXME: Make input controllers interchangable.

    var controller_eraser = new Fill_Bucket_Controller();
    //INPUT.add_universal_controller(controller_eraser);

    var controller_line_drawing = new Line_Draw_Controller();
    INPUT.add_universal_controller(controller_line_drawing);

    beginTime();
}

function setup()
{
    EX.G = new Canvas_Drawer();    

    // Embed the polylines within a graph.
    var embedder = new SCRIB.PolylineGraphEmbedder();
    //var graph    = embedder.embedPolyline(line);
    EX.graph    = embedder.embedPolylineArray([]);

    // Now Use a Post Processor to derive easy to work with structures which may be drawn to the screen.
    EX.postProcessor = new SCRIB.PolylineGraphPostProcessor();
    EX.postProcessor.load_graph(EX.graph);

    // Immediately write out the graph to face info structures.
    EX.faces = EX.postProcessor.generate_faces_info();
    EX.postProcessor.generateBVH();

    colorGraph(EX.faces);
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

        var color = face.color;

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
           G.fillColor(color);
           G.strokeColor(0x000000);
           G.drawPolygon(face.polyline);
           G.drawPolyline(face.polyline);
        }
        else
        {
            // Draw complemented faces later.
            comp_faces.push(face);
        }
    }

    while(comp_faces.length > 0)
    {
        face = comp_faces.pop();

        // Draw all of the complemented faces.
        G.strokeColor(0xffffff);
        G.drawPolyline(face.polyline);
    }
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
    this.radius = 2;
    this.mouse_circle = new BDS.Circle(new BDS.Point(0, 0), 20, true);
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

function Line_Draw_Controller()
{
    // The circle that follows the mouse.
    this.radius = 5;
    this.mouse_circle = new BDS.Circle(new BDS.Point(0, 0), this.radius, true);

    this.mouse_pressed = false;

    this.faces = EX.faces;
    
    // The list of constructed lines.
    this.lines = [];

    // The current line being constructed.
    this.current_line = null;

    this.lastPoint = null;
    this.currentPoint = null;
}

Line_Draw_Controller.prototype =
{
    mouse_down(event)
    {
        // Only trigger once.
        if(this.mouse_pressed)
        {
            return;
        }

        this.mouse_pressed = true;
        

        var x = event.x;
        var y = event.y;

        // -- Start a line.

        if(this.current_line === null)
        {
            this.current_line = new BDS.Polyline(false);
            this.lines.push(this.current_line);
            
            this.lastPoint = new BDS.Point(x, y);
            this.current_line.addPoint(this.lastPoint);

            this.currentPoint = new BDS.Point(x, y);
            this.current_line.addPoint(this.currentPoint);
            return;
        }

        // Stop line drawing upon double click.
        var dx = event.x - this.lastPoint.x;
        var dy = event.y - this.lastPoint.y;
        if(Math.abs(dx) + Math.abs(dy) < 4)
        {
            this.current_line.removeLastPoint();
            this.embedLine(this.current_line);

            this.current_line = null;
            return;
        }

        // Non-starting point.
        this.lastPoint = this.currentPoint;
        this.currentPoint = new BDS.Point(x, y);
        this.current_line.addPoint(this.currentPoint);
    },

    mouse_up(event)
    {
        this.mouse_pressed = false;
    },

    mouse_move(event)
    {
        // Move the circle centered on the new mouse position.
        this.mouse_circle.setPosition(event.x, event.y);

        if(this.current_line !== null)
        {
            this.currentPoint.x = event.x + Math.random();
            this.currentPoint.y = event.y + Math.random();
        }
        
    },

    // Difference in time between the previous call and this call.
    time(dt)
    {
        // Clear the screen for new drawing.
        EX.G.clearScreen();

        // Draw the faces to the screen.
        drawFaceInfoArray(EX.G, this.faces);

        if(this.current_line !== null)
        {
            drawPolyLine_Array(EX.G, [this.current_line]);
        }

        // Draw the mouse.
        EX.G.strokeColor(0xffffff);
        EX.G.fillColor(0x111111);
        EX.G.drawCircle(this.mouse_circle);

        EX.G.drawScreenBounds();

        this.drawVerts();
    },

    drawVerts()
    {
        iter = EX.graph.verticesBegin();

        while(iter.hasNext())
        {
            var vert = iter.next();
            var point = vert.data.point;

            var circle = new BDS.Circle(point, 5, true);

            EX.G.strokeColor(0xffffff);
            EX.G.fillColor(0x222222);// Grey.
            EX.G.drawCircle(circle);

            EX.G.fillColor(0xffffff);// Grey.
            EX.G.drawText(vert.id, point.x + 16, point.y + 16);
        }
    },

    window_resize(event)
    {

    },

    // Embeds the given line into the current graph embedding and updates the face list.
    embedLine(line)
    {
        EX.postProcessor.embedAnotherPolyline(line);
        this.faces = EX.postProcessor.generate_faces_info();

        colorGraph(this.faces);
    }

}


/* 0. Fix Line drawing.
 * 1. Program UI controllers to accept button polygon geometries.
 * 2. Implement a screen clearing controller.
 * 3. Retool the 'example_core.js' Input_Controller tree to allow for changes in the current tool controller.
 * 4. //sliders, etc.
 */


function UI_Controller()
{
    // The UI_Controller represents the span of all UI elements
    // within a bounding volume hiearchy.
    this.bvh = null;
}

UI_Controller.prototype =
{
    mouse_down(event)
    {
        // Only trigger once.
        if(this.mouse_pressed)
        {
            return;
        }

        this.mouse_pressed = true;
        

        var x = event.x;
        var y = event.y;

        // -- Start a line.

        if(this.current_line === null)
        {
            this.current_line = new BDS.Polyline(false);
            this.lines.push(this.current_line);
            
            this.lastPoint = new BDS.Point(x, y);
            this.current_line.addPoint(this.lastPoint);

            this.currentPoint = new BDS.Point(x, y);
            this.current_line.addPoint(this.currentPoint);
            return;
        }

        // Stop line drawing upon double click.
        var dx = event.x - this.lastPoint.x;
        var dy = event.y - this.lastPoint.y;
        if(Math.abs(dx) + Math.abs(dy) < 4)
        {
            this.current_line.removeLastPoint();
            this.embedLine(this.current_line);

            this.current_line = null;
            return;
        }

        // Non-starting point.
        this.lastPoint = this.currentPoint;
        this.currentPoint = new BDS.Point(x, y);
        this.current_line.addPoint(this.currentPoint);
    },

    mouse_up(event)
    {
        this.mouse_pressed = false;
    },

    mouse_move(event)
    {
        // Move the circle centered on the new mouse position.
        this.mouse_circle.setPosition(event.x, event.y);

        if(this.current_line !== null)
        {
            this.currentPoint.x = event.x + Math.random();
            this.currentPoint.y = event.y + Math.random();
        }
        
    },

    // Difference in time between the previous call and this call.
    time(dt)
    {
        // Clear the screen for new drawing.
        EX.G.clearScreen();

        // Draw the faces to the screen.
        drawFaceInfoArray(EX.G, this.faces);

        if(this.current_line !== null)
        {
            drawPolyLine_Array(EX.G, [this.current_line]);
        }

        // Draw the mouse.
        EX.G.strokeColor(0xffffff);
        EX.G.fillColor(0x111111);
        EX.G.drawCircle(this.mouse_circle);

        EX.G.drawScreenBounds();

        this.drawVerts();
    },

    drawVerts()
    {
        iter = EX.graph.verticesBegin();

        while(iter.hasNext())
        {
            var vert = iter.next();
            var point = vert.data.point;

            var circle = new BDS.Circle(point, 5, true);

            EX.G.strokeColor(0xffffff);
            EX.G.fillColor(0x222222);// Grey.
            EX.G.drawCircle(circle);

            EX.G.fillColor(0xffffff);// Grey.
            EX.G.drawText(vert.id, point.x + 16, point.y + 16);
        }
    },

    window_resize(event)
    {

    },

    // Embeds the given line into the current graph embedding and updates the face list.
    embedLine(line)
    {
        EX.postProcessor.embedAnotherPolyline(line);
        this.faces = EX.postProcessor.generate_faces_info();

        colorGraph(this.faces);
    }

}


// Run Example.
main();