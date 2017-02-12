// Generated by CoffeeScript 1.11.1

/*

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
 */

(function() {
  SCRIB.TopologyLinker = (function() {
    function TopologyLinker() {}

    TopologyLinker.link_island_vertex = function(vertex, edge, halfedge, twin, interior, exterior) {
      vertex.halfedge = halfedge;
      edge.halfedge = halfedge;
      interior.halfedge = halfedge;
      exterior.halfedge = halfedge;
      halfedge.edge = edge;
      halfedge.face = exterior;
      halfedge.next = halfedge;
      halfedge.prev = halfedge;
      halfedge.twin = twin;
      halfedge.vertex = vertex;
      twin.edge = edge;
      twin.face = interior;
      twin.next = twin;
      twin.prev = twin;
      twin.twin = halfedge;
      twin.vertex = vertex;
    };

    TopologyLinker.link_edge_to_vertices = function(v1, v2, new_edge, new_he1, new_he2, new_face) {
      var he1, he2, next1, next2, ref;
      ref = this.find_cycle_containing_both_verts(v1, v2), next1 = ref[0], next2 = ref[1];
      if (next1 === null) {
        this.split_face_by_adding_edge(next1, next2, new_edge, new_he1, new_he2, new_face);
        return;
      }
      he1 = this.find_complemented_cycle_at_vert(v1);
      he2 = this.find_complemented_cycle_at_vert(v2);
      return this.union_faces_by_adding_edge(he1, he2, new_edge, new_he1, new_he2, new_face);
    };

    TopologyLinker.find_outgoing_halfedge_on_cycle = function(halfedge_on_cycle, target_vertex) {
      var current, start;
      start = halfedge_on_cycle;
      current = start;
      while (true) {
        if (current.vertex === target_vertex) {
          return current;
        }
        current = current.next;
        if (current === start) {
          break;
        }
      }
      return null;
    };

    TopologyLinker.find_cycle_containing_both_verts = function(v1, v2) {
      var current, he_v2, start;
      start = v1.halfedge;
      current = start;
      while (true) {
        he_v2 = this.find_outgoing_halfedge_on_cycle(current, v2);
        if (he_v2 !== null) {
          return [current, he_v2];
        }
        current = current.twin.next;
        if (current === start) {
          break;
        }
      }
      return [null, null];
    };

    TopologyLinker.find_complemented_cycle_at_vert = function(vert) {
      var current, start;
      start = vert.halfedge;
      current = start;
      while (true) {
        if (this.is_cycle_complemented(current)) {
          return current;
        }
        current === current.twin.next;
        if (current === start) {
          break;
        }
      }
    };

    TopologyLinker.is_cycle_complemented = function(halfedge) {
      var addVert, polyline;
      polyline = BDS.Polyline(true);
      addVert = function(vert) {
        return polyline.addPoint(vert.data.point);
      };
      SCRIB.TopologyLinker.map_cycle_vertices(halfedge, addVert);
      return polyline.isComplemented();
    };

    TopologyLinker.map_cycle_vertices = function(halfedge, f_of_v) {
      var current, start;
      start = halfedge;
      current = start;
      while (true) {
        f_of_v(current.vertex);
        current = current.next;
        if (current === next) {
          break;
        }
      }
    };

    TopologyLinker.find_outgoing_halfedge_on_face = function(vertex, face) {
      var current, start;
      start = vertex.halfedge;
      current = start;
      while (true) {
        if (current.face === face) {
          return current;
        }
        current = current.twin.next;
        if (current !== start) {
          break;
        }
      }
      return null;
    };

    TopologyLinker.split_face_by_adding_edge = function(he1, he2, new_edge, new_he1, new_he2, new_face) {
      return this._link_edge_to_cycle_locations(he1, he2, new_edge, new_he1, new_he2, new_face);
    };

    TopologyLinker.union_faces_by_adding_edge = function(he1, he2, new_edge, new_he1, new_he2, new_face) {
      var face1, face2;
      face1 = he1.face;
      face2 = he2.face;
      this._link_edge_to_cycle_locations(he1, he2, new_edge, new_he1, new_he2, new_face);
      face1.destroy();
      return face2.destroy();
    };

    TopologyLinker._link_edge_to_cycle_locations = function(he1, he2, new_edge, new_he1, new_he2, new_face) {
      var next1, next2, old_face, prev1, prev2, vert1, vert2;
      next1 = he1;
      next2 = he2;
      prev1 = next1.prev;
      prev2 = next2.prev;
      vert1 = next1.vertex;
      vert2 = next2.vertex;
      old_face = next1.face;
      new_edge.halfedge = new_he1;
      new_he1.next = next2;
      new_he1.prev = prev1;
      new_he1.vertex = vert1;
      new_he1.twin = new_he2;
      new_he1.face = old_face;
      new_he1.edge = new_edge;
      next2.prev = new_he1;
      prev1.next = new_he1;
      new_he2.next = next1;
      new_he2.prev = prev2;
      new_he2.vertex = vert2;
      new_he2.twin = new_halfedge1;
      new_he2.face = old_face;
      new_he1.edge = new_edge;
      next1.prev = new_he2;
      prev2.next = new_he2;
      this.link_cycle_to_face(next1, new_face);
      return new_face.halfedge = next1;
    };

    TopologyLinker.link_cycle_to_face = function(halfedge, face_target) {
      var current, start;
      start = halfedge;
      current = start;
      while (true) {
        current.face = face_target;
        if (current === start) {
          break;
        }
      }
    };

    TopologyLinker.unlink_edge = function(edge, new_face, params) {
      var degree1, degree2, face, face1, face2, halfedge1, halfedge2, merge_faces, next, prev, split_faces, vert1, vert2;
      halfedge1 = edge.halfedge;
      halfedge2 = halfedge1.twin;
      vert1 = halfedge1.vertex;
      vert2 = halfedge2.vertex;
      degree1 = vert1.degree();
      degree2 = vert2.degree();
      face1 = halfedge1.face;
      face2 = halfedge2.face;
      merge_faces = face1 !== face2;
      face = null;
      if (merge_faces) {
        face = this._merge_faces(face1, face2, face_new);
      } else {
        face = face1;
      }
      if (degree1 === 1) {
        if (params.erase_lonely_vertices) {
          vert1.destroy();
        } else {
          vert1.make_lonely();
        }
      }
      if (degree2 === 1) {
        if (params.erase_lonely_vertices) {
          vert2.destroy();
        } else {
          vert2.make_lonely();
        }
      }
      if (degree1 === 1 && degree2 === 1) {
        face1.destroy();
        edge.destroy();
        halfedge1.destroy();
        halfedge2.destroy();
        return;
      }
      if (degree2 > 1) {
        next = halfedge1.next;
        prev = halfedge2.prev;
        next.prev = prev;
        prev.next = next;
        face.halfedge = next;
        vert2.halfedge = next;
      }
      if (degree1 > 1) {
        next = halfedge2.next;
        prev = halfedge1.prev;
        next.prev = prev;
        prev.next = next;
        face.halfedge = next;
        vert1.halfedge = next;
      }
      split_faces = !merge_faces && degree1 > 1 && degree2 > 1;
      if (split_faces) {
        this._split_face_by_removing_edge(edge, face_new);
      } else {
        face_new.destroy();
      }
      if (!split_faces && !merge_faces) {
        face.data.marked = true;
      }
      halfedge1.destroy();
      halfedge2.destroy();
      edge.destroy();
    };

    TopologyLinker._merge_faces = function(face1, face2) {
      var current, h0, halfedge1, halfedge2, new_face;
      halfedge1 = face1.halfedge;
      halfedge2 = face2.halfedge;
      new_face = face1;

      /*
      h0 = halfedge1
      current = h0
      
      loop # DO
          current.face = new_face
          current = current.next
      
           * WHILE
          break unless current != h0
       */
      h0 = halfedge2;
      current = h0;
      while (true) {
        current.face = new_face;
        current = current.next;
        if (current === h0) {
          break;
        }
      }
      new_face.halfedge = h0;
      face2.destroy();
      return face1;
    };

    TopologyLinker._split_face_by_removing_edge = function(edge, face_new) {
      var current, face_new1, face_new2, face_old, halfedge1, halfedge2, next1, next2, start;
      halfedge1 = edge.halfedge;
      halfedge2 = halfedge1.twin;
      face_old = halfedge1.next.face;
      face_new1 = face_new;
      face_new2 = face_old;
      next1 = halfedge1.next;
      next2 = halfedge2.next;
      face_new1.halfedge = next1;
      face_new2.halfedge = next2;
      start = next1;
      current = start;
      while (true) {
        current.face = face_new1;
        current = current.next;
        if (current === start) {
          break;
        }
      }
      start = next2;
      current = start;
      while (true) {
        current.face = face_new2;
        current = current.next;
        if (current === start) {
          break;
        }
      }
      return [face_new1, face_new2];
    };

    return TopologyLinker;

  })();

}).call(this);