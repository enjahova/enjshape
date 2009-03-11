
class EnjShape
  attr_accessor :minx, :miny, :maxx, :maxy, :shptype, :numrecs
  SHPTYPES = {
  0 => "NullShape",
  1 => "Point",
  3 => "Arc", #PolyLine
  5 => "Polygon",
  8 => "MultiPoint",
  11 => "PointZ",
  13 => "ArcZ", #PolyLineZ
  15 => "PolygonZ",
  18 => "MultiPointZ",
  21 => "PointM",
  23 => "ArcM", #PolyLineM
  25 => "PolygonM",
  28 => "MultiPointM",
  31 => "MultiPatch",
  }
  

  def initialize(filename)
    #all shape related files must have same name (x.shp, x.dbf, x.shx)
    name = filename[0,filename.size() - 4] #cut off the extension
    @shpfilename = "#{name}.shp"
    @dbffilename = "#{name}.dbf"
    @shxfilename = "#{name}.shx"
    #test for existance of .shp, .dbf and .shx
    @shpfile = File.new(@shpfilename, "rb")
    @dbffile = File.new(@dbffilename, "rb")
    #@shpfile.binary 
    #@dbffile.binary
    #.shx isn't mandatory but we should be aware
    @shxfile = File.new(@shxfilename, "rb")
    #@shxfile.binary
  end

  def parseshp()
    #read the shx file
#    shxreader = BinaryReader.new(@shxfile)
#    shxheader = shxreader.read(100) #identical to shp file header
#    while !@shxfile.eof
#      offset = shxreader.read_nint() * 2
#      reclen = shxreader.read_nint() * 2  #Record Number
#      puts "shx: #{offset}, #{reclen}"
#    end
    
    
    #read the shp file header
    shpreader = BinaryReader.new(@shpfile)
    filecode = shpreader.read_nint()
    cruft = shpreader.read_nint(5)
    @filelen = shpreader.read_nint() * 2  #in bytes
    version = shpreader.read_int()
    @shptype = SHPTYPES[shpreader.read_int()] #only depend on this in general (each record determines its Shape class)
    #puts "#{filecode} #{@filelen} #{version} #{@shptype}"
    #bounding box
    @minx = shpreader.read_double()
    @miny = shpreader.read_double()
    @maxx = shpreader.read_double()
    @maxy = shpreader.read_double()
    @minz = shpreader.read_double()
    @maxz = shpreader.read_double()
    @minm = shpreader.read_double()
    @maxm = shpreader.read_double()
    #puts "minx:#{@minx} miny:#{@miny} maxx:#{@maxx} maxy:#{@maxy} " +
    #     "minz:#{@minz} maxz:#{@maxz} minm:#{@minm} maxm:#{@maxm} "
    
    #load the spatial data
    records = {}
    while !@shpfile.eof
      #each record has a 8 byte header
      header = shpreader.read_nint(2)
      recnum = header[0]  #Record Number
      reclen = header[1] * 2 #Content length (in bytes)
      #We dynamically figure out which type of shape this record is
      #inttype = shpreader.read_int() 
      #shptype = SHPTYPES[inttype]
      #puts "rec: #{recnum} itype: #{inttype} stype: #{shptype}"
      shptype = SHPTYPES[shpreader.read_int()]


      #We now parse the following record based on what type it is
      #puts "recnum: #{recnum}"
      #puts "reclen: #{reclen}"
      #puts "bla: #{shptype}"
      @units = "latlong" #we just assume default of latlong, can change with shape.set_units(units)
      s = eval "#{shptype}.new(recnum, @units)"
      next if shptype == "NullShape"
      s.parse(shpreader)
      records[recnum] = s
    end
    @records = records.sort #array with entries [recnum, shape]
    @numrecs = @records.size()
    
  end
  
  def parsedbf()
    #load the dbf file
    reader = DBF::Table.new @dbffilename
    return reader
    #puts reader.schema
    #cols = reader.columns
    #cols.each { |c| puts c.name }
    #recs = reader.records
    #rec = reader.record(0)
    #puts "lets try: #{rec.attributes()['BUILDING']}"
    #recs.each { |r| puts r.}
  end
  
  def parseshx()
    #load the index file
  end
  
  def set_units(units)
    @units = units
    #puts "in EnjShape.set_units: @units: #{@units} units: #{units}"
    @records.each { |key, val| val.set_units(@units) }
  end
  
  def render(entities, flatten, pushpull, start, stop)

    ra = @records[start...stop]
    #puts "size: #{ra.size} start: #{ra[0][0]} stop: #{ra[ra.size-1][0]}"
    ra.each {|rec| rec[1].render(entities, flatten, pushpull)}
    #@records.each {|rec| rec[1].render(entities, flatten, pushpull)}
    ##else
      ##@records.each {|rec| rec[1].render(entities, flatten)}
      #@records.each { |key, val| eid = val.render(entities, flatten); i +=1  }
      #@records.keys.sort_by {|s| s.to_s}.map {|key| [key, @records[key]] }
      
      #rec_array = @records.sort
      #rs = rec_array.size()
      
      #start -= 1
      #stop -= 1   #weird indexing
      #ra1 = rec_array[start...stop]
      #ra2 = rec_array[rs/2...rs]
      #ra1.each {|rec| puts "#{rec[0]}"; rec[1].render(entities, flatten)}
      #puts "rs: #{rs/2}"
      #ra2.each {|rec| puts "#{rec[0]}"; rec[1].render(entities, flatten)}
      
      
      #rec_array.each {|rec| puts "#{rec[0]}"; rec[1].render(entities, flatten)}
    ##end
    #puts "records rendered: #{i}"

    
  end
end


def loadShapeFile()
  #home = File.expand_path "~"
  #shpfiles = File.join home, "programming/GIS/sketchup/shapefile/data"
  #shapefile = File.join shpfiles, "buildings.shp"
  #statefile = File.join shpfiles, "footprints.shp"

  #this will work for OS X, and hopefully M$
  if( ENV["HOME"] )
      homedir = File.expand_path("~")
      $:.push homedir
  end
  
  #load the file from an "open file" prompt and check to make sure its at least .shp
  shapefile = UI.openpanel("Import Shape File", "", "")
  if shapefile && shapefile[-3..-1] == "shp"
    #also check for dbf and shx
    shape = EnjShape.new(shapefile)
  else
    UI.messagebox "Must load a valid shapefile"
    return false
  end
  
  shape.parseshp()
  dbf = shape.parsedbf()
  
  #if latlong, flatten?
  #center based on bounds
  centerx = shape.minx + (shape.maxx - shape.minx) / 2
  centery = shape.miny + (shape.maxy - shape.miny) / 2

  #ask the user a few things about their shapefile and how they want it rendered
  loadDialog = UI::WebDialog.new("Load Shapefile")
  loadDialog.set_position(100,100)
  loadDialog.set_size(420,330)
  
  shapename = shapefile.split('/')[-1] 
  #should check for windows or mac, only splits for Mac
  #puts RUBY_PLATFORM
  html_path = Sketchup.find_support_file "loadShape.html" ,"Plugins/enjshape"
  puts html_path
  loadDialog.set_file(html_path)
  
=begin 
  html_name = "Shapefile: #{shapename}<br>"
  html_bounds = "<table><tr><td>minx: #{shape.minx} </td><td>miny: #{shape.miny} </td></tr><tr><td>maxx: #{shape.maxx} </td><td>maxy: #{shape.maxy}</td></tr></table><br>"
  html_units = "Units: <select id='units'><option value='latlong'>latlong</option><option value='meters'>meters</options><option value='feet'>feet</options></select><br>"
  html_center = "Center X: <input id='centerx' type='text' size='20' value='#{centerx}'> <br>Center Y: <input id='centery' type='text' size='20' value='#{centery}'><br>"
  html_flatten = "<select id='flatten' #{'disabled' if shape.shptype == 'Polygon'}><option value='flatten'>flatten</option><option value='world'>world</options></select><br>"
  #html_units = "Units: <input id='units' type='text' size='10' value='latlong'><br>"
  html_submit = "<input type=submit value=\"Render\" onclick=\"window.location='skp:render@shape'\">"
  #if polygon we should give option to pushpull by a DBF field
  html_pushpull = "Push/pull your polygon by an amount specified in field:<br><select id='pushpull'><option value='---' selected>---</option>"
  cols = dbf.columns
  cols.each { |c| html_pushpull += "<option id='#{c.name}'>#{c.name}</option>"}
  html_pushpull += "</select>"
  html_pushpull += "<select id='pp_units'><option value='meters'>meters</options><option value='feet'>feet</options></select><br>"
  html = "<html><body>" + html_name + html_bounds + html_units + html_center + html_flatten 
  html += html_pushpull if shape.shptype == "Polygon"  #only do if polygon
  
  html_start_stop = "start: <input id='start' type='text' size='20' value='0'> <br>stop: <input id='stop' type='text' size='20' value='0'><br>"
  html += html_start_stop
  html += html_submit + "</body></html>"
  loadDialog.set_html(html)
=end
  
  #loadDialog.set_file("load.html", $:[0] + "/enjshape/")
  loadDialog.add_action_callback("loadParams") { |d, p| 
    params = "{"
    params += "'shapefile':'#{shapename}',"
    params += "'bounds':{'minx':#{shape.minx}, 'miny':#{shape.miny}, 'maxx':#{shape.maxx}, 'maxy':#{shape.maxy}},"
    if shape.shptype == 'Polygon'
      params += "'polygon':true,"
      params += "'dbffields':\"<option value='---' selected>---</option>"
      cols = dbf.columns
      cols.each { |c| params += "<option id='#{c.name}'>#{c.name}</option>"}
      params += "\","
    else
      params += "'polygon':false,"
    end
    params += "records:#{shape.numrecs}"
    params += "}"
    #puts params
    js_call = "gotParams(#{params});"
    #puts js_call
    #js_call = "window.alert('hello')"
    d.execute_script(js_call)
  }
  
  
  loadDialog.add_action_callback("render") { |d, p| 
    puts "rendering!"
    units = d.get_element_value("units")
    start = d.get_element_value("start").to_i
    stop = d.get_element_value("stop").to_i

    
    shape.set_units(units)
    #puts "units in html: #{units}"
    
    if shape.shptype == "Polygon"
      dpp = d.get_element_value("pushpull")
      dpp_i = d.get_element_value("pushpull_i").to_f
      #puts "#{dpp} and #{dpp_i}"
      if dpp == "---" and dpp_i > 0
        pushpull = [dpp, dpp_i]
      else
        pushpull = [dpp, dbf, d.get_element_value("pp_units")] #going to pass the column name as well as the dbf reader
      end
    else
      pushpull = ["---", 0]
    end
    
    d.close()
    
    
    #add advanced option for these
    flatten = true
=begin    
    if units == "latlong"
      flatten = d.get_element_value("flatten") == "flatten"
    else
      flatten = true
    end
=end
    
    nr = shape.numrecs
    if stop > 0
      if stop < start
        #user error! should prompt.
        temp = start
        start = stop
        stop = temp
      end
      if stop > nr
        #user error! should prompt
        stop = nr
      end
      if start < 0
        #user error! should prompt
        start = 0
      end
      render_shape(shape, units, [centerx, centery], flatten, pushpull, start, stop)
    else
    
    
      #handle large # of records
      #sketchup seems to sputter when trying to render over 1000, this is an arbitrary hack
      #in an attempt to make it stop skipping shapes. Works better but not perfect.
      split = 20
      if nr > split
        rparts = nr / split
        (0..rparts).each { |i|
          start = i * split
          stop = (i + 1) * split
          if stop > nr
            stop = nr
          end
          #puts "start: #{start} stop: #{stop}"
          render_shape(shape, units, [centerx, centery], flatten, pushpull, start, stop)
        }
      else
        start = 0
        stop = nr
        render_shape(shape, units, [centerx, centery], flatten, pushpull, start, stop)
      end
      
    end
    
  }
  loadDialog.show()
  
end

def render_shape(shape, units, center, flatten, pushpull, start, stop)

  model = Sketchup.active_model
  model.start_operation $enjStrings.GetString("Import Shapefile")
  entities = model.active_entities

  si = model.shadow_info
  
  si["Latitude"] = center[1]
  si["Longitude"] = center[0]

  shape.render(entities, flatten, pushpull, start, stop)

=begin
  # Look at all of the entities in the selection.
  face_count = 0
  entities.each { |entity| 
    if entity.typename == "Face"
      face_count = face_count + 1
    end
  }
  puts "face count: #{face_count}"
=end
  view = model.active_view
  newview = view.zoom_extents
  
  model.commit_operation
end



if( not $enjshape_menu_loaded )
    enjshape_menu = UI.menu("Plugins").add_submenu($enjStrings.GetString("EnjShape"))

    enjshape_menu.add_item($enjStrings.GetString("Import Shapefile")) { loadShapeFile() }
    $enjshape_menu_loaded = true
end