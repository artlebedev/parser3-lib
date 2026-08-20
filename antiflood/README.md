# Protection Against Duplicate Messages Using hashfile

**Author**: [Misha v.3](https://www.parser.ru/forum/members/?id=17), March 10, 2005
**Version**: 1.13
**Tags**: Spam

The basic idea behind this method of protecting against duplicate posts is as follows: when displaying the form for adding a message, we generate a unique UID and place it both in a hidden field and in a hashfile for a couple of hours (it seems to me that a couple of hours is enough time to formulate your thought and send it to the server).

Once the POST data arrives, we check whether the hashfile contains a record with the submitted UID. If it does, we add the message and remove the record from the hashfile; otherwise, we assume the message was already added earlier (a double click on submit, a page reload) or that it's being added by hand without going through our form (which we don't particularly want).

Now, here's the code itself:

```parser3
# path where the hashfile and lock-file will live
$data_dir[/../data]

# open the hashfile
$hashfile[^hashfile::open[$data_dir/_double]]

^if(def $form:uid){
	$uid[$form:uid]
}{
	^rem{ *** generate a uid and add it to the hashfile for 2 hours *** }
	$uid[^math:uuid[]]
	$hashfile.[$uid][
		$.value[1]
		$.expires(2/24)
	]
}

$is_show_form(1)

^if(def $form:uid){
	^rem{ *** $form:uid arrived - data is being posted *** }
	^file:lock[$data_dir/_lock]{
		^if(^hashfile.[$uid].int(0) == 1){
			^rem{ *** the matching uid is in the hashfile - all good,
add the message *** }
			...

			^rem{ *** remove the processed key from the hashfile *** }
			^hashfile.delete[$uid]

			^rem{ *** walk through all records so the expired ones
get cleaned up *** }
			^hashfile.foreach[k;]{}

			<p>Your message has been added successfully.</p>
		}{
			^rem{ *** nope, that's not right: we don't know anything
about this uid, goodbye *** }
			<p>Your message has already been added previously.</p>
		}
		$is_show_form(0)
	}
}


^if($is_show_form){
	<form method="post" action="./">
		<input type="hidden" name="uid" value="$uid" />
		<i>Name:</i><br />
		<input type="text" name="name" value="$form:name" /><br />
		<i>E-mail:</i><br />
		<input type="text" name="email" value="$form:email" /><br />
		<i>Message:</i><br />
		<textarea name="text">$form:text</textarea>
		<br />
		<input type="submit" name="action" value="Submit" />
	</form>
}
```

Using a hashfile is by no means mandatory. As temporary storage you could just as well use a separate database table (a heap table, for instance), but with Parser I think using a hashfile for this purpose is quite justified.

I used to protect against duplicates with a hashfile too, but I stored the UIDs of records I had already added to the database there for several hours. With that approach, more records were stored in the hashfile at any given time, and on top of that there was no protection against some primitive spammers who post to forums without ever opening the form (a different class provides more reliable spam protection by using the mechanism described here as one of its building blocks, so I recommend using it either way).

Another possible approach to duplicate protection is storing UIDs in extra columns of the guestbook/forum tables etc., with a unique index, but I don't like that approach, since it means storing a fairly large amount of information that ends up being completely useless afterward.

Honestly, you didn't even have to read everything written above — you could just download the class, which comes with a working example, and copy the pattern :)

[Original documentation on parser.ru](https://www.parser.ru/lib/antiflood/)
