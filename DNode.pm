package DNode;
use v5.10.0;
use strict;
use warnings;

use IO::Socket::INET;
use IO::Select;
use JSON qw/encode_json decode_json/;
use Class::Inspector;

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
    $self->{sock} = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port)
        or die "Connect failed: $!";
    
    my $conn = {};
    
    $self->_request('methods',
        ref $self->{constructor} eq 'CODE'
            ? $self->{constructor}($self->{remote}, $conn)
            : $self->{constructor}
    );
}

sub listen {
    die 'Not implemented.';
}

sub _request {
    my $self = shift;
    my ($method, @args) = @_;
    my $sock = $self->{sock};
    my $scrub = $self->_scrub(\@args);
    print $sock encode_json({
        method => $method,
        arguments => $scrub->{object},
        callbacks => $scrub->{callbacks},
        links => [],
    }), "\n";
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

1;
