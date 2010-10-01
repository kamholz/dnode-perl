package Walk;

sub new {
    my ($class, $object) = @_;
    return bless { path => [], object => $object }, $class;
}

sub walk {
    my ($self, $cb) = @_;
    return $self->_walk($self->{object}, $cb);
}

sub _walk {
    my ($self, $obj, $cb) = @_;
    my $node = Node->new($obj);
    $cb->($node);
    
    my $value = $node->value;
    my $ref = ref $value;
    
    if ($ref eq 'HASH') {
        return { map {
            my $key = $_;
            push @{$self->{path}}, $key;
            my $walked = $self->_walk($value->{$_}, $cb);
            pop @{$self->{path}};
            $key => $walked;
        } keys %$value };
    }
    elsif ($ref eq 'ARRAY') {
        my @acc;
        for my $i (0 .. $#$value) {
            push @{$self->{path}}, $i;
            push @acc, $self->_walk($value->[$i], $cb);
            pop @{$self->{path}};
        }
        return \@acc;
    }
    elsif ($ref eq 'GLOB' or $ref eq 'Regexp' or $ref eq '') {
        return $value;
    }
    elsif ($ref->isa('HASH')) {
        #my @blessed = @{ Class::Inspector->methods($value) // [] };
        return $self->_walk({ %$value }, $cb);
    }
    elsif ($ref->isa('ARRAY')) {
        return $self->_walk({ @$value }, $cb);
    }
}

package Node;

sub new {
    my ($class, $value) = @_;
    return bless { value => $value }, $class;
}

sub value { (shift)->{value} }
sub path { (shift)->{path} }

1;
