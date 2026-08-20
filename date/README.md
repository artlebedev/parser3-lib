# Class for Working with Dates

**Author**: [Misha v.3](https://www.parser.ru/forum/members/?id=17), February 27, 2014
**Version**: 1.38
**Tags**: Morphology

A class that provides some additional capabilities for working with objects of the "date" type.

After p3 came out, I really missed date formatting (POSIX-style), so I wrote this class, which does that kind of conversion, among other things.

Example calls (the class's methods are called statically):

Print `now` in a human-readable format, in Russian:
`^dtf:format[%T %d %h %Y]`

Print `now` in a human-readable format, in English:
`^dtf:format[%T %d %h %Y;;$dtf:ei-locale]`

Print a birthday from the `$bithday` variable in `%d/%m/%Y` format:
`^dtf:format[%d/%m/%Y;$bithday]`

## dtf.p

```parser3
###################################
# Methods described:
# @create[date]                         constructs a date-type object from a string/date
# @format[fmt;date;locale]              outputs the given date, using a format string
# @last-day[date]                       returns the date of the last day of the given [current] month
# @from822[string]                      creates a date from the given date-string in RFC822 format
# @to822[date;timezone]                 shifts the date from the current TZ to the specified TZ and outputs it as a string in RFC822 format
# @setLocale[locale]                    sets a new locale value, returning the old one
# @resetLocale[]                        resets the locale to the default
#
###################################
```

[Original documentation on parser.ru](https://www.parser.ru/lib/date/)
