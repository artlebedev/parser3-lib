# Class for Fighting Spam in Forms

**Author**: [Misha v.3](https://www.parser.ru/forum/members/?id=17), September 1, 2006
**Version**: 2.2
**Tags**: Spam

The proposed class uses several mechanisms to protect website forms against spam.

First, checks are done on the referrer both when the form is opened and when data is submitted. As the programmer, you can specify a list of allowed URLs, arriving from which won't cause the class to treat the visitor as a spammer coming from search engine results or simply passing your own URL as the referrer. You can also disallow processing altogether when the referrer value is empty.

Second, before the form is displayed, a unique identifier is generated, saved to a hashfile, and placed into a hidden field. When the data arrives, user-defined processing runs only if the submitted identifier matches the stored one. This guarantees that nobody can post data without first loading the form (and each issued identifier has a limited lifetime, on top of that). This mechanism was applied separately before and is described in detail in the [antiflood](https://www.parser.ru/lib/antiflood/) class example.

Third, the class incorporates a [mechanism](https://www.parser.ru/forum/?id=50523) proposed by forum member [ASharky](https://www.parser.ru/forum/members/?id=397), whereby before the form is displayed it gets modified: redundant fields are added to it that must, under no circumstances, ever be sent back to the server. On the client side we have to hide these fields with CSS (if they're submit|image fields) or clear their values with JavaScript (if they're hidden fields), while robots that open the form from the site, fill it in according to a predefined template, and POST the data will most likely fail to guess which fields need to be cleared for the submission to succeed (that said, if someone really wants to spam you specifically, they'll build a custom algorithm for their spam-bot targeting your form and spam you anyway).

Fourth, the class checks whether someone is trying to stuff the form with a bunch of fields that weren't mentioned in the `<form/>` at the time the form was requested, and if it detects this kind of activity — it rejects the request. There is, however, an option to specify a list of fields that the class should ignore in this regard.

Fifth, you can specify a list of regular expressions with weights, which are used to check all fields after the form is submitted, along with a triggering threshold — if that threshold is exceeded, data processing won't be started.

And finally, the class lets you add Turing tests to the form (an example is included in the archive), meaning that in order for the data to be processed, the visitor has to solve a specific task (perform an arithmetic calculation, recognize a picture, choose the correct answer to a given question, etc).

If spam activity is detected, the class doesn't execute your code but throws an exception, which must be handled.

The class itself rearranges the order of real and fake fields in the html and has a great many settings, letting you configure, among other things, the number of fake fields, the parameters for static and dynamic modification of their attributes, whether to enable an automatic spammer-banning mechanism, and more.

The class works with `<input type="submit|image|button" />` and in principle should work with `<button />`, however harsh reality is such that several `<button/>` elements don't behave correctly in IE (tested with version 6.0).

For example, see how this code behaves in IE versus FF/Opera:

```html
<form method="get">
	<button type="submit" name="action" value="1">1</button>
	<button type="submit" name="action" value="2">2</button>
	<button type="submit" name="action" value="3">3</button>
	<button type="submit" name="action" value="4">4</button>
</form>
```

After clicking any of the buttons, in IE you'll see in the browser's address bar: `?action=1&action=2&action=3&action=4`. So when using `<button />`, there's really only one way out: use JavaScript to remove the redundant buttons, or set their `disabled` attribute. You could of course set that attribute on the fake buttons using the class itself, but robots that download the form, fill it in per a template and post it back aren't so dumb as to send back fields carrying that attribute.

The class is easy to hook up to forms that already exist on a site, since doing so doesn't require calling a bunch of methods in a strictly defined order or modifying the form's html. At the start of the document, create an instance of the class:

```parser3
$oAntiSpam[^AntiSpam::create[hash of parameters]]
$bShowForm(true)
```

and define its behavior with the parameters (for details on the parameters, see the commented examples included in the archive, or the class's own code — and be prepared for the fact that there are a lot of parameters). Then, around the html form you're already outputting:

```html
<form ...>
	...
</form>
```

add:

```parser3
^if($bShowForm){
	^oAntiSpam.print{
		<form ...>
			...
		</form>
	}{
		$exception.handled(true)
		...add here the code to handle the exception thrown while outputting
		the form, which will happen when the spam filter triggers...
	}
}
```

And finally, change your existing POST-handling logic from:

```parser3
^if(def $form:field){
	... your event-handling code ...
}
```

to:

```parser3
^oAntiSpam.exec{
	... your event-handling code ...
	$bShowForm(false)
}{
	$exception.handled(true)
	...add here the code to handle the exception thrown during a POST,
	which will happen if spam activity is detected or
	if the fields turn out not to be filled in...
}
```

Note: you no longer need to manually check whether some field is defined in order to tell whether a POST happened or not — the class handles that itself and only runs the contents of `exec` if a real data POST is taking place and no signs of spam activity were found.

The `print` and `exec` methods can be thought of as analogs of `try`. Their body only runs under "favorable" conditions (for `print`: if no signs of a spammer were found; for `exec`: if a real POST is happening and, again, no signs of spam were found), while the error-handling part is reached if spam activity is detected, or if inside your own handling code you throw an exception yourself (for instance, upon detecting that some fields weren't filled in).

[Original documentation on parser.ru](https://www.parser.ru/lib/antispam/)
