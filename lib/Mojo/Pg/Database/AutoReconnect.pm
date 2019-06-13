package Mojo::Pg::Database::AutoReconnect;
use Mojo::Base 'Mojo::Pg::Database';

our $VERSION = "0.01";

has 'owner_pid';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;
    $self->owner_pid($$);
    return $self;
}

sub reconnect {
    my ($self) = @_;

    $self->_in_transaction_check();

    my $dbh = $self->{dbh};
    $self->disconnect;
    $self->{dbh} = $dbh->clone();
    $self->owner_pid($$);
}

sub disconnect {
    my $self = shift;
    $self->owner_pid(undef);
    $self->_unwatch;
    $self->{dbh}->disconnect;
}


sub dbh {
    my ($self) = @_;
    if ( $_[1] ) {
        $self->{dbh} = $_[1];
        $self->owner_pid($$);
        return;
    }

    my $dbh = $self->{dbh};
    if ( !defined $self->owner_pid || $self->owner_pid != $$ ) {
        $self->reconnect;
    }

    $dbh = $self->{dbh};
    if ( !$dbh->FETCH('Active') || !$dbh->ping ) {
        $self->reconnect;
    }

    return $self->{dbh};
}

sub _in_transaction_check {
    my ($self) = @_;

    if ( $self->{dbh}->FETCH('BegunWork') ) {
        # TODO: fetch sufficient caller information
        # my $caller = [caller()];
        # my $pid    = $self->owner_pid();
        #Carp::confess("Detected transaction during a connect operation (last known transaction at $caller->[1] line $caller->[2], pid $pid). Refusing to proceed at");
        Carp::confess("Detected transaction during a connect operation. Refusing to proceed");
    }
}


sub DESTROY {
  my $self = shift;

  my $waiting = $self->{waiting};
  $waiting->{cb}($self, 'Premature connection close', undef) if $waiting->{cb};

  return unless (my $pg = $self->pg) && (my $dbh = $self->{dbh}); # modify using raw dbh
  $pg->_enqueue($dbh) unless $dbh->{private_mojo_no_reuse};
}


1;
__END__

=encoding utf-8

=head1 NAME

Mojo::Pg::AutoReconnect - A lightweight medicine for using database

=head1 SYNOPSIS

    use Mojo::Pg::AutoReconnect;
    my $db = Mojo::Pg::AutoReconnect->new(connect_info => ['dbi:SQLite:...', '', '']);
    
    $db->insert(book => {title => 'mybook1', author => 'me', ...});

    my $book_id = $db->last_insert_id;
    my $row = $db->single(book => {id => $book_id});

    print 'Title: '. $row->{title}. "\n";
    
    my @rows = $db->select(book => sql_ge(price => 500));
    
    ### or non-strict mode
    my @rows = $db->select(book => {price => {'>=' => 500}});

    for my $r (@rows) {
        printf "Title: %s \nPrice: %s yen\n", $r->{title}, $r->{price};
    }
    
    # or using iterator
    my $iter = $db->select(book => {price => {'>=' => 500}});
    while (my $row = $iter->next) {
        printf "Title: %s \nPrice: %s yen\n", $row->{title}, $row->{price};
    }
    
    $db->update(book => [author => 'oreore'], {author => 'me'});
    
    $db->delete(book => {author => 'me'});
    
    ### using transaction
    do {
        my $txn = $db->txn_scope;
        $db->insert(book => ...);
        $db->insert(store => ...);
        $txn->commit;
    };

=head1 DESCRIPTION

atode

=head1 ATTRIBUTES

=head1 METHODS

=head2 new

    my $db = Mojo::Pg::AutoReconnect->new( connect_info => [$dsn, $dbuser, $dbpass] );

Instantiate and connect to db. Then, it returns L<DBIx::Mojo::Pg::AutoReconnect> object.

=head1 LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tsucchi E<lt>tsucchi@cpan.orgE<gt>

=head1 SEE ALSO

L<Mojo::Pg>

L<Otogiri>

=cut

