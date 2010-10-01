#!/usr/bin/env perl
use warnings;
use strict;
use DNode;

DNode->new({
    f => sub {
        my $x = shift;
        my $cb = shift;
        $cb->(30000 + $x);
    }
})->listen(5050);
