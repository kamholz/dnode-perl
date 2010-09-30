package DNode;
use v5.10.0;
use strict;
use warnings;

use AnyEvent::Socket qw/tcp_connect/;
use AnyEvent::Handle;
#use Class::Inspector;

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
    my $block = (first { ref eq 'CODE' }) // sub { };
    
    my $conn = {};
    
    my $cv = AnyEvent->condvar;
    tcp_connect $host, $port, sub {
        my $fh = shift;
        $self->{handle} = new AnyEvent::Handle(fh => $fh);
        my $handler; $handler = sub {
            my ($h, $json) = @_;
            $self->_handle($json);
            $h->push_read(json => $handler);
        };
        $self->{handle}->push_read(json => $handler);
        $self->_request('methods', ref $self->{constructor} eq 'CODE'
            ? $self->{constructor}($self->{remote}, $conn)
            : $self->{constructor}
        );
    };
    $cv->recv;
}

sub listen {
    die 'Not implemented.';
}

sub _request {
    my $self = shift;
    my ($method, @args) = @_;
    my $scrub = $self->_scrub(\@args);
    $self->{handle}->push_write(json => {
        method => $method,
        arguments => $scrub->{object},
        callbacks => $scrub->{callbacks},
        links => [],
    });
    $self->{handle}->push_write("\n");
}

sub _handle {
    my $self = shift;
    my $req = shift;
    if ($req->{method} =~ m/^\d+$/) {
        my $args = $self->_unscrub($req);
        my $id = $req->{method};
        $self->{callbacks}{$id}(@$args)
    }
    elsif ($req->{method} eq 'methods') {
        $self->{remote} = $self->_unscrub($req)->[0];
    }
}

sub _scrub {
    my $self = shift;
    my $target = shift;
    
    my @path;
    my %callbacks;
    
    my $walk; $walk = sub {
        my $obj = shift;
        my $ref = ref $obj;
        
        if ($ref eq 'HASH') {
            return { map {
                my $key = $_;
                push @path, $key;
                my $walked = $walk->($obj->{$_});
                pop @path;
                $key => $walked;
            } keys %$obj };
        }
        elsif ($ref eq 'ARRAY') {
            my @acc;
            for my $i (0 .. $#$obj) {
                push @path, $i;
                push @acc, $walk->($obj->[$i]);
                pop @path;
            }
            return \@acc;
        }
        elsif ($ref eq 'CODE') {
            $self->{last_id} ++;
            my $id = $self->{last_id};
            $self->{callbacks}{$id} = $obj;
            $callbacks{$id} = [ @path ];
            return '[ Function ]';
        }
        elsif ($ref eq 'GLOB') {
            die 'Glob refs not supported';
        }
        elsif ($ref eq 'Regexp') {
            die 'Regexp refs not supported'
        }
        elsif ($ref eq '') {
            return $obj;
        }
        elsif ($ref->isa('HASH')) {
            #my @blessed = @{ Class::Inspector->methods($obj) // [] };
            return $walk->({ %$obj });
        }
        elsif ($ref->isa('ARRAY')) {
            return $walk->({ @$obj });
        }
    };
    
    return { object => $walk->($target), callbacks => \%callbacks };
}

sub _unscrub {
    my $self = shift;
    my $req = shift;
    return $req->{arguments}; # for now
}

1;
