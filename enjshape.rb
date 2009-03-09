require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'

#helper for reading binary files
require 'enjshape/binary'

#dbf library
#require 'date'
require 'enjshape/dbfglobals'
require 'enjshape/dbfrecord'
require 'enjshape/dbfcolumn'
require 'enjshape/dbftable'
require 'enjshape/llatude'
#shapes
require 'enjshape/shapes'
require 'enjshape/util'

$enjStrings = LanguageHandler.new("EnjShape.strings")
if $enjInfo.nil? then $enjInfo = {"about"=>SketchupExtension.new($enjStrings.GetString("ENJ's ShapeFile Importer"), "enjshape/load.rb")}; end
$enjInfo["about"].creator = $enjStrings.GetString("Ian Johnson")
$enjInfo["about"].copyright = $enjStrings.GetString("#{[0xA9].pack('U*')}2007-2009, Ian Johnson")
$enjInfo["about"].version = ".2 - 03/15/2009"
$enjInfo["about"].description = $enjStrings.GetString(
     "Plugins -> EnjShape -> Import Shapefile.\r\n" +
     "Adds the ability to import ESRI Shapefiles to Sketchup.\r\n" +
     "http://enja.org/enjshape\r\n" +
     "Thanks to the people making their code available on the internet who made this possible (see README.txt).\r\n")
$enjInfo["help"] = $enjStrings.GetString(
     "Right now EnjShape only supports Point, Arc, and Polygon.\r\n\n" +
     "You can change what the origin will be aligned to (defaults to midpoint of the bounding box).\r\n\n" + 
     "\"Flattening\" is used when converting latlong into sketchup units. Since Sketchup is a 3d environment we don't project and get points on the globe. If you want to have polygons they need to be planar so you must flatten the points (set z = 0 for all points).\r\n\n" + 
     "You can also Push/Pull your imported shapes automatically by looking at a field from the dbf. You must choose the appropriate units.\r\n" +
     "\n")

status = Sketchup.register_extension($enjInfo["about"], false)




