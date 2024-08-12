# -*- encoding: utf-8 -*-

SHELL = /bin/sh

MD2HTML = /home/jf/.local/bin/grip
MD2HTMLOPT = --export --no-inline

.SUFFIXES:
.SUFFIXES: .md .html

.md.html:
	$(MD2HTML) $< $(MD2HTMLOPT)
	perl -i -p -e 's/\<table\>/<table border="1">/; s/\xc2\xa0/\&nbsp;/g' $@

target: Documentation.fr.html Documentation.en.html
