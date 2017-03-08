###

Polyline Graph Topology Generator.

Generates Halfedge Topology associated with Polyline Graph Data Objects.

Written by Bryce Summers
Move to its own file on 3 - 7 - 2017.
###
class SCRIB.PolylineGraphGenerator

    constructor: (@_graph) ->

    # These functions should be used in all of my processings of polyline graphs.
    newGraph: () ->
        return SCRIB.PolylineGraphEmbedder.newGraph()

    newFace: (graph) ->
        graph = @_graph if not graph
        return SCRIB.PolylineGraphEmbedder.newFace(graph)

    newEdge: (graph) ->
        graph = @_graph if not graph
        return SCRIB.PolylineGraphEmbedder.newEdge(graph)

    newHalfedge: (graph) ->
        graph = @_graph if not graph
        return SCRIB.PolylineGraphEmbedder.newHalfedge(graph)

    newVertex: (graph) ->
        graph = @_graph if not graph
        return SCRIB.PolylineGraphEmbedder.newVertex(graph)

    # According to the ray vert1 --> vert2,
    # returns which side vert3 is on.
    # This is necessary for planar topological updates, such as splitting faces.
    # This is a useful geometric condition that has ties to orientation.
    line_side_test: (vert1, vert2, vert3) ->
        
        pt_c = vert3.data.point
        ray = @_ray(vert1, vert2)

        return ray.line_side_test(pt_c)

    # Returns true if vert_pt is inside of the angle ABC, where a, b, c are vertices.
    # This will be used for linking edges to the correct angle.
    # pt is inside if it is counterclockwise to BA and clockwise to BC.
    vert_in_angle: (vert_a, vert_b, vert_c, vert_pt) ->

        # Due to the orientation of a Computer Graphics plane,
        # we have swapped vert a and vert c.
        ray1 = @_ray(vert_b, vert_c)
        ray2 = @_ray(vert_b, vert_a)

        ray_pt = @_ray(vert_b, vert_pt)
 
        angle1 = ray1.getAngle()
        angle2 = ray2.getAngle()
        angle_pt = ray_pt.getAngle()

        # Apply mod Math.PI*2 wrapping functions to ensure the integrity of the check.
        # Make sure angle2 is an upper bound.
        if angle2 <= angle1 # NOTE: Equality enables correct tail angles that encompass the entire 360 degrees.
            angle2 += Math.PI*2

        if angle_pt < angle1
            angle_pt += Math.PI*2

        # Return if in bounds.
        return angle1 <= angle_pt and angle_pt <= angle2

    _ray: (v1, v2) ->
        a = v1.data.point
        b = v2.data.point

        dir = b.sub(a)

        ray = new BDS.Ray(a, dir, 1)
        return ray