# Directory Listing Display with Automatic Image Preview Generation

**Author**: [Misha v.3](https://www.parser.ru/forum/members/?id=17), February 8, 2008
**Version**: 1.4
**Tags**: Graphics

Sometimes you want to put up files for your friends to download. But if there are images among the published files (say, photos from the last party), it's inconvenient for visitors when there are no previews. Creating them by hand for temporarily-published files tends to be tedious, and besides, a machine can handle that job just fine.

The proposed class outputs a directory's file listing, similar to the Apache [mod_autoindex](http://httpd.apache.org/docs/2.0/mod/mod_autoindex.html) module, but on top of that it can also automatically generate previews for images.

The class uses an object of [one of the classes for working with images](http://www.kulikoff.net/parser3/img/) to do its job. However, this object is only needed if you want automatic preview generation. If you don't need that (for example, you don't want to display previews at all, or you'd rather create them by hand) — you don't need an object of that class.

To use this class, place an `auto.p` file in the directory where you plan to publish subdirectories with files; in its `@main[]` method, create an object of the `AutoIndex` class with the parameters you need and call its `exec` method. Something like this:

```parser3
@main[][sDir;oAutoIndex]
$sDir[/dir/with/files]

$oAutoIndex[^AutoIndex::create[$sDir;

# options for generating previews
	$.bAutoCreatePreviews(true)
	$.oImg[^NConvert::create[
		$.sScriptPath[/../exec]
		$.sScriptName[nconvert.exe]

		$.bRemoveMeta(true)
		$.bKeepRatio(true)
		$.iQuality(75)
		$.iColors(^hParams.iColors.int(64))
	]]
	$.iWidth(120)
	$.iHeight(120)

# operation options
#	$.bRemoveUnusedPreviews(true)

# display options
	$.hOrder[
		$.sField[N]
#		$.sDirection[desc]
	]
	$.tExclude[^table::create{sName^#0Aindex.htm}]
#	$.bIconsAreLinks(false)
#	$.bSuppressSorting(true)
#	$.bSuppressPreview(true)
#	$.bSuppressIcon(true)
#	$.bSuppressLastModified(true)
#	$.bSuppressSize(true)
#	$.bSuppressDescription(true)
]]

^oAutoIndex.exec[]

#end @main[]
```

After that, create the directory, drop your files into it, add a dummy `index.html` (containing, say, just `@dummy[]`), and voilà: on the very first request, previews will be generated for the images and the directory index will be displayed. The class will automatically delete previews that are no longer used (unless you tell it not to) and regenerate them whenever the corresponding images get updated.

Using the settings, you can control the size of the generated previews, as well as which columns are displayed and how they're sorted.

If you're too lazy to copy the dummy `index.html` around, you can always read up on `mod_rewrite` and use it to make your life even easier.

Limitations: if you drop a lot of images into a directory, generating previews for all of them will likely take a while, and the browser may time out waiting for a response. I might fix this at some point so it stops happening, but for now just hit Reload a few times :)

I'm not planning to add functionality for modifying the original files, since the class's purpose is generating an index page with a file listing.

[Original documentation on parser.ru](https://www.parser.ru/en/lib/autoindex/)
