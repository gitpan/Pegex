##
# name:      Pegex::Compiler::Bootstrap
# abstract:  Bootstrapping Compiler for a Pegex Grammar
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011

package Pegex::Compiler::Bootstrap;
use Pegex::Mo;
extends 'Pegex::Compiler';

use Pegex::Grammar::Atoms;

sub parse {
    my $self = shift;
    $self = $self->new unless ref $self;
    my $grammar_text = shift;
    $self->tree({});
    $grammar_text =~ s/^#.*\n+//gm;
    $grammar_text =~ s/^\s*\n//;
    $grammar_text .= "\n" unless $grammar_text =~ /\n\z/;
    $grammar_text =~ s/;/\n/g;
    for my $rule (split /(?=^\w+:\s*)/m, $grammar_text) {
        (my $value = $rule) =~ s/^(\w+):// or die;
        my $key = $1;
        $value =~ s/\s+/ /g;
        $value =~ s/^\s*(.*?)\s*$/$1/;
        $self->tree->{$key} = $value;
        $self->tree->{'+top'} ||= $key;
        $self->tree->{'+top'} = $key if $key eq 'TOP';
    }

    for my $rule (sort keys %{$self->tree}) {
        next if $rule =~ /^\+/;
        my $text = $self->tree->{$rule};
        my @tokens = ($text =~ m{(
            /[^/]*/ |
            \*\* |
            [\!\=\-\+\.]?<\w+>[\?\*\+]? |
            `[^`]*` |
            \| |
            [\!\=?\.]?\[ |
            \][\?\*\+]? |
            \([\!\=?]? |
            \)[\?\*\+]?
        )}gx);
        die "No tokens found for rule <$rule> => '$text'"
            unless @tokens;
        unshift @tokens, '[';
        push @tokens, ']';
        my $tree = $self->make_tree(\@tokens);
        $self->tree->{$rule} = $self->compile_next($tree);  
    }
    return $self;
}

sub make_tree {
    my $self = shift;
    my $tokens = shift;
    my $stack = [];
    my $tree = [];
    push @$stack, $tree;
    for my $token (@$tokens) {
        if ($token =~ /^[\!\=?\.]?[\[]/) {
            push @$stack, [];
        }
        push @{$stack->[-1]}, $token;
        if ($token =~ /^[\]]/) {
            my $branch = pop @$stack;
            push @{$stack->[-1]}, $self->wilt($branch);
        }
    }
    return $tree->[0];
}

sub wilt {
    my $self = shift;
    my $branch = shift;
    return $branch unless ref($branch) eq 'ARRAY';
    my $wilted = [];
    for (my $i = 0; $i < @$branch; $i++) {
        push @$wilted, ($branch->[$i] eq '**')
            ? ['**', pop(@$wilted), $branch->[++$i]]
            : $branch->[$i];
    }
    return $wilted;
}

sub compile_next {
    my $self = shift;
    my $node = shift;
    my $unit = ref($node) ?
        $node->[0] eq '**'
            ? $self->compile_sep($node) :
        $node->[2] eq '|'
            ? $self->compile_group($node, 'any')
            : $self->compile_group($node, 'all')
    :
        $node =~ m!/! ? $self->compile_re($node) :
        $node =~ m!<! ? $self->compile_rule($node) :
        $node =~ m!`! ? $self->compile_error($node) :
            die $node;

    while (defined $unit->{'.all'} and @{$unit->{'.all'}} == 1) {
        $unit = $unit->{'.all'}->[0];
    }
    return $unit;
}

my %prefixes = (
    '!' => ['+asr', -1],
    '=' => ['+asr', 1],
    '.' => '-skip',
    '-' => '-pass',
    '+' => '-wrap',
);

sub compile_sep {
    my $self = shift;
    my $node = shift;
    my $object = $self->compile_next($node->[1]);
    $object->{'.sep'} = $self->compile_next($node->[2]);
    return $object;
}

sub compile_group {
    my $self = shift;
    my $node = shift;
    my $type = shift;
    die unless @$node > 2;
    my $object = {};
    if ($node->[0] =~ /^([\=\!\.\-\+])/) {
        my ($key, $val) = ($prefixes{$1}, 1);
        ($key, $val) = @$key if ref $key;
        $object->{$key} = $val;
    }
    if ($node->[-1] =~ /([\?\*\+])$/ and not $object->{'+qty'}) {
        $object->{'+qty'} = $1;
    }
    shift @$node;
    pop @$node;
    if ($type eq 'any') {
        $object->{'.any'} = [
            map $self->compile_next($_), grep {$_ ne '|'} @$node
        ];
    }
    elsif ($type eq 'all') {
        $object->{'.all'} = [
            map $self->compile_next($_), @$node
        ];
    }
    return $object;
}

sub compile_re {
    my $self = shift;
    my $node = shift;
    my $object = {};
    $node =~ s!^/(.*)/$!$1! or die $node;
    $object->{'.rgx'} = $node;
    return $object;
}

sub compile_rule {
    my $self = shift;
    my $node = shift;
    my $object = {};
    if ($node =~ s/^([\=\!\-\+\.])//) {
        my ($key, $val) = ($prefixes{$1}, 1);
        ($key, $val) = @$key if ref $key;
        $object->{$key} = $val;
    }
    if ($node =~ s/([\?\*\+])$// and not $object->{'+qty'}) {
        $object->{'+qty'} = $1;
    }
    $node =~ s!^<(.*)>$!$1! or die;
    $object->{'.ref'} = $node;
    if (defined(my $re = Pegex::Grammar::Atoms->atoms->{$node})) {
        $self->tree->{$node} ||= {'.rgx' => $re};
    }

    return $object;
}

sub compile_error {
    my $self = shift;
    my $node = shift;
    my $object = {};
    $node =~ s!^`(.*)`$!$1! or die $node;
    $object->{'.err'} = $node;
    return $object;
}

1;
