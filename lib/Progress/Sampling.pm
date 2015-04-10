use strict;
use warnings;
package Progress::Sampling;
use Time::HiRes qw( gettimeofday tv_interval );
use Readonly;

Readonly my %DEFAULT => (
    interval => 10,
);


sub new {
    my $class = shift;
    my %param = @_;

    my $max      = delete $param{max};
    my $interval = delete $param{interval};

    my $now = [ gettimeofday ];

    my $self = bless {
        _max        => $max,
        _started_at => $now,
        _interval   => $interval,
    }, $class;

    return $self;
}

sub init {
    my $self = shift;
    $self->{_started_at} = [ gettimeofday ];
    return;
}

sub started_at { shift->{_started_at} }

sub current { shift->{_current} }

sub interval { shift->{_interval} || $DEFAULT{interval} }

sub worked {
    my $self = shift;

    $self->{_current}++;
    my $need_to_generate = ( $self->current % $self->interval ) == 0;

    return
        unless $need_to_generate;

    $self->{_elapsed} = tv_interval( $self->started_at );

    return $self->format;
}

sub max { shift->{_max} }

sub progress { shift->{_progress} }

sub elapsed { shift->{_elapsed} }

sub speed {
    my $self = shift;
    return
        unless $self->elapsed;
    return $self->current / $self->elapsed;
}

sub percentage {
    my $self = shift;
    return ( ( $self->current / $self->max ) * 100 );
}

sub remain {
    my $self = shift;
    my $remain_count = $self->max - $self->current;
    my $speed        = $self->speed
        or return;
    return $remain_count / $speed;
}

sub format {
    my $self = shift;
    return sprintf "%d[%%] = %d/%d,\t%.4f[w/s],\t%d[s] remain", $self->percentage, $self->current, $self->max, $self->speed, $self->remain;
}

1;
