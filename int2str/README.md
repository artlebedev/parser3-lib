# Writing a Number in Words

**Author**: Viktor Smirnov, May 29, 2008
**Tags**: Numbers

## int2str.p

```parser3
@CLASS
int2str

# The class's methods can be used statically.
#
# @int2str[i;gender;upper]
#				Writes a number in words.
#				i - the number (int)
#				gender - grammatical gender (masculine - m and feminine - f)
#				upper - if defined, capitalizes the first letter
# @money2str[amount]
#				Writes a double as: the amount of rubles in words and the kopecks as digits
#				amount - the amount of money.
#				The integer part is rubles, the first two digits of the fractional part are kopecks.
#
# Usage example:
#
# $to_pay(123456.78) $to_pay_nds($to_pay/6)
#
# <h2>Prepayment amount for services: ^number_format[^to_pay.format[%.2f];,;.](2) rub.</h2>
# <p><i>Amount in words: ^int2str:money2str($to_pay)</i></p>
# <p><i>Including tax: ^number_format[^to_pay_nds.format[%.2f];,;.](2) rub.</i></p>
#
# (c) Viktor Smirnov 2003
# bugfix in method @money2str[]: PAF
# little optimization: Misha v.3
```

Based on [feedback from forum visitors](https://www.parser.ru/forum/?id=47736), changes were made to the class to prevent rounding errors from occurring, and a small optimization was made along the way.

The author was informed about the modifications, and with his permission, the modified class was published alongside the original.

The `int2str.zip` archive contains the number-to-words class with modifications by PAF and Misha v.3; `int2str.origin.zip` contains the original, unmodified class.

[Original documentation on parser.ru](https://www.parser.ru/lib/int2str/)
