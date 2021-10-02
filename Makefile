.PHONY: build clean

build:
	@mkdir -p build/Eikana.spoon
	cp init.lua docs/docs.json build/Eikana.spoon
	cd build; zip -r Eikana.spoon.zip Eikana.spoon
	@mkdir -p Spoons
	mv build/Eikana.spoon.zip Spoons/

clean:
	rm -rf build/*
