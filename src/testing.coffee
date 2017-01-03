class SCRIB.Testing

    constructor: () ->
        @test_points()
        @test_lines()
        @test_intersector()
        console.log("All tests have passed!")
        document.getElementById("text").innerHTML = "All Tests Have Passed!";

    ASSERT: (b) ->
        if !b
            err = new Error()
            console.log(err.stack)
            throw new Error("Assertion Failed!")

    test_points: () ->

        p0 = new SCRIB.Point(1, 1, 1)
        p1 = new SCRIB.Point(2, 3, 4)

        # Addition.
        p2 = p0.add(p1)
        @ASSERT(p2.x == 3)
        @ASSERT(p2.y == 4)
        @ASSERT(p2.z == 5)

        # Subtraction.
        p2 = p0.sub(p1)
        @ASSERT(p2.x == -1)
        @ASSERT(p2.y == -2)
        @ASSERT(p2.z == -3)

        p2 = p1.sub(p0)
        @ASSERT(p2.x == 1)
        @ASSERT(p2.y == 2)
        @ASSERT(p2.z == 3)        

        # Multiplication
        p2 = p0.multScalar(5)
        @ASSERT(p2.x == 5)
        @ASSERT(p2.y == 5)
        @ASSERT(p2.z == 5)

        p2 = new SCRIB.Point(5, 0)

        mag = p2.norm2()
        @ASSERT(24.99 < mag and mag < 25.01)
        mag = p2.norm()
        @ASSERT(4.99 < mag and mag < 5.01)


    test_lines: () ->

        points = [new SCRIB.Point(0, 0), new SCRIB.Point(2, 0), new SCRIB.Point(1, 1), new SCRIB.Point(1, -1)]

        l0 = new SCRIB.Line(0, 1, points)
        l1 = new SCRIB.Line(2, 3, points)

        @ASSERT(points[0] == l0.p1)
        @ASSERT(points[1] == l0.p2)

        @ASSERT(points[2] == l1.p1)
        @ASSERT(points[3] == l1.p2)

        @ASSERT(l0.line_side_test(points[2]) * l0.line_side_test(points[3]) < 0)

        @ASSERT(l0.detect_intersection(l1))
        @ASSERT(l1.detect_intersection(l0))

        @ASSERT(points.length == 4)
        @ASSERT(l0.intersect(l1))

        pt = l0.getLatestIntersectionPoint()
        @ASSERT(pt.y < .0001 and pt.y > -.0001)

        @ASSERT(points.length == 5)

        return

    test_intersector: () ->

        len = 100

        points = [new SCRIB.Point(0, 0),
                  new SCRIB.Point(100, 0)]

        for i in [0...len] by 1
            points.push(new SCRIB.Point(i + .1, -1))
            points.push(new SCRIB.Point(i + .1, 1))

        lines = []
        lines.push(new SCRIB.Line(0, 1, points))
        for i in [0...len] by 1
            i1 = 2 + i*2
            i2 = 2 + i*2 + 1
            lines.push(new SCRIB.Line(i1, i2, points))


        intersector = new SCRIB.Intersector()


        ###
        Test Brute Force intersection.
        ###

        intersector.intersect_brute_force(lines)

        split_lines = []
        len = lines.length
        for i in [0...len] by 1
            lines[i].getSplitLines(split_lines)

        # middle lines, up lines, and down lines.
        @ASSERT(split_lines.length == 101 + 100 + 100)

        for i in [1...len] by 1
            @ASSERT(Math.floor(split_lines[i].p1.x) == i - 1)
            @ASSERT(Math.floor(split_lines[i].p2.x) == i)

        # Clear the previous results.
        for i in [0...len]
            lines[i].clearIntersections()

        ###
        Test Optimized Intersection.
        ###

        len = 100

        points = [new SCRIB.Point(0, 0),
                  new SCRIB.Point(100, 0)]

        for i in [0...len] by 1
            points.push(new SCRIB.Point(i + .1, -1))
            points.push(new SCRIB.Point(i + .1, 1))

        lines = []
        lines.push(new SCRIB.Line(0, 1, points))
        for i in [0...len] by 1
            i1 = 2 + i*2
            i2 = 2 + i*2 + 1
            lines.push(new SCRIB.Line(i1, i2, points))

        intersector.intersect(lines)

        split_lines = []
        len = lines.length
        for i in [0...len] by 1
            lines[i].getSplitLines(split_lines)

        # middle lines, up lines, and down lines.
        @ASSERT(split_lines.length == 101 + 100 + 100)

        for i in [1...len] by 1
            @ASSERT(Math.floor(split_lines[i].p1.x) == i - 1)
            @ASSERT(Math.floor(split_lines[i].p2.x) == i)


        return

    test_halfedge: () ->


new SCRIB.Testing()