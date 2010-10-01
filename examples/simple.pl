#!/usr/bin/env perl
use warnings;
use strict;
use DNode;

# just the connect part for now
DNode->new({})->connect(5050, sub {
    my $remote = shift;
    $remote->{f}(sub {
        my $x = shift;
        print "x=<$x>\n";
    })
});
