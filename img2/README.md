# Resizing Images Using External Programs

**Author**: Eugene Spearance, November 11, 2005
**Version**: 1.0.3.4
**Tags**: Graphics

I struggled for a long time, as many probably have, trying to figure out how to make previews (small images) for pictures. After all, that would make it possible to build photo galleries with Parser, place pictures in news items, and so on. I needed a universal tool that wouldn't be picky about file format (jpg, gif, png), that could perform various manipulations on images, and that was capable of producing an adequate, predictable result.

That tool is called ImageMagick, one of the most powerful graphics libraries out there. Combined with Perl, it gives you exactly what you need. Let me pause for a moment on the question of why use Perl at all, since it's come up more than once on the forum: on my hosting, there's no way to use the ready-made programs (convert, composite, etc.) that come with the ImageMagick package — that's the only reason I have to use Perl. If you do have that option available, more power to you.

Not long ago I noticed the `nconvert` utility, which is bundled with [xnview](http://www.xnview.com/), an image viewer. This utility can also perform various file transformations, but it's less demanding to install and configure. You can read about installing and using the utility [here](https://www.parser.ru/forum/?id=43100).

Using the products mentioned above, I wrote a small class for working with images.

## Main methods

`^images:save[image_file;destination_path;image_name;remove_meta;format]`

* `$image_file` — the value received from a form field, with an attribute, or an object of the `file` class.
* `$destination_path` — the path where the image will be saved.
* `$image_name` — the new filename without an extension. If this parameter is omitted, the file will be saved under its current name.
* `$remove_meta` — a 1/0 value. Removes EXIF, IPTC, etc. metadata (removing it causes the file to be recompressed at 80%). This functionality requires nConvert.
* `$format` — the file format to save the image in (`gif|jpg|jpeg|jpe|png`).

Saves the picture to the `$destination_path` directory under the name `$image_name` in `$format` format, checking along the way whether the picture is a valid file. If no path is given, the picture is saved in the root directory (`/`). If no filename or format is specified, the picture is saved with its current values.

`^images:resize[params]`

* `$.source_path` — the path where the large image is located.
* `$.destination_path` — the path where the reduced (preview) image will be saved. If this parameter is omitted, the reduced image overwrites the original.
* `$.image_name` — the name of the source file.
* `$.x_size` — the width to shrink the source image to.
* `$.y_size` — the height to shrink the source image to.
* `$.quality` — the compression quality for jpg and png files, as a percentage from 1 to 100.

Resizes the source image by width and height, and saves it in the current format. If only one linear dimension is specified, the other is scaled proportionally. The result is saved to the `$destination_path` directory under the name `$image_name`. If `$source_path` isn't specified, the picture is taken from the root directory (`/`). If `$destination_path` isn't specified, the picture is saved to `$source_path`. Both shrinking and enlarging the picture are supported.

## Usage example

Task: save a large picture, `12345.gif` (500×500 px), in `jpg` format, with 80% compression quality and the filename `54321.jpg`, into the `/big/` folder, and save a small version (100×120 px) into the `/small/` folder.

```parser3
@USE
images.p

...

$source_path[/big/]
$destination_path[/small/]
$extension[^file:justext[$form:pict.name]]
$image_name[54321.$extension]
$format[jpg]
^if(!^images:save[$form:picture;$source_path;$image_name;0;$format]){
	^if(^extension.lower[] ne ^format.lower[]){
		$image_name[${image_name}.$format]
	}
	$status[^images:resize[
		$.source_path[$source_path]
		$.destination_path[$destination_path]
		$.image_name[$image_name]
		$.x_size(100)
		$.y_size(120)
		$.quality[80]
	]]
	^if(!$status){
		^rem{ *** everything's fine *** }
	}{
		^rem{ *** an error occurred *** }
		$status
	}
}
```

## Frequently encountered errors

* If you want to try the example, check whether Perl is installed on your hosting or local machine, and also make sure the ImageMagick library is present — without it, the example won't work.
* If your Perl is located somewhere other than `#!/usr/bin/perl`, don't forget to fix that path.
* If you did fix it, don't forget to strip Windows-style line endings out of the Perl scripts.
* Make sure you specify the correct paths to the script file — in my case the path looks like `/../cgi-bin`, but yours may be different.
* Don't forget to set execute permissions on the `*.pl` scripts.
* Make sure `enctype="multipart/form-data"` is present — without this attribute you won't be able to pass files through the form, and don't forget to use POST as the data-submission method.
* Specify the `action="path_to_file"` attribute on the `<form>` tag. Omitting it in IIS can cause an error (comment by Misha v.3).

[Original documentation on parser.ru](https://www.parser.ru/en/lib/img2/)
