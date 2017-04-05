/*
 * New Line Embedding Controller.
 * Moved here by Bryce Summers on 4.4.2017
 *
 * Logic for a simple polyline drawing tool that is then embedded into a HalfEdgeGraph using a 
 * SCRIB.PolylinePostProcessor object.
 */

function Controller_NewLine(postProcessor, graphics)
{
    // The circle that follows the mouse.
    this.radius = 5;
    this.mouse_circle = new BDS.Circle(new BDS.Point(0, 0), this.radius, true);

    this.mouse_pressed = false;
  
    // The list of constructed lines.
    this.lines = [];

    // The current line being constructed.
    this.current_line = null;

    this.lastPoint    = null;
    this.currentPoint = null;


    // Used for executing the algorithmic commands.
    this.postProcessor = postProcessor;

    // SCRIB.G_Graphs object, a BDS.G_Canvas may be retrieved from within it.
    this._G_graph  = graphics;
    this._G_canvas = graphics.getLowerG();

    this._active = true;

    this._graph = this.postProcessor.getCurrentGraph();
}

Controller_NewLine.prototype =
{
    setActive(isActive)
    {
        this._active = isActive;

        if(isActive === false)
        {
            this.finish();
        }
    },

    isActive()
    {
        return this._active;
    },

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

            this.finish();
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

        if(this.current_line !== null)
        {
            this._G_graph.drawPolyLine_Array([this.current_line]);
        }

        // Draw the mouse.
        this._G_canvas.strokeColor(0xffffff);
        this._G_canvas.fillColor(0x111111);
        this._G_canvas.drawCircle(this.mouse_circle);

        // Draw fancy verts over top of the graph.
        this._G_graph.drawVerts(this._graph);
    },

    drawVerts()
    {
        iter = this._graph.verticesBegin();

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
        this.postProcessor.embedAnotherPolyline(line);
    },

    finish()
    {
        this.current_line = null;
    }

}