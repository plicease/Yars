package Yars;

=head1 NAME

Yars (Yet Another REST Server)

=over

=cut

use strict;
use warnings;
use base 'Clustericious::App';
use Yars::Routes;
use Yars::Balancer;
use Yars::Message::Request;
use Yars::Content::Single;
our $VERSION = '0.44';

__PACKAGE__->attr( secret => rand );

=item startup

Called by the server to start up, we change
the object classes to use Yars::Message::Request
for incoming requests.

=cut

sub startup {
    my $self = shift;
    $self->SUPER::startup(@_);
    $self->hook(after_build_tx => sub {
        my ($tx,$app) = @_;
        Yars::Tools->refresh_config($app->config);
        my $req = Yars::Message::Request->new();
        $tx->req($req);
    });
}

1;
