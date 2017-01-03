###
Line with associated intersection data.
Written by Bryce Summers on 1 - 2 - 2017.
###

class SCRIB.Line


    constructor: (start_point_index, end_point_index, point_array) ->

        # Point indices.
        @p1_index = start_point_index
        @p2_index = end_point_index

        # The canonical array of points.
        @points = point_array;

        @p1 = @points[@p1_index]
        @p2 = @points[@p2_index]

        @offset = @p2.sub(@p1)

        # Float[]
        # Collection of doubles representing the percentage a point is between p1 and p2.
        @split_points_per = []

        #int[]
        # The indices of the points.
        @split_points_indices = []


    ###
    intersects the given other_line with this line.
    Adds a split point if they do intersect.
    Any created split points are added to the referenced global collection of points.
    # Line -> bool
    ###
    intersect: (other) ->

        # Already Previously Connected.
        # Connected at a joint in the input polyline.
        if @p1_index == other.p1_index or @p1_index == other.p2_index or
           @p2_index == other.p1_index or @p2_index == other.p2_index
            return false

        # No intersection.
        if !@detect_intersection(other)
            return false
        
        # Yes intersection.
        @_report_intersection(other)
        return true

    ###
    Returns a signed floating point number indicating which direction the given point is relative to this line.
    # Point -> float.
    ###
    line_side_test: (c) ->
        return (@p2.x - @p1.x)*(c.y - @p1.y) - (@p2.y - @p1.y)*(c.x - @p1.x)

    ###
    Appends all of the split set of lines in order to the output vector.
    Adds itself if it does not contain any split lines.
    Line pts are oriented along the polyline, such that p1 comes before p2 in the polyline + intersection point ordering.
    Line[] -> void
    ###
    getSplitLines: (lines_out) ->

        # Number of split points.
        len = @split_points_per.length;

        # Not split points.
        if len == 0
        
            # Saves work.
            lines_out.push(@)
            return
        

        # First sort points.
        @_sort_split_points()

        # Make sure the last line is pushed.
        # This ensures that that initial line will be pushed if this line has no intersections.
        @split_points_indices.push(@p2_index)

        # Append all of the line's segments to the inputted array.
        last_indice = @split_points_indices[0]

        # The initial line.
        lines_out.push(new SCRIB.Line(@p1_index, last_indice, @points))

        # for i = 1; i < len; i++
        for i in [1...len]
            next_indice = @split_points_indices[i]
            lines_out.push(new SCRIB.Line(last_indice, next_indice, @points))
            last_indice = next_indice

        # The last line.
        lines_out.push(new SCRIB.Line(last_indice, @p2_index, @points))

        # Done.
        return

    ###
    This function should only be called after a call to intersect has returned true.
    Returns the last intersection point.
    this is only guranteed to be valid immediatly after the true return from the intersect function.
    void -> Point.
    ###
    getLatestIntersectionPoint: () ->
    
        return @points[@points.length - 1]
    
    ###
    Internally sorts the split points from the start to the end of this line.
    ###
    _sort_split_points: () ->

        len = @split_points_per.length

        # Insertion sort.
        for i in [1...len]#(int i = 1; i < len; i++)
            for i2 in [i - 1 ..0]#for (int i2 = i - 1; i2 >= 0; i2--)
            
                i1 = i2 + 1;

                if @split_points_per[i2] <= @split_points_per[i1]
                   break

                # -- Swap at indices i2 and i2 + 1.
                # Keep the percentage measuremtents consistent with the indices.
                temp_f = @split_points_per[i2]
                @split_points_per[i2] = @split_points_per[i1]
                @split_points_per[i1] = temp_f

                temp_i = @split_points_indices[i2]
                @split_points_indices[i2] = @split_points_indices[i1]
                @split_points_indices[i1] = temp_i

        return

    ###
    Returns true iff this line segment intersects with the other line segment.
    Doesn't do any degeneracy checking.
    Line -> bool.
    ###
    detect_intersection: (other) ->
        
        # float test results.
        a1 = @line_side_test(other.p1)
        a2 = @line_side_test(other.p2)

        b1 = other.line_side_test(@p1)
        b2 = other.line_side_test(@p2)

        ###
        The product of two point based line side tests will be negative iff
        the points are not on strictly opposite sides of the line.
        If the product is 0, then at least one of the points is on the line not containing the points.
        ###
        
        return a1*a2 <= 0 && b1*b2 <= 0;
    ###
    Line -> void.
    ###
    _report_intersection: (other) ->

        # Find the intersection point.

        ###
        u = ((bs.y - as.y) * bd.x - (bs.x - as.x) * bd.y) / (bd.x * ad.y - bd.y * ad.x)
        v = ((bs.y - as.y) * ad.x - (bs.x - as.x) * ad.y) / (bd.x * ad.y - bd.y * ad.x)
        Factoring out the common terms, this comes to:

        dx = bs.x - as.x
        dy = bs.y - as.y
        det = bd.x * ad.y - bd.y * ad.x
        u = (dy * bd.x - dx * bd.y) / det
        v = (dy * ad.x - dx * ad.y) / det
        ###

        # Extract the relevant points.
        as = @p1
        bs = other.p1
        ad = @offset
        bd = other.offset

        # floats.
        dx = bs.x - as.x
        dy = bs.y - as.y
        det = bd.x * ad.y - bd.y * ad.x
        u = (dy * bd.x - dx * bd.y) / det
        v = (dy * ad.x - dx * ad.y) / det

        # The intersection is at time coordinates u and v.
        # Note: Time is relative to the offsets, so p1 = time 0 and p2 is time 1.

        # u is the time coordinate for this line.
        @split_points_per.push(u)

        # v is the time coordinate for the other line.
        other.split_points_per.push(v)

        intersection_point = as.add(ad.multScalar(u))

        # Get the next index that will be used to store the newly created point.
        index = @points.length
        @points.push(intersection_point)

        @split_points_indices.push(index)
        other.split_points_indices.push(index)

    # Clears away all intersection data.
    clearIntersections: () ->

        @split_points_per = []
        @split_points_indices = []