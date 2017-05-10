/*
 * Verts Controller.
 * Written by Bryce Summers on 5 - 10 - 2017
 *
 * TODO:
 * - Displays vert locations to user.
 * - Manages a BVH of vertex locations.
 * - Allows a user to click and drag a vertex.
 * - Topologically disconnects a node from its neighbors and reconnects at the new location.
 * - Manages association between verts and curves. Allows users to modify the positions and tangents.
 */

function Controller_Verts(postProcessor, graphics)
{
    // Store inputs.
    this.postProcessor = postProcessor

    // The circle that follows the mouse.
    this.radius = 2;
    this.mouse_circle = new BDS.Circle(new BDS.Point(0, 0), this.radius, true);

    this.mouse_pressed = false;
  
    this._G_graph  = graphics;
    this._G_canvas = graphics.getLowerG();

    this._active = true;
    this._graph = this.postProcessor.getCurrentGraph();


    // Interaction logic.
    this.selected_vertex = null
}

Controller_Verts.prototype =
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
    },

    mouse_up(event)
    {
        this.mouse_pressed = false;
    },

    mouse_move(event)
    {
        // Move the circle centered on the new mouse position.
        this.mouse_circle.setPosition(event.x, event.y);

        // Update the current mouse selection when the mouse is unpressed.
        if(!this.mouse_pressed)
        {
            this.select_vertex();
            return;   
        }

        // Move the selected vertex when the mouse is pressed.
        if(this.mouse_pressed)
        {
            this.move_vertex();
            return;
        }
           
    },

    select_vertex()
    {
        var pt = this.circle.getPosition();
        this.selected_vertex = this.postProcessor.query_vertex_at_pt();
    },

    move_vertex()
    {
        this.selected_vertex.data.position = this.circle.getPosition()
    },

    // Difference in time between the previous call and this call.
    time(dt)
    {
        // Draw fancy verts over top of the graph.
        //this._G_graph.drawVerts(this._graph);
        this.drawVerts();
        this.drawMouse();
    },

    drawMouse()
    {
        // Draw the mouse.
        this._G_canvas.strokeColor(0xffffff);
        this._G_canvas.fillColor(0x111111);
        this._G_canvas.drawCircle(this.mouse_circle);
    },

    drawVerts()
    {
        iter = this._graph.verticesBegin();

        while(iter.hasNext())
        {
            var vert = iter.next();
            var point = vert.data.point;

            var circle = new BDS.Circle(point, 5, true);

            // Vertex Circle.
            this._G_canvas.strokeColor(0xffffff);

            // Display normal vertices in grey.
            if(vert != this.selected_vertex)
            {
                this._G_canvas.fillColor(0x222222); // Grey.
            }
            else // Display the selected vertex in green.
            {
                this._G_canvas.fillColor(0x00ff00); // Red.
            }

            this._G_canvas.drawCircle(circle);

            // Text Label.
            this._G_canvas.fillColor(0xffffff);
            this._G_canvas.drawText(vert.id, point.x + 16, point.y + 16);
        }
    },

    window_resize(event)
    {

    },

    finish()
    {
        // TODO.
        //throw new Error("TODO");
        console.log("TODO");
    }

}