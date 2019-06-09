package Mojo::Pg::Database::AutoReconnect;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

use parent 'Mojo::Pg::Database';


sub reconnect {
    my ($self) = @_;

    $self->_in_transaction_check();

    #$self->disconnect();

    my $dbh = $self->{dbh};
    $self->{dbh} = $dbh->clone();
    #$dbh->disconnect();
    #$self->owner_pid($$);
}

sub dbh {
    my ($self) = @_;
    if ( $_[1] ) {
        $self->{dbh} = $_[1];
        return;
    }

    my $dbh = $self->{dbh};
    if ( !defined $dbh->{pg_pid} || $dbh->{pg_pid} != $$ ) {
        $self->reconnect;
    }
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
        # my $pid    = $self->{dbh}->{pg_pid};
        Carp::confess("Detected transaction during a connect operation. Refusing to proceed at");
        #Carp::confess("Detected transaction during a connect operation (last known transaction at $caller->[1] line $caller->[2], pid $pid). Refusing to proceed at");
    }
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

tsucchi E<lt>tsucchi@cpanm.orgE<gt>

=head1 SEE ALSO

L<Mojo::Pg>

L<Otogiri>

=cut

