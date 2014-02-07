package Pegex::Tree;
{
  $Pegex::Tree::VERSION = '0.23';
}

use Pegex::Base;
extends 'Pegex::Receiver';

sub gotrule {
    my $self = shift;
    @_ || return ();
    return {$self->{parser}{rule} => $_[0]}
        if $self->{parser}{parent}{-wrap};
    return $_[0];
}

sub final {
    my $self = shift;
    return(shift) if @_;
    return [];
}

1;
