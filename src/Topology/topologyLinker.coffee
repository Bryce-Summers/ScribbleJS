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

    unlinked: an element that contains only null pointers.
    linked: an element that contains relevant pointers to other elements, which is assumed to fullfill the topological invariants of a Halfedgemesh.

###

class SCRIB.TopologyLinker

    # Needs an element generator that produces proper data associated elements.
    constructor: (@generator, @graph) ->


    # Creates elements to link this vertex with itself.
    # All topological elements are assumed to be brand new.
    link_island_vertex: (vertex) ->

        # For now, I'm just going with null island vertices.
        vertex.halfedge = null

        ###
        edge     = @generator.newEdge(@graph)
        halfedge = @generator.newHalfedge(@graph)
        twin     = @generator.newHalfedge(@graph)
        interior = @generator.newFace(@graph)
        exterior = @generator.newFace(@graph)

        # 1 point Sub Graph.
        
        vertex.halfedge = halfedge
        edge.halfedge   = halfedge

        # The interior is trivial and is defined by a trivial internal and external null area point boundary.
        
        # Self referential exterior loop.
        halfedge.edge   = edge
        halfedge.face   = exterior
        halfedge.next   = halfedge
        halfedge.prev   = halfedge
        halfedge.twin   = twin
        halfedge.vertex = vertex
        exterior.halfedge = halfedge

        # Self referential interior loop.
        twin.edge   = edge
        twin.face   = interior
        twin.next   = twin
        twin.prev   = twin
        twin.twin   = halfedge
        twin.vertex = vertex
        interior.halfedge = twin
        ###

        return vertex

    # Removes and deletes all extraneous connected elements to this vertex.
    unlink_island_vertex: (vertex) ->

        ###
        he1   = vertex.halfedge
        he2   = he1.twin
        edge  = he1.edge
        face1 = he1.face
        face2 = he2.face

        he1.destroy()
        he2.destroy()
        edge.destroy()
        face1.destroy()
        face2.destroy()

        vertex.halfedge = null
        ###

        return

    # Links two vertices together via a direct edge.
    # Updates the face information, etc.
    # We also assume consistent orientation between continents.
    link_verts: (v1, v2) ->

        # CASE 1: Either v1 or v2 is a degenerate island.

        # If both verts are along, we unlink them then link them in a line continent.
        if v1.isAlone() and v2.isAlone()
            @unlink_island_vertex(v1)
            @unlink_island_vertex(v2)
            @link_vert_line_continent([v1, v2])
            return

        if v1.isAlone()
            @unlink_island_vertex(v1)

            # I used to find a complemented cycle,
            # but now we find the left_most outgoing edge that passes the left test.
            external_he = @find_halfedge_at_vert_containing_vert(v2, v1)
            @link_vert_to_external_face(v1, external_he)
            return

        if v2.isAlone()
            @unlink_island_vertex(v2)
            external_he = @find_halfedge_at_vert_containing_vert(v1, v2)
            @link_vert_to_external_face(v2, external_he)
            return

        # Non degenerate Cases:
        # 1. Both verts are on the same face and the edge splits the face.
        # 2. Both verts are on separate complemented boundary faces and the edge bridges 2 continents.

        # Check for case 1.
        # use a specially made function that halfedges on the same cycle, but which are legal to be linked.
        [next1, next2] = @find_cycle_containing_vert_segment(v1, v2)
        #[next1, next2] = @find_cycle_containing_both_verts(v1, v2)

        if next1 != null
            @split_face_by_adding_edge(next1, next2)
            return

        # Case 2.

        # This works lovely, now that we use the angle sorting functions for finding the correct halfedges ;)
        he1 = @find_halfedge_at_vert_containing_vert(v1, v2)
        he2 = @find_halfedge_at_vert_containing_vert(v2, v1)

        @union_faces_by_adding_edge(he1, he2)
        return

    # Returns the outgoing halfedge from the star vertex that is that comes
    # after the ray from the star_vert to target vert in clockwise order.
    find_halfedge_at_vert_containing_vert: (star_vert, target_vert) ->
        start   = star_vert.halfedge
        current = start

        loop

            next = current.twin.next

            vert_a = next.twin.vertex
            vert_b = star_vert
            vert_c = current.twin.vertex

            if @generator.vert_in_angle(vert_a, vert_b, vert_c, target_vert)
                return next

            # Iterate over outgoing halfedges from the star_vert.
            current = current.twin.next

            if current == start
                debugger
                throw new Error("Proper angle segment not found.")

    # Returns a halfedge originating from the target vertex that is within the cycle containing the given halfedge.
    # Returns null otherwise.
    find_outgoing_halfedge_on_cycle: (halfedge_on_cycle, target_vertex) ->

        start   = halfedge_on_cycle
        current = start

        loop
            return current if current.vertex == target_vertex
            current = current.next
            break unless current != start
        return null

    # Returns [he1 originating from v1, he2 originating from v2],
    # Such that they are on the same face.
    find_cycle_containing_both_verts: (v1, v2) ->

        # For every outgoing edge in the first vert, we will check if its cycle contains the second vert.
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

    # Returns [he1 originating from v1, he2 originating from v2],
    # Such that they are on the same face and an embedded straight
    # line from v1 to v2 is contained wthin the face.
    # This is useful for planar topological face splitting.
    find_cycle_containing_vert_segment: (v1, v2) ->

        # First we make sure that their is a cycle that exists and contains both verts.
        [a, b] = @find_cycle_containing_both_verts(v1, v2)

        # If there is no solution, then return nulls.
        if a == null
            return [null, null]

        # ASSUMPTION: v1 and v2 are on the same cycle and there is a
        # straight line between them that crosses no edges in the current planar embedding.
        # They must each uniquely have an edge insertion position,
        # which is on the same face on their respective star neighborhoods.
        a = @find_halfedge_at_vert_containing_vert(v1, v2)
        b = @find_halfedge_at_vert_containing_vert(v2, v1)

        if a.face != b.face
            debugger
            throw new Error("This should not be possible.")

        return [a, b]


        # FIXME: I will need to 

        # Find pairs of edges that are on the cycle.
        # For every outgoing edge in the first vert, we will check if its cycle contains the second vert.
        # This is sufficient.
        # FIXME: We could optimize this to use the vert with the lowest degree.

        ###
        start   = v1.halfedge
        current = start

        start1 = null
        end1   = null
        start2 = null
        end2   = null

        # Find a first pair.
        loop
            he_v2 = @find_outgoing_halfedge_on_cycle(current, v2)

            if he_v2 != null
                start1 = current
                end1   = he_v2
                break

            current = current.twin.next
            break unless current != start

        # Find a second pair.
        current = current.twin.next
        loop
            he_v2 = @find_outgoing_halfedge_on_cycle(current, v2)

            if he_v2 != null
                start2 = current
                end2   = he_v2
                break

            current = current.twin.next
            break unless current != start

        # Case 1: Didn't find anything.
        if start1 == null
            return [null, null]

        # Case 2: At least one of the vertices has more than 1 outgoing halfedge on the same face.
        start1 = @away_from_star_point(start1, end1)
        start2 = @away_from_star_point(end1, start1)

        # If this halfedge goes left towards the vert, then it must be the right one.
        # FIXME: This may fail with internal stars.
        if @left_test(start1, v2)
            return [start1, @towards_star_point(start2, start1)]
        if @left_test(start2, v1)
            return [start2, @towards_star_point(start1, start2)]

        # Case: 3: This is a loop topology, and we can safely use the alternate unique cycle.
        # FIXME: This ignores internal stars.
        return [start2, end2]
        ###

    # Returns the halfedge that travels towards the target halfedge, 
    # rather back to the candidate halfedge's vertex first.
    away_from_star_point: (candidate_halfedge, target_halfedge) ->

        # The vertex that we want to orient away from.
        vertex = candidate_halfedge.vertex

        start   = candidate_halfedge
        current = start

        loop
            current = current.next

            # Case 1: Target Halfedge was found.
            if current == target_halfedge
                return candidate_halfedge

            # Case 2: We've looped around the tail.
            # We keep going, because the input might be a star topology.
            if current.vertex == vertex
                candidate_halfedge = current

            # No tails, also the target halfedge is not even in this cycle.
            if current == start
                return candidate_halfedge

        throw new Error("Never get here.")
        return

    towards_star_point: (candidate_halfedge, target_halfedge) ->

        # The vertex that we want to orient away from.
        vertex = candidate_halfedge.vertex

        start   = candidate_halfedge
        current = start

        loop
            # We go backwards.
            current = current.prev

            # Case 1: Target Halfedge was found.
            if current == target_halfedge
                return candidate_halfedge

            # Case 2: We've looped around the tail.
            # We keep going, because the input might be a star topology.
            if current.vertex == vertex
                candidate_halfedge = current

            # No tails, also the target halfedge is not even in this cycle.
            if current == start
                return candidate_halfedge

        throw new Error("Never get here.")
        return

    # Returns whether the target_vert is to the left of the halfedge defined ray.
    # This is a necessary orientation test for face splitting.
    left_test: (halfedge, target_vert) ->
        vert1 = halfedge.vertex
        vert2 = halfedge.next.vertex

        vert_c = target_vert

        return @generator.line_side_test(vert1, vert2, vert_c) < 0


    find_complemented_cycle_at_vert: (vert) ->

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
    is_cycle_complemented: (halfedge) ->

        polyline = new BDS.Polyline(true)

        addVert = (vert) -> @polyline.addPoint(vert.data.point)
        addVert.polyline = polyline # Provide addVert with a function level variable.

        @map_cycle_vertices(halfedge, addVert)

        return polyline.isComplemented()

    # Applies the function f(v) to every vertex in the given cycle.
    map_cycle_vertices :(halfedge, f_of_v) ->

        start   = halfedge
        current = start

        loop # DO
            f_of_v(current.vertex)
            current = current.next
            break unless current != start # While.

        return


    # Returns a halfedge going out of the given vertex that is on the given face.
    # returns null if none exist.
    find_outgoing_halfedge_on_face: (vertex, face) ->

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
    split_face_by_adding_edge: (he1, he2) ->

        # Since we are splitting, we can just split the edge and not have to worry about deleting topological elements.
        @_link_edge_to_cycle_locations(he1, he2)


    # he1 = Halfedge on a boundary originating from the endpoint of the new edge.
    # he2 = Halfedge on another continent's boundary.
    # new_x elements that have been freshly allocated, which we will link.
    union_faces_by_adding_edge: (he1, he2) ->

        face1 = he1.face
        face2 = he2.face

        @_link_edge_to_cycle_locations(he1, he2)

        # The link subfunction automatically links the face to the new face, so we can now safely
        # destroy the original two complemented faces.
        face1.destroy()
        face2.destroy()


    _link_edge_to_cycle_locations: (he1, he2) ->

        next1 = he1
        next2 = he2

        prev1 = next1.prev
        prev2 = next2.prev

        vert1 = next1.vertex
        vert2 = next2.vertex

        old_face = next1.face

        # Allocate new Topological Elements.
        new_edge = @generator.newEdge()
        new_he1  = @generator.newHalfedge()
        new_he2  = @generator.newHalfedge()
        new_face = @generator.newFace()

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
        new_he2.twin   = new_he1
        new_he2.face   = old_face
        new_he2.edge   = new_edge
        next1.prev = new_he2
        prev2.next = new_he2

        # Finally link all of the halfedges in one of the now existing cycles to the new face.
        @link_cycle_to_face(new_he1, new_face)
        #@link_cycle_to_face(new_he2, old_face)

        # Update halfedge pointers for each face.
        new_face.halfedge = new_he1
        old_face.halfedge = new_he2
        return

    # Links every halfedge in the given cycle to the given face.
    link_cycle_to_face: (halfedge, face_target) ->

        start   = halfedge
        current = start

        loop
            current.face = face_target
            current = current.next

            break unless current != start

        return

    # ASSUMPTION: vert is unlinked.
    link_vert_to_external_face: (vert, external_halfedge) ->

        he1 = @generator.newHalfedge()
        he2 = @generator.newHalfedge()
        edge = @generator.newEdge()

        # Halfedge1 comes from the new vert.
        vert.halfedge = he1
        he1.vertex = vert
        # Halfedge2 comes from the external face vert.
        he2.vertex = external_halfedge.vertex

        he1.twin = he2
        he2.twin = he1
        he1.edge = edge
        he2.edge = edge
        edge.halfedge = he1
    
        prev_external = external_halfedge.prev

        # Relink the 4 relvent halfedges.
        he1.next = external_halfedge
        he1.prev = he2
        he2.prev = prev_external
        he2.next = he1

        prev_external.next = he2
        external_halfedge.prev = he1

        # Now link the two new halfedge to the external face.
        external_face = external_halfedge.face
        he1.face = external_face
        he2.face = external_face
        return


    # Unlinks the given edge from its graph.
    # There is a lot of depth to this operation.
    # SCRIB.Edge, SCRIB.Face (Freshly allocated.)
    # (The face will be used in case of a face split)
    # Otherwise it will be destroyed.
    #params = params = {erase_lonely_vertices: bool}
    unlink_edge: (edge, params) ->

        debugger if edge == null

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
            face = @_merge_faces(face1, face2)
        else
            face = face1

        # After this point there is only one face and it is called face.

        # Destroy lonely vertices.
        if degree1 == 1
            if params.erase_lonely_vertices
                vert1.destroy()
            else
                @link_island_vertex(vert1)

        if degree2 == 1

            if params.erase_lonely_vertices
                vert2.destroy()
            else
                @link_island_vertex(vert2)

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
            @_split_face_by_removing_edge(edge)

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
    _merge_faces: (face1, face2) ->

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
    _split_face_by_removing_edge: (edge) ->

        halfedge1 = edge.halfedge
        halfedge2 = halfedge1.twin

        face_old = halfedge1.next.face
        face_new = @generator.newFace()

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

    # Links a polyline of verts together into a fully linked continent.
    link_vert_line_continent: (verts) ->

        # Handle Degenerate cases.
        if verts.length < 1
            return

        if verts.length == 1
            @link_island_vertex(verts[0])
            return

        edges = [] # SCRIB.Edge.
        forward_edges   = [] # SCRIB.Halfedge.
        backwards_edges = []

        complemented_face = @generator.newFace()

        first_index = 0
        last_index  = verts.length - 2

        # Allocate edges.
        # Link Halfedges --> Vertex
        #      Halfedges <-> Edges.
        #      Vertex -> Halfedge.
        # Twin linking.
        for i in [first_index .. last_index] by 1

            edge = @generator.newEdge()
            halfedge1 = @generator.newHalfedge()
            halfedge2 = @generator.newHalfedge()

            edge.halfedge  = halfedge1
            halfedge1.edge = edge
            halfedge2.edge = edge

            halfedge1.twin = halfedge2
            halfedge2.twin = halfedge1

            halfedge1.vertex = verts[i]
            halfedge2.vertex = verts[i + 1]

            halfedge1.face = complemented_face
            halfedge2.face = complemented_face

            # Verts linked to forwards edges.
            verts[i].halfedge = halfedge1

            edges.push(edge)
            forward_edges.push(halfedge1)
            backwards_edges.push(halfedge2)

        # Complete the final vert -> halfedge linking.
        last_halfedge                    = backwards_edges[last_index]
        verts[verts.length - 1].halfedge = last_halfedge
        complemented_face.halfedge       = last_halfedge

        # Link up next and previous pointers.
        for i in [first_index + 1..last_index - 1] by 1
            he0 = forward_edges[i - 1]
            he1 = forward_edges[i]
            he2 = forward_edges[i + 1]

            back0 = backwards_edges[i + 1]
            back1 = backwards_edges[i]
            back2 = backwards_edges[i - 1]

            he1.prev = he0
            he1.next = he2

            back1.prev = back0
            back1.next = back2

        # Link the first pair.
        forward_edges[first_index].prev   = backwards_edges[first_index]
        backwards_edges[first_index].next = forward_edges[first_index]

        # Link the last pair.
        forward_edges[last_index].next   = backwards_edges[last_index]
        backwards_edges[last_index].prev = forward_edges[last_index]

        if first_index < last_index
            forward_edges[first_index].next   = forward_edges[first_index + 1]
            backwards_edges[first_index].prev = backwards_edges[first_index + 1]
            forward_edges[last_index].prev   = forward_edges[last_index - 1]
            backwards_edges[last_index].next = backwards_edges[last_index - 1]

        return

    # Splits apart the given edge by adding the given vertex.
    split_edge_with_vert: (edge, vert) ->

        # This routine splits the halfedges, such that they maintain their originating verts.

        # OLD:
        # Forwards1
        # Backwards1

        # Forwards1  ->      -> Forwards2
        # edge           vert     edge2
        # Backwards2 <-      <- Backwards1

        # These will originate from the verts at the end of the original edge.
        forwards1   = edge.halfedge
        backwards1 = forwards1.twin

        # Halfedges originating at the input spitting vertex.
        forwards2   = @generator.newHalfedge()
        backwards2 = @generator.newHalfedge()
        forwards2.vertex   = vert
        backwards2.vertex = vert
        vert.halfedge = forwards2

        # Create the second edge and link it properly.
        edge2 = @generator.newEdge()
        edge.halfedge   = forwards1
        edge2.halfedge  = forwards2
        forwards1.edge   = edge
        forwards2.edge   = edge2
        backwards1.edge = edge2
        backwards2.edge = edge

        # Link Twins.
        forwards1.twin   = backwards2
        backwards2.twin = forwards1
        forwards2.twin   = backwards1
        backwards1.twin = forwards2

        # Link next and previous pointers.
        forwards2.prev = forwards1
        forwards2.next = forwards1.next
        forwards2.next.prev = forwards2
        forwards1.next = forwards2

        backwards2.prev = backwards1
        backwards2.next = backwards1.next
        backwards2.next.prev = backwards2
        backwards1.next = backwards2

        # Copy face Pointers.
        forwards2.face   = forwards1.face
        backwards2.face = backwards1.face

        # Handle Tail endpoint splitting conditions.

        # Previous conditions.
        ###
        if forwards1.prev == backwards1
            forwards1.prev = backwards2
        if backwards1.prev == forwards1
            backwards1.prev = forwards2
        ###

        return