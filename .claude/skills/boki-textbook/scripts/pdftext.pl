#!/usr/bin/env perl
# 最小限のPDFテキスト抽出（FlateDecode・オブジェクトストリーム・ToUnicode CMap 対応）
# 出力: page<TAB>x<TAB>y<TAB>text（y の大きい順＝上から、x の小さい順）
use strict;
use warnings;
use Compress::Zlib;

my $file = shift or die "usage: pdftext.pl file.pdf\n";
open my $fh, '<:raw', $file or die $!;
my $pdf = do { local $/; <$fh> };
close $fh;

my (%obj, %stream);

sub inflate_data {
    my $d = shift;
    my ($i) = inflateInit();
    return '' unless $i;
    my ($out) = $i->inflate($d);
    return $out // '';
}

while ($pdf =~ /(\d+)\s+(\d+)\s+obj\b(.*?)\bendobj/gs) {
    my ($n, $body) = ($1, $3);
    if ($body =~ /^(.*?)stream\r?\n(.*)\r?\nendstream/s) {
        my ($dict, $data) = ($1, $2);
        $obj{$n}    = $dict;
        $stream{$n} = ($dict =~ m{/FlateDecode}) ? inflate_data($data) : $data;
    }
    else {
        $obj{$n} = $body;
    }
}

for my $n (keys %stream) {
    next unless $obj{$n} =~ m{/Type\s*/ObjStm};
    my ($first) = $obj{$n} =~ m{/First\s+(\d+)};
    my $s   = $stream{$n};
    my @hdr = grep { length } split /\s+/, substr($s, 0, $first);
    for (my $k = 0; $k < @hdr; $k += 2) {
        my ($on, $off) = @hdr[$k, $k + 1];
        my $end = ($k + 3 < @hdr) ? $hdr[$k + 3] : length($s) - $first;
        $obj{$on} //= substr($s, $first + $off, $end - $off);
    }
}

sub deref {
    my $v = shift;
    return $obj{$1} if defined $v && $v =~ /^\s*(\d+)\s+\d+\s+R\s*$/;
    return $v;
}

my %cmap_cache;
sub parse_cmap {
    my $n = shift;
    return $cmap_cache{$n} if $cmap_cache{$n};
    my %m;
    my $s = $stream{$n} // '';
    while ($s =~ /beginbfchar(.*?)endbfchar/gs) {
        my $blk = $1;
        while ($blk =~ /<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>/g) { $m{ hex $1 } = $2; }
    }
    while ($s =~ /beginbfrange(.*?)endbfrange/gs) {
        my $blk = $1;
        while ($blk =~ /<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*(<[0-9A-Fa-f]+>|\[[^\]]*\])/g) {
            my ($lo, $hi, $dst) = (hex $1, hex $2, $3);
            if ($dst =~ /^<([0-9A-Fa-f]+)>$/) {
                my $base = hex $1;
                $m{$_} = sprintf('%04X', $base + $_ - $lo) for $lo .. $hi;
            }
            else {
                my @d = $dst =~ /<([0-9A-Fa-f]+)>/g;
                $m{ $lo + $_ } = $d[$_] for 0 .. $#d;
            }
        }
    }
    return $cmap_cache{$n} = \%m;
}

sub hex_to_text {
    my $h = shift;
    my $out = '';
    for (my $i = 0; $i + 4 <= length $h; $i += 4) {
        my $u = hex substr($h, $i, 4);
        $out .= chr($u) if $u >= 0x20;
    }
    return $out;
}

binmode STDOUT, ':encoding(UTF-8)';
my @pages = sort { $a <=> $b } grep { $obj{$_} =~ m{/Type\s*/Page\b} && $obj{$_} !~ m{/Type\s*/Pages} } keys %obj;
my $pno = 0;
for my $p (@pages) {
    $pno++;
    my $pd  = $obj{$p};
    my $res = $pd =~ m{/Resources\s*(\d+\s+\d+\s+R)} ? deref($1) : $pd;
    my $fontdict = '';
    if    ($res =~ m{/Font\s*(\d+\s+\d+\s+R)}) { $fontdict = deref($1); }
    elsif ($res =~ m{/Font\s*<<(.*?)>>}s)       { $fontdict = $1; }
    my %fmap;
    while ($fontdict =~ m{/(\w+)\s+(\d+)\s+\d+\s+R}g) {
        my ($fname, $fo) = ($1, $2);
        my $fd = $obj{$fo} // '';
        $fmap{$fname} = parse_cmap($1) if $fd =~ m{/ToUnicode\s+(\d+)\s+\d+\s+R};
    }
    my @cs;
    if    ($pd =~ m{/Contents\s*\[([^\]]*)\]})        { @cs = $1 =~ /(\d+)\s+\d+\s+R/g; }
    elsif ($pd =~ m{/Contents\s+(\d+)\s+\d+\s+R})     { @cs = ($1); }
    my $content = join "\n", map { $stream{$_} // '' } @cs;

    my ($cur, $x, $y) = (undef, 0, 0);
    my @runs;
    my $emit = sub {
        my ($t, $lit) = @_;
        my $o = '';
        if ($lit) { $o = $t; }
        else {
            my $m = $cur ? $fmap{$cur} : undef;
            for (my $i = 0; $i + 4 <= length $t; $i += 4) {
                my $g = hex substr($t, $i, 4);
                if ($m) { my $u = $m->{$g}; $o .= hex_to_text($u) if defined $u; }
            }
        }
        push @runs, [$x, $y, $o] if $o =~ /\S/;
    };
    my $num = qr/-?[\d.]+/;
    while ($content =~ m{/(\w+)\s+$num\s+Tf|($num)\s+($num)\s+($num)\s+($num)\s+($num)\s+($num)\s+Tm|($num)\s+($num)\s+T[dD]\b|<([0-9A-Fa-f]*)>\s*Tj|\[((?:[^\]\\]|\\.)*)\]\s*TJ}g) {
        if    (defined $1)  { $cur = $1; }
        elsif (defined $2)  { ($x, $y) = ($6, $7); }
        elsif (defined $8)  { $x += $8; $y += $9; }
        elsif (defined $10) { $emit->($10, 0); }
        elsif (defined $11) {
            my $arr = $11;
            while ($arr =~ /<([0-9A-Fa-f]*)>|\(((?:[^)\\]|\\.)*)\)/g) {
                if (defined $1) { $emit->($1, 0) } else { $emit->($2, 1) }
            }
        }
    }
    for my $r (sort { $b->[1] <=> $a->[1] || $a->[0] <=> $b->[0] } @runs) {
        printf "%d\t%.0f\t%.0f\t%s\n", $pno, $r->[0], $r->[1], $r->[2];
    }
}
