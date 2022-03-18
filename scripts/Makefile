R = ROM095
test-fixquote:
	$s -xsl:fix_quote.xsl level1-fixed/$R.xml > tmp/$R.xml
	-diff -w level1-fixed/$R.xml test/$R.xml
	${j1} test/$R.xml
one:
	$s -xsl:eltec2text.xsl level1-fixed/$R.xml > text/$R.txt
	get-conllu.pl text/$R.txt conll
	eltec-conllu2tei.pl conll/$R.conllu level1-fixed test
	${j2} test/$R-L2.xml

test-conllu2tei:
	eltec-conllu2tei.pl conll/ROM005.conllu level1-fixed test
	${j2} test/ROM005-L2.xml
test-conllu:
	get-conllu.pl 'text/ROM005.txt' conll
test-tei2text:
	$s -xsl:eltec2text.xsl level1-fixed/ROM005.xml > text/ROM005.txt

nohup:
	nohup time make all > nohup.all &
all:	tei2text text2conllu conllu2tei
conllu2tei-single:
	eltec-conllu2tei.pl 'conll/ROM*.conllu' level1-fixed ../level2
	${j2} ../level2/ROM*.xml
conllu2tei:
	ls -d conll/ROM*.conllu | $P --jobs 10 \
	eltec-conllu2tei.pl {} level1-fixed ../level2
	${j2} ../level2/ROM*.xml
text2conllu:
	rm -f conll/*
	get-conllu.pl 'text/ROM*.txt' conll
chars:
	rm -f stats/chars-files.txt
	ls text/ROM*.txt | $P --jobs 24 \
	'chars.pl {} >> stats/chars-files.txt'
	chars-summ.pl < stats/chars-files.txt > stats/chars.txt
tei2text:
	find level1-fixed -name 'ROM*.xml' | $P --jobs 10 \
	'$s -xsl:eltec2text.xsl {} > text/{/.}.txt'
tags:
	rm -f stats/tags.*
	find ../level1 -name 'ROM*.xml' | $P --jobs 10 \
	'$s -xsl:tagcount2.xsl {} >> stats/tags.tmp'
	cut -f1 stats/tags.tmp | sort | uniq > stats/tags.lst
	rm -f stats/tags.tmp

#Fix quotes with plain text but on paragraph-level, so that they contain a <p>
fixquote:
	ls -d level1-fixed/ROM*.xml | $P --jobs 5 \
	'$s -xsl:fix_quote.xsl {} > tmp/{/}'
	${j1} tmp/*.xml

# level1-fixed/* have been hand-edited, so we can't automatically make them anymore
xxx-fix-l1:
	find ../level1/ -name 'ROM*.xml' | $P --jobs 10 \
	'$s -xsl:fix_level1.xsl {} > level1-fixed/{/}; ${j1} level1-fixed/{/}'
val-l2:
	${j2} ../level2/*.xml
val-l1:
	${j1} level1-fixed/*.xml


####################3
s = java -jar /usr/share/java/saxon.jar
j = java -jar /usr/share/java/jing.jar
j1 = $j ../../Schemas/eltec-1.rng
j2 = $j ../../Schemas/eltec-2_strict.rng
P = parallel --gnu --halt 2
