use strict;
use warnings;
package Progress::Sampling::OutputControl::Linear;
use fields qw( interval );

sub new {
    my $class = shift;
    my %param = @_;;
    my $self = fields::new( $class );
    @{ $self }{ qw( interval ) } = @param{ qw( interval ) };
    return $self;
}

sub can_skip {
    my $self  = shift;
    my $count = shift;
    return $count % $self->{interval};
}

1;
