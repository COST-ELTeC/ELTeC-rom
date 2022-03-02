chars:
	rm -f ../slv-fchars.txt
	nice find ../Anal/ -name 'SLV*.txt' | \
	$P --jobs 24 chars.pl {} >> ../slv-fchars.txt
	chars-summ.pl < ../slv-fchars.txt > ../slv-chars.txt
tei2text:
	./eltec2text.pl ../../level1 ../Anal
val-l2:
	${j2} ../level2/*.xml
val-l1:
	${j1} ../level1-fixed/*.xml


fix-l1:
	nice find ../level1/ -name 'ROM*.xml' | $P --jobs 10 \
	'$s -xsl:fix_level1.xsl {} > level1-fixed/{/}; ${j1} level1-fixed/{/}'

####################3
s = java -jar /usr/share/java/saxon.jar
j = java -jar /usr/share/java/jing.jar
j1 = $j ../../Schemas/eltec-1.rng
j2 = $j ../../Schemas/eltec-2_strict.rng
P = parallel --gnu --halt 2
