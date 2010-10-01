#!/usr/bin/env perl
use warnings;
use strict;
use DNode;

DNode->new({
    f => sub {
        my $cb = shift;
        $cb->(31337);
    }
})->listen(5050);
