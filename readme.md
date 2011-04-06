Source for https://eval.to/.  Currently the code is rather messy, as I
was trying out a bunch of different ideas and haven't cleaned up yet.


Development
===========

To run locally for development, you'll need to first install Racket
and the hackinator.  For installation instructions, see the
[hackinator readme](https://github.com/awwx/hack#readme).

Change `source*` in the second "else" part of the if in config.arc to
the location where you have the eval.to source checked out.  Change
`datadir*` in the 5th line of `data.arc` to a convenient location to
store the data directory.

You can start the server on port 8080 with:

    hack evalto.recipe

You should now be able to go to
[http://localhost:8080](http://localhost:8080/) (note http, not https)
and see the home page.

For the rest of the site to work, you'll need to run the server behind
nginx.  If you don't already have nginx installed, on Ubuntu you can
install it with:

    sudo apt-get install -y nginx

then change /etc/nginx/nginx.conf to be a symbolic link to
evalto/nginx/nginx.conf.

Now when you start nginx you should be able to go to
[https://localhost/](https://localhost/) (note this time it's https,
not http) and see the home page again.  The rest of the site should
now work.


Contributors
============

[Kirubakaran](https://github.com/kirubakaran) fixed the endlessly
spinning browser page loading indicator.
