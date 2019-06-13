requires 'perl', '5.008001';
requires 'Mojo::Pg';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Requires';
    requires 'Mock::Quick'
};

on 'develop' => sub {
    requires 'Test::PostgreSQL';
};
