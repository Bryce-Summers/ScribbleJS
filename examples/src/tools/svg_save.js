function svg_saver()
{
    this.text = [];
}

svg_saver.prototype =
{

    start_svg()
    {
        this.text = [];
        this.boundingBox = null;
        this.paths = [];
    },

    // BDS.Box -> sets the dimensions of this svg file.
    setBoundingBox(box)
    {
        this.boundingBox = box;
    },

    // BDS.Polyline, (int or null), int
    addPath(polyline, fill, stroke)
    {
        var output = "<path ";

        // Specify the path's stylization.
        output += "style="
        output += "\"" // Start quote.
        if(fill != null)
        {
            output += "fill:" + this.intToColorString(fill) + ";";
        }
        else // No fill.
        {
            output += "fill:none;";
        }
        output += "fill-rule:evenodd;"
        output += "stroke:" + this.intToColorString(stroke) + ";";
        output += "stroke-width:1px;"
        output += "stroke-opacity:1"
        output += "\"\n" // End quote.

        // Specify the path's geometry.
        output += "d=\"M ";
        var len = polyline.size();
        for(var i = 0; i < len; i++)
        {
            var pt = polyline.getPoint(i);
            output += pt.x + "," + pt.y + " ";
        }
        if(polyline.isClosed())
        {
            output += "z";
        }

        // Add a trailing 
        output += "\"\n";

        // Identify the face for the user.
        output += "id=\"face 1\"\n"

        // Close the path.
        output += "/>\n"


        this.paths.push(output);

        /*
        <path
       style="fill:none;fill-rule:evenodd;stroke:#000000;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
       d="m 71.42857,740.93364 11.42857,0 242.85715,-62.85715 102.85714,220 -282.85714,25.71429 z"
       id="face1"
       />
       */
    },

    // #rrggbb (number)
    intToColorString(color)
    {
        // Create a hex color string with the full 6 characters.
        var str = "000000" + color.toString(16);
        str = str.substr(-6);
        return "#" + str;
    },

    // Returns a text string representing the internal specification for a svg file.
    generate_svg(filename)
    {
        var output = "";

        output += this.generate_header();

        // Grouping Operation.
        //output += "<g>\n"

        for(var i = 0; i < this.paths.length; i++)
        {
            output += this.paths[i];
        }

        //output += "</g>\n";

        output += "</svg>";

        console.log(output);

        this.download(filename + ".svg", output);

    },

    generate_header()
    {
        var endl = "\n";
        var header = "<svg xmlns=\"http://www.w3.org/2000/svg\"" + endl;
        header += "width=\""  + 500 + "\""   + endl;
        header += "height=\"" + 500 + "\"\n" + endl;

        // viewbox.
        var s = " ";// space.
        var x0 = this.boundingBox.min.x;
        var y0 = this.boundingBox.min.y;
        var w  = this.boundingBox.max.x - x0;
        var h  = this.boundingBox.max.y - y0;

        header += "viewBox=\"" + x0 + s + y0 + s + w + s + h + "\"" + endl;
        header += ">"

        return header;
    },


    download(filename, text)
    {
        var pom = document.createElement('a');
        pom.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text));
        pom.setAttribute('download', filename);

        if (document.createEvent) {
            var event = document.createEvent('MouseEvents');
            event.initEvent('click', true, true);
            pom.dispatchEvent(event);
        }
        else {
            pom.click();
        }
    },
}