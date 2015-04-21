Summary of PDF support in hxFormat

Currently it only support the following features :
  * parse PDF content
  * handle Encryption (version 2.3 and 2.4 only)
  * handle FlateDecode filter (zlib)

This should be enough however to extract useful informations from most available PDF documents.

# Usage #

Here's an example of PDF usage :

```
var input = neko.io.File.read("myfile.pdf",true);
// parse the file content
var p = new format.pdf.Reader();
var data = p.read(i);
// decrypt (if encrypted)
var data = new format.pdf.Crypt().decrypt(data);
// unfilter (unzip the zipped parts)
var data = new format.pdf.Filter().unfilter(data);
// trace the PDF datas
for( o in data )
    trace(o)
```

The PDF data consists of an array of `format.pdf.Data`. An object can be either a set of commands for display some datas or some images datas, etc.

No work has been currently done to interpret or parse these objects further than the raw data available as part of the PDF format. Pictures and text however should be extractable by using this file format support as long as the PDF is not too much complex.