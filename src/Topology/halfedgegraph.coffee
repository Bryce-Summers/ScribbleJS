###
Halfedge Graph / Mesh class.
Written by Bryce Summers on 1 - 2 - 2017.
###

###
* FIXME: Writeup my modified usage, now that we are in javasccript.
*
* Usage:
*
* The Application programmer / New Media Artist specifies the following:
* 1. The data format they have availible for graph construction (e.g. vectors of openframeworks points.)
* 2. The Algorithms they need.
* 3. The data format that they wish to receive the results in.
*
* They will do so by specifying which class definitions they want.
*
* The algorithm designer / computational geometer specifies the following:
* 1. Definitions for the associated data.
* 2. The interface for constructing Graphs from application data
* 3. The interface for running algorithms on the Graphs.
* 4. The interface for allowing the application programmer to retrieve the results.
*
* If done elegantly, the New Media Artist should never need to touch the halfedge mesh, go on pointer journeys, and
* they should be able to treat the internal implementation as a black box.
###

###
# -- Associated Data Classes.

#Since Javascript is untyped, these will mostly be her for convenience, and the user can insert the data they wish into each of these structures.

Every graph element will have a reserved variable called 'data' for linking to application specific information.

class SCRIB.Graph_Data
class SCRIB.Vertex_Data
class SCRIB.Face_Data
class SCRIB.Halfedge_Data
class SCRIB.Edge_Data
###

###
// FIXME: Clean up this prose.

// -- Structural definition of classes.
// Every class is specified by its connectivity information and a pointer to associated user data.

// All elements may be marked and unmarked by algorithms and users to specific sets of elements that meet various criteria.

// The Graph class represents an entire graph embedding defined by points in space.
// For the purposes of the facefinder, the output graph will be planar.
// connected via edges that intersect only at vertices.
// The FaceFinder class may be used to derive a Graph from a set of potentially intersecting input polylines.
###
class SCRIB.Graph

    ###
    // Graph classes are where all of the actual data will be stored, so it contains vectors of valued data,
    // rather than pointers.
    // All ID's contained within these vectors will reference tha index of the object within these vectors.

    // Ideally, vertices, edges, and halfedges will be ordered logically according to the order they were input into the facefinder,
    // but I will need to do some more thinking on how to formally specify these things.
    ###

    constructor: (@_allocate_index_arrays) ->

        # Note: Heap allocated elements will be stored at permanent places and accessed via List Iterators.
        @_faces     = new BDS.DoubleLinkedList()
        @_vertices  = new BDS.DoubleLinkedList()
        @_edges     = new BDS.DoubleLinkedList()
        @_halfedges = new BDS.DoubleLinkedList()

        @_next_face_id     = 0
        @_next_vertice_id  = 0
        @_next_edge_id     = 0
        @_next_halfedge_id = 0

        # Only used to store elements for construction purposes.
        # These should be deallocated when they are no longer needed.
        # FIXME: Think about factoring these guys out into a HalfedgeBuilder / random access class.
        if @_allocate_index_arrays
            @_face_array     = []
            @_vertex_array   = []
            @_edge_array     = []
            @_halfedge_array = []

        # Extra Application specific information.
        @_data = null

    # --- Public Interface. -------------------------------

    # Allocation functions.

    newFace: () ->

        id = @_next_face_id++
        output = new SCRIB.Face()
        @_faces.push_back(output)
        @_face_array.push(output) if @_face_array
        output.id = id

        # Provide a pointer to the element's iterator.
        iter = @_faces.end()
        iter.prev()._iterator = iter

        return output

    newVertex: () ->
    
        id = @_next_vertice_id++
        output = new SCRIB.Vertex()
        @_vertices.push_back(output)
        @_vertex_array.push(output) if @_vertex_array
        output.id = id

        # Provide a pointer to the element's iterator.
        iter = @_vertices.end()
        iter.prev()._iterator = iter

        return output
    

    newEdge: () ->
    
        id = @_next_edge_id++
        output = new SCRIB.Edge()
        @_edges.push_back(output)
        @_edge_array.push(output) if @_edge_array
        output.id = id

        # Provide a pointer to the element's iterator.
        iter = @_edges.end()
        iter.prev()._iterator = iter

        return output

    newHalfedge: () ->
    
        id = @_next_halfedge_id++
        output = new SCRIB.Halfedge()
        @_halfedges.push_back(output)
        @_halfedge_array.push(output) if @_halfedge_array
        output.id = id

        # Provide a pointer to the element's iterator.
        iter = @_halfedges.end()
        iter.prev()._iterator = iter

        return output

    # Removes pointers to the given element in this Graph's data structures.
    # I could put these functions in every element, but I reserve the right to changed the internal implementation at some point.
    deleteElement: (e) ->
        e._iterator.remove()

    getData: () -> @_data

    # Counting functions.
    numFaces:     () -> @_faces.size()
    numVertices:  () -> @_vertices.size()
    numEdges:     () -> @_edges.size()
    # Should theoretically be numEdges * 2.
    numHalfedges: () -> @_halfedges.size()


    # Random Access Functions. These only work when the arrays have been allocated.
    # We put these in private _underscore to indicate that users should not use these functions, except during construction.
    # I think that I should refactor these guys to a Halfedge Construction class.
    getFace: (id) ->
    
        return @_face_array[id]

    getVertex: (id) ->

        return @_vertex_array[id]

    getEdge: (id) ->

        return @_edge_array[id]

    getHalfedge: (id) ->
    
        return @_halfedge_array[id]

    # This should be called after you no longer need random access, such as after construction.
    # Random access is only meant for construction and does not support deletion.
    
    delete_index_arrays: () ->

        delete @_face_array
        delete @_vertex_array
        delete @_edge_array
        delete @_halfedge_array
    



    ###
     - Iteration functions.
     - These all return BDS.DoubleListIterator's
    ###

    facesBegin:     () -> @_faces.begin()
    facesEnd:       () -> @_faces.end()

    verticesBegin:  () -> @_vertices.begin()
    verticesEnd:    () -> @_vertices.end()

    edgesBegin:     () -> @_edges.begin()
    edgesEnd:       () -> @_edges.end()

    halfedgesBegin: () -> @_halfedges.begin()
    halfedgesEnd:   () -> @_halfedges.end()


class SCRIB.Face

    constructor: () ->
        # Representative from the interior loop of halfedges defining the boundary of the face.
        @halfedge = null
        @data = new SCRIB.Face_Data()
        @id = null
        @_iterator = null

    destroy: () ->
        @_iterator.remove()

# A vertex will have a dummy edge that points to itself if it is by itself.
# These lone vertices will be considered to have degree 1.
# the dummy will have itself as a twin as well.
class SCRIB.Vertex

    constructor: () ->

        # A representative halfedge that is traveling away from this Vertex.
        # this -> halfedge -> vertex = this.
        # SCRIB.Halfedge
        @halfedge = null

        @data = null
        @id = null
        @_iterator = null

    destroy: () ->
        @_iterator.remove()

    isAlone: () ->
        # Null, non populated vertex or
        # Self looping unitary halfedge.
        return @halfedge == null or @halfedge.next == @halfedge

    # ASSSUMES: Well formed halfedge mesh.
    degree: () ->

        start = @halfedge
        current = start.twin.next
        count = 1

        while start != current
            count++
            current = current.twin.next
            continue

        return count

    make_lonely: () ->
        debugger

        # FIXME: I should use the Topology linker's link island functionality.

        @halfedge = null

    # Returns the outgoing halfedge from this vertex to the given vertex.
    get_outgoing_halfedge_to: (vert) ->
        start = @halfedge.twin
        current = start.next.twin

        # Loop around searching for the appropriate outgoing halfedge.
        loop

            # Check current halfedge for the goal vertex.
            if current.vertex == vert
                return current.twin

            if current == start
                debugger;
                throw Error("Vert not found!");

            current = current.next.twin

# Non directed edges, very useful for getting consecutive ID's within input polylines.
class SCRIB.Edge

    # SCRIB.Halfedge.
    @halfedge   = null
    @data       = null
    @id         = null
    @_iterator  = null

    destroy: () ->
        @_iterator.remove()


class SCRIB.Halfedge

    constructor: () ->

        # SCRIB.Halfedge's
        @twin = null
        @next = null
        @prev = null

        # SCRIB.Face
        @face = null

        # SCRIB.Edge
        @edge = null

        # SCRIB.Vertex
        @vertex = null
        

        # SCRIB.Halfedge_Data
        @data = null
        @id   = null
        @_iterator  = null

    destroy: () ->
        @_iterator.remove()