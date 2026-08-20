# Useful User-Defined Operators

**Author**: [Misha v.3](https://www.parser.ru/forum/members/?id=17), May 20, 2011
**Version**: 1.22
**Tags**: E-mail, XML, Files, Numbers

When I first started using Parser 3 instead of Parser 2, I really missed operators such as `^ifdef[]` and similar ones. So I wrote my own user-defined operators and used them in my projects.

Later I decided there was no reason to create so many entities in `MAIN`, so I moved them into separate static classes. At the same time, I removed methods I no longer used. As a result, the four new files are about 10 KB in total, compared with 15 KB for the old single file.

However, if you do not want to write class prefixes such as `^Lib:trim[$sVar]` and prefer the old syntax, `^trim[$sVar]`, the included `LibComp.p` and `LibCompFull.p` files can help. They contain wrapper operators as well as operators that I considered unnecessary and did not include in the updated library.

The new library also includes an improved method for validating e-mail address formats. It does not recognize every address that should be considered valid according to RFC 822, but you can compare the old method, the new method, and an RFC-compliant validator whose regular expression is more than 6 KB long on [this page](https://www.parser.ru/_/check_email.html).

## Lib.p

```parser3
###########################################################################
# cut trailing and leading chars $sChars (whitespaces by default) for $sText
@trim[sText;sChars]


###########################################################################
# print link to $sURI with attributes $uAttr (string or hash) if $sURI specified, otherwise just print $sLabel
@href[sURI;sLabel;uAttr]


###########################################################################
# set location header for redirecting to $sURI and prevent caching
# $.bExternal option makes redirect 
@location[sURI;hParam]


###########################################################################
# check email format
@isEmail[sEmail]


###########################################################################
# print $iNum as a binary string
@dec2bin[iNum;iLength]


###########################################################################
# makes hash of tables from $tData. if $sKeyColumn is not specified 'parent_id' will be used
@createTreeHash[tData;sKeyColumn]


###########################################################################
# print number. options $.iFracLength, $.sThousandDivider and $.sDecimalDivider are available
@numberFormat[dNumber;hParam]


###########################################################################
# looks over hash elements in specified order
@foreach[hHash;sKeyName;sValueName;jCode;sSeparator;sDirection]


###########################################################################
# returns hash with parser version
@getParserVersion[]


###########################################################################
# every odd call returns $sColor1, every even - $sColor2, without parameters - reset sequence
@color[sColor1;sColor2]


###########################################################################
# creates 2-levels hash
@create2LevelHash[uData;sField1;sField2]
```

## FileSystem.p

```parser3
###########################################################################
# return size for specified file or file with specified filename
@getFileSize[uFile]


###########################################################################
# print string with file size. $.hName with bytes/KB/MB texts, $.sDecimalDivider and $.sFormat can be specified
@printFileSize[iSize;hParam]


###########################################################################
# $.bRecursive(true) - copy all subdirs
@copy[sFrom;tTo;hParam]


###########################################################################
# $.bRecursive(true) - copy all subdirs
@dirCopy[sDirFrom;sDirTo;hParam]


###########################################################################
# $.bRecursive(true) - all subdirs will be deleted
@dirDelete[sDir;hParam]
```

## Doc.p

```parser3
###########################################################################
# print $xDoc as string without DOCTYPE and XML declaration
@toString[xDoc]
```

## Node.p

```parser3
############################################################
# print $xNode as string
@toString[xNode;sRootTag]


############################################################
# print $xNode VALUE as string: <aaa><bbb>ccc</bbb></aaa> => "<bbb>ccc</bbb>"
@valueToString[xNode;sRootTag]


############################################################
# go through all nodes in $hNodeList and execute $jCode
@foreach[hNodeList;hNodeName;sNode;sAttr;jCode;sSeparator]


############################################################
# go through all children for $xParent and execute $jCode
@foreachChild[xParent;hNodeName;sNode;sAttr;jCode;sSeparator]


############################################################
# get children of $xParent as hash
@getChildren[xParent;hNodeName]
```

The library contains the static classes `Lib.p`, `FileSystem.p`, `Doc.p`, `Node.p`, `Convert.p`, `ArrayList.p`, and `ArrayListEnumerator.p`, as well as classes providing backward compatibility with the old operators.

[Original documentation on parser.ru](https://www.parser.ru/lib/lib/)
