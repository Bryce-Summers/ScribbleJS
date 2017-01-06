###
* Transforms a set of input polylines into a planar graph embedding.
*
* Written by Bryce Summers.
*
* 8/16/2016: Written as a more fully advanced version of FaceFinder.h,
*            which outputs sophisticated graph structures oozing with useful connectivity information.
* 1/4/2017:  Ported to Coffeescript.
*
* Original C++ code written for the STUDIO for Creative Inquiry at Carnegie Mellon University.
###

###
* These algorithms include:
* Preprocessing:
* [EMPTY]
*
* Main Algorithm:
* 1. The main algorithm for embedding a set of polylines in space and determining the set of non chordal cycles in the
*    associated embedded planar graph.
*
* - A polygon is closed if it has identical starting and ending points and open otherwise.
*   The algorithm may be configured to output either open or closed polygons based on the closed_loop mode state.
*
* FIXME: If a user draws a second line completely around an original line, then their will be faces defined by both an external
*        face on the original polyline embedding and an internal face on the new enclosing embedding.
*        This may invalidate some users' assumptions of a global planar graph embedding without any holes.
*
* Post Processing:
* 1. Determine internal and external faces. (Initial Release)
* 2. Determine trivial and non trivial area faces according to a constant area threshold value. (8/11/2016)
*    (If you can't think of any good constant values, you might want to look at the field of
*     Topological Data Analysis and their 'barcode' concept: https://en.wikipedia.org/wiki/Topological_data_analysis.
* 3. Clipping off tails, i.e. portions of faces that enclose 0 area. (8/11/2016)
*    This could potentially be put into the getCycle function, but I think that it is best to make this a dedicated post processing step instead
*    in order to preserve the simplicity of the main algorithm.
*    This algorithm properly handles faces with either duplicated or non-duplicated starting and ending points.
*    i.e. Those produced in open and closed mode.
###


###
// FIXME: Write a list of all of the relevant interesting properties of the my planar embedding implementation.
// Edges always point to the forward facing halfedge.
// forward facing half edges are consecutively ordered in the first half.
// backwards facing half edges are consecutively ordered in the reverse order of the first half.
###


class SCRIB.PolylineGraphEmbedder

        ###
        A User can explicitly pass false to force the intersection points to be found using a brute force algorithm that
        may potentially be more robust and reliable than the optimized intersection algorithm,
        but it kills the performance.
        ###
        constructor: (@_useFastAlgo) ->
            if @_useFastAlgo == undefined
                @_useFastAlgo = true

            # The canonical collection of points at their proper indices.
            # BDS.Point[]
            @_points = []

            # The original input lines.
            # SCRIB.Line[]
            @_lines_initial = [];

            # Split version of original input lines, where lines only intersect at vertices.
            # SCRIB.Line[]
            @_lines_split = []

            ###
            // The graph that is being built.
            // Once it is returned, the responsibility for this memory transfers to the user and the pointer is forgotten from this class.
            # FIXME: Should this graph embedded remember this guy?
            ###
            @_graph = null

        # --- Public API.

        ###
        Derives a planar graph embedding from the given input polyline.
        Assumes all points are distinct.
        ###
        #SCRIB.Polyline -> SCRIB.Graph
        embedPolyline: (inputs) ->

            # Handle Trivial Input.
            if inputs.size() <= 1

                return @_trivial(inputs)

            # Make sure that the previous data is cleared.
            @_loadPolyline(inputs)

            return @_do_the_rest()

        ###
        # Derive faces from a set list of vertex disjoint polyline inputs.
        # Note: Each individual polyline specifies properties such as being closed or not.
        # Polyline[] (An array of polylines) -> SCRIB.Graph
        ###
        embedPolylineArray: (inputs) ->

            # Make sure that the previous data is cleared.
            len = inputs.length
            for e in inputs
            
                @_loadPolyline(e)

            return @_do_the_rest()


        # --- Private functions

        # The trivial function constructs the proper output for input polylines of size 1 or 0.
        # ASSUMES input is of size 0 or 1.
        # SCRIB.Polyline -> Graph
        _trivial: (polyline) ->

            graph = @_newGraph()

            if polyline.size() < 1
            
                return graph # Trivial empty Graph.
            

            # 1 point Graph.

            ###
            We construct one of each element for the singleton graph.
            NOTE: This allocation is a wrapper on top of the Graph allocation function, which allocates its Vertex_Data object.
            the other functions this->new[ ____ ] work in the same way.
            ###
            vertex      = @_newVertex()
            vertex_data = vertex.data
            edge        = @_newEdge()

            interior = @_newFace()
            exterior = @_newFace()
            interior_data = interior.data
            exterior_data = exterior.data

            halfedge = @_newHalfedge()
            twin     = @_newHalfedge() # Somewhat fake, since singleton graphs are degenerate.

            vertex_data.point = polyline.getPoint(0)

            vertex.halfedge = halfedge
            edge.halfedge   = halfedge

            # The interior is trivial and is defined by a trivial internal and external null area point boundary.
            interior.halfedge = halfedge
            interior_data.addHole(exterior)

            exterior.halfedge = halfedge

            # Self referential exterior loop.
            halfedge.edge   = edge
            halfedge.face   = exterior
            halfedge.next   = halfedge
            halfedge.prev   = halfedge
            halfedge.twin   = twin
            halfedge.vertex = vertex

            # Self referential interior loop.
            twin.edge   = edge
            twin.face   = interior
            twin.next   = twin
            twin.prev   = twin
            twin.twin   = halfedge
            twin.vertex = vertex

            return graph


        # Perform the rest of the embedding algorithm.
        # () -> Graph
        _do_the_rest: () ->

            # ASSUMPTION: Step 1. Input Loading has been acomplished.
            # We should have a list of indexed points and index associated edges.

            @_splitIntersectionPoints()
            @_allocate_graph_from_input()
            @_sort_outgoing_edges_by_angle()
            @_associate_halfedge_cycles()

            # SCRIB.Graph
            output = @_deriveFaces()

            # Deallocate unneeded memory, only needed for construction.
            output.delete_index_arrays()


            @_cleanup();

            return output;

        # -- Step 1. Compute canonical input structures.

        ###
        The embedding is broken down into seperate phases. Here I have listed each operation,
        followed by the data structures that they have built.

        Appends the given input points to the collated single input point array.
        Performs point fudging to avoid degenerate behavior.
        Starts up the indexed collection of points.
        SCRIB.Polyline -> ()
        ###
        ###
        New Constructed data Fields:
        //The canonical collection of points at their proper indices.
        BDS.Point[] @_points
        // The original input lines.
        SCRIB.Line[] @_lines_initial
        ###
        _loadPolyline: (polyline) ->

            # Populate the original points.
            len = polyline.size()

            # The offset is the initial index of the first input point.
            # We can therefore load multiple input lines and keep the indices distinct.
            offset = @_points.length

            for i in [0...len] by 1
            
                # FIXME: I might no any of these vertical line prevention techniques.
                input_point = polyline.getPoint(i)#.add(new BDS.Point(Math.random(), Math.random()))

                # A Paranoid vertical line prevention technique.
                if (offset > 0 or i > 0) and @_points[offset + i - 1].x == input_point.x
                
                    input_point.x += .001
                

                @_points.push(input_point)
                

            # Populate the original lines.
            for i in [0...len - 1] by 1
            
                @_lines_initial.push(new SCRIB.Line(i + offset, i + offset + 1, @_points))
            

            ###
            Add a line connecting the first and last points on the original set of input points if
            the polyline is closed.
            In other words put a duplicate copy of the initial point.
            ###
            if polyline.isClosed()

                # connects last point at index (len - 1 + offset) to the first point, located at index (0 + offset).
                @_lines_initial.push(new SCRIB.Line(len - 1 + offset, 0 + offset, @_points))

            return


        # -- Step 2. Find intersections in the input and compute the embedded polyline structure.

        ###
        Intersects the input lines, then splits them and connects them appropiatly.
        Populates the list of edge disjoint lines that only intersect at vertices.
        puts the edge in consecutive order following the input polylines.
        results put into this.lines_split
        () -> ()
        ###
        ###
        New Constructed data Field:
        Split version of original input lines, where lines only intersect at vertices.
        SCRIB.Line[] @_lines_split
        ###
        _splitIntersectionPoints: () ->

            intersector = new SCRIB.Intersector()

            # Use a custom made O(maximum vertical overlap * log(maximum vertical overlap).
            # Very small constant factors, cache friendly.
            if (@_bUseFastAlgo)

                intersector.intersect(@_lines_initial)
            else
                # Naive brute force algo.
                # N^2. Small constants. As robust as it gets.
                intersector.intersect_brute_force(@_lines_initial)

            # Populate the split sequence of lines.
            numLines = @_lines_initial.length

            # Populates the list of edge disjoint lines that only intersect at vertices.
            # puts the edge in consecutive order following the input polylines.
            for i in [0...numLines] by 1

                line = @_lines_initial[i]
                line.getSplitLines(@_lines_split)

            return


        ###
        #-- Step 3. Proccess the embedded input and initialize the Planar Graph vertices, edges, and halfedges.
        Allocates the output graph object and allocates vertices, edges, and halfedges for the input data.
        Vertices are Indexed as follows [original points 1 for input polyline 1, then 2, ...,
        new intersection points for polyline 1, then 2, etc, ...]
        Halfedges are indexed in polyline input order, then in backwards input order.
        () -> ()
        ###
        ###
        New Constructed data Field:
        The graph that is being built and will eventually be returned to the user.
        SCRIB.Graph @_graph
        ###
        _allocate_graph_from_input: () ->

            @_graph = @_newGraph()

            # -- Allocate all Vertices and their outgoing halfedge temporary structure.
            for point in @_points

                vert      = @_newVertex()
                vert_data = vert.data

                vert.halfedge   = null
                vert_data.point = point

            # -- Allocate 2 halfedges and 1 full edge for ever line in the split input.
            
            for e in @_lines_split
            
                @_newHalfedge()
                @_newHalfedge()
                @_newEdge()
            
            ###
            Associate edges <-> halfedges.
                  halfedges <-> twin halfedges.
                  halfedges <-> vertices.
            ###
            last_forwards_halfedge  = null
            last_backwards_halfedge = null
            len = @_lines_split.length
            last_index = len * 2 - 1
            for i in [0 ... len] by 1
            
                line        = @_lines_split[i]
                vertex_ID      = line.p1_index
                vertex_twin_ID = line.p2_index
                edge_ID        = i
                halfedge_ID    = i              # Forwards halfedges with regards to the polyline.
                twin_ID        = last_index - i # Backwards halfedges.

                edge      = @_graph.getEdge(edge_ID)
                halfedge  = @_graph.getHalfedge(halfedge_ID) # Forwards facing.
                twin      = @_graph.getHalfedge(twin_ID)     # Backwards facing.
                vert      = @_graph.getVertex(vertex_ID)
                vert_twin = @_graph.getVertex(vertex_twin_ID)

                vert_data      = vert.data
                vert_twin_data = vert_twin.data

                # Edge <--> Halfedge.
                edge.halfedge = halfedge
                halfedge.edge = edge
                twin.edge     = edge

                # Halfedge <--> twin Halfedges.
                halfedge.twin = twin
                twin.twin     = halfedge

                # Halfedge <--> Vertex.

                halfedge.vertex = vert
                twin.vertex     = vert_twin

                # Here we gurantee that Halfedge h->vertex->halfedge = h iff
                # the halfedge is the earliest halfedge originating from the vertex in the order.

                # FIXME: This no longer seems necessary, because of the outgoing edge structure.
                # Desired properties may be maintained at a later step.

                if vert.halfedge == null
                
                    vert.halfedge = halfedge
                

                if vert_twin.halfedge == null
                
                    vert_twin.halfedge = twin
                

                # -- We store outgoing halfedges for each vertex in a temporary outgoing edges structure.
                debugger if halfedge == undefined or twin == undefined

                vert_data.outgoing_edges.push(halfedge)
                vert_twin_data.outgoing_edges.push(twin)

            # End of Association For Loop.
            return


        # -- Step 4. Sort all outgoing edge lists for intersection vertices by the cartesian angle of the edges.
        # () -> ()
        _sort_outgoing_edges_by_angle: () ->

            # Sort each outgoing edges list.
            iter = @_graph.verticesBegin()

            while iter.hasNext()
            
                vert_data      = iter.next().data
                outgoing_edges = vert_data.outgoing_edges
                @_sort_outgoing_edges(outgoing_edges)

            return


        # Step 4 helper function.
        # Sorts the outgoing_edges by the angles of the lines from the center
        # point to the points cooresponding to the outgoing edges.
        # SCRIB.Halfedge[]
        _sort_outgoing_edges: (outgoing_edges) ->

            # Initialize useful information.
            len = outgoing_edges.length

            # Less than 2 are already sorted, regardless of orientation.
            return if len <= 2

            # Note: len == 3 is sorted, but possibly of the wrong orientation.

            # float[]
            angles = []

            # Extract central information.
            outgoing_halfedge_representative = outgoing_edges[0]
            center_vert  = outgoing_halfedge_representative.vertex
            center_data  = center_vert.data
            center_point = center_data.point

            # Populate the angles array with absolute relative angles.

            for edge in outgoing_edges
            
                # SCRIB.Halfedge's
                hedge_out = edge
                hedge_in  = hedge_out.twin

                outer_vert  = hedge_in.vertex
                outer_data  = outer_vert.data
                outer_point = outer_data.point

                angle = Math.atan2(outer_point.y - center_point.y,
                                   outer_point.x - center_point.x)
                angles.push(angle)
            

            # Insertion sort based on the angles.
            for i in [0...len] by 1
                for i2 in [i - 1 .. 0] by -1#for (i2 = i - 1; i2 >= 0; i2--)

                    i1 = i2 + 1

                    if angles[i2] <= angles[i1]
                    
                        break
                    

                    # -- Swap at indices i2 and i2 + 1.
                    # Keep the angle measurements synchronized with the halfedges.
                    temp_f     = angles[i2]
                    angles[i2] = angles[i1]
                    angles[i1] = temp_f

                    temp_he = outgoing_edges[i2]
                    outgoing_edges[i2] = outgoing_edges[i1]
                    outgoing_edges[i1] = temp_he

                    debugger if outgoing_edges[i1] == undefined or outgoing_edges[i2] == undefined

            return

        ###
        # -- Step 5.
        Determines the next and previous pointers for the halfedges in the Graph.
        This is done almost entirely using the sets of outgoing edges for each vertex.
        vertices of degree 2 associate their 2 pairs of neighbors.
        vertices of degree are on a tail and associate their one pair of neighbors.
        vertices of degree >2 are intersection points and they first sort their neighbors, then associate their star.
        This function sets the Vertex_Data objects classification data.
        # () -> ()
        ###
        _associate_halfedge_cycles: () ->
            
            iter = @_graph.verticesBegin()
            while(iter.hasNext())
            
                vert = iter.next()
                vert_data      = vert.data
                outgoing_edges = vert_data.outgoing_edges
                degree = outgoing_edges.length

                # Singleton point.
                if degree == 0
                
                    vert_data.singleton_point = true

                    halfedge = vert.halfedge

                    # ASSERTION: halfedge != null. If construction the user inputs a graph with singleton points.
                    # FIXME: Perhaps I should allocate the half edge here for the trivial case. Maybe I should combine the
                    # places in my code where I define the singleton state.
                    halfedge.next = halfedge
                    halfedge.prev = halfedge
                    continue
                

                # Tail vertex.
                if degree == 1
                
                    vert_data.tail_point = true

                    hedge_out = vert.halfedge
                    hedge_in  = hedge_out.twin

                    hedge_out.prev = hedge_in
                    hedge_in.next  = hedge_out
                    continue
                

                # Mark junction points.
                if (degree > 2)
                
                    vert_data.intersection_point = true
                

                # Link the halfedge neighborhood.
                for i in [0...degree] by 1
                
                    hedge_out = outgoing_edges[i]

                    if hedge_out == undefined or hedge_out.twin == undefined
                        debugger

                    hedge_in  = hedge_out.twin

                    # This combined with the sort order determines the consistent orientation.
                    # I think that it defines a clockwise orientation, but I could be wrong.
                    
                    # FIXME: There is something wrong about this ordering.

                    hedge_in.next  = outgoing_edges[(i + 1) % degree]
                    hedge_out.prev = outgoing_edges[(i + degree - 1) % degree].twin
                

                continue

            # End of Vertice Iteration Loop.
            return



        ###
        # Step 6.
        # Uses the vertex and edge complete halfedge mesh to add face data.
        # Also produces simpler cycle structures along that serve as an alternate representation of the faces.
        # () -> SCRIB.Graph
        ###
        _deriveFaces: () ->

            # For each halfedge, output its cycle once.
            iter = @_graph.halfedgesBegin()
            
            # Iterate through all originating points.
            while(iter.hasNext())

                halfedge      = iter.next()
                halfedge_data = halfedge.data

                # Avoid previously traced cycles.
                if halfedge_data.marked
                    continue
                
                face          = @_newFace()
                face.halfedge = halfedge
                @_trace_face(face)
            

            # Clear the marks.
            @_graph.data.clearHalfedgeMarks();

            return @_graph;

        ###
        REQUIRES: 1. face -> halfedge well defined already.
                  2. halfedge next pointer well defined already.
        ENSURES:  links every halfedge in the loop starting and ending at face -> halfedge
                  with the face.
        # SCRIB.Face -> ()
        ###
        _trace_face: (face) ->
        
            start   = face.halfedge
            current = start

            loop # do
                current.face = face
                current.data.marked = true
                current = current.next

                #while
                break unless current != start 
        
            return

        ###
        Free all of the intermediary data structures.
        Clear input structures.
        Unmark the output.
        ###
        _cleanup: () ->

            @_points        = []
            @_lines_initial = []
            @_lines_split = []

        # Helper functions.

        # Application Specific allocation functions.
        # REQUIRE: All allocation function need the graph to be already instantiated.

        # () -> SCRIB.Graph
        _newGraph: () ->
        
            output       = new SCRIB.Graph(true)
            output.data  = new SCRIB.Graph_Data(output)
            return output

        # () -> SCRIB.Faace
        _newFace: () ->

            output  = @_graph.newFace()
            output.data = new SCRIB.Face_Data(output)
            return output


        # () -> SCRIB.Edge
        _newEdge: () ->
        
            output      = @_graph.newEdge()
            output.data = new SCRIB.Edge_Data(output)
            return output
        

        # () -> SCRIB.Halfedge
        _newHalfedge: () ->
        
            output      = @_graph.newHalfedge()
            output.data = new SCRIB.Halfedge_Data(output)
            return output

        _newVertex: () ->
        
            output = @_graph.newVertex()
            output.data  = new SCRIB.Vertex_Data(output)
            return output