use strict;
use warnings;
package Progress::Sampling::OutputControl::Fibonacci;
use fields qw( max _current _did_exceed );
use Readonly;

Readonly my $MAX => 10946;
Readonly my @NUMBERS => (
    # 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765, 10946,

    # omit first 2 numers to can_not_skip work
    1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765, 10946,
);

sub new {
    my $class = shift;
    my %param = @_;
    my $self = fields::new( $class );
    $self->{max}         = $param{max} || $MAX;
    $self->{_current}    = 0;
    $self->{_did_exceed} = 0;
    return $self;
}

sub can_skip {
    my $self  = shift;
    my $count = shift || 0;

    if ( $self->{_did_exceed} ) {
        return ( ( $count % $self->{max} ) == 0 );
    }

    my $can_not_skip = $count == $NUMBERS[ $self->{_current} ];

    if ( $can_not_skip ) {
        $self->{_current}++;
        $self->{_did_exceed} = !$NUMBERS[ $self->{_current} ];
    }

    return !$can_not_skip;
}

1;
