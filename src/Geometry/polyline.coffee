###
Polyline class

Written by Bryce Summers on 1 - 4 - 2017.

Note: Closed Polylines are polygons...
 - So we will put all of our polygon code into this class.

###

class SCRIB.Polyline

    # FIXME: Maybe I should use SCRIB.Point_info's instead.
    # SCRIB.Point[], bool
    constructor: (@_isclosed, points_in) ->
        if @_isClosed == undefined
            @_isclosed = false

        @_points = []

        if points_in
            @appendPoints(points_in)

    appendPoints: (array) ->

        for p in array
            @addPoint(p)

    addPoint: (p) ->
        @_points.push(p)

    removeLastPoint: () ->
        return @_points.pop()


    getPoint: (index) ->
        return @_points[index]

    size: () ->
        return @_points.length

    isClosed: () ->
        return @_isclosed

    ###
    * http://math.blogoverflow.com/2014/06/04/greens-theorem-and-area-of-polygons/
    * Computes the area of a 2D polygon directly from the polygon's coordinates.
    * The area will be positive or negative depending on the
    * clockwise / counter clockwise orientation of the points.
    * Also see: https://brycesummers.wordpress.com/2015/08/24/a-proof-of-simple-polygonal-area-via-greens-theorem/
    * Note: This function interprets this polyline as closed.
    #  -> float
    ###
    computeArea: () ->

        len = @_points.length
        p1  = @_points[len - 1]

        area = 0.0

        # Compute based on Green's Theorem.
        for i in [0...len] by 1
        
            p2 = @_points[i]
            area += (p2.x + p1.x)*(p2.y - p1.y)
            p1 = p2 #/ Shift p2 to p1.

        return area / 2.0

    # -> bool
    isComplemented: () -> 
        
        return@computeArea() > 0