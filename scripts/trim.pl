#!/usr/bin/perl
use warnings;
use utf8;
binmode STDIN, 'utf8';
binmode STDOUT, 'utf8';
binmode STDERR, 'utf8';
undef $/;
my $str = <>;
my ($teiHeader, $teiText) = $str =~ m|(.+</teiHeader>)(.+)|s;
$teiText =~ s|"\n[\t ]+|" |gs;
$teiText =~ s|\n[\t ]+<s |\n<s |gs;
$teiText =~ s|\n[\t ]+<rs |\n<rs |gs;
$teiText =~ s|\n[\t ]+</rs>|\n</rs>|gs;
$teiText =~ s|\n[\t ]+<w |\n<w |gs;
$teiText =~ s|\n[\t ]+<pc |\n<pc |gs;
print $teiHeader;
print $teiText;
