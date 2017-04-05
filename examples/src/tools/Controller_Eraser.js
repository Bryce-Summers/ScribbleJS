/*
 * Fills Controller.
 * Moved here by Bryce Summers on 4.4.2017.
 * 
 * This class indicates the logic to make a simple fill bucket tool.
 */

function Controller_Eraser(postProcessor, graphics)
{
    // The circle that follows the mouse.
    this.radius = 2;
    this.mouse_circle = new BDS.Circle(new BDS.Point(0, 0), 20, true);
    this.faces_stored  = []
    this.colors_stored = []

    this.mouse_pressed = false;

    this.halfedges = [];

    // Used for executing the algorithmic commands.
    this.postProcessor = postProcessor;

    // SCRIB.G_Graphs object, a BDS.G_Canvas may be retrieved from within it.
    this._G_graph  = graphics;
    this._G_canvas = graphics.getLowerG();

    this._active = true;
}

Controller_Eraser.prototype =
{

    setActive(isActive)
    {
        this._active = isActive;
    },

    isActive()
    {
        return this._active;
    },

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
        var faces = this.postProcessor.query_faces_in_circle(this.mouse_circle);

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
            face_info.color = this._G_canvas.interpolateColor(face_info.color, 0xffffff, .75);
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
            var edge_infos = this.postProcessor.halfedgesToEdges(this.halfedges);

            // Erase every edge and any trivial elements that arise.
            params = {erase_lonely_vertices: true}
            this.postProcessor.eraseEdges(edge_infos, params);
            this.faces = this.postProcessor.generate_faces_info();

            var graph = this.postProcessor.getCurrentGraph();
            this._G_graph.colorGraph(graph, this.faces);
        }

        return;

    },

    // Difference in time between the previous call and this call.
    time(dt)
    {
     
        // Draw the faces to the screen.
        //this._G_graph.drawFaceInfoArray(this.faces);

        // Draw the set of edges that the user is threatening to delete.
        this._G_graph.drawEdgeInfoArray(this.halfedges);

        // Draw the mouse with circle.
        this._G_canvas.strokeColor(0xffffff);
        this._G_canvas.fillColor(0x111111);
        this._G_canvas.drawCircle(this.mouse_circle);
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
