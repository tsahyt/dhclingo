THEME=beige

setup:
	wget https://github.com/hakimel/reveal.js/archive/master.tar.gz
	tar -xzvf master.tar.gz
	mv reveal.js-master reveal.js	

standalone: slides.md
	pandoc -t revealjs --slide-level 2 --filter pandoc-citeproc -s -i -o slides.html slides.md -V theme=$(THEME)

simple: slides.md
	pandoc -t revealjs --filter pandoc-citeproc -s -i -o slides.html slides.md -V revealjs-url=http://lab.hakim.se/reveal-js -V theme=$(THEME)

beamer: slides.md
	pandoc --pdf-engine=xelatex -t beamer --filter pandoc-citeproc -s -o slides.pdf slides.md
