#!/usr/bin/perl
# Insert CONLL-U annotated text into source TEI files and update teiHeader
# It is assumed that tags in @text_elements are the only ones containing text,
# and that they not contain mixed content (if they do, the markup is discarded)
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

my $anaExt = 'conllu';
my $Saxon = 'java -jar /usr/share/java/saxon.jar';
my $META  = "$Bin/meta.xsl";
my $TRIM  = "$Bin/trim.pl";

binmode STDERR, 'utf8';

$conll_dir = shift;
$in_dir = shift;
$out_dir = shift;

#Top-level element that contains text
$root_element = 'text';

#Elements taken to contain text
#@text_elements = ('head', 'p', 'l', 'quote', 'note', 'trailer');
@text_elements = ('head', 'label', 'p', 'l', 'note', 'trailer');
    
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
    $/ = "# newpar";
    my @conll = ();
    while (<TBL>) {
	chomp; #Newpar is snipped off, a line starts with newpar_id number
	push(@conll, $_) if /\t/; #First one will be empty, so check if \t
    }
    close TBL;
    
    #Read in source TEI
    open IN, '<:utf8', $tei_in or die;
    open OUT, '>:utf8', $tmp_out or die "Cant open tmp output file $tmp_out!\n";
    undef $/;
    $TEI = <IN>;
    $TEI =~ m|(^.+<$root_element ?[^>]*>)(.+)(</$root_element>.+)|s;
    print OUT $1;
    print OUT &merge($2, @conll);
    print OUT $3;
    close IN;
    close OUT;
    #`cp $tmp_out $tei_out`;
    $status = system("$Saxon -xsl:$META $tmp_out | $TRIM > $tei_out");
    die "ERROR: Conversion to TEI for $tmp_out failed!\n"
     	if $status;
}

sub merge {
    my $tei = shift;
    my @conll = @_;
    my $out;
    while ($tei) {
	my $element = &text_element_start($tei);
	#An element that we want to process the content of
	if ($element) {
	    # print STDERR "::: $element\n";
	    my $tagore = '^\s*<' . $element . '?[^>]*>';
	    my $tagcre = "</$element>";
	    my ($tago, $text, $tagc) = $tei =~ m|($tagore)(.+?)($tagcre)|s
		or die "Can't match $element on:\n$tei";
	    $tei =~ s|\Q$tago$text$tagc\E||s or die;
	    $out .= "$tago\n";
	    print STDERR "ERROR: No more CoNLL for XML: $text\n"
		unless @conll;
	    my $conll_ab = shift(@conll);
	    &check_synch($text, $conll_ab);
	    $out .= conll2tei($conll_ab);
	    $out .= "\n$tagc";
	}
	elsif (my ($comment) = $tei =~ m|^(\s*<!--.+?-->)|s) {
	    $out .= $comment;
	    $tei =~ s|\Q$comment\E||;
	}
	elsif (my ($tago) = $tei =~ m|^(\s*<[[:alpha:]][^ />]+ ?[^>]*/?>)|) {
	    $out .= $tago;
	    $tei =~ s|\Q$tago\E||;
	}
	elsif (my ($tagc) = $tei =~ m|^(\s*</[[:alpha:]][^>]+>)|) {
	    $out .= $tagc;
	    $tei =~ s|\Q$tagc\E||;
	}
	elsif ($tei =~ m|^\s+$|) {
	    $out .= $tei;
	    $tei = '';
	}
	else {
	    die "Strange input $tei!"
	}
    }
    return $out
}

sub check_synch {
    my $tei = shift;
    my $conll = shift;
    my ($conll_incipit) = $conll =~ /\n# text =\s+(.+?) *\n/
	or die "WEIRD2: $conll";
    $tei = &xml_decode($tei);
    # print STDERR "PAIR:\n$tei\n$conll_incipit\n\n";
    die "Out of synch:\nCONLL:\t$conll_incipit\nXML:\t$tei\n"
	unless $tei =~ /^\Q$conll_incipit\E/;
}	    

sub text_element_start {
    my $tei = shift;
    my $element;
    foreach my $elem (@text_elements) {
	if ($tei =~ m|^\s*<$elem( [^>]+)?>|) {$element = $elem}
    }
    return $element
}

#Convert one ab into TEI
sub conll2tei {
    my $conll = shift;
    my $tei;
    foreach my $sent (split(/\n\n/, $conll)) {
	next unless $sent =~ /# text = .+\n/;
	$tei .= sent2tei($sent);
    }
    $tei =~ s|\s+$||;
    return $tei
}

#Convert one sentence into TEI
sub sent2tei {
    my $conll = shift;
    my $tei;
    my $tag;
    my $element;
    my $space;
    my @toks = ();
    $tei = "<s>\n";
    foreach my $line (split(/\n/, $conll)) {
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
	if ($xpos =~ /^[A-Z]{2,}/) {
	    $tag = 'pc'
	}
	else {$tag = 'w'}
	my $feats = $ufeats;

	# Switch original and modernised forms
	if (my ($original) = $local =~ /OriginalForm=([^|]+)/) {
	    $local =~ s/OriginalForm=\Q$original\E/ModernForm=$token/;
	    $token = $original;
	}
	

	$space = $local !~ m/SpaceAfter=No/;
	$local =~ s/Spaces?After=[^\|]+//;

	$feats .= "|$local" if $local and $local ne '_';
	$feats .= "|XPOS=$xpos";
	$feats =~ s/_\|//;
	$feats = &xml_encode($feats);

	$token = &xml_encode($token);
	$lemma = &xml_encode($lemma);
	$lemma =~ s/"/&quot;/g; #As it will be an attribute value
	
	$element = "<$tag pos=\"$upos\" msd=\"$feats\" lemma=\"$lemma\">$token</$tag>";
	$element =~ s| lemma=".+?"|| if $tag eq 'pc';
	$element =~ s| | join="right" | unless $space;
	push @toks, $element;
    }
    $tei .= join "\n", @toks;
    $tei .= "\n</s>\n";
    return $tei
}

sub xml_decode {
    my $str = shift;
    $str =~ s|<.+?>||sg;
    $str =~ s|\s+| |g;
    $str =~ s|^ ||;
    $str =~ s| $||;
    $str =~ s|&amp;|&|g;
    $str =~ s|&lt;|<|g;
    $str =~ s|&gt;|>|g;
    return $str
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
