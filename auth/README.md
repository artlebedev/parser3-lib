# Authentication Class

**Author**: [Misha v.3](https://www.parser.ru/forum/members/?id=17), August 22, 2009
**Version**: 1.84
**Tags**: Authentication

To understand what `$oSql` is, you need to read [the article](https://www.parser.ru/lib/sql/), download one of the SQL classes mentioned in it, and hook it up in `auto.p`.

The class and the scripts for generating the required tables come with fairly detailed comments, from which you can learn quite a lot about how the authentication class works.

All session/user information is stored in the database, and I have no plans to implement storing it in files instead. To create the database tables the authentication class needs, run the corresponding scripts.

After that, use the `_auth_setpwd.html` file to set a password for the `admin` user created by those scripts.

Now everything is ready to use the authentication class — just don't forget to hook it up (the package includes test files with examples of typical operations).

Open `_auth_info.html` in your browser, enter the login `admin` and the password you set via the `_auth_setpwd.html` file, and... log in. Then click the "Change settings" link and change my email address to your own :)

**Attention!**
You'll most likely want to change the login/logout forms' html/xml right away — so don't do that inside `auth.p`. Create a child class, override in it all the methods responsible for the functionality you need, and make your changes in the child class's code instead. That way, when I update the class (adding something useful or fixing bugs), you won't need to redo your changes to it (hunting for the differences along the way) — you'll simply copy it in place of the old one, and that's it.

The authentication class, test files, and scripts for creating the required tables under MySQL, PgSQL, MS SQL, and Oracle. Includes breaking changes compared to the previous version.

[Original documentation on parser.ru](https://www.parser.ru/lib/auth/)
