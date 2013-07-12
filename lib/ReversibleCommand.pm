use strict;
use warnings;

use v5.10;

package ReversibleCommand;

use Carp qw(croak);

# BEGIN Package Functions

sub run {
    my $command = shift;
    my @command = (ref($command) eq 'ARRAY' ? @$command : $command);
    return system(@command);
}

sub named_args {
    my %argv = @_;

    my $required = delete $argv{required};
    my $optional = delete $argv{optional};
    my $args     = delete $argv{args};

    unless ($required || $optional) {
        croak 'missing argument specification';
    }

    unless ($args) {
        croak 'missing args';
    }

    my @unexpected_argv = keys %argv;
    if (@unexpected_argv) {
        croak 'unexpected named argument(s): ' . join(', ', @unexpected_argv);
    }

    my %o_args = @$args;
    my %o_argv;

    my @missing_required;
    for my $r (@$required) {
        if (exists $o_args{$r}) {
            $o_argv{$r} = delete $o_args{$r};
        } else {
            push @missing_required, $r;
        }
    }
    if (@missing_required) {
        croak 'missing required argument(s): ' . join(', ', @missing_required);
    }

    for my $o (@$optional) {
        $o_argv{$o} = delete $o_args{$o};
    }

    my @unexpected_o_args = keys %o_args;
    if (@unexpected_o_args) {
        croak 'unexpected named argument(s): ' . join(', ', @unexpected_o_args);
    }

    return %o_argv;
}

# END Package Functions
# BEGIN Class Methods

sub new {
    my $class = shift;
    my %args = named_args(
        args => \@_,
        required => [qw(forward)],
        optional => [qw(reverse)],
    );

    my $object = \%args;
    return bless $object, $class;
}

sub transaction {
    my $class = shift;
    my @commands = @_;

    my $err;
    my @done_commands;
    while (my $command = shift @commands) {
        my $forward = $command->{forward};
        run($forward);
        if ($? == 0) {
            push  @done_commands, $command;
        } else {
            my @forward = (ref($forward) eq 'ARRAY' ? @$forward : $forward);
            $err = 'command failed: ' . join(' ', @forward);
            $class->rollback(@done_commands);
            return (undef, $err);
        }
    }

    return (1, undef);
}

sub rollback {
    my $class = shift;
    my @commands = @_;

    while (my $command = shift @commands) {
        next unless $command->{reverse};
        run($command->{reverse});
        unless ($? == 0) {
            die 'FATAL: failed during rollback';
        }
    }

    # undef = success, die = failure
    return;
}

# END Class Methods

1;
