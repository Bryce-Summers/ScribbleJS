// Generated by CoffeeScript 1.11.1

/*
    Polyline Graph Associated Data classes.

    Adapted by Bryce Summers on 1 - 3 - 2017.

    Purpose: These classes provide application specific associated data structures that are linked into HalfedgeGraph elements.

    They will be used for algorithms on planar graph embeddings from polyline inputs.
 */

(function() {
  SCRIB.Graph_Data = (function() {
    function Graph_Data(graph) {
      this.graph = graph;
    }

    Graph_Data.prototype.clearFaceMarks = function() {
      var iter, results;
      iter = this.graph.facesBegin();
      results = [];
      while (iter.hasNext()) {
        results.push(iter.next().data.marked = false);
      }
      return results;
    };

    Graph_Data.prototype.clearVertexMarks = function() {
      var iter, results;
      iter = this.graph.verticesBegin();
      results = [];
      while (iter.hasNext()) {
        results.push(iter.next().data.marked = false);
      }
      return results;
    };

    Graph_Data.prototype.clearEdgeMarks = function() {
      var iter, results;
      iter = this.graph.edgesBegin();
      results = [];
      while (iter.hasNext()) {
        results.push(iter.next().data.marked = false);
      }
      return results;
    };

    Graph_Data.prototype.clearHalfedgeMarks = function() {
      var iter, results;
      iter = this.graph.halfedgesBegin();
      results = [];
      while (iter.hasNext()) {
        results.push(iter.next().data.marked = false);
      }
      return results;
    };

    Graph_Data.prototype.clearMarks = function() {
      this.clearFaceMarks();
      this.clearVertexMarks();
      this.clearEdgeMarks();
      return this.clearHalfedgeMarks();
    };

    return Graph_Data;

  })();

  SCRIB.Face_Data = (function() {
    function Face_Data(face) {
      var hole_representatives;
      this.face = face;
      this.marked = false;
      hole_representatives = [];
    }

    Face_Data.prototype.addHole = function(hole) {
      return hole_representatives.push(hole);
    };


    /*
    // The area of the face is determined by the intersection this face with all of the hole faces,
    // which will be specified by exterior facing edge that enclose an infinite complemented area.
     */

    return Face_Data;

  })();

  SCRIB.Vertex_Data = (function() {
    function Vertex_Data(vertex) {
      this.vertex = vertex;
      this.point = null;
      this.marked = false;
      this.tail_point = false;
      this.intersection_point = false;
      this.singleton_point = false;

      /*
       * Used as a temporary structure for graph construction, but it is also may be relevant to users.
       * I don't know whether I will maintain this structure outside of graph construction.
       * FIXME: I might switch this to being a pointer to allow for me to null it out when no longer needed.
       * SCRIB.Halfedge[]
       */
      this.outgoing_edges = [];
    }

    Vertex_Data.prototype.isExtraordinary = function() {
      return this.tail_point || this.intersection_point;
    };

    return Vertex_Data;

  })();

  SCRIB.Edge_Data = (function() {
    function Edge_Data(edge) {
      this.edge = edge;
      this.marked = false;
    }

    return Edge_Data;

  })();

  SCRIB.Halfedge_Data = (function() {
    function Halfedge_Data(halfedge) {
      this.halfedge = halfedge;
      this.marked = false;
      this.next_extraordinary = null;
    }

    Halfedge_Data.prototype.isExtraordinary = function() {
      return this.halfedge.vertex.data.isExtraordinary();
    };

    return Halfedge_Data;

  })();

}).call(this);