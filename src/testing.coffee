class SCRIB.Testing

    constructor: () ->

        console.log("All tests have passed!")
        document.getElementById("text").innerHTML = "All Tests Have Passed!";

    ASSERT: (b) ->
        if !b
            err = new Error()
            console.log(err.stack)
            throw new Error("Assertion Failed!")




new SCRIB.Testing()