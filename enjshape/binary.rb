#Shamelessly lifted from a google search for "ruby read binary"
#http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/23048
#credits:
#Michael Neumann <neumann s-direktnet.de>
#merlin.zwo InfoDesign GmbH
#http://www.merlin-zwo.de

#modified by Ian Johnson (enjahova@gmail.com)

class BinaryReader

  DEF = [ 
    [ :short,  2, 's' ],
    [ :ushort, 2, 'S' ],

    [ :int,    4, 'i' ],
    [ :uint,   4, 'I' ],
    [ :nint,   4, 'N' ],  #network integer (big-endian)

    [ :float,  4, 'f' ],
    [ :double, 8, 'd' ]
  ]

  DEF.each do |meth, size, format|
    eval %{
      def read_#{ meth }(n = 1)
        _read(n, #{size}, '#{ format }')
      end
    }
  end

  def initialize( handle )
    @handle = handle
  end
  
  def read(size)
    str = @handle.read(size)
    puts str
    return str
  end

  private

  def _read(n, size, format)
    bytes = n * size

    str = @handle.read(bytes)
    raise "failure during read" if str.nil? or str.size != bytes 

    val = str.unpack(format * n) 

    if n == 1
      val.first
    else
      val
    end
  end

end

#You can use this as follows:
#  file = File.new(...)
#  file.binary       # only neccessary on Windows 
#  reader = BinaryReader.new( file )

#  aFloat = reader.read_float
#  int1, int2 = reader.read_int(2)   # read two integers
  # ... read_double, read_ushort etc..