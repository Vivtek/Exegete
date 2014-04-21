#!perl -T

use Test::More tests => 1;
use Exegete;

# Our testing procedure is pretty simple - we'll just load the local project defined in this directory,
# then follow the regular build procedure and check each step along the way.

my $publisher = Exegete->new();

ok($publisher);

$publisher->load('test_book');
$publisher->mull_over();
$publisher->load_content();
$publisher->index();
$publisher->generate();
$publisher->express();
$publisher->post_build();
