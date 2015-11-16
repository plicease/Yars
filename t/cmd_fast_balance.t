use strict;
use warnings;
use 5.010;
use Test::Clustericious::Config;
use Test::More tests => 2;

create_config_ok Yars => { url => 'http://localhost:3001' };

use_ok 'Yars::Command::yars_fast_balance';
