#!/usr/bin/env perl
use strict; use warnings; use utf8; use open qw(:std :encoding(UTF-8));
my ($tf, $ef) = @ARGV; local $/;
open my $t, "<", $tf or die; my $s = <$t>; close $t;
open my $e, "<", $ef or die; my $x = <$e>; close $e; my $n = 0;
while ($x =~ /^<<<<\n(.*?)\n====\n(.*?)\n>>>>$/msg) { my ($o, $w) = ($1, $2); $n++; my $c = () = $s =~ /\Q$o\E/g; die "edit $n: $c 回: " . substr($o,0,30) . "\n" if $c != 1; $s =~ s/\Q$o\E/$w/; }
open my $out, ">", $tf or die; print $out $s; close $out; print "$tf: $n edits\n";
