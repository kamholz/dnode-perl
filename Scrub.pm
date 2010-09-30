package Scrub;

sub new {
    return bless { callbacks => {}, last_id => 0 }, shift;
}

sub scrub {
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

sub unscrub {
    my $self = shift;
    my $req = shift;
    return $req->{arguments}; # for now
}

1;
