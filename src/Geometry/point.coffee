###
Point.

Written by Bryce Summers on 1 - 2 - 2017.

Implements Arithmetic.

add, sub, multScalar
###

class SCRIB.Point

    constructor : (@x, @y, @z) ->

        if !@z
            @z = 0.0

    clone: () ->
        return new SCRIB.Point(@x, @y, @z)

    add: (pt) ->
        out = @clone()
        out.x += pt.x
        out.y += pt.y
        out.z += pt.z
        return out

    sub: (pt) ->
        out = @clone()
        out.x -= pt.x
        out.y -= pt.y
        out.z -= pt.z
        return out

    multScalar: (s) ->
        out = @clone()
        out.x *= s
        out.y *= s
        out.z *= s
        return out

    toString: () ->
        output = "Point(" + @x + ", " + @y

        if @z
            output += ", " + @z

        output += ")"

        return output

    magnitude: () ->
        return @norm()

    # Euclidean Norm.
    norm: () ->
        return Math.sqrt(@norm2())

    # Square of the Euclidean norm.
    norm2: () ->
        return @x*@x + @y*@y + @z*@z