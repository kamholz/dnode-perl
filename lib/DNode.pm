package DNode;
use 5.10.0;
use strict;
use warnings;

use AnyEvent::Socket qw/tcp_connect tcp_server/;
use AnyEvent::Handle;
use DNode::Conn;

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
    tcp_connect $host, $port, sub { $self->_handle(shift, $block) };
    $cv->recv;
}

sub listen {
    my $self = shift;
    my $host = first { ref eq '' and !/^\d+$/ } @_;
    my $port = first { ref eq '' and m/^\d+$/ } @_ or die 'No port specified';
    my $block = (first { ref eq 'CODE' } @_) // sub { };
    
    my $cv = AnyEvent->condvar;
    tcp_server $host, $port, sub { $self->_handle(shift, $block) };
    $cv->recv;
}

sub _handle {
    my ($self, $fh, $block) = @_;
    my $handle = new AnyEvent::Handle(fh => $fh);
    my $conn = DNode::Conn->new(handle => $handle, block => $block);
    
    $conn->request('methods', ref $self->{constructor} eq 'CODE'
        ? $self->{constructor}($self->{remote}, $conn)
        : $self->{constructor}
    );
}

1;
