package Pegex::Module;
$Pegex::Module::VERSION = '0.24';
use Pegex::Base;

has parser_class => 'Pegex::Parser';
has grammar_class => (
    default => sub {
        my $class = ref($_[0]);
        die "$class needs a 'grammar_class' property";
    },
);
has receiver_class => 'Pegex::Tree';

sub parse {
    my ($self, $input) = @_;
    $self = $self->new unless ref $self;
    my $parser = $self->parser_class->new(
        grammar => $self->grammar_class->new,
        receiver => $self->receiver_class->new,
    );
    $parser->parse($input);
}

1;
