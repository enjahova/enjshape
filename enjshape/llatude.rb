include Math

class LLAtude # Copyright(c) 2006, John WS Hibbs, SwaJime's Cove(sm), swajime.com   
   @@A = 6378137.m();                # def Swa.A; A;   end #   meters, Equatorial radius (semi-major axis)
   @@IF = 298.257223563;             # def Swa.IF; IF; end #   Inverse Flattening
   @@F = 1.0/@@IF;                   # def Swa.F; F;   end #   Flattening
   @@B = @@A - @@A*@@F;              # def Swa.B; B;   end #   Polar radius (semi-minor  axis)
   @@EE = 2.0*@@F-@@F**2;            # def Swa.EE; EE; end #     eccentricity(squared)
   @@EE1 = (@@A**2-@@B**2)/(@@B**2); # def Swa.EE1; EE1; end #     eccentricity prime (squared)
   @@PolarAxis = [Geom::Point3d.new(0,0,0), Geom::Vector3d.new(0,0,1)]
   @@showAs = "d°m's\"" # "d°m's\"" | "[d,m,s]" | "d" | "r"
   @@toGeo = nil
   @@fromGeo = nil
   @@range = nil # [33.706, 33.709, -117.632, -117.629,10] # nil
   def initialize (where) # where = [lat,lon,h] or Geom::Point3d or unsupported
      if where.kind_of?(Geom::Point3d)
         pt = where.transform(LLAtude.toGeo)
         @given = "Sketchup Point"
         @x = pt.x.to_inch
         @y = pt.y.to_inch
         @z = pt.z.to_inch
      elsif where.kind_of?(Array)
         lla = where
         @given = "LLAtude"
         @latitude = lla[0]
         @longitude = lla[1]
         @height = lla[2].inch
      else
         puts("LLAtude.new(argument) with argument type of #{where.class} is not supported.")
      end
   end
   def LLAtude.toDMS(angle) # Copyright(c) 2006, John WS Hibbs, SwaJime's Cove(sm), swajime.com  
      a = (angle*360000).round()/360000.0
      d = a.truncate
      m = (60*a.abs%60).truncate
      s = ((3600*a.abs%60)*100).round/100.0
      [d,m,s]
   end   
   def to_s # Copyright(c) 2006, John WS Hibbs, SwaJime's Cove(sm), swajime.com   
      if @@showAs == "d°m's\""
         dms = LLAtude.toDMS(latitude.radians.abs)
         display = "#{dms[0]}° #{dms[1]}\' #{dms[2]}\""
         display << (latitude < 0 ? ' S, ' : ' N, ')
         dms = LLAtude.toDMS(longitude.radians.abs)
         display << "#{dms[0]}° #{dms[1]}\' #{dms[2]}\""
         display << (longitude < 0 ? ' W' : ' E')
         display << ", #{height.to_s}"
      elsif @@showAs == "[d,m,s]"
         dmsLat = LLAtude.toDMS(latitude.radians)
         dmsLong = LLAtude.toDMS(longitude.radians)
         display = "#{dmsLat.inspect}, #{dmsLong.inspect}"
         display << ", #{height.to_s}"
      elsif @@showAs == "d"
         display = "#{latitude.radians}, #{longitude.radians}"
         display << ", #{height.to_s}"
      elsif @@showAs == "r"
         display = "#{latitude}, #{longitude}"
         display << ", #{height.to_s}"
      else
         display = "@@showAs #{@@showAs} is not supported"            
      end
   end
   def to_a; [latitude, longitude, height]; end
   def pvcr; @pvcr.nil? ? @pvcr=@@A/sqrt(1-@@EE*(sin(latitude))**2) : @pvcr; end # prime vertical  curvature radius  (i.e. radius of Normal @ latitude) 
   def mcr; @mcr.nil? ? @mcr=@@A*(1.0-@@EE)/((1.0-@@EE*(sin(latitude))**2)**1.5) : @mcr; end  # meridional curvature radius (not used atm)
   def p; @p.nil? ? p=sqrt(x**2+y**2) : @p; end
   def t; @t.nil? ? t=atan2(z*@@A,p*@@B) : @t; end
   def latitude #; @lat.nil? ? @lat=atan2(z+@@EE1*@@B*(sin(t))**3,p-@@EE*@@A*(cos(t))**3) : @lat; end
      return @latitude if @given == "LLAtude"
      return atan2(z+@@EE1*@@B*(sin(t))**3,p-@@EE*@@A*(cos(t))**3) if @given == "Sketchup Point"
      puts "LLAtude.latitude() not available for #{@given}"
      nil
   end
   def longitude #; @long.nil? ? @long=atan2(y,x) : @long; end
      return @longitude if @given == "LLAtude"
      return atan2(y,x) if @given == "Sketchup Point"
      puts "LLAtude.longitude() not available for #{@given}"
      nil
   end
   def height #; @h.nil? ? @h=Sketchup.format_length(p/cos(latitude)-pvcr) : @h; end
      return @height if @given == "LLAtude"
      #return Sketchup.format_length(p/cos(latitude)-pvcr) if @given == "Sketchup Point"
      return (p/cos(latitude)-pvcr).inch if @given == "Sketchup Point"
      puts "LLAtude.height() not available for #{@given}"
      nil
   end
   def altitude; height(); end
   def x #; @x.nil? ? @x=(pvcr+height)*cos(latitude)*cos(longitude) : @x; end
      return @x if @given == "Sketchup Point"
      return (pvcr+@height)*cos(@latitude)*cos(@longitude) if @given == "LLAtude"
      puts "LLAtude.x() not available for #{@given}"
      nil
   end
   def y #; @y.nil? ? @y=(pvcr+height)*cos(latitude)*sin(longitude) : @y; end
      return @y if @given == "Sketchup Point"
      return (pvcr+@height)*cos(@latitude)*sin(@longitude) if @given == "LLAtude"
      puts "LLAtude.y() not available for #{@given}"
      nil
   end
   def z #; @z.nil? ? @z=(pvcr*(1-@@EE)+height)*sin(latitude) : @z; end
      return @z if @given == "Sketchup Point"
      return (pvcr*(1-@@EE)+@height)*sin(@latitude) if @given == "LLAtude"
      puts "LLAtude.z() not available for #{@given}"
      nil
   end
   def location; @loc.nil? ? @loc=Geom::Point3d.new([x,y,z]) : @loc; end
   def position; @pos.nil? ? @pos=location.transform(LLAtude.fromGeo) : @pos; end
   #def elevation
   #   mifFile = File.new("", "r")
   #   midFile = File.new("", "r")
   #   mifFile.close
   #   midFile.close
   #end
   def LLAtude.setModelLocation()
      # latlong.rb coppyright(C) 2006 jim.foltz@gmail.com
      # john@swajime.com added elevation, compressed, & added getOrientation
      si = Sketchup.active_model.shadow_info
      prompts = ["Country:","Location:","Latitude:","Longitude:","Elevation:","North Angle:","Show North Angle?"]
      choices = ["", "", "", "", "", "", "true|false"]
      defaults =[si["Country"],si["City"],si["Latitude"],si["Longitude"],si["Elevation"],si["NorthAngle"],si["DisplayNorth"]]
      ret = UI.inputbox( prompts, defaults, choices, "Custom Location" )
      return unless ret # Method exits here if user hits Cancel button
      #
      # User hits OK, so set values
      si["Country"] = ret[0]; si["City"] = ret[1]
      si["Latitude"] = ret[2]; si["Longitude"] = ret[3]; si["Elevation"] = ret[4]
      si["NorthAngle"] = ret[5]; si["DisplayNorth"] = eval(ret[6])
      @@toGeo = getOrientation!
      @@fromGeo = @@toGeo.inverse
   end
   def LLAtude.getOrientation!()
      si = Sketchup.active_model.shadow_info
#si = Sketchup.active_model.shadow_info
#if si["Elevation"].nil? then si["Elevation"] = 0.feet; end
#if (si["Elevation"].zero?) then v = 1 else v = si["Elevation"]; end
      v=1325.feet
      @@origin = LLAtude.new([si["Latitude"].degrees, si["Longitude"].degrees, v]).location
      @@sl = (LLAtude.new([si["Latitude"].degrees, si["Longitude"].degrees, 0])).location # sealevel
      @@zaxis = Geom::Vector3d.new(@@origin.x-@@sl.x, @@origin.y-@@sl.y, @@origin.z-@@sl.z)
      @@pole = Geom.intersect_line_plane(@@PolarAxis, [@@origin, @@zaxis])
      y_axis = Geom::Vector3d.new(@@pole.x-@@origin.x, @@pole.y-@@origin.y, @@pole.z-@@origin.z)
      northAngle = Geom::Transformation.rotation(@@origin, @@zaxis, si["NorthAngle"].degrees)
      @@yaxis = y_axis.transform!(northAngle)
      @@xaxis = @@yaxis * @@zaxis
      #@@xaxis.length = @@yaxis.length = @@zaxis.length = 1
      Geom::Transformation.new @@xaxis, @@yaxis, @@zaxis, @@origin
      end
   def LLAtude.toGeo; @@toGeo.nil? ? @@toGeo = LLAtude.getOrientation! : @@toGeo; end
   def LLAtude.fromGeo; @@fromGeo.nil? ? @@fromGeo = toGeo.inverse : @@fromGeo; end
   def LLAtude.showAs()
      ret = UI.inputbox(["Show Coordinates As"], [@@showAs], ["d°m's\"|[d,m,s]|d|r"], "")
      return unless ret
      @@showAs = ret[0]
   end
   def LLAtude.resetRange()
      pt0 = LLAtude.new(ORIGIN)
      pta = LLAtude.new([((pt0.latitude.radians*60).floor/60.0).degrees,((pt0.longitude.radians*60).floor/60.0).degrees,0])
      ptb = LLAtude.new([(pta.latitude.radians+1.0/60.0).degrees,(pta.longitude.radians+1.0/60.0).degrees,0])
      @@range = [pta.latitude.radians,ptb.latitude.radians,pta.longitude.radians,ptb.longitude.radians,12]
   end
   def LLAtude.range()
      return @@range unless @@range.nil?
      LLAtude.resetRange()
   end
   def LLAtude.setRange
      ret = UI.inputbox(["Minimum Latitude","Maximum Latitude","Minimum Longitude","Maximum Longitude","Segments"], range(),"Set LLA range")
      return unless ret
      @@range = ret
   end
end # class LLAtude