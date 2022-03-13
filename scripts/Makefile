chars:
	rm -f stats/chars-files.txt
	ls text/ROM*.txt | $P --jobs 24 \
	'chars.pl {} >> stats/chars-files.txt'
	chars-summ.pl < stats/chars-files.txt > stats/chars.txt
tei2text:
	find ../level1 -name 'ROM*.xml' | $P --jobs 10 \
	'$s -xsl:eltec2text.xsl {} > text/{/.}.txt'
tags:
	rm -f stats/tags.*
	find ../level1 -name 'ROM*.xml' | $P --jobs 10 \
	'$s -xsl:tagcount2.xsl {} >> stats/tags.tmp'
	cut -f1 stats/tags.tmp | sort | uniq > stats/tags.lst
	rm -f stats/tags.tmp

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
