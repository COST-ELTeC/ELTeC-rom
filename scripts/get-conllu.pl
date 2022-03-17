#!/usr/bin/perl
use warnings;
use utf8;
use FindBin qw($Bin);

binmode STDERR, 'utf8';

$inFiles = shift;
$conllDir = shift;

# cf. https://lindat.mff.cuni.cz/services/udpipe/api-reference.php "Converting JSON Result to Plain Text"
$Params  = '-F model=romanian-nonstandard-ud-2.6-200830 -F tokenizer= -F tagger= ';
$Tagger  = 'http://lindat.mff.cuni.cz/services/udpipe/api/process | ';
$Python  = 'PYTHONIOENCODING=utf-8 python -c ';
$Python .= '"import sys,json; sys.stdout.write(json.load(sys.stdin)[\'result\'])"';


foreach my $inFile (glob $inFiles) {
    my ($fName) = $inFile =~ m|([^/]+)\.txt$|
	or die "Bad input $inFile!\n";
    $outFile = "$conllDir/$fName.conllu";
    $Command = "curl -F data=\@$inFile $Params $Tagger $Python";
    print STDERR $Command;
    $status = system("$Command > $outFile");
    die "ERROR: Getting CoNNL-U for $inFile failed!\n"
     	if $status;
}
