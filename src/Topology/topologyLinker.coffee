###

Topology Processor.

Written by Bryce Summers on 1 - 27 - 2017.

Provides general purpose topological modification functions for HalfedgeGraphs, and primarily those that are interpreted as Planar embeddings.

Some of the functions require that 

Takes freshly allocated, but unlinked topologies and correctly links or unlinks them.

This class only performs linking, any allocation of metadata should be handled elsewhere in classes that support topological element allocation.


Terminology:

    Island: A singleton vertex.
    Continent: A connected component surrounded by an external face.
    Tail: A region including edges that have the same face on both sides.

###

class SCRIB.TopologyLinker

    # SCRIB.Vertex, SCRIB.Edge, SCRIB.Halfedge, SCRIB.Halfedge, SCRIB.Face, SCRIB.Face
    # All topological elements are assumed to be brand new.
    @link_island_vertex: (vertex, edge, halfedge, twin, interior, exterior) ->

        # 1 point Sub Graph.
        
        vertex.halfedge = halfedge
        edge.halfedge   = halfedge

        # The interior is trivial and is defined by a trivial internal and external null area point boundary.
        interior.halfedge = halfedge
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

        return

    # Links a new edge, and two halfedges to 2 already linked vertices.
    # Relinks the vertices.
    # ASSUMES the linked edge does not invalidate the planarity of the graph.
    # SCRIB.Edge, SCRIB.Halfedge, SCRIB.Halfedge, SCRIB.Vertex, SCRIB.Vertex
    # We also assume consistent orientation between continents.
    @link_edge_to_vertices: (v1, v2, new_edge, new_he1, new_he2, new_face) ->

        # Cases:
        # 1. Both verts are on the same face and the edge splits the face.
        # 2. Both verts are on separate complemented boundary faces and the edge bridges 2 continents.

        # Check for case 1.
        [next1, next2] = @find_cycle_containing_both_verts(v1, v2)

        if next1 == null
            @split_face_by_adding_edge(next1, next2, new_edge, new_he1, new_he2, new_face)
            return

        # Otherwise Proceed to linking the continents by spanning the two complimented verts.
        # NOTE: It should only be possible for there to be one complimented vert.
        he1 = @find_complemented_cycle_at_vert(v1)
        he2 = @find_complemented_cycle_at_vert(v2)

        @union_faces_by_adding_edge(he1, he2, new_edge, new_he1, new_he2, new_face)


    # Returns a halfedge originating from the target vertex that is within the cycle containing the given halfedge.
    # Returns null otherwise.
    @find_outgoing_halfedge_on_cycle: (halfedge_on_cycle, target_vertex) ->

        start   = halfedge_on_cycle
        current = start

        loop
            return current if current.vertex == target_vertex
            current = current.next
            break unless current != start
        return null

    # Returns [he1 originating from v1, he2 originating from v2]
    @find_cycle_containing_both_verts: (v1, v2) ->

        # For every outgoing edge in the first vert, we will check its cycle contains the second vert.
        # This is sufficient.
        # FIXME: We could optimize this to use the vert with the lowest degree.

        start   = v1.halfedge
        current = start

        loop
            he_v2 = @find_outgoing_halfedge_on_cycle(current, v2)

            if he_v2 != null
                return [current, he_v2]

            current = current.twin.next
            break unless current != start

        return [null, null]


    @find_complemented_cycle_at_vert: (vert) ->

        start   = vert.halfedge
        current = start

        loop

            return current if @is_cycle_complemented(current)
            current == current.twin.next

            # While.
            break unless current != start

    # We require vertices to have data elements with points on them.
    # Boundaries are implicitly defined, rather than explicitly with a boolean flag.
    # Boundaries are defined to be those cycles that are complemented.
    @is_cycle_complemented: (halfedge) ->

        polyline = BDS.Polyline(true)

        addVert = (vert) -> polyline.addPoint(vert.data.point)

        SCRIB.TopologyLinker.map_cycle_vertices(halfedge, addVert)

        return polyline.isComplemented()

    # Applies the function f(v) to ever vertex in the given cycle.
    @map_cycle_vertices :(halfedge, f_of_v) ->

        start   = halfedge
        current = start

        loop
            f_of_v(current.vertex)
            current = current.next
            break unless current != next

        return


    # Returns a halfedge going out of the given vertex that is on the given face.
    # returns null if none exist.
    @find_outgoing_halfedge_on_face: (vertex, face) ->

        start   = vertex.halfedge
        current = start

        loop # DO
            return current if current.face == face
            current = current.twin.next

            # WHILE
            break unless current == start

        return null

    # Splits the face containing the two input halfedges into two via an edge that goes
    # from the originating vertex of he1 to the origination point of he2.
    # Uses all of the given new elements in this procedure.
    @split_face_by_adding_edge: (he1, he2, new_edge, new_he1, new_he2, new_face) ->

        # Since we are splitting, we can just split the edge and not have to worry about deleting tolological elements.
        @_link_edge_to_cycle_locations(he1, he2, new_edge, new_he1, new_he2, new_face)


    # he1 = Halfedge on a boundary originating from the endpoint of the new edge.
    # he2 = Halfedge on another continent's boundary.
    # new_x elements that have been freshly allocated, which we will link.
    @union_faces_by_adding_edge: (he1, he2, new_edge, new_he1, new_he2, new_face) ->

        face1 = he1.face
        face2 = he2.face

        @_link_edge_to_cycle_locations(he1, he2, new_edge, new_he1, new_he2, new_face)

        # The link subfunction automatically links the face to the new face, so we can now safely
        # destroy the original two complemented faces.
        face1.destroy()
        face2.destroy()


    @_link_edge_to_cycle_locations: (he1, he2, new_edge, new_he1, new_he2, new_face) ->
        next1 = he1
        next2 = he2

        prev1 = next1.prev
        prev2 = next2.prev

        vert1 = next1.vertex
        vert2 = next2.vertex

        old_face = next1.face

        # Linking.

        new_edge.halfedge    = new_he1

        new_he1.next   = next2
        new_he1.prev   = prev1
        new_he1.vertex = vert1
        new_he1.twin   = new_he2
        new_he1.face   = old_face
        new_he1.edge   = new_edge
        next2.prev = new_he1
        prev1.next = new_he1

        new_he2.next   = next1
        new_he2.prev   = prev2
        new_he2.vertex = vert2
        new_he2.twin   = new_halfedge1
        new_he2.face   = old_face
        new_he1.edge   = new_edge
        next1.prev = new_he2
        prev2.next = new_he2

        # Finally link all of the halfedges in one of the now existing cycles to the new face.
        @link_cycle_to_face(next1, new_face)
        new_face.halfedge = next1        

    # Links every halfedge in the given cycle to the given face.
    @link_cycle_to_face: (halfedge, face_target) ->

        start   = halfedge
        current = start

        loop
            current.face = face_target
            break unless current != start

        return


    # Unlinks the given edge from its graph.
    # There is a lot of depth to this operation.
    # SCRIB.Edge, SCRIB.Face (Freshly allocated.)
    # (The face will be used in case of a face split)
    # Otherwise it will be destroyed.
    #params = params = {erase_lonely_vertices: bool}
    @unlink_edge: (edge, new_face, params) ->

        # All we need to think about from this point forward
        # is that the two halfedges are twins of each other.
        # We will destroy both faces and construct a new one to represent the merged face.

        halfedge1 = edge.halfedge
        halfedge2 = halfedge1.twin

        vert1 = halfedge1.vertex
        vert2 = halfedge2.vertex

        degree1 = vert1.degree()
        degree2 = vert2.degree()

        face1 = halfedge1.face
        face2 = halfedge2.face

        # Demolish face1 and fix up the faces.

        # We will merge the faces, if necessary.
        merge_faces = (face1 != face2)

        face = null
        if merge_faces
            face = @_merge_faces(face1, face2, face_new)
        else
            face = face1

        # After this point there is only one face and it is called face.

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
            
            # Guranteed to be only 1 face.
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
            face.halfedge = next # Safe pointer redirection.
            vert2.halfedge = next # Safe pointer redirection.

        # Other direction.
        if degree1 > 1
            next = halfedge2.next
            prev = halfedge1.prev
            next.prev = prev
            prev.next = next
            face.halfedge = next # Safe.
            vert1.halfedge = next

        split_faces = not merge_faces and degree1 > 1 and degree2 > 1

        # Handle Line Splitting.
        # If there is a face with a 0 area region, such as an embedded non-closed polyline,
        # then deletion in the middle of line touching the same face on both sides
        #  will actually produce an extra complementd face.
        if split_faces
            @_split_face_by_removing_edge(edge, face_new)
        else
            # We only need the new face if the faces get split.
            face_new.destroy()

        # Delete end of line.
        if not split_faces and not merge_faces
            # Uses markings to indicate which face will need an update in the face generation stage.
            face.data.marked = true

        # Finally, we delete the edge and halfedges.
        halfedge1.destroy()
        halfedge2.destroy()
        edge.destroy()

        return

    # Merges the two input faces and returns the final face object.
    # This acts only upon the halfedge topology.
    @_merge_faces: (face1, face2) ->

        halfedge1 = face1.halfedge
        halfedge2 = face2.halfedge

        new_face = face1

        # FIXME: This can be optimized if we know how large each face is.

        # Link old face's halfedges to one face.

        ###
        h0 = halfedge1
        current = h0

        loop # DO
            current.face = new_face
            current = current.next

            # WHILE
            break unless current != h0
        ###

        h0 = halfedge2
        current = h0

        loop # DO
            current.face = new_face
            current = current.next

            # WHILE
            break unless current != h0

        # Link the Face to a halfedge.
        new_face.halfedge = h0

        #face1.destroy()
        face2.destroy()

        return face1

    # Splits one face into 2 complemented faces by removing the given edge.
    # Assumes that The edge is bounded by the same face on both sides.
    # Assumes that the given edge will soon be deleted.
    # Assumes the edge is still
    @_split_face_by_removing_edge: (edge, face_new) ->

        halfedge1 = edge.halfedge
        halfedge2 = halfedge1.twin

        face_old  = halfedge1.next.face
        face_new1 = face_new
        face_new2 = face_old

        next1 = halfedge1.next
        next2 = halfedge2.next
        
        face_new1.halfedge = next1
        face_new2.halfedge = next2

        # Update all of the pointers on side1.
        start   = next1
        current = start

        # Iterate over the edges on one side of the split and set their face to the new face.
        loop #DO
            current.face = face_new1
            current      = current.next

            # WHILE
            break unless current != start

        # Update all of the pointers on side1.
        start   = next2
        current = start

        # Iterate over the edges on one side of the split and set their face to the new face.
        loop #DO
            current.face = face_new2
            current      = current.next

            # WHILE
            break unless current != start

        return [face_new1, face_new2]