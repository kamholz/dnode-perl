package DNode;
use v5.10.0;
use strict;
use warnings;

use AnyEvent::Socket qw/tcp_connect/;
use AnyEvent::Handle;
require './Conn.pm';

sub new {
    my $class = shift;
    my $ctr = shift;
    return bless {
        constructor => $ctr,
        events => {},
        remote => {},
        callbacks => {},
        last_id => 0,
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
    my $block = (first { ref eq 'CODE' } @_) // sub { };
    
    my $cv = AnyEvent->condvar;
    tcp_connect $host, $port, sub {
        my $fh = shift;
        my $handle = new AnyEvent::Handle(fh => $fh);
        my $conn = Conn->new(handle => $handle, block => $block);
        
        $conn->request('methods', ref $self->{constructor} eq 'CODE'
            ? $self->{constructor}($self->{remote}, $conn)
            : $self->{constructor}
        );
    };
    $cv->recv;
}

sub listen {
    die 'Not implemented.';
}

1;
