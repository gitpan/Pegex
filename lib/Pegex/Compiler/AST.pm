##
# name:      Pegex::Compiler::AST
# abstract:  Pegex Compiler AST
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::Compiler::Receiver;
use Pegex::Receiver -base;

use Pegex::Grammar::Atoms;

has 'top';
has 'extra_rules' => {};

# Uncomment this to debug. See entire raw AST.
# sub final {
#     my ($self, $match) = @_;
#     XXX $match;
# }
# 
# __END__


sub got_grammar {
    my ($self, $match) = @_;
    my $grammar = {
        '+top' => $self->top,
        %{$self->extra_rules},
    };
    my $rules = $match->[0];
    for (@$rules) {
        $_ = $_->[1];
        my ($key, $value) = %$_;
        $grammar->{$key} = $value;
    }
    return $grammar;
}

sub got_rule_definition {
    my ($self, $match) = @_;
    my $name = $match->[1]{rule_name}{1};
    $self->{top} ||= $name;
    my $value = $match->[3]{rule_group};
    return +{ $name => $value };
}

sub got_bracketed_group {
    my ($self, $match) = @_;
    my $group = $match->[1]{rule_group};
    if (my $mod = $match->[2]{1}) {
        $group->{'+mod'} = $mod;
    }
    return $group;
}

sub got_all_group {
    my ($self, $match) = @_;
    my $list = $self->get_group($match);
    die unless @$list;
    return $list->[0] if @$list == 1;
    return { '.all' => $list };
}

sub got_any_group {
    my ($self, $match) = @_;
    my $list = $self->get_group($match);
    die unless @$list;
    return $list->[0] if @$list == 1;
    return { '.any' => $list };
}

sub get_group {
    my ($self, $group) = @_;
    sub get {
        my $it = shift;
        my $ref = ref($it) or return;
        if ($ref eq 'HASH') {
            return($it->{rule_item} || ());
        }
        elsif ($ref eq 'ARRAY') {
            return map get($_), @$it;
        }
        else {
            die;
        }
    };
    return [ get($group) ];
}

sub got_rule_reference {
    my ($self, $match) = @_;
    my ($assertion, $ref, $quantifier) =
        @{$match}{qw(1 2 3)};
    my $node = +{ '.ref' => $ref };
    if (my $regex = Pegex::Grammar::Atoms->atoms->{$ref}) {
        $self->extra_rules->{$ref} = +{ '.rgx' => $regex };
    }
    if (my $mod = $assertion || $quantifier) {
        $node->{'+mod'} = $mod;
    }
    return $node;
}

sub got_regular_expression {
    my ($self, $match) = @_;
    return +{ '.rgx' => $match->{1} };
}

sub got_error_message {
    my ($self, $match) = @_;
    return +{ '.err' => $match->{1} };
}

1;
