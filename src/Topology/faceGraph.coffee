###

Face Graph.

Written by Bryce Summers on 2 - 12 - 2017.

Purpose: Represents face to face connectivity, such as that needed for coloring.
###

class SCRIB.FaceGraph

    # Constructed from a HalfedgeGraph.
    constructor: (graph) ->

        # int -> SCRIB.Face[]
        # Maps face ids to arrays of faces.
        @faces = {}

        # First populate the map with an array for all faces.
        iter = graph.facesBegin()
        while iter.hasNext()
            face = iter.next()
            @faces[face.id] = []

        # Iterate through all edges and link up faces.
        iter = graph.edgesBegin()

        while iter.hasNext()
            edge = iter.next()

            halfedge = edge.halfedge
            face1 = halfedge.face
            face2 = halfedge.twin.face

            @faces[face1.id].push(face2)
            @faces[face2.id].push(face1)

    # Returns a map from face ids to integers,
    # such that no two faces share a common index.
    autoColor: () ->

        # We use a 6 coloring scheme based on Brooks' theorem.
        # and an algorithm presented in the paper entitled "Two Linear-Time Algorithms for 5-Coloring a Planar Graph from 1980."

        # First we get a list of tuples containing face id's and degree's.
        # In the FaceGraph, faces are really thought of as vertices.
        id_degrees = []

        for key, value of @faces
            id_degrees.push([parseInt(key), value.length])

        ###
        id_degrees.sort(
            (a, b) -> 
                degree1 = a[1]
                degree2 = b[1]
                return degree1 - degree2
            )
        ###

        face_id_order = []
        for id_degree in id_degrees
            face_id_order.push(id_degree[0])

        return @greedyColor(face_id_order)


    # Takes a list of integers cooresponding to the order the faces will be greedily colored.
    greedyColor: (face_id_order) ->

        # Right now, we will start with a greedy algorithm.
        coloring = {}
        colored = new Set()

        for face_id in face_id_order

            # We need to convert the string casted indices back to numbers.
            neighbors = @faces[face_id]          

            # Indices that are already taken.
            taken = new Set()

            # add every colored neighbor color id to the taken set.
            for face in neighbors

                if not colored.has(face.id)
                    continue;

                taken.add(coloring[face.id])

            # Determine the color for the current 'key' face.
            index = 0
            while taken.has(index)
                index++

            coloring[face_id] = index
            colored.add(face_id) # Inform future iterations, that this face has been colored.

        return coloring

