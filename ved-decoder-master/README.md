ved-decoder
===========

A decoder for the ved parameter of referrer URIs from google written in python

To find out, what the purpose of this repository is, please read [Google Referrer Query Strings Debunked](http://gqs-decoder.blogspot.com/2013/08/google-referrer-query-strings-debunked-part-1.html).

You can also try out a [web version](//gqs-decoder.appspot.com) of this decoder.

Pull requests welcome!

running
=======

``cat veds.txt|./ved.py``

hacking
=======

install google protobuf compiler:

``apt-get install protobuf-compiler`` or
``brew install protobuf`` or
[install protobuf from source](https://code.google.com/p/protobuf/)

modify ved.proto or ved.py and recompile the .proto-file via
``make all``

notes
=====

a modified copy of python-protobuf 2.5.0 is included in this repository. it is licensed via [New BSD License](http://opensource.org/licenses/BSD-3-Clause). The reason for that is, that in Google App Engine (GAE), you cannot use packages from the google namespace.
