use strict;
use warnings;
use Test::Clustericious::Config;
use Test::Clustericious::Cluster 0.22;
use Test::More tests => 5;
use Digest::file qw( digest_file_hex );
use Yars::Client;

my $cluster = Test::Clustericious::Cluster->new;

subtest prep => sub {
  plan tests => 3;
  $cluster->create_cluster_ok(qw( Yars ));
  create_directory_ok 'data';
  create_directory_ok 'state';
};

my $t = $cluster->t;
my $y = Yars::Client->new;

subtest 'Yars::Client#status' => sub {
  plan tests => 3;
  my $status = $y->status;
  is $status->{app_name}, 'Yars', 'status.app_name = Yars';
  is $status->{server_url}, $cluster->url, 'status.server_url = ' . $cluster->url;
  is $y->tx->req->headers->header('X-Yars-Skip-Verify'), 'on', 'X-Yars-Skip-Verify: on';;
};

subtest 'Yars::Client#upload, #download' => sub {
  plan tests => 3;

  my $tmp = create_directory_ok 'tmp';
  my $data = "some data $$ ".time;
  do {
    open my $fh, '>', "$tmp/foo";
    print $fh $data;
    close $fh;
  };

  subtest 'Yars::Client#upload' => sub {
    plan tests => 4;
    ok $y->upload("$tmp/foo"), "uploading foo";
    is $y->res->code, '201', 'Created';

    my $content = $y->get(digest_file_hex("$tmp/foo",'MD5'),'foo');
    ok $content, "got content";
    is $content, $data, "got same content";
  };

  subtest 'Yars::Client#download' => sub {
    plan tests => 4;
    my $download_dir = create_directory_ok 'download';
    chdir $download_dir or die $!;
    ok $y->download(digest_file_hex("$tmp/foo",'MD5'),'foo'), "Downloaded foo";
    ok -e 'foo', "Downloaded foo";
    my $got = join "", IO::File->new("<foo")->getlines;
    is $got, $data, "got same contents";
    chdir(File::Spec->rootdir);
  };
};

subtest 'Yars::Client#send, #retrieve without filename' => sub {
  plan tests => 3;
  my $location = $y->send(content => "flintstone");
  ok $location, "Sent content, location is $location.";
  ok !$y->errorstring, "No error";
  my $same = $y->retrieve(location => $location);
  is $same, "flintstone", "Got same content back";
};

subtest 'Yars::Client#send, #retrieve with filename' => sub {
  plan tests => 3;
  my $location = $y->send(name => "barney", content => "rubble");
  my $md5 = $y->res_md5;
  ok $location, "Sent content, location is $location.";
  ok !$y->errorstring, "No error";
  my $same = $y->retrieve(name => "barney", md5 => $md5);
  is $same, "rubble", "Got same content back";
};

# TODO
# my $status = $y->check_manifest($filename);
# diag explain $status;

__DATA__

@@ etc/Yars.conf
---
% use Test::Clustericious::Config;
url : <%= cluster->url %>

servers :
    - url : <%= cluster->urls->[0] %>
      disks :
        - root : <%= dir home, 'data' %>
          buckets : [0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F]

state_file: <%= file home, 'state', 'state' %>
