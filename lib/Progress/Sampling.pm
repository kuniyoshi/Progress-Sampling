use strict;
use warnings;
package Progress::Sampling;
use fields qw( max interval format format_specifier _output_controler _format _format_fields _started_at _count _elapsed );
use Time::HiRes qw( gettimeofday tv_interval );
use Readonly;
use Progress::Sampling::OutputControl::Linear;
use Progress::Sampling::OutputControl::Fibonacci;

Readonly my %DEFAULT => (
    interval         => 10,
    format           => "__PERCENTAGE__[%] = __COUNT__/__MAX__,\t__SPEED__,\t__REMAIN__[s] remain",
    format_specifier => {
        __PERCENTAGE__ => q{%d},
        __COUNT__      => q{%d},
        __MAX__        => q{%d},
        __SPEED__      => q{%.4f},
        __REMAIN__     => q{%d},
    },
);
Readonly my $FORMAT_WITHOUT_MAX => "progress: __COUNT__\t__SPEED__";

sub new {
    my $class = shift;
    my %param = @_;

    for my $key ( grep { !exists $param{ $_ } } keys %DEFAULT ) {
        $param{ $key } = $DEFAULT{ $key };

        if ( $key eq "format_specifier" && ( my $max = $param{max} || $DEFAULT{max} ) ) {
            $param{format_specifier} = {
                %{ $DEFAULT{format_specifier} },
                __COUNT__ => sprintf "%%%dd", length $max,
            };
        }
    }

    my $self = fields::new( $class );

    @{ $self }{ keys %param } = values %param;

    return $self->init;
}

sub gen_format {
    my $self       = shift;
    my $format_str = shift;
    my @fields;

    $format_str =~ s{[%]}{%%}g;
    $format_str =~ s{(__[A-Z]+__)}{
        push @fields, $1;
        $self->{format_specifier}{ $1 };
    }egmsx;

    return ( $format_str, \@fields );
}

sub init {
    my $self = shift;
    my $format;
    my $output_controler;

    $self->{_started_at} = [ gettimeofday ];

    if ( exists $self->{max} ) {
        $format = $self->{format};
    }
    else {
        $format = $FORMAT_WITHOUT_MAX;
    }

    @{ $self }{ qw( _format _format_fields ) } = $self->gen_format( $format );

    if ( exists $self->{max} ) {
        $output_controler = Progress::Sampling::OutputControl::Linear->new(
            interval => $self->{interval},
        );
    }
    else {
        $output_controler = Progress::Sampling::OutputControl::Fibonacci->new;
    }

    $self->{_output_controler} = $output_controler;

    return $self;
}

sub worked {
    my $self = shift;

    return
        if $self->{_output_controler}->can_skip( $self->{_count}++ );

    $self->{_elapsed} = tv_interval( $self->{_started_at} );

    return $self->format;
}

sub percentage {
    my $self = shift;
    return ( ( $self->{_count} / $self->{max} ) * 100 );
}

sub speed {
    my $self = shift;
    return
        unless $self->{_elapsed};
    return $self->{_count} / $self->{_elapsed};
}

sub remain {
    my $self = shift;
    my $remain_count = $self->{max} - $self->{_count};
    my $speed        = $self->speed
        or return;
    return $remain_count / $speed;
}

sub _get_field_value {
    my $self = shift;
    my $name = shift;
    my $original = $name;
    $name =~ s{\A __ }{}msx;
    $name =~ s{ __ \z}{}msx;
    $name = lc $name;
    return $self->{ $name }
        if exists $self->{ $name };
    return $self->$name
        if $self->can( $name );
    $name = "_$name";
    return $self->{ $name }
        if exists $self->{ $name };
    return $self->$name
        if $self->can( $name );
    die "Could not get value $original -> $name";
}

sub format {
    my $self = shift;
    return sprintf $self->{_format},
        map { $self->_get_field_value( $_ ) }
        @{ $self->{_format_fields} };
}

1;
