#!/usr/bin/perl
# Insert CONLL-U annotated text into source TEI files and update teiHeader
# It is assumed that <p> and <l> are the only elements containing text,
# and that they does not contain mixed content
# Usage:
# conllu2tei.pl <CONLL-U DIR> <SOURCE-TEI DIR> <TARGET-TEI DIR>
#
use warnings;
use utf8;
use Time::Piece;
my $now = localtime;

use FindBin qw($Bin);

use File::Temp qw/ tempfile tempdir /;  #creation of tmp files and directory
`mkdir $Bin/tmp` unless -e "$Bin/tmp";
$tmpDir="$Bin/tmp";
my $tempDir = tempdir(DIR => $tmpDir, CLEANUP => 1);

#$anaExt = 'conllu';
$anaExt = 'conllu.ner';
$Saxon = 'java -jar /usr/share/java/saxon.jar';
$META  = "$Bin/meta.xsl";
$TRIM  = "$Bin/trim.pl";

binmode STDERR, 'utf8';

$conll_dir = shift;
$in_dir = shift;
$out_dir = shift;

#Prefixed to use on values, and the type of the UD linkGrp
#$msd_prefix = 'mte';

if ($conll_dir =~ /\.$anaExt/) {$in_conllu = $conll_dir}
elsif (glob("$conll_dir/*.$anaExt")) {$in_conllu = "$conll_dir/*.$anaExt"}
elsif (glob("$conll_dir/*/*.$anaExt")) {$in_conllu = "$conll_dir/*/*.$anaExt"}
else {die "Cant find CONLL-U files in $conll_dir!\n"}

$in_conllu =~ s|//|/|g;

foreach my $udFile (glob $in_conllu) {
    my ($fname) = $udFile =~ m|([^/]+)\.$anaExt$|
	or die "Bad input $udFile!\n";
    $tei_in = "$in_dir/$fname.xml";
    die "Cant find input TEI file in $tei_in!\n"
	unless -e $tei_in;
    $tei_out = "$out_dir";
    `mkdir $tei_out` unless -e $tei_out;
    $tei_out .= "/$fname-L2.xml";

    $tmp_out = "$tempDir/$fname-ana.tmp";
    
    if (-z $udFile) {
	print STDERR "WARN: empty $udFile, skipping!\n";
	next
    }
    else {print STDERR "INFO: processing $fname\n"}
    
    # Read in CONLL-U
    open TBL, '<:utf8', $udFile or die;
    $/ = "# newpar id = ";
    my @connlu = ();
    while (<TBL>) {
	chomp; #Newpar is snipped off, a line starts with newpar_id number
	push(@connlu, $_) if /\t/; #First one will be empty, so check if \t
    }
    close TBL;
    
    #Read in one line from source TEI
    #Assume each element contains the tags and text in one line!
    $/ = "\n";
    open IN, '<:utf8', $tei_in or die;
    open OUT, '>:utf8', $tmp_out or die "Cant open tmp output file $tmp_out!\n";

    my $prefix = '';
    my $body = '';
    my $skip = 1;
    while (<IN>) {
	if (m|</teiHeader>|) {
	    print OUT;
	    $skip = 0
	}
	elsif ($skip) {print OUT}
	elsif (m|<p ?[^>]*>.+</p>$| or m|<l ?[^>]*>.+</l>$| or m|<note ?[^>]*>.+</note>$|) {
	    ($stag, $text, $etag) = m|(\s*<.+>)(.+)(</.+>)|
		or die "WEIRD1: $_";
	    die "No more CONLLU for XML: $text\n" unless @connlu;
	    $conllu_ab = shift(@connlu);
	    ($conllu_incipit) = $conllu_ab =~ /\n# text = (.+)\n/
		or die "WEIRD2: $conllu_ab";
	    #Skip empty segments
	    $text =~ s/\s+/ /gs; 
	    $text =~ s/^ //;
	    $text =~ s/ $//;
	    unless ($text =~ /\S/ and $conllu_incipit =~ /\S/) {
	    	print STDERR "ERROR: empty segment $_\n";
		next
	    }
	    $conllu_incipit =~ s/\s+/ /gs; 
	    $conllu_incipit =~ s/^ //;
	    $conllu_incipit =~ s/ $//;
	    $conllu_incipit = &xml_encode($conllu_incipit);
	    ## print STDERR "PAIR:\n$text\n$conllu_incipit\n\n";
	    die "Out of synch:\nCONLL:\t$conllu_incipit\nXML:\t$text\n"
		unless $text =~ /^\Q$conllu_incipit\E/;
	    
	    $teiana_ab = conllu2tei($conllu_ab);
	    
	    $body .= "$stag\n$teiana_ab\n$etag";
	}
	else {$body .= $_}
    }
    close IN;

    print OUT $prefix;
    print OUT $body;
    close OUT;
    
    $status = system("$Saxon -xsl:$META $tmp_out | $TRIM > $tei_out");
    die "ERROR: Conversion to TEI for $tmp_out failed!\n"
	if $status;
}

#Convert one ab into TEI
sub conllu2tei {
    my $conllu = shift;
    my $tei;
    foreach my $sent (split(/\n\n/, $conllu)) {
	next unless $sent =~ /# text = .+\n/;
	$tei .= sent2tei($sent);
    }
    $tei =~ s|\s+$||;
    return $tei
}

#Convert one sentence into TEI
sub sent2tei {
    my $conllu = shift;
    my $tei;
    my $tag;
    my $element;
    my $space;
    my @toks = ();
    $tei = "<s>\n";
    foreach my $line (split(/\n/, $conllu)) {
	chomp $line;
	if ($line =~ m|^<name type="(.+?)">|) {
	    push @toks, "<rs type=\"$1\">";
	    next;
	}
	if ($line =~ m|^</name>|) {
	    push @toks, "</rs>";
	    next;
	}
	next unless $line =~ /^\d+\t/;
 	my ($n, $token, $lemma, $upos, $xpos, $ufeats, $link, $role, $extra, $local) 
	    = split /\t/, $line;
	if ($xpos =~ /Z/) {$tag = 'pc'}	
	else {$tag = 'w'}
	my $feats = $ufeats;

	# Switch original and modernised forms
	if (my ($original) = $local =~ /OriginalForm=([^|]+)/) {
	    $local =~ s/OriginalForm=\Q$original\E/ModernForm=$token/;
	    $token = $original;
	}
	
	$feats .= "|$local" if $local and $local ne '_';
	$feats .= "|XPOS=$xpos";
	$feats =~ s/_\|//;
	$feats = &xml_encode($feats);
	
	$space = $local !~ m/SpaceAfter=No/;
	$token = &xml_encode($token);

	#De-accent, like simple modernisation
	#$lemma =~ tr/ÀÁÔàáâèéêìíòóôùúûěſ/AAOaaaeeeiiooouuues/
	#    unless $xpos =~ /[XZ]/;
	
	$lemma = &xml_encode($lemma);
	$lemma =~ s/"/&quot;/g; #As it will be an attribute value
	#$element = "<$tag ana=\"$msd_prefix:$xpos\" msd=\"$feats\" lemma=\"$lemma\">$token</$tag>"
	$element = "<$tag pos=\"$upos\" msd=\"$feats\" lemma=\"$lemma\">$token</$tag>";
	$element =~ s| lemma=".+?"|| if $tag eq 'pc';
	$element =~ s| | join="right" | unless $space;
	push @toks, $element;
    }
    $tei .= join "\n", @toks;
    $tei .= "\n</s>\n";
    return $tei
}

sub xml_encode {
    my $str = shift;
    $str =~ s|&|&amp;|g;
    $str =~ s|<|&lt;|g;
    $str =~ s|>|&gt;|g;
    return $str
}

sub trim {
    my $str = shift;
    $str =~ s|"\n[\t ]+|" |gs;
    $str =~ s|\n[\t ]+<s |<s |gs;
    $str =~ s|\n[\t ]+<name |<name |gs;
    $str =~ s|\n[\t ]+</name|</name|gs;
    $str =~ s|\n[\t ]+<w |<s |gs;
    $str =~ s|\n[\t ]+<pc |<s |gs;
    return $str
}
