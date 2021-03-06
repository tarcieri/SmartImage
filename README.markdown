SmartImage
==========

"It's like a Swiss Army Knife for images, but one of those tiny ones you can 
 keep on your keychain"

SmartImage provides a cross-platform solution for image compositing that works
on both MRI and JRuby. If using RMagick feels like swatting a fly with a 
nuclear missile, and ImageScience just doesn't get you there, SmartImage is 
hopefully at that sweet spot in the middle.

The functionality available in the current version is somewhat limited, but
should be added easily in the future thanks to a focus on modularity and a
clear codebase free of lots of platformisms that normally hinder portability.

The goal of SmartImage is to support the most common image compositing tasks
in a Ruby-like API while not becoming bloated and huge like RMagick, and also
remaining portable across multiple Ruby implementations, including JRuby.

Backends
--------

SmartImage works by implementing a platform-specific SmartImage::Canvas class
that encompasses all of the low level image manipulation primitives.  Two such
canvases are currently available:

* SmartImage::RMagickCanvas: a canvas backend based on the RMagick gem
* SmartImage::JavaCanvas: a canvas backend based on Java AWT/Graphics2D APIs

Can it create thumbnails for my Ruby on Rails-based web application?
--------------------------------------------------------------------

Yes, SmartImage *CAN* create thumbnails for your Ruby on Rails-based web
application!  And it can do it in the most cross-platform manner imaginable!
If you are looking for a thumbnail solution that will allow you to safely 
migrate your web application to JRuby in the future, look no further than 
SmartImage.

To use SmartImage in your Rails application, simply add the following to
config/environment.rb:

    config.gem 'smartimage'

(there is an appropriate place to put this line, BTW.  The exact location
is left as an exercise to the reader)


You can also 

     $ gem install smartimage # now use it like 
     >> require 'rubygems'
     >> require 'smartimage'

That's it!  Now wherever you would like to generate thumbnails, use the
following:

    SmartImage.thumbnail_file(
      "path/to/input.jpg", 
      "path/to/output.jpg", 
      :width  => 69,
      :height => 42
    )

This will generate a thumbnail which is at most 69 pixels wide (but could be
smaller) and at most 42 pixels tall (but again, could be smaller).  It looks
at the file extension to determine the output format.  We specified a .jpg
so it will output a JPEG encoded image.

Why could it be smaller, you ask?  Because SmartImage preserves the aspect
ratio of the original image by default.  SmartImage allows you to set aside
space of a predetermined width/height, but will ensure images are scaled
with their aspect ratio preserved.

Don't like this behavior?  Want to stretch out your thumbnails all weird?
Just turn it off:

    SmartImage.thumbnail_file(
      "path/to/input.jpg", 
      "path/to/output.jpg", 
      :width  => 69,
      :height => 42,
      :preserve_aspect_ratio => false
    )
  
Tada!  Stretched-out images!  Yay!

What if I want to work with raw image data instead of files?
------------------------------------------------------------

SmartImage provides both file-based and data-based methods for every API.  All
the APIs are the same, except file-based APIs have "_file" on the end.

For example, above we used the SmartImage.thumbnail_file API.  However, there's
also a SmartImage.thumbnail API that works on raw image data:

    thumbnail = SmartImage.thumbnail image, :width => 69, 
                                            :height => 42, 
                                            :format => :jpg
                                          
This API produces a thumbnail in-memory from the given input image, also 
in-memory.  We've requested a .jpg thumbnail, with a max width of 69 and
a max height of 42.

If an image format isn't specified, the default is PNG.

Converting image types:
------------------------------

This is similar to the above, but like

    converted_image = SmartImage.thumbnail image, :format => :jpg # default is to convert to png, available "to" types are jpg, png, gif.

What other APIs are available?
------------------------------

SmartImage allows you to successively manipulate an image buffer.  Here's an
example and below is the deconstruction:

    SmartImage.new(69, 42) do |image|
      image.composite_file 'mongoose.jpg', :width => 115,
                                           :height => 95,
                                           :preserve_aspect_ratio => false
 
      image.alpha_mask_file 'mask.png'
      image.composite_file  'overlay.png'
      image.write 'output.png'
    end
  
The first thing to notice is that SmartImage.new takes a width, a height, and
a block.  Creating a new SmartImage makes a new image "canvas" that you can
draw to.  However, all the drawing must take place within the block.  You
can't do things with SmartImages outside the block.  The block yields you
a SmartImage object that you can manipulate willy nilly within the block.
But after the block, it's kaput, sorry.  This is because certain silly C 
extensions lack the ability to garbage collect memory safely and require safe
allocation and deallocation of memory.

The first thing we do is composite an image file onto the buffer.  Just like
the SmartImage.thumbnail_file method we give it an options has with a width,
height, and aspect ratio preservation options.

After that an alpha mask is applied.  SmartImage supports applying alpha masks
in the form of grayscale images where white is opaque and black is transparent.

After that, a glossy overlay is composited over the top of the canvas.

When it's all done, we write to an output file.  We've specified 'output.png'
so it will write a PNG image to the given file.

Doesn't RMagick leak memory?
----------------------------

It does if you use it wrong.  There are experimental attempts to safely garbage
collect RMagick images.  However, your best bet is to work with an API which is
designed so you can't leak memory, which is exactly what SmartImage provides.

SmartImage would be over 9000 times better if it...
---------------------------------------------------

Please fork me!  I'm sure there's a whole world of better backends that 
SmartImage could be using on MRI-like interpreters than RMagick.  Imagine a
lightweight FFI wrapper to libfreeimage or something to that effect.

If there's something SmartImage doesn't do that you'd like it do to, please
send me a pull request.  Just keep in mind that cross-implementation 
consistency is a major focus of SmartImage, so if you implement a new image
backend it should implement all methods of SmartImage::BaseCanvas, and if you
wish to add a new method to either SmartImage or SmartImage::BaseCanvas it 
should work across all implementations.

Mailing List, Author Info
-------------------------

You can subscribe to the SmartImage mailing list by sending email to:

  smartimage@librelist.com
  
SmartImage was created by Tony Arcieri.  You can contact him through
github or follow him on Twitter at @bascule.  He also frequents
IRC on freenode as tarcieri.

Credits
-------

SmartImage assumes your Ruby interpreter supports the absurdly powerful RMagick
library, unless you're running JRuby, in which case it uses the absurdly 
powerful Java Graphics2D library and AWT.

[Mongoose courtesy Wikimedia Commons](http://en.wikipedia.org/wiki/File:Mongoose.jpg)