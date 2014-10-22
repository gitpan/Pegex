package t::TestPegex;
use strict;
use warnings;

use Test::More;

BEGIN {
    eval "require YAML::XS; 1"
        or plan skip_all => 'Requires YAML::XS';
    if ($ENV{PERL_TEST_DIFFERENCES}) {
        require Test::Differences;
        no warnings;
        *is = \&Test::Differences::eq_or_diff;
    }
}

my $p;
sub import {
    strict->import;
    warnings->import;
    $p = caller;
    no strict 'refs';
    *{$p."::is"} = \&is;
    END { run(\&{$p."::run"}) }
}

sub run {
    my $callback = shift;
    no warnings 'once';
    my $data = YAML::XS::Load(do {local $/; <main::DATA>});
    plan tests => $data->{plan};
    my $blocks = $data->{blocks};
    my @only = grep $_->{ONLY}, @$blocks;
    $blocks = \@only if @only;
    for my $block (@$blocks) {
        next if $block->{SKIP};
        $callback->($block);
        last if $block->{LAST};
    }
}

package t::TestPegex::AST;
use Pegex::Mo;
extends 'Pegex::Receiver';

sub got_zero { return 0 };
sub got_empty { return '' };
sub got_undef { return undef }

1;
