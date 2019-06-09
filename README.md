# NAME

Mojo::Pg::AutoReconnect - A lightweight medicine for using database

# SYNOPSIS

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

# DESCRIPTION

atode

# ATTRIBUTES

# METHODS

## new

    my $db = Mojo::Pg::AutoReconnect->new( connect_info => [$dsn, $dbuser, $dbpass] );

Instantiate and connect to db. Then, it returns [DBIx::Mojo::Pg::AutoReconnect](https://metacpan.org/pod/DBIx::Mojo::Pg::AutoReconnect) object.

# LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tsucchi <tsucchi@cpanm.org>

# SEE ALSO

[Mojo::Pg](https://metacpan.org/pod/Mojo::Pg)

[Otogiri](https://metacpan.org/pod/Otogiri)
