package Conn;
require './Scrub.pm';

sub new {
    my $class = shift;
    my $self;
    my %args = @_;
    $args{scrub} = Scrub->new($args{handle});
    
    my $handler; $handler = sub {
        my ($h, $json) = @_;
        $self->handle($json);
        $h->push_read(json => $handler);
    };
    $args{handle}->push_read(json => $handler);
    
    $self = bless \%args, $class;
    return $self;
}

sub handle {
    my $self = shift;
    my $req = shift;
    if ($req->{method} =~ m/^\d+$/) {
        my $args = $self->{scrub}->unscrub($req);
        my $id = $req->{method};
        $self->{scrub}{callbacks}{$id}(@$args);
    }
    elsif ($req->{method} eq 'methods') {
        $self->{remote} = $self->{scrub}->unscrub($req)->[0];
        $self->{block}($self->{remote});
    }
}

sub request {
    my $self = shift;
    my ($method, @args) = @_;
    my $scrub = $self->{scrub}->scrub(\@args);
    $self->{handle}->push_write(json => {
        method => $method,
        arguments => $scrub->{object},
        callbacks => $scrub->{callbacks},
        links => [],
    });
    $self->{handle}->push_write("\n");
}

1;
