use strict;
use warnings;
use Test::More;
use Mock::Quick;
use Mojo::Pg;
use Mojo::Pg::Database::AutoReconnect;

use Test::Requires 'Test::PostgreSQL';

my $t = Test::PostgreSQL->new(
    my_cnf => {
        'skip-networking' => '',
    }
) or plan skip_all => $Test::PostgreSQL::errstr;


my $pg = Mojo::Pg->new();
$pg->dsn($t->dsn(dbname => 'test'));
$pg->username('');
$pg->password('');
$pg->database_class('Mojo::Pg::Database::AutoReconnect');

my $sql_person = <<'EOF';
CREATE TABLE person (
    id   serial       PRIMARY KEY,
    name character(48) NOT NULL,
    age  integer
);
EOF

my $db = $pg->db;
$db->dbh->do($sql_person);

my $person_id = $db->insert('person', {
    name => 'Sherlock Shellingford',
    age  => 15,
}, {
    returning => 'id'
})->hash->{id};

subtest 'reconnect', sub {
    $db->disconnect();
    $db->reconnect();
    my $row = $db->select('person', '*', { id => $person_id })->hash;
    ok( defined $row );
};

subtest 'auto reconnect', sub {
    $db->disconnect();
    #$db->reconnect();
    my $row = $db->select('person', '*', { id => $person_id })->hash;
    ok( defined $row );
};

subtest 'in transaction', sub {
    #my $row = $db->select('person', '*', { id => $person_id })->hash;
    my $txn = $db->begin();
    my $guard = qclass(
        -takeover => 'DBI::db',
        ping => sub { 0 },
    );

    eval {
        $db->insert('person', {
            name => 'Nero Yuzurizaki',
            age  => 15,
        });
    };

    like( $@, qr/^Detected transaction/ );
};

ok 1;

done_testing;
