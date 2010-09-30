package DNode;
use v5.10.0;

use IO::Socket::INET;
use IO::Select;
use JSON qw/encode_json decode_json/;

sub new {
    my $class = shift;
    my $ctr = shift;
    return bless {
        constructor => $ctr,
        events => {},
    }, $class;
}

sub on {
    my $self = shift;
    my $events = $self->{events};
}

sub connect {
    use List::Util qw/first/;
    my $self = shift;
    my $host = (first { ref eq '' and !/^\d+$/ } @_) // 'localhost';
    my $port = first { ref eq '' and m/^\d+$/ } @_ or die 'No port specified';
    my $block = (first { ref eq 'CODE' }) // sub { };
    $self->{sock} = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port)
        or die "Connect failed: $!";
    $self->_request('methods');
}

sub listen {
    die 'Not implemented.';
}

sub _request {
    my $self = shift;
    my ($method, @args) = @_;
    my $sock = $self->{sock};
    print $sock encode_json({
        method => $method,
        arguments => [ @args ],
        callbacks => {},
        links => [],
    }), "\n";
}

1;
