package Pegex::Receiver;
{
  $Pegex::Receiver::VERSION = '0.23';
}

use Pegex::Base;

has parser => (); # The parser object.

# Flatten a structure of nested arrays into a single array in place.
sub flatten {
    my ($self, $array, $times) = @_;
    $times //= -1;
    while ($times-- and grep {ref($_) eq 'ARRAY'} @$array) {
        @$array = map {
            (ref($_) eq 'ARRAY') ? @$_ : $_
        } @$array;
    }
    return $array;
}

1;
