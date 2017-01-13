###
    Polyline Graph Associated Data classes.

    Adapted by Bryce Summers on 1 - 3 - 2017.

    Purpose: These classes provide application specific associated data structures that are linked into HalfedgeGraph elements.

    They will be used for algorithms on planar graph embeddings from polyline inputs.
###


class SCRIB.Graph_Data
    
    # SCRIB.Graph
    constructor: (@graph) ->
        
    clearFaceMarks: () ->
        iter = @graph.facesBegin();
        while(iter.hasNext())
            iter.next().data.marked = false

    clearVertexMarks:   () ->
        iter = @graph.verticesBegin()
        while(iter.hasNext())
            iter.next().data.marked = false

    clearEdgeMarks:     () ->

        iter = @graph.edgesBegin()
        while(iter.hasNext())
            iter.next().data.marked = false

    clearHalfedgeMarks: () ->

        iter = @graph.halfedgesBegin()
        while(iter.hasNext())
            iter.next().data.marked = false

    clearMarks: () ->
        @clearFaceMarks()
        @clearVertexMarks()
        @clearEdgeMarks()
        @clearHalfedgeMarks()

class SCRIB.Face_Data
    
    constructor: (@face) ->
        
        @marked = false

        # Scrib.Face[] 
        hole_representatives = []

        # A Pointer to a SCRIB.Face_Info object.
        @info = null

    addHole: (hole) ->

        hole_representatives.push(hole)

    ###
    // The area of the face is determined by the intersection this face with all of the hole faces,
    // which will be specified by exterior facing edge that enclose an infinite complemented area.
    ###


class SCRIB.Vertex_Data

    constructor: (@vertex) ->
        
        # BDS.Point
        @point  = null
        @marked = false
        @tail_point = false

        # Labels Vertices that have more than two outgoing edges.
        @intersection_point = false

        # FIXME: Remove this if it is just taking up unneeded space.
        @singleton_point = false

        ###
        # Used as a temporary structure for graph construction, but it is also may be relevant to users.
        # I don't know whether I will maintain this structure outside of graph construction.
        # FIXME: I might switch this to being a pointer to allow for me to null it out when no longer needed.
        # SCRIB.Halfedge[]
        ###
        @outgoing_edges = []

        @info = null

    isExtraordinary: () ->

        return @tail_point || @intersection_point


class SCRIB.Edge_Data

    constructor: (@edge) ->

        @marked = false
        @info = null


class SCRIB.Halfedge_Data

    constructor: (@halfedge) ->
    
        @marked = false
        @next_extraordinary = null

        # A Pointer to a SCRIB.Face_Info object.
        @info = null

    # A Halfedge will be labeled as extraordinary iff its vertex is an intersection point or a tail_point.
    isExtraordinary: () ->

        return @halfedge.vertex.data.isExtraordinary()

