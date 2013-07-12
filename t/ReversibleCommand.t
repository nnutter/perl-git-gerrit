use strict;
use warnings;

use Test::More tests => 4;
use File::Temp qw();

use_ok('ReversibleCommand');

subtest 'named_args' => sub {
    plan tests => 8;

    my %args;
    my %base_args = (
        args => [
            first_name => 'Nathan',
            last_name  => 'Nutter',
            gender     => 'male',
            age        => 30,
        ],
        required => [
            'first_name',
            'last_name',
        ],
        optional => [
            'gender',
            'age',
        ],
    );

    $@ = '';

    %args = %base_args;
    $args{invalid_key} = 'some_value';
    eval { ReversibleCommand::named_args(%args) };
    like($@, qr/^unexpected named argument/,
        'errored when invalid key passed to named_args');
    $@ = '';

    %args = %base_args;
    delete $args{args};
    eval { ReversibleCommand::named_args(%args) };
    like($@, qr/^missing args/,
        'errored when missing args');
    $@ = '';

    %args = %base_args;
    delete $args{required};
    delete $args{optional};
    eval { ReversibleCommand::named_args(%args) };
    like($@, qr/^missing argument specification/,
        'errored when missing both required and optional');
    $@ = '';

    %args = %base_args;
    delete $args{required};
    $args{args} = [
        gender      => 'male',
        age         => 30,
    ];
    eval { ReversibleCommand::named_args(%args) };
    is($@, '', 'did not error when optional are specified');
    $@ = '';

    %args = %base_args;
    delete $args{optional};
    $args{args} = [
        first_name  => 'Nathan',
        last_name   => 'Nutter',
    ];
    eval { ReversibleCommand::named_args(%args) };
    is($@, '', 'did not error when required are specified');
    $@ = '';

    %args = %base_args;
    $args{args} = [
        last_name  => 'Nutter',
        gender     => 'male',
        age        => 30,
    ];
    eval { ReversibleCommand::named_args(%args) };
    like($@, qr/^missing required argument.*first_name/,
        'errored when missing required argument');
    $@ = '';

    %args = %base_args;
    $args{args} = [
        first_name => 'Nathan',
        last_name  => 'Nutter',
        gender     => 'male',
    ];
    eval { ReversibleCommand::named_args(%args) };
    is($@, '', 'did not error when missing optional argument');
    $@ = '';

    %args = %base_args;
    $args{args} = [
        first_name  => 'Nathan',
        last_name   => 'Nutter',
        gender      => 'male',
        age         => 30,
        invalid_key => 'some_value',
    ];
    eval { ReversibleCommand::named_args(%args) };
    like($@, qr/^unexpected named argument.*invalid_key/,
        'errored when invalid argument passed in args');
    $@ = '';
};

subtest 'transaction success' => sub {
    plan tests => 4;

    my $dir = File::Temp->newdir();
    ok(-d $dir, 'made temp dir');

    my $a = File::Spec->join($dir, 'A');

    my @commands;
    push @commands, ReversibleCommand->new(
        forward => ['touch', $a],
        reverse => ['rm',    $a],
    );
    push @commands, ReversibleCommand->new(
        forward => 'true',
    );

    my ($rv, $err) = ReversibleCommand->transaction(@commands);
    ok($rv, 'transaction succeeded');
    is($err, undef, 'no error message');
    ok((-f $a), 'transaction was rolled back');
};

subtest 'transaction rollback' => sub {
    plan tests => 4;

    my $dir = File::Temp->newdir();
    ok(-d $dir, 'made temp dir');

    my $a = File::Spec->join($dir, 'A');

    my @commands;
    push @commands, ReversibleCommand->new(
        forward => ['touch', $a],
        reverse => ['rm',    $a],
    );
    push @commands, ReversibleCommand->new(
        forward => 'false',
    );

    my ($rv, $err) = ReversibleCommand->transaction(@commands);
    is($rv, undef, 'transaction failed');
    like($err, qr/^command failed.*false/, 'false command failed');
    ok((! -f $a), 'transaction was rolled back');
};
