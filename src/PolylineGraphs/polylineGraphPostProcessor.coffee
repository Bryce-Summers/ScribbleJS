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
# Convinent naming convention, more so for our benifit than the machine's since javscript is dynamically typed.

typedef SCRIB.Polyline[]  <-> Face_Vector_Format
typedef int[]                  <-> Int_Vector_Format
typedef {}                     <-> ID_Set
###

class SCRIB.Point_Info

    ###
    // The halfedge that this point represents when this point is collected in a Point_Vector to represent a face.
    // This may be used to easily extract local connectivity information and attributes for this point and its neighbors.
    // WARNING: This always points to the original embedding's connectivity information,
    // which means that things like next pointers may no longer be valid after tails are clipped or other algorithms.
    // Faces and twin pointers should still be valid though...
    # @halfedge is only defined for HalfedgeGraph based souce embeddings.
    ###

    # SCRIB.Point, int, SCRIB.halfedge
    constructor: (@point, @id, @halfedge) ->


class SCRIB.Face_Info

    constructor: () ->

        # SCRIB.Face_Info[]
        @holes  = []

        # SCRIB.Point_Info
        @points = []
        @polyline = new SCRIB.Polyline(true) # Closed.

        # Contains a set of all faces contributing to this unioned face.
        @faces_id_set = new Set()

        @complemented = false

    size: () ->
        return @points.length

    isClosed: () ->
        return polyline.isClosed()

    getLastPointInfo: () ->
        return @points[@points.length - 1]

    push: (point_info) ->
        @points.push(point_info)
        @polyline.addPoint(point_info.point)

    pop: () ->
        @polyline.removeLastPoint()
        return @points.pop()

    at: (index) ->
        return @points[index]

    isComplemented: () ->
        return @polyline.isComplemented()

class SCRIB.PolylineGraphPostProcessor


    constructor: () ->
    
        @_graph = null

        # Face point vector format.
        # SCRIB.Polyline[]
        @_face_vector = null

    # -- Data Structure Conversion.
    # () -> SCRIB.Face_Info[]
    # Converts a Graph Object into a face_info vector.
    convert_to_face_infos: () ->
        
        #SCRIB.Face_Info[]
        output = []

        iter = @_graph.facesBegin()
        while iter.hasNext()

            face = iter.next()

            face_output = new SCRIB.Face_Info(true) # Closed Polyline.
            face_output.faces_id_set.add(face.id)

            starting_half_edge = face.halfedge
            current            = starting_half_edge

            # Convert the entire face into point info objects.
            loop # DO
            
                vert = current.vertex
                vert_data = vert.data

                point = vert_data.point
                id    = vert.id

                
                point_info = new SCRIB.Point_Info(point, id, current)
                face_output.points.push(point_info)
                face_output.polyline.addPoint(point)

                # Iterate.
                current = current.next

                # while
                break unless starting_half_edge != current

            output.push(face_output)

        # End of while iteration loop.
        return output

    ###
    This class performs operations on face vectors, but it only uses the current face vector as an input.
    The class never changes the loaded face vector internally.
    It is up to the user to load the proper face vector when they need a change.
    ###

    load_face_vector: (@_face_vector) ->
    load_graph: (@_graph) ->

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
            clipped_face   = @clipTails(unclipped_face)

            # Append only non trivial faces to the output.
            if clipped_face.size() > 0
            
                output.push(clipped_face)
            
        return output

    # Returns a copy of the single input face without any trivial area contiguous subfaces. (Tails)
    # May return a 0 point polyline if the input line is non-intersecting.
    # SCRIB.Face_Info -> SCRIB.Face_Info
    clipTails: (input) ->

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
