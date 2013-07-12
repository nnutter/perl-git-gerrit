use strict;
use warnings;

package GitReviewPush;

sub main {
    my %options = @_;
    # validate options

    unless (validate_upstream()) {
        return (undef, 'invalid upstream');
    }

    my $upstream = GitQuery->upstream;
    my $branch = GitQuery->branch;
    my @changes = GitQuery->log($upstream, $branch);
    if (@changes == 0) {
        return (undef, 'no changes');
    } elsif (@changes > 1) {
        # create a branch
        # reset back to upstream
        # switch to branch
    }
    push_branch();
    # if --reset
    #   if feature branch
    #       checkout non_feature
    #   else
    #       tag?
    #       reset to upstream
}

sub validate_upstream {
    my $upstream_remote = GitQuery->upstream_remote;
    my $upstream_branch = GitQuery->upstream_branch;
    return ($upstream_remote && $upstream_branch);
}

sub push_branch {
    my $branch = GitQuery->branch;
    my $upstream_remote = GitQuery->upstream_remote;
    my $upstream_branch = GitQuery->upstream_branch;

    my $refname = $branch . ':refs/for/' . $upstream_branch;
    return run('git', 'push', $upstream_remote, $refname);
}

1;
