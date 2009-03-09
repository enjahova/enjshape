
class Shape
  attr_accessor :recnum, :units
  
  def initialize(recnum, units)
    @recnum = recnum
    @units = units
  end
  
  def set_units(units)
    @units = units
    #puts "in Shape.set_units: @units: #{@units} units: #{units}"
  end
end


class Polygon < Shape
  
  #rings is an array of indexes of the starting point of each ring in the points array
  attr_accessor :bbox, :rings, :points
  
  def initialize(recnum, units)
    super(recnum, units)
  end
  
  def set_units(units)
    @units = units
    @points.each { |p| p.set_units(units) }
  end
  
  def parse(reader)
    #bbox = [minx, miny, maxx, maxy]
    @bbox = reader.read_double(4)
    @numparts = reader.read_int()  #rings are also called parts
    @numpoints = reader.read_int() #total number of points
    @rings = reader.read_int(@numparts)
    @points = []
    (0...@numpoints).each { |a| p = Point.new(@recnum, @units); p.parse(reader); @points << p }
    ##puts "#{@recnum} numparts: #{@numparts} points: #{@points.size()}"
  end
  
  def render(entities, flatten, pushpull=["---"])
    #faces = []
    #handle the pushpull
    if pushpull[0] != "---"
      dbf = pushpull[1]
      rec = dbf.record(@recnum) #get corresponding record
      pp = rec.attributes()[pushpull[0]]  #get the value from the column of this record
      if pushpull[2] == "meters"
        pp = pp.m
      else
        pp = pp.feet
      end
    else
      pp = 0
    end
    
    if @numparts == 1
      ##puts "recnum: #{@recnum} single part"
      pts3d = []
      #puts "units: #{@units}"
      @points.each { |p| pts3d << p.point3d(flatten) }#; puts "p: #{p.x} meters: #{p.x.m} feet: #{p.x.feet}" }
      #puts "recnum: #{recnum} pts3d size: #{pts3d.size()}"
      #pts3d.each { |p| puts "p3d #{p}"}
      begin
        p3d = strip_duplicates(pts3d)
        face = entities.add_face p3d
        face.reverse! if face.normal.z < 0
        face.pushpull(pp)
        #return face.entityID
      rescue
        puts "record: #{@recnum} had a problem"
        #pts3d.each { |p| puts "p3d #{p}"}
      #  puts "dupicate points probably: #{@recnum}"
      #  p3d = strip_duplicates(pts3d)
      #  p3d.each { |p| puts "p3d #{p}"}
      #  #puts "*** recnum: #{recnum} p3d size: #{p3d.size()}"
      #  face = entities.add_face p3d
      #  face.reverse! if face.normal.z < 0
      #  face.pushpull(pp)
      #  
      end
      
    else
      (0...@numparts).each do |r|
        puts "recnum: #{@recnum} part: #{r}"
        ##puts "point indices: #{@rings[r]},#{@rings[r+1]}"
        istart = @rings[r]
        iend = @rings[r+1] || @points.size()
        pts = @points[istart...iend]
        #need some data validation
        #figure out if this is an inside ring or not
        #self.inner? pts
        #if its inside, we need erase the face
        #if not we do nothing
        pts3d = []
        pts.each { |p| pts3d << p.point3d(flatten) }
        face = entities.add_face pts3d
        face.reverse! if face.normal.z < 0
        face.pushpull(pp)
       end
    end
    
  end
  
  def inner?(points)
    #need to finish
    size = points.size()
    #shapefiles include the ending point even though it is the same as the first point
    puts "ring first: #{points[0].x},#{points[0].y} ring last: #{points[size-1].x},#{points[size-1].y}"
  end
  
end

class NullShape < Shape
  def initialize(recnum, units)
    super(recnum, units)
  end
end

class Point < Shape
  attr_accessor :x, :y, :z
  
  def initialize(recnum, units)
    super(recnum, units)
  end
  
  def parse(reader)
    x,y = reader.read_double(2)
    @x = x
    @y = y
  end
  
  def point3d(flatten)
    #puts "in point3d || units: #{@units}"
    #puts "in point3d || flatten: #{flatten}"
    if @units == "latlong"
      #puts ll_to_point3d(flatten)
      return ll_to_point3d(flatten)
    else
      if flatten
        @z = 0
      end
      #puts [@x, @y, @z]
      if @units == "meters"
        return [@x.m, @y.m, @z.m]
      elsif @units == "feet"
        #puts "this is what we want: #{@x} #{@x.feet} z: #{@z} #{@z.feet}"
        return [@x.feet, @y.feet, @z.feet]
      end
    end
  end
  
  #we can "flatten" the point, basically ignoring the latlong z value and projecting straight up to the xy plane
  #this is useful for polygons which need to be planar to be created
  def ll_to_point3d(flatten)
    #puts "x: " + @x.to_s
    #puts "y: " + @y.to_s
    #we are assuming points in latlon
    lla = LLAtude.new([@y.degrees, @x.degrees, 0])
    if flatten
      @z = 0
    else
      @z = lla.position.z
    end
    p = [lla.position.x, lla.position.y, @z]
    return p
    #return lla.position
    #return Geom::Point3d.new(@x, @y, z)
  end
  
  def render(entities, flatten)
    entities.add_cpoint(point3d(flatten))
  end
  
end

class MultiPoint < Shape
  attr_accessor :bbox, :points
  
  def initialize(recnum, units)
    super(recnum, units)
  end
  
  def set_units(units)
    @units = units
    @points.each { |p| p.set_units(units) }
  end
  
  def parse(reader)
    @bbox = reader.read_double(4)
    @numpoints = reader.read_int() #total number of points
    @points = []
    (0...@numpoints).each { |a| p = Point.new(@recnum, @units); p.parse(reader); @points << p }
  end
  
  def render(entities, flatten)
    @points.each { |p| p.render(entities, flatten) }
  end
end



class Arc < Shape
  attr_accessor :bbox, :parts, :points
  
  def initialize(recnum, units)
    super(recnum, units)
  end
  
  def set_units(units)
    @units = units
    @points.each { |p| p.set_units(units) }
  end
  
  def parse(reader)
    @bbox = reader.read_double(4)
    @numparts = reader.read_int() 
    @numpoints = reader.read_int() #total number of points
    @rings = reader.read_int(@numparts) #stores the starting index of each part
    @points = []
    (0...@numpoints).each { |a| p = Point.new(@recnum, @units); p.parse(reader); @points << p }
  end
  
  def render(entities, flatten)
    if @numparts > 1
      (0...@numparts).each do |r|
        #puts "recnum: #{@recnum} part: #{r}"
        ##puts "point indices: #{@rings[r]},#{@rings[r+1]}"
        istart = @rings[r]
        iend = @rings[r+1] || @points.size()
        pts = @points[istart...iend]
        pts3d = []
        pts.each { |p| pts3d << p.point3d(flatten) }
        curve = entities.add_curve pts3d
      end
    else
      pts = @points
      pts3d = []
      pts.each { |p| pts3d << p.point3d(flatten) }
      curve = entities.add_curve pts3d
    end
    
    #puts "edges #{edges}"
  end
end


class PointM < Point
  attr_accessor :m
  
  def initialize(recnum, units)
    super(recnum, units)
  end
  
  def parse(reader)
    super(reader)
    #might need to "try" this if M is optional
    @m = reader.read_double()
  end
  
  def render(entities, flatten)
    super(entities, flatten)
  end
end

class MultiPointM < MultiPoint
  attr_accessor :m, :mbound
  
  def initialize(recnum, units)
    super(recnum, units)
  end
  
  def parse(reader)
    super(reader)
    #might need to "try" this if M is optional
    @mbound = reader.read_double(2)
    @m = []
    (0...@numpoints).each { |a| @m << reader.read_double() }
  end
  
  def render(entities, flatten)
    super(entities, flatten)
  end
end

class ArcM < Arc
  attr_accessor :m, :mbound
  
  def initialize(recnum, units)
    super(recnum, units)
  end
  
  def parse(reader)
    super(reader)
    #might need to "try" this if M is optional
    @mbound = reader.read_double(2)
    @m = []
    (0...@numpoints).each { |a| @m << reader.read_double() }
  end
  
  def render(entities, flatten)
    super(entities, flatten)
  end
end

class PolygonM < Polygon
  attr_accessor :m, :mbound
  
  def initialize(recnum, units)
    super(recnum, units)
  end
  
  def parse(reader)
    super(reader)
    #might need to "try" this if M is optional
    @mbound = reader.read_double(2)
    @m = []
    (0...@numpoints).each { |a| @m << reader.read_double() }
  end
  
  def render(entities, flatten)
    super(entities, flatten)
  end
end

class PointZ < Point
  attr_accessor :z, :m
  
  def initialize(recnum, units)
    super(recnum, units)
  end
  
  def parse(reader)
    #super(reader)
    #might need to "try" this if M is optional
    x,y = reader.read_double(2)
    @x = x
    @y = y
    @z = reader.read_double()
    @m = reader.read_double()
  end
  
  def render(entities, flatten)
    super(entities, flatten)
  end
end

class MultiPointZ < MultiPoint
  attr_accessor :z, :zbound, :m, :mbound
  
  def initialize(recnum, units)
    super(recnum, units)
  end
  
  def parse(reader)
    super(reader)
    @zbound = reader.read_double(2)
    @z = []
    (0...@numpoints).each { |a| @z << reader.read_double() }
    #might need to "try" this if M is optional
    @mbound = reader.read_double(2)
    @m = []
    (0...@numpoints).each { |a| @m << reader.read_double() }
  end
  
  def render(entities, flatten)
    super(entities, flatten)
  end
end

class ArcZ < Arc
  attr_accessor :z, :zbound, :m, :mbound
  
  def initialize(recnum, units)
    super(recnum, units)
  end
  
  def parse(reader)
    super(reader)
    @zbound = reader.read_double(2)
    @z = []
    (0...@numpoints).each { |a| @z << reader.read_double() }
    #might need to "try" this if M is optional
    @mbound = reader.read_double(2)
    @m = []
    (0...@numpoints).each { |a| @m << reader.read_double() }
  end
  
  def render(entities, flatten)
    super(entities, flatten)
  end
end

class PolygonZ < Polygon
  attr_accessor :z, :zbound, :m, :mbound
  
  def initialize(recnum, units)
    super(recnum, units)
  end
  
  def parse(reader)
    super(reader)
    @zbound = reader.read_double(2)
    @z = []
    (0...@numpoints).each { |a| @z << reader.read_double() }
    #might need to "try" this if M is optional
    @mbound = reader.read_double(2)
    @m = []
    (0...@numpoints).each { |a| @m << reader.read_double() }
  end
  
  def render(entities, flatten)
    super(entities, flatten)
  end
end