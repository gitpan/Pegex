##
# name:      Pegex::Grammar
# abstract:  Pegex Grammar Base Class
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011, 2012

package Pegex::Grammar;
use Pegex::Base;

# Grammar can be in text or tree form. Tree will be compiled from text.
# Grammar can also be stored in a file.
has file => ();
has text => (
    builder => 'make_text',
    lazy => 1,
);
has tree => (
    builder => 'make_tree',
    lazy => 1,
);

sub make_text {
    my ($self) = @_;
    my $filename = $self->file
        or return '';
    open TEXT, $filename
        or die "Can't open '$filename' for input\n:$!";
    return do {local $/; <TEXT>}
}

sub make_tree {
    my ($self) = @_;
    my $text = $self->text
        or die "Can't create a '" . ref($self) .
            "' grammar. No tree or text or file.";
    require Pegex::Compiler;
    return Pegex::Compiler->new->compile($text)->tree;
}

# This import is to support: perl -MPegex::Grammar::Module=compile
sub import {
    my ($package) = @_;
    if (((caller))[1] =~ /^-e?$/ and @_ == 2 and $_[1] eq 'compile') {
        $package->compile_into_module();
        exit;
    }
    if (my $env = $ENV{PERL_PEGEX_AUTO_COMPILE}) {
        my %modules = map {($_, 1)} split ',', $env;
        if ($modules{$package}) {
            if (my $grammar_file = $package->file) {
                if (-f $grammar_file) {
                    my $module = $package;
                    $module =~ s!::!/!g;
                    $module .= '.pm';
                    my $module_file = $INC{$module};
                    if (-M $grammar_file < -M $module_file) {
                        $package->compile_into_module();
                        local $SIG{__WARN__};
                        delete $INC{$module};
                        require $module;
                    }
                }
            }
        }
    }
}

sub compile_into_module {
    my ($package) = @_;
    my $grammar_file = $package->file;
    open GRAMMAR, $grammar_file
        or die "Can't open $grammar_file for input";
    my $grammar_text = do {local $/; <GRAMMAR>};
    close GRAMMAR;
    my $module = $package;
    $module =~ s!::!/!g;
    $module = "$module.pm";
    my $file = $INC{$module} or return;
    require Pegex::Compiler;
    my $perl = Pegex::Compiler->new->compile($grammar_text)->to_perl;
    open IN, $file or die $!;
    my $module_text = do {local $/; <IN>};
    close IN;
    $perl =~ s/^/  /gm;
    $module_text =~ s/^(sub\s+make_tree\s*\{).*?(^\})/$1\n$perl$2/ms;
    open OUT, '>', $file or die $!;
    print OUT $module_text;
    close OUT;
}

1;

=head1 SYNOPSIS

Define a Pegex grammar (for the Foo syntax):

    package Pegex::Foo::Grammar;
    use base 'Pegex::Base';
    extends 'Pegex::Grammar';

    has text => q{
    foo: <bar> <baz>
    ... rest of Foo grammar ...
    };

then use it to parse some Foo:

    use Pegex::Parser;
    my $parse_tree = Pegex::Parser->new(
        grammar => 'Pegex::Foo::Grammar',
        receiver => 'Pegex::Tree',
    )->parse('my/file.foo');

=head1 DESCRIPTION

Pegex::Grammar is a base class for defining your own Pegex grammar classes.
You just need to provide the grammar view the C<text> or the C<file>
attributes.

When L<Pegex::Parser> uses your grammar, it will want it in the tree (compiled)
form, so L<Pegex::Grammar> provides automatic compilation support.

=head1 PROPERTIES AND METHODS

=over

=item tree

This is the data structure containing the compiled grammar for your syntax. It
is usually produced by C<Pegex::Compiler>. You can inline it in the C<tree>
method, or else the C<make_tree> method will be called to produce it.

The C<make_tree> method will call on Pegex::Compiler to compile the C<text>
property by default. You can define your own C<make_tree> method to do
override this behavior.

Often times you will want to generate your own Pegex::Grammar subclasses in an
automated fashion. The Pegex and TestML modules do this to be performant. This
also allows you to keep your grammar text in a separate file, and often in a
separate repository, so it can be shared by multiple programming language's
module implementations.

See L<https://github.com/ingydotnet/pegex-pgx> and
L<https://github.com/ingydotnet/pegex-pm/blob/master/lib/Pegex/Pegex/Grammar.pm>.

=item text

This is simply the text of your grammar, if you define this, you should
(probably) not define the C<tree> property. This grammar text will be
automatically compiled when the C<tree> is required.

=item file

This is the file where your Pegex grammar lives. It is usually used when you
are making a Pegex module. The path is relative to your top level module
directory.

=item make_tree

This method is called when the grammar needs the compiled version.

=over

=back
