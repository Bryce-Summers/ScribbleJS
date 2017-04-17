/*
 * Defines namespaces.
 * Adapted by Bryce Summers on 12 - 30 - 2016.
 */

// Scribble JS.
SCRIB = {};



// Used for debugging.
// Prints, counts, and unit tests the halfedge graph.
// This should be called from the console.
SCRIB.printHalfedgeMesh = function(graph)
{
    if(graph === undefined)
    {
        graph = EX.Graph;
    }

    var iter = graph.halfedgesBegin();

    while(iter.hasNext())
    {

        halfedge = iter.next();
        console.log(halfedge);

        SCRIB.ASSERT(halfedge.edge != null);
        SCRIB.ASSERT(halfedge.twin != null);
        SCRIB.ASSERT(halfedge.twin.twin == halfedge);
        SCRIB.ASSERT(halfedge.next != null);
        SCRIB.ASSERT(halfedge.prev != null);
        SCRIB.ASSERT(halfedge.next.prev == halfedge);
        SCRIB.ASSERT(halfedge.prev.next == halfedge);
    }

    // -- Test edges.
    var iter = graph.edgesBegin();
    while(iter.hasNext())
    {
        edge = iter.next();
        SCRIB.ASSERT(edge.halfedge.edge == edge);
    }

    var iter = graph.facesBegin();
    while(iter.hasNext())
    {
        face = iter.next();
        SCRIB.printFace(face);// Print the faces present.
        SCRIB.ASSERT(face.halfedge.face == face);
    }

    SCRIB.ASSERT(graph.numHalfedges() == graph.numEdges()*2);

    console.log("TotalHalfedges = " + graph.numHalfedges());
    console.log("TotalEdges = " + graph.numEdges());
    console.log("TotalFaces = "     + graph.numFaces());
    console.log("TotalVerts = "     + graph.numVertices());

    return "All Tests have passed";
};

SCRIB.printFace = function(face)
{
    console.log(face);
    var out = ""
    var start   = face.halfedge;
    var current = start;

    do
    {
        //SCRIB.ASSERT(current.face == face);
        console.log("vert " + current.vertex.id + "--> face " + current.face.id)
        out = out + "" + current.vertex.id + ", "
        current = current.next;
    }while(current != start);

    console.log(out);

    var out = ""
    var start   = face.halfedge;
    var current = start;

    // Watch out for cycles.
    var hare = start;

    do
    {
        SCRIB.ASSERT(current.face == face);
        out = out + "" + current.vertex.id + ", "
        current = current.prev;
        hare = hare.prev.prev;

        if (current != start && hare == current)
        {
            console.log("ERROR: Malformed previous pointers.");
            throw new Error("Errof: Malformed previous pointer.");
            SCRIB.ASSERT(false);
        }

    }while(current != start);
    console.log("Face Backwards.");
    console.log(out);
};

SCRIB.printHalfedge = function(halfedge)
{
    out = ""
    out = out + halfedge.vertex.id + " --> " + halfedge.twin.vertex.id
    console.log(out);
    return out
};

SCRIB.printEdge = function(edge)
{
    out = ""
    out = out + edge.halfedge.vertex.id + " <--> " + edge.halfedge.twin.vertex.id
    console.log(out);
    return out   
};

SCRIB.ASSERT = function(b)
{
    if(!b)
    {
        err = new Error()
        console.log(err.stack)
        debugger
        throw new Error("Assertion Failed!")
    }
};