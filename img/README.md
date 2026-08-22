# Classes for Working with Images Using the NConvert and ImageMagick Utilities

**Author**: Denis Kulikov, November 18, 2013
**Version**: 1.11
**Tags**: Graphics

This is a copy of the article taken from [the author's site](http://www.kulikoff.net/parser3/img/). The copy may become outdated, so it's recommended to try the original source first.

For all its wonderfulness, Parser has a very limited set of functions for working with images. Nevertheless, when building sites with this language, the need periodically comes up to resize an image, rotate it, or save it in another format.

Well, as usual, if Parser can't do something, you have to call an external script that can do what's needed and make use of its output. And that's where the wonderful `nconvert` utility comes to the rescue (thanks to Eugene Spearance for the tip). The utility can do a whole lot, so for the maniacs out there, the possibilities for working with images are now limited only by their maniacal imagination :). Since I'm not a maniac myself, the class described here implements the main capabilities needed for working with pictures.

A little later, Misha v.3 suggested making the class more universal and combining it with ImageMagick as well. To do this, only the methods defining the class's interface were kept in the original `Img.p`. Everything responsible for calling external scripts, along with some other specific bits, was moved out into the corresponding `NConvert.p` and `ImageMagick.p` classes, which are descendants of the `Img` class.

What's the point of all this? So that it's not agonizingly painful when, moving to a different host, you discover there's no ImageMagick there, or no suitable version of `nconvert` for that OS. In that case, if you're using the described set of classes, all you need to do is hook up `NConvert.p` instead of the `ImageMagick.p` you were using (or vice versa) — and that's it, nothing else in the code needs to change. And don't think you'll never have to move — the moment you think that, you definitely will have to! :)

## So, what can the class do, and how do you work with it

First you need to decide which external program you're going to use.

**Creating the object.** That's where the differences end — from this point on, you can use the methods of the `$oImg` object, which share a common interface regardless of which external program you're using.

Notes:

* In the examples below, `$sFileSrc` and `$sFileDest` are the source and destination files respectively (paths are given relative to the web-space root).
* The `jpeg`, `gif`, `png`, `bmp`, and `tiff` formats are supported for conversion.
* If the source image's format isn't forced explicitly, it's determined from the destination file's extension.
* By default, quality 80% is used when converting to jpg, and 64 colors when converting to gif.
* The default values can be overridden when creating the object, using the `$.iColors`, `$.iQuality`, `$.bKeepRatio`, and `$.bRemoveMeta` parameters.

### Getting information about an image

```parser3
^oImg.info[$sFileSrc]
```

Returns the following hash:

* `$.sFormat` — format
* `$.iWidth` — width (px)
* `$.iHeight` — height (px)
* `$.sCompression` — compression
* `$.iColors` — number of colors
* `$.iXdpi` — horizontal resolution (dpi)
* `$.iYdpi` — vertical resolution (dpi)
* `$.sOrientation`

When using ImageMagick, the following field may also be present:

* `$.sQuality`

### Converting an image to the required format

```parser3
^oImg.convert[$sFileSrc;$sFileDest;$sFormat;$hParams]
```

Here:

* `$sFormat` — output format
* `$hParams` — a hash with the following fields:
  * `$.bRemoveMeta` — flag for removing metadata
  * `$.iQuality` — quality for jpg and png
  * `$.iColors` — number of colors (256, 216, 128, 64, 32, 16, or 8)

### Resizing an image

```parser3
^oImg.resize[$sFileSrc;$sFileDest;$sWidth;$sHeight;$hParams]
```

Here:

* `$sWidth` and `$sHeight` — the width and height of the resulting image, respectively
* `$hParams` — a hash with the following fields:
  * `$.bKeepRatio` — flag for preserving the aspect ratio (0 by default)
  * `$.sResizeType` — resize type:
    * `incr` — only enlarge
    * `decr` — only shrink
  * `$.bRemoveMeta` — flag for removing metadata
  * `$.sFormat` — output format
  * `$.iQuality` — quality for jpg and png
  * `$.iColors` — number of colors (256, 216, 128, 64, 32, 16, or 8)
  * `$.sResampleType` — algorithm used when resizing:
    * `lz`, `lanczos` — Lanczos (default)
    * `g`, `gaussian` — Gaussian
    * `m`, `mitchell` — Mitchell

    NConvert only:
    * `q`, `quick` — Quick resize
    * `l`, `linear` — Bi-linear (linear)
    * `h`, `hermite` — Hermite
    * `b`, `bell` — Bell
    * `bs`, `bspline` — Bspline

### Cropping a rectangular area (crop)

```parser3
^oImg.crop[$sFileSrc;$sFileDest;$iX;$iY;$iCropWidth;$iCropHeight;$hParams]
```

Here:

* `$iX` — x-coordinate of the top-left corner
* `$iY` — y-coordinate of the top-left corner
* `$iCropWidth` — width of the cropped area
* `$iCropHeight` — height of the cropped area
* `$hParams` — a hash with the following fields:
  * `$.sFormat` — output format
  * `$.bRemoveMeta` — flag for removing metadata
  * `$.iQuality` — quality for jpg and png
  * `$.iColors` — number of colors (256, 216, 128, 64, 32, 16, or 8)

### Applying a "watermark"

```parser3
^oImg.watermark[$sFileSrc;$sFileDest;$sWMFile;$hParams]
```

Here:

* `$sWMFile` — the image being overlaid (a semi-transparent png works best)
* `$hParams` — a hash with the following fields:
  * `$.iX` — x-coordinate of the top-left corner of the overlaid image
  * `$.iY` — y-coordinate of the top-left corner of the overlaid image
  * `$.sPosition` — position of the overlaid image:
    * `top-left`, `left-top` → top-left
    * `top-center`, `center-top` → top-center
    * `top-right`, `right-top` → top-right
    * `center-left`, `left-center` → center-left
    * `center` → center
    * `center-right`, `right-center` → center-right
    * `bottom-left`, `left-bottom` → bottom-left
    * `bottom-center`, `center-bottom` → bottom-center
    * `bottom-right`, `right-bottom` → bottom-right
  * `$.sFormat` — output format (except gif)
  * `$.bRemoveMeta` — flag for removing metadata
  * `$.iQuality` — quality for jpg and png

Specify either the position or the coordinates.

Note: when using ImageMagick, don't forget to specify the script name responsible for this transformation when creating the object:

```parser3
^use[ImageMagick.p]
$oImg[^ImageMagick::create[
#	Path to convert from the ImageMagick package
	$.sScriptPath[/../data/bin/ImageMagick]
#	Name of the file itself
	$.sScriptName[convert]
#	Name of the composite file for @watermark[] (if used)
	$.hScriptName[
		$.watermark[composite]
	]
]]
```

### Rotating an image

```parser3
^oImg.rotate[$sFileSrc;$sFileDest;$iAngle;$hParams]
```

Here:

* `$iAngle` — angle in degrees
* `$hParams` — a hash with the following fields:
  * `$.sBGColor` — background color (format "R,G,B")
  * `$.sFormat` — output format
  * `$.bRemoveMeta` — flag for removing metadata
  * `$.iQuality` — quality for jpg and png
  * `$.iColors` — number of colors (256, 216, 128, 64, 32, 16, or 8)

### Rotating a JPEG without quality loss

```parser3
^oImg.rotateJPG[$sFileSrc;$iAngle]
```

Here `$iAngle` is the rotation angle in degrees (+/-90, 180, +/-270). As a result, the original file gets replaced.

This method only works when using NConvert. It's not implemented in the ImageMagick class, since the library of the same name has no equivalent functionality.

Many thanks to Misha v.3 for the criticism and helpful advice.

If anyone uses other utilities for working with images, [feel free to contribute](https://www.parser.ru/forum/users/?uid=595) :)

And that's really it. The archive `Img.zip` contains the `Img`, `ImageMagick`, and `NConvert` classes; a separate archive, `ImageResize.zip`, contains the `ImageResize` class, which simplifies resizing images.

[Original documentation on parser.ru](https://www.parser.ru/en/lib/img/)
