package Scrub;
require './Walk.pm';

sub new {
    return bless { callbacks => {}, last_id => 0 }, shift;
}

sub scrub {
    my $self = shift;
    my $obj = shift;
    
    my %callbacks;
    my $walked = Walk->new($obj)->walk(sub {
        my $node = shift;
        my $ref = ref $node->value;
        if ($ref eq 'CODE') {
            my $id = $self->{last_id} ++;
            $self->{callbacks}{$id} = $node->value;
            $callbacks{$id} = [ $node->path ];
            $node->value = '[ Function ]';
        }
    });
    
    return { object => $walked, callbacks => \%callbacks };
}

sub unscrub {
    my $self = shift;
    my $req = shift;
    return Walk->new($req->{arguments})->walk(sub {
        my $node = shift;
        my $ref = ref $node->value;
    });
}

1;
