# Moved to http://github.com/HaxeFoundation/format #

hxFormat is the repository for different file-formats support for the Haxelanguage.

# Formats #

Currently supported formats are :

  * ABC (Flash AS3 bytecode format)
  * AMF (Flash serialized object)
  * BMP
  * FLV (Flash Video)
  * GZ
  * JPG (writer only)
  * MP3
  * PBJ (PixelBender Binary file)
  * PDF (only generic file structure and partial decryption)
  * PNG
  * SWF (Flash file format)
  * TAR
  * ZIP

Planned future formats include :

  * AMF3 (supported in FlashPlayer 9+)
  * PE (Windows EXE)
  * ISO (Disk Image)
  * ... anything you want to contribute (please ask on the Haxe google group)

# Installation #

hxFormat is available on haxelib, so simply run the following command : `haxelib install format`. To use the library, simply add `-lib format` to your commandline parameters.

# Package Structure #

Each format lies in its own package, for example `format.pdf` contains classes for PDF.

The `format.tools` package contain some tools that might be shared by several formats but don't belong to a specific one.

Each format must provide the following files :
  * one `Data.hx` file that contain only data structures / enums used by the format. If there is really a lot, they can be separated into several files, but it's often my easy for the end user to only have to do one single `import format.xxx.Data` to access to all the defined types.
  * one `Reader.hx` class which enable to read the file format from an `haxe.io.Input`
  * one `Writer.hx` class which enable to write the file format to an `haxe.io.Output`
  * some other classes that might be necessary for manipulating the data structures

It's important in particular that the data structures storing the decoded information are separated from the actual classes manipulating it. This enable full access to all the file format infos and the ability to easily write libraries that manipulate the format, even if later the Reader implementation is changed for example.