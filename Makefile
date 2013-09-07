GHCFLAGS=-Wall -XNoCPP -fno-warn-name-shadowing -XHaskell98
HLINTFLAGS=-XHaskell98 -XNoCPP -i 'Use camelCase' -i 'Use String' -i 'Use string literal' -i 'Use list comprehension' --utf8 -XMultiParamTypeClasses
VERSION=0.1.0.0

.PHONY: all clean doc install

all: report.html doc dist/build/libHSopenexchangerates-$(VERSION).a dist/openexchangerates-$(VERSION).tar.gz

install: dist/build/libHSopenexchangerates-$(VERSION).a
	cabal install

report.html: Currency/OpenExchangeRates.hs
	-hlint $(HLINTFLAGS) --report Currency.hs Currency

doc: dist/doc/html/openexchangerates/index.html README

README: openexchangerates.cabal
	tail -n+$$(( `grep -n ^description: $^ | head -n1 | cut -d: -f1` + 1 )) $^ > .$@
	head -n+$$(( `grep -n ^$$ .$@ | head -n1 | cut -d: -f1` - 1 )) .$@ > $@
	-printf ',s/        //g\n,s/^.$$//g\nw\nq\n' | ed $@
	$(RM) .$@

dist/doc/html/openexchangerates/index.html: dist/setup-config Currency/OpenExchangeRates.hs
	cabal haddock --hyperlink-source

dist/setup-config: openexchangerates.cabal
	cabal configure

clean:
	find -name '*.o' -o -name '*.hi' | xargs $(RM)
	$(RM) report.html
	$(RM) -r dist dist-ghc

dist/build/libHSopenexchangerates-$(VERSION).a: openexchangerates.cabal dist/setup-config Currency/OpenExchangeRates.hs
	cabal build --ghc-options="$(GHCFLAGS)"

dist/openexchangerates-$(VERSION).tar.gz: openexchangerates.cabal dist/setup-config Currency/OpenExchangeRates.hs README
	cabal check
	cabal sdist
