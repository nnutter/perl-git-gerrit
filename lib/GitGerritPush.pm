use strict;
use warnings;

package GitGerritPush;

use Git::Repository qw(Log Branch Tag Hooks);

sub main {
    my %options = @_;

    my $repo = Git::Repository->new();
    my $branch = $repo->branch;
    my $upstream = $branch->upstream;
    my $remote = $upstream->remote;

    validate($repo);

    my $target = target($branch->name, $upstream->remote_branch_name);
    $remote->push($branch->name, $target);

    if (!topic_branch($branch)) {
        # message
        # tag?
        $branch->reset(
            mode => 'hard',
            commit => $upstream->name,
        );
    }
}

sub topic_branch {
    my $branch = shift;
    my $upstream = $branch->upstream;
    return (
        $upstream->remote_branch_name ne $branch->name
        ? $branch->name
        : undef);
}

sub target {
    my $local_name = shift;
    my $remote_name = shift;

    my $target = join('/', 'refs', 'for', $remote_name);
    if ($local_name ne $remote_name) {
        $target = join('/', $target, $local_name);
    }
    return $target;
}

sub validate {
    my $repo = shift;

    validate_commit_hook($repo);

    my $branch = $repo->branch;
    validate_branch($branch);

    my $upstream = $branch->upstream;
    validate_upstream($upstream);

    my $remote = $upstream->remote;
    validate_remote($remote);

    my $range = join('..', $upstream->name, $branch->name);
    my @changes = $repo->log($range);
    validate_changes(@changes);

    if (@changes > 1) {
        validate_topic_branch($branch);
    }
}

sub validate_commit_hook {
    my $repo = shift;

    my $commit_hook = (grep { $_ eq /[\/\\]commit-msg$/ } $repo->hooks)[0]
    unless ($commit_hook) {
        die 'commit-msg hook is missing';
    }
}

sub validate_branch {
    my $branch = shift;
    unless ($branch) {
        die 'branch is undefined';
    }
    unless ($branch->isa('Git::Repository::Branch::Local')) {
        die 'branch is not expected type';
    }
}

sub validate_upstream {
    my $upstream = shift;
    unless ($upstream) {
        die 'upstream is undefined';
    }
}

sub validate_remote {
    my $remote = shift;
    unless ($remote) {
        die 'remote is undefined';
    }
    unless ($remote->name eq 'gerrit') {
        die 'remote is not gerrit';
    }
}

sub validate_changes {
    my @changes = shift;
    unless (@changes) {
        die 'no changes';
    }
    my @missing_change_id = grep { $_->body !~ /Change-IDs:/ } @changes;
    if (@missing_change_id) {
        die 'missing Change-IDs';
    }
}

sub validate_topic_branch {
    my $branch = shift;
    unless (topic_branch($branch)) {
        die 'not a topic branch';
    }
}

1;
