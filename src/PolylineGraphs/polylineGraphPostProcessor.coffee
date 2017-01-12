###
The PolylineGraphPostProcessor class.
*
* Written and adapted from FaceFinder on 8/18/2016.
* Ported to Coffeescript on 1 - 4 - 2017.
*
* Purpose:
*
* Allows users to convert Planar Polyline Embedded Graphs into mainstream C++ data structures.
* This class then provides some useful processing algorithms on these output structures.
*
* I may also put information extraction algorithms here.
*
* The key idea is that the post processor doesn't mutate the Graph object in any way.
* FIXME: Use the Graph Mutator Proccessor instead (Currenly non existant.) if you wish to modify the graph.
*
* Maybe I will make a modification mode.
###

###

Tested Features:
    convert_to_face_infos()

Untested Features:
    clipTails()
    mergeFaces()
    BDS.BVH2D = generateBVH() [requires HalfedgeMesh]

    # Splits the current embedding by the given polyline.
    embedAnotherPolyline(polyLine)
    eraseEdgesInCircle()

###

# FIXME: I am not sure if I will actually use this for anything.
class SCRIB.Edge_Info

    # SCRIB.Edge
    constructor: (@edge, @halfedge_info) ->
        @id = @edge.id



class SCRIB.Halfedge_Info

    ###
    # Represents and points to a halfedge. Its pointers may not be valid after algorithms such as tail clipping.
    // Faces and twin pointers should still be valid though...
    # @halfedge is only defined for HalfedgeGraph based souce embeddings.
    # Also contains a pointer to its face_info object.
    ###

    # SCRIB.halfedge, SCRIB.Face_Info
    constructor: (@halfedge, @face_info) ->

        vert      = @halfedge.vertex
        vert_data = vert.data

        @point = vert_data.point
        @id    = @halfedge.id

        # Create a 2 point polyline from the start to the end of this halfedge.
        # This polyline may and will be used in the construction of edge BVH's
        @polyline = new BDS.Polyline(false)
        @polyline.addPoint(@point)
        @polyline.setAssociatedData(@) # Provide a reference back to this class for BVH query calls.

        # Now add the second point
        next_vert  = @halfedge.next.vertex
        next_data  = next_vert.data
        next_point = next_data.point
        @polyline.addPoint(next_point)

class SCRIB.Face_Info

    # Input is a SCRIB.Face
    constructor: (face) ->

        @generateInfoFromFace(face)

    generateInfoFromFace: (face) ->

        if face == undefined
            face = @face
        else
            @face = face

        # SCRIB.Face_Info[]
        @holes  = []

        # SCRIB.Halfedge_Info
        @halfedges = []

        # Stores a BVH of all of the SCRIB.Halfedge_Info objects.
        @_halfedge_bvh = null

        # The polyline that is used to represent this face in a face BVH.
        @polyline = new BDS.Polyline(true) # Closed.
        @polyline.setAssociatedData(@) # Provide a reference back to this class for BVH query calls.      

        # Contains a set of all faces contributing to this unioned face.
        @faces_id_set = new Set()
        @faces_id_set.add(face.id)
        @id = face.id # The canonical id.

        # Walk the face to create the edge and point info.
        starting_half_edge = face.halfedge
        current = starting_half_edge

        # Convert the entire face into Halfedge Info Objects.
        loop # DO
                     
            halfedge_info = new SCRIB.Halfedge_Info(current, @)

            @push(halfedge_info)

            # Iterate.
            current = current.next

            # while
            break unless starting_half_edge != current

        
        @complemented = @polyline.isComplemented()
        return

    size: () ->
        return @points.length

    isClosed: () ->
        return polyline.isClosed()

    getLastPointInfo: () ->
        return @points[@points.length - 1]

    push: (halfedge_info) ->
        @halfedges.push(halfedge_info)
        @polyline.addPoint(halfedge_info.point)

    pop: () ->
        @polyline.removeLastPoint()
        return @points.pop()

    at: (index) ->
        return @points[index]

    isComplemented: () ->
        return @polyline.isComplemented()

    # We need this for drawing unclosed polylines.
    isExterior: () ->
        return @isComplemented()

    # generates the bounding volume Hierarchies from scratch.
    #BDS.BVH2D = generateBVH() [requires @_graph]
    generateBVH: () ->

        segments = @polyline.toPolylineSegments()

        len = segments.length
        for i in [0...len] by 1

            line = segments[i]
            halfedge = @halfedges[i]
            line.setAssociatedData(halfedge)

        @_halfedge_bvh = new BDS.BVH2D(segments)

        return @_halfedge_bvh

    ###
    Edge Intersection functions.
    Returns all edges within this face that are also within the given geometries.
    ###

    # BDS.Circle, Halfedge_Info[] (Optional) -> SCRIB.Halfedge_Info[]
    query_halfedges_in_circle: (circle, output) ->
        return @query_halfedges_in_geometry(circle, output)

    # BDS.Polyline, Halfedge_Info[] (Optional) -> SCRIB.Halfedge_Info[]
    query_halfedges_in_polyline: (polyline, output) ->
        return @query_halfedges_in_geometry(polyline, output)

    # BDS.Geometry, Halfedge_Info[] (Optional) -> SCRIB.Halfedge_Info[]
    query_halfedges_in_geometry: (geom, output) ->

        all_halfedges = @query_halfedges_in_box(geom.generateBoundingBox())

        # filter to only those halfedges that intersect the input geometry.
        for halfedge in all_halfedges

            polyline = halfedge.polyline

            if geom.detect_intersection_with_polyline(polyline)
                output.push(halfedge)

        return output

    # BDS.Box, [] (optional) -> SCRIB.Halfedge_Infos[]
    query_halfedges_in_box: (box, output_list) ->

        if @_halfedge_bvh == null
            @generateBVH()

        if output_list == undefined
            output_list = []

        # Extract all intersecting polylines.
        polylines = @_halfedge_bvh.query_box_all(box)

        for line in polylines
            output_list.push(line.getAssociatedData())

        return output_list


# This post processor allows the user to load a HalfedgeGraph object and then never touch the graph again.
# This class performs all of the algorithms for the user and returns results in easy to use
# Face_Info, Edge_Info, and Halfedge_Info data structures.
# These data structures themselves contain pointers to the Halfedge Graph elements, in case the user wants to do something more advanced.
class SCRIB.PolylineGraphPostProcessor


    constructor: (@_graph) ->
    
        # This is the main structure
        @_graph = null

        # SCRIB.Face_Info[]
        # If this is loaded, then future calls to convert_to_face_infos will
        # preserve the faces that still exist in the halfedgemesh in their output.
        # It is also required foor algorithms such as tail clipping.
        @_face_vector = []

        # Used for face queries.
        @_face_bvh = null


    # -- Data Structure Conversion.
    # () -> SCRIB.Face_Info[]
    # Generates a Face_Info array from the current state of the graph object.
    # sets the internal @_face_vector, which is needed for many algorithms.
    # Users should store the returned face vector and refer to it for the output results of many of these algorithms.
    # This is a very important function. It removes faces that no longer exist and updates the bvh if needed.
    # O(|old_faces| + |newly_allocated_faces| * log(n) for bounding volume hierarchy modifications, if needed.)
    # In general, you ought to generate faces the first time, before allocating the bvh.
    # The bvh may become less optimized as it goes along.
    generate_faces_info: () ->

        #SCRIB.Face_Info[]
        # the ideas is that since faces are sorted by id, we will have a one-to-one coorespoindence between old faces and
        # the faces iterated through the Halfedgegraph.
        old_faces = @_face_vector
        next_old_index = 0
        next_old_face = null
        if old_faces.length > 0
            next_old_face = old_faces[next_old_index]
            next_old_index++

        # We will go along and 
        # 1. Filter out face_infos for faces that no longer exist
        # 2. Instantiate new face_infos for faces that now exist.
        #SCRIB.Face_Info[]
        @_face_vector = []

        # Iterate through All faces in the graph.
        iter = @_graph.facesBegin()
        while iter.hasNext()

            face = iter.next()

            # Skip over old faces until we get to a relevant one.
            # Remove them from the bvh as we go.
            # We take advantage of the fact that faces are stored in id order from least to greatest.
            while next_old_face != null and next_old_face.id < face.id

                # Remove the destroyed face from the bvh.
                if @_face_bvh != null
                    
                    result = @_face_bvh.remove(next_old_face.polyline)
                    console.log(result)

                    # We want to find out what is wrong.
                    if not result
                        debugger

                if next_old_index < old_faces.length
                    next_old_face = old_faces[next_old_index]
                    next_old_index++
                else
                    # No more old faces.
                    next_old_face = null

            # Add the old faces that still exist.
            # Nothing needs to change!
            if next_old_face != null and next_old_face.id == face.id
                @_face_vector.push(next_old_face);

                if next_old_index < old_faces.length
                    next_old_face = old_faces[next_old_index]
                    next_old_index++
                else
                    next_old_face = null
                continue

            # Allocate new face_infos, add them to the bvh, if it exists.
            face_output = new SCRIB.Face_Info(face) # Closed Polyline.
            @_face_vector.push(face_output)

            if @_face_bvh != null
                @_face_bvh.add(face_output.polyline)

            continue
            # End of iteration over all faces.

        # Remove the remaining old faces that no longer have a counterpart in the graph.
        while next_old_face != null

            if @_face_bvh != null
                    
                result = @_face_bvh.remove(next_old_face.polyline)
                console.log(result)

                if next_old_index < old_faces.length
                    next_old_face = old_faces[next_old_index]
                    next_old_index++
                else
                    # No more old faces.
                    next_old_face = null

        # FIXME: Consider whether this is necessary.
        if @_face_bvh != null
            @_face_bvh.optimize()

        return @_face_vector

    get_current_faces_info: () ->
        return @_face_vector

    load_graph: (@_graph) -> # Invalidates the previous face vector.
        @_face_vector = []
        @_face_bvh = null

    # These seem a bit silly outside of C++, but maybe they will be useful to folks.
    free_face_vector: () ->
        @_face_vector = null

    free_graph: () ->
        @_graph = null


    # -- Post processing algorithms.

    ###
    Appends the indices of any external faces amongst the input list of faces to the output vector.
    NOTE : The input type is equivelant to the output type of the face finding functions,
    so using this function may be a natural extension of using the original functions.
    # int[] -> () [appends complemented faces to input]
    ###
    determineComplementedFaces: (output) ->

        len = @_face_vector.length

        for index in [0 ... len]

            face_info = @_face_vector[index]
            area = face_info.polyline.computeAreaOfPolygon()

            if area > 0
            
                output.push(index)
            
        # End of the for loop.
        return

    # Appends to output the indices of the faces of **NonTrivial** Area (area >= min_area)
    # int[], float
    determineNonTrivialAreaFaces: (output, min_area) ->

        len = @_face_vector.length

        for index in [0 ... len]
        
            face_info = @_face_vector[index]
            area = face_info.polyline.computeAreaOfPolygon()            

            # Absolute value to account for external faces.
            area = if area >= 0 then (area) else (-area)

            if area >= min_area
            
                output.push(index)

        # End of the for loop.
        return

    # Appends to output the indices of the faces of **Trivial** Area (area < min_area)
    # int[], float
    determineTrivialAreaFaces: (output, min_area) ->

        len = @_face_vector.length

        for index in [0 ... len]
        
            face_info = @_face_vector[index]
            area = face_info.polyline.computeAreaOfPolygon()            

            # Absolute value to account for external faces.
            area = if (area >= 0) then (area) else (-area)

            if area < min_area
                output.push(index)

        # End of the for loop.
        return

    ###
    Input: a set of faces, Output: a new set of faces that have no trivial contiguous subfaces.
    clips all of the polylines currently loaded in this post processor.
    ENSURES: Polygons will be output either open or closed in the manner that they are passed in.
    ENSURES: Omits faces consisting of only a single long tail.
    The user is still responsible to deallocating the original vector.
    # () -> face_info[] (with no tails)
    ###
    clipAllTails: () ->

        input  = @_face_vector
        output = []

        len = input -> size()

        for index in [0...len]

            unclipped_face = input[index]
            clipped_face   = @_clipTails(unclipped_face)

            # Append only non trivial faces to the output.
            if clipped_face.size() > 0
            
                output.push(clipped_face)
            
        return output

    # Returns a copy of the single input face without any trivial area contiguous subfaces. (Tails)
    # May return a 0 point polyline if the input line is non-intersecting.
    # SCRIB.Face_Info -> SCRIB.Face_Info
    _clipTails: (input) ->

        output = new SCRIB.Face_Info()

        len = input -> size()

        # Faces cannot enclose area if they have less than 3 vertices.
        # This pre check rules out trivial input without a start and end point.
        if len < 3 or !input.isClosed()
        
            return output # EMPTY.
        
        # NOTE: We will assume all faces are closed, otherwise it will be trivial or self-intersecting.

        #int's
        p_start = (input -> at(0)).ID
        p_end   = (input -> at(len - 1)).ID

        ###
        The main idea behind tail clipping is to transform regions of the form ABA --> A,
        in other words removing any consecutive pairs of half edges cooresponding to the same full edge.
        We therefore
        ###

        # Stores whether the last iteration of the loop clipped a tail ending.
        # We can use this to ensure that the loop goes around the starting point to properly clip all tails.
        clipped_previous = false
        non_empty_output = false

        # NOTE: we will be using the len variable in this routine to gradually cull the back of the list as needed which
        #       wraps around the arbitrary list starting point location.

        for i in [0...len]
        
            # Determine the nearest previous unpruned point, which will be pruned if it is mirrored by the next point.
            p_previous = NaN # int
            non_empty_output = output.size() > 0 # bool

            # A non pruned point exists in the output.
            if non_empty_output
            
                p_previous = output.getLastPointInfo().ID
            
            else #Otherwise use the unpruned point at the tail of the unpruned list prefix sublist.
            
                p_previous = input.points[len - 1].ID
            
            p_next = input.points[(i + 1) % len].ID

            # If haven't locally detected a tail, then we simply push the point onto the output.
            if p_previous != p_next
            
                output.push(input.at(i % len))
                clipped_previous = false
                continue
            

            # Actually prune the current point and the previous point.
            clipped_previous = true

            if (non_empty_output)
            
                # Prune output point.
                output.pop()
            
            else
            
                # Prune tail point.
                len -= 1

            ###
            Don't add the current point, because we prune it as well.
            If p_next ends up now being a non tail point, it will be successfully added during the next iteration.
            We don't add it now, because we want to give it the opportunity to pruned by its next neighbor.
            ###
            continue
        # End of For Loop.


        # Due to the wrap around nature of face loops, the beginning may be in the middle of a tail,
        # so, if necessary, we now need to prune the beginning of the output

        # We will now prune the beginning of the output.
        prune_num = 0
        while clipped_previous # Essentially a while true loop if clipped_previous is true at the end of the first pass.
        
            len = output.size()

            # Entire face has been pruned.
            if len < 3
            
                return output
            

            p_previous = (output.at(len - 1)).ID
            p_next = (output.at(prune_num + 1)).ID

            if p_previous != p_next
            
                break
            

            # Prune the head and tail of the output.
            prune_num += 1
            output.pop()
            continue
        # End of while clipped_previous.

        # If the wrap pruning pass was done, we need to downsize the array to exclude the no longer relevant data.
        if (clipped_previous)
        
            # FIXME: Make sure this works.
            output.splice(0, prune_num)
        

        return output

    ###
    Uses the currently loaded this->graph object as Input.
    Takes in a vector containing the integer IDs of the faces to be merged.
    Takes a dictionary containing integers and outputs a set of faces representing the merge.
    Outputs the result of unioning all of the faces.
    Set -> SCRIB.FaceInfo[]
    ###
    mergeFaces: (face_ID_set) ->

        # Temporarily store the raw list of face_info's in SCRIB.Face_Info[]'s
        faces_uncomplemented = []
        faces_complemented = []

        # Go through all halfedges in all relevant faces and trace any representational union faces one time each.

        for id in face_ID_Set
        
            Face     * face    = graph.getFace(id)
            Halfedge * start   = face.halfedge
            Halfedge * current = face.halfedge
            loop # DO
            
                if current.data.marked == false and @_halfedgeInUnion(face_ID_set, current)
                
                    face_info = @_traceUnionFace(face_ID_set, current)
                    if not face_info.isComplemented()
                    
                        face.complemented = false
                        faces_uncomplemented.push(face)
                    
                    else
                    
                        face.complemented = true
                        faces_complemented.push(face)

                # Try the next edge.
                current = current.next

                # While
                break unless current != start
            continue
        #End of For Loop
        

        # Clear markings.
        graph.data.clearHalfedgeMarks()

        # Now we associate face_info objects with their internal complemented hole objects.
        # SCRIB.Face_Info[]
        output = []
        
        #map<int -> SCRIB.ace_info>
        # Javascript dictionaries act as associative arrays.
        map = {}

        # On the first pass we add all exterior faces to the output and the map.
        for face_info in faces_uncomplemented
        
            output.push_back(face_info)
            set = face_info.faces_ID_set

            for id in set
            
                map[id] = face            


        # On the second pass we add all complemented faces to the proper uncomplemented face hole set.
        # FIXME: Think about what will happen if their is a complemented face that should be by itself.
        #        What about merging a complemented and uncomplemented face.
        for face_info in faces_complemented
        
            # Face_Info -> Set -> SetIterator -> {value:, done:} -> int
            id = face_info.faces_id_set.keys().next().value
            
            uncomplemented_face = map[id]

            # If the index is not associated with an uncomplemented face, (i.e. it is not found in the map.)
            # then this uncomplemented face must be singleton,
            # instead of a hole. We therefore add it to the direct output.
            if not uncomplemented_face
            
                output.push(face)
                continue

            # Otherwise we add it as a hole to the relevant face.
            uncomplemented_face.holes.push_back(face_info)

        return output


    # -- Private functions.

    ###
    Returns true iff the given hafedge is included in the output of the union of the given faces.
    I.E. returns true iff the given half edge -> face is within the set of unioned faces and half_edge->twin -> face is not.
    Tail edges, where the halfedge and its twin are on the same face are not considered to be in a halfedgeUnion face.
    Set, SCRIB.Halfedge -> bool.
    ###
    _halfedgeInUnion: (face_id_set, start) ->

        # SCRIB.Face (Halfedge element)
        face = start.face
        face_id = face.id
        face_found = face_id_set.has(face_id)

        twin_face = start.twin.face
        twin_ID   = twin_face -> ID
        twin_face_found = face_Id_set.has(twin_ID)

        # true iff Twin face not in the set of faces in the union.
        # NOTE: Tail edges with the same Face on both sides are treated as not in the union,

        return face_found and not twin_face_found

    ###
    // Given an In Union halfege, traces its face_info union face information.
    // Properly sets the output's: points and face_IDs fields.
    // Marks halfedges, therefore calling functions are responsible for unmarking halfedges.
    Set, SCRIB.Halfedge -> SCRIB.Face_Info
    ###
    _traceUnionFace: (face_ID_set, start) ->

        output = new SCRIB.Face_Info()
        output_ID_set = output.faces_ID_set

        # We only need to worry about tracing output points,
        # because the holes will associated later on from faces tracing with this function.

        # Iterate over halfedges.
        current = start
        loop # DO

            current.data.marked = true

            # Output current point (with halfedge).
            current_point_info = @_halfedgeToPointInfo(current)
            output.push(current_point)
            current_face_ID = current.face.ID
            output_ID_set.add(current_face_ID)

            # Transition to the next halfedge along this union face.
            current = @_nextUnionFace(face_ID_set, current)

            # WHILE
            break unless current != start

        return output



    # Given a halfedge inside of a unionface, returns the next halfedge within that face.
    # Set<Int>, SCRIB.Halfedge -> SCRIB.Halfedge
    _nextUnionFace: (face_ID_Set, current) ->

        # Go around the star backwards.

        # Transition from the incoming current edge to the backmost candidate outgoing edge.
        current = current.twin.prev.twin
        
        # NOTE: WE could theoretically put in an infinite loop check here, because this code will fail if the graph is malformed.

        # Keep trying out candidate outgoing faces, until we find the first one that works.
        while not @_halfedgeInUnion(face_ID_Set, current)
        
            # The cycling operations come in two forms, since we flip our orientation after each path change attempt.
            current = current.prev.twin

        return current

    # SCRIB.Halfedge -> SCRIB.Point_Info
    _halfedgeToPointInfo: (halfedge) ->

        vertex      = halfedge.vertex
        vertex_data = vertex.data
        return new SCRIB.Point_Info(vertex_data.point, vertex.ID, halfedge)


    # generates the bounding volume hierarchies from scratch.
    #BDS.BVH2D = generateBVH() [requires @_graph]
    generateBVH: () ->

        # We need the external face for deleting unfilled polylines.
        polylines = @facesToPolylines(@_face_vector, true)
        @_face_bvh = new BDS.BVH2D(polylines)

    # Converts to a set of polylines.
    # For applications such as element querying, it may be best to leave out complemented_faces.
    # Face_Info[], bool (optional) -> Polyline[]
    facesToPolylines: (face_infos, allow_complemented_faces) ->

        if allow_complemented_faces == undefined
            allow_compleemented_faces = false

        output = []

        for face_info in face_infos
            polyline = face_info.polyline

            # Add non complemented faces and complemented faces if they are permitted.
            if (not polyline.isComplemented()) or allow_complemented_faces
                output.push(polyline)

            continue;

        return output

    polylinesToAssociatedData: (polylines) ->
        output = []

        for line in polylines
            output.push(line.getAssociatedData())

        return output

    # Splits the current embedding by the given polyline.
    # Updates the internal line and face bvh's
    # BDS.Polyline -> ()
    embedAnotherPolyline: (polyLine) ->
        throw new Error("IMPLEMENT ME PLEASE!")

    ###
    # Graph wide Edge Queries.
    # Returns all elements in the graph within the given regions.
    # NOTE: If you already have faces found, it will be better to use the Face_Info query functions.
    # Note: Edge queries are implemented by first performing a face query
    # and then perfomring edge queries on those face's edge bvh's in the Face_Info objects.
    ###

    # BDS.Circle, Halfedge_Info[] (Optional) -> SCRIB.Halfedge_Info[]
    query_edges_in_circle: (circle, output) ->
        return @query_edges_in_geometry(circle, output)

    # BDS.Polyline, Halfedge_Info[] (Optional) -> SCRIB.Halfedge_Info[]
    query_edges_in_polyline: (polyline, output) ->
        return @query_edges_in_geometry(polyline, output)

    # BDS.Geometry, Halfedge_Info[] (Optional) -> SCRIB.Halfedge_Info[]
    query_edges_in_geometry: (geom, output) ->

        edges = @query_halfedges_in_box(geom.generateBoundingBox())

        for halfedge in edges

            polyline = halfedge.polyline

            if geom.detect_intersection_with_polyline(polyline)
                output.push(geom)

        return output

    # BDS.Box -> SCRIB.Halfedge_Info[]
    query_halfedges_in_box: (box, output) ->

        faces = @query_faces_in_box(box);

        if output == undefined
            output = []

        for face in faces
            # All halfedges in the bounding box.
            face.query_halfedges_in_box(box, output)

        return output


    ###
    # Face Queries.
    # Returns elements within the face bvh in the given area regions.
    ###

    # BDS.Circle -> Polyline[]
    query_faces_in_circle: (circle) ->
        return @query_faces_in_geometry(circle)

    # BDS.Circle -> Polyline[]
    query_faces_in_polyline: (polyline) ->

        return @query_faces_in_geometry(polyline)

    # Returns a list of polylines in the given geometry.
    # It needs to specify a .generateBoundingBox() function and
    # a .detect_intersection_with_polyline(line) function.
    query_faces_in_geometry: (geom) ->

        box = geom.generateBoundingBox()

        polylines_in_box = @_face_bvh.query_box_all(box)

        # Filter by intersection with circle.
        output = []
        for polyline in polylines_in_box
            if geom.detect_intersection_with_polyline(polyline)
                output.push(polyline.getAssociatedData())

        return output

    query_faces_in_box: (box) ->

        return @polylinesToAssociatedData(@_face_bvh.query_box_all(box))

    # SCRIB.HalfedgeInfo[] --> SCRIB.EdgeInfo[]
    halfedgesToEdges: (halfedge_infos) ->

        output = []

        # Don't include duplicate Edges.
        set = new Set();

        for halfedge_info in halfedge_infos

            halfedge = halfedge_info.halfedge
            edge     = halfedge.edge
            id       = edge.id

            # Avoid duplicates.
            continue if set.has(id)

            set.add(id)
            edge_info = new SCRIB.Edge_Info(edge, halfedge_info)
            output.push(edge_info)
            continue

        return output


    ###
    # Element Deletion Methods.
    # These delete all Halfedge Mesh elements within a given region.
    # They then rebuild and preserve the invariants of the mesh.
    ###

    # Erases ever one of the edges from the graph.
    # Deletes relevant halfedges, vertices, and face elements as well.
    # The user can get the results by calling .generate_faces_info()
    # SCRIB.Edge_Info -> ()
    #params = {erase_lonely_vertices: true}
    # specifies whether or not we will keep vertices of 0 degree that may be formed.
    # along with their universal face.
    eraseEdges: (edge_infos, params) ->


        for edge_info in edge_infos
            @_eraseEdge(edge_info, params)

        # Generate an updated set of faces, which will also dynamicaly remove and add faces to the bvh.
        @generate_faces_info()

        return


    # SCRIB.Edge -> ()
    # [removes edge and related halfedges, vertices, relevant elements from the HalfedgeGraph]
    # Redirects pointers to restore the graph invariants.
    # FIXME: I need to think about dynamically updating the bounding volume hierarchies.
    # I need to update the face one and the edge hierarchiy of the remaining face.
    _eraseEdge: (edge_info, params) ->

        edge = edge_info.edge

        # All we need to think about from this point forward
        # is that the two halfedges are twins of each other.
        #face1 = edge_info.halfedge_info.face_info.face
        
        # We want the merge to face to be the face info that we have a pointer to.
        # Because we want the non-merged face to be deleted during generate_faces_info()
        face_info = edge_info.halfedge_info.face_info
        if edge.halfedge.face.id == face_info.id
            halfedge1 = edge.halfedge
            halfedge2 = halfedge1.twin
        else
            halfedge2 = edge.halfedge
            halfedge1 = halfedge2.twin

        vert1 = halfedge1.vertex
        vert2 = halfedge2.vertex

        degree1 = vert1.degree()
        degree2 = vert2.degree()

        face1 = halfedge1.face
        face2 = halfedge2.face

        # Demolish face1 and fix up the faces.

        # We must merge and delete one of the faces if this edge lies on two faces.
        merge_faces = (face1 != face2)

        # We direct every halfedge on face2 to face1
        # We merge to face1, because we have a pointer to its face_info for reconstructing a bvh.
        # We destroy face2.
        # Note: There is no need to do this or to destory the face if we are not merging.
        # We can safely iterate around the face, because we have not yet made any changes.
        if merge_faces

            h0 = halfedge2.next
            current = h0

            loop
                current.face = face1
                current = current.next
                break unless current != h0

            face2.destroy()

        # Destroy lonely vertices.
        if degree1 == 1
            if params.erase_lonely_vertices
                vert1.destroy()
            else
                vert1.make_lonely()

        if degree2 == 1

            if params.erase_lonely_vertices
                vert2.destroy()
            else
                vert2.make_lonely()

        # demolish the remainder of a lonely edge.
        # This halfedge is floating in space.
        # We can simply delete everything, since nothing else points to this edge island.
        if degree1 == 1 and degree2 == 1
            face1.destroy()
            edge.destroy()
            halfedge1.destroy()
            halfedge2.destroy()
            return

        # Redirect the face pointer to a valid halfedge.
        # Fix either end of the halfedge path that doen't terminate in a tail point.
        if degree2 > 1
            next = halfedge1.next
            prev = halfedge2.prev
            next.prev = prev
            prev.next = next
            face1.halfedge = next # Safe pointer redirection.
            vert2.halfedge = next # Safe pointer redirection.

        # Other direction.
        if degree1 > 1
            next = halfedge2.next
            prev = halfedge1.prev
            next.prev = prev
            prev.next = next
            face1.halfedge = next # Safe.
            vert1.halfedge = next

        # Handle Line Splitting.
        # If there is a face with a 0 area region, such as an embedded non-closed polyline,
        # then deletion in the middle of line touching the same face on both sides
        #  will actually produce an extra complementd face.
        if not merge_faces and degree1 > 1 and degree2 > 1

            # We will use a brand new face for face 2 now.
            face_new = SCRIB.PolylineGraphEmbedder.newFace(@_graph)
            face_old = face1
            next1 = halfedge1.next
            next2 = halfedge2.next
            
            face_old.halfedge = next1
            face_new.halfedge = next2

            # Update all of the pointers on face2.
            start = face_new.halfedge
            current = start

            # Since we have already fixed up the faces,
            # We simply iterate over all edge in the face.
            loop # DO
                current.face = face_new
                current = current.next

                # WHILE
                break unless current != start


        # Finally, we delete the edge and halfedges.
        halfedge1.destroy()
        halfedge2.destroy()
        edge.destroy()

        # If we have a previously valid face bvh,
        # then we need to update the state for the face that we are keeping.
        # Update the bvh state 
        # Update the face info that is still in use with a correct bvh.
        if @_face_bvh != null
    
            # Extract the legacy face info.        
            face_info = edge_info.halfedge_info.face_info

            # Remove its no longer valid polyline from the bvh.
            @_face_bvh.remove(face_info.polyline)

            # Genrate new internal data based on face_info.face
            face_info.generateInfoFromFace(face1)

            # Generate its internal BVH, but this might be going overboard and too soon.
            face_info.generateBVH()

            # Add the face_info's new polyline to the bvh to replace the older one.
            @_face_bvh.add(face_info.polyline)

        return