###

A Useful Graphics class for drawing Scribble.js objects,
such as Polyline Graph embeddings, HalfedgeGraphs, etc
onto a canvas element.

Takes in a BDS.G_ object and creates these calls using that object.
Because of this, A canvas target drawing class may be swapped out for a three.js, serial writing, 
or alternative drawing class that comes along.


It also has some visual design and aethetics functions, such as colorGraph(), which 6 colors a list of face_infos.

###

class SCRIB.G_Graphs

    constructor: (@_G) ->

        # @_G : BDS.G_... object that implements the BDS.Interface_G interface.

    # Allows users to change the underlying graphics object.
    setLowerG: (g) -> @_G = g

    # Allows users to retrive the lower level graphics object.
    getLowerG: () -> @_G

    drawVerts: (graph) ->

        iter = graph.verticesBegin()

        while iter.hasNext()
        
            vert  = iter.next()
            point = vert.data.point

            circle = new BDS.Circle(point, 5, true)

            @_G.strokeColor(0xffffff)
            @_G.fillColor  (0x222222) # Grey.
            @_G.drawCircle (circle)

            @_G.fillColor(0xffffff) # Grey.
            @_G.drawText(vert.id, point.x + 16, point.y + 16)

    # Draws an array of SCRIB.Face_Info structures to the screen,
    # using HTML5 Canvas2D.
    drawFaceInfoArray: (face_info_array) ->

        comp_faces = []
        len = face_info_array.length
        for i in [0...len] #var i = 0; i < len; i++
        
            face = face_info_array[i]

            # Note: We could put the color attribute in face.face.faceData.color,
            # But, I want to keep halfedge stuff out of my ScribbleJS user's mind...
            # Instead they should interact directly with the Face_Info objects.
            if face.color == undefined
                face.color = @_G.randomColor()

            color = face.color

            # Draw Non-complemented faces.
            if not face.isExterior()
            
               @_G.fillColor(color)
               @_G.strokeColor(0x000000)
               @_G.drawPolygon(face.polyline)
               @_G.drawPolyline(face.polyline)
            
            else
            
                # Draw complemented faces later.
                comp_faces.push(face)

        while comp_faces.length > 0
        
            face = comp_faces.pop()

            # Draw all of the complemented faces.
            @_G.strokeColor(0xffffff)
            @_G.drawPolyline(face.polyline)


    drawEdgeInfoArray: (edge_info_array) ->
    
        # Red Strokes.
        @_G.strokeColor(0xff0000)

        len = edge_info_array.length
        for i in [0...len] #(var i = 0; i < len; i++)
        
            edge_info = edge_info_array[i]
            @_G.drawPolyline(edge_info.polyline)

    drawPolyLine_Array: (polylines) ->
    
        # Red Strokes.
        @_G.strokeColor(0xff0000)

        len = polylines.length
        for i in [0...len] #(var i = 0; i < len; i++)
            @_G.drawPolyline(polylines[i])

    # This function 6 colors the given list of faces.
    colorGraph: (graph, face_infos) ->      

        faceGraph = new SCRIB.FaceGraph(graph)
        coloring = faceGraph.autoColor()

        colors = [0xbae3ff,
                  0xffbae3,
                  0xe3ffba,
                  0xffd6ba,
                  0xbac1ff,
                  0xbafff9]

        for i in [0...face_infos.length] by 1 #(var i = 0; i < face_infos.length; i++)
        
            face_info = face_infos[i]

            color_id = parseInt(coloring[face_info.id])

            # Assign colors based on coloring.
            if color_id >= colors.length
                face_info.color = @_G.newColor(100, 100, 100)
            else
                face_info.color = colors[color_id]