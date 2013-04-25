#!perl -T

use Test::More tests => 7;
use constant EPS => 1e-3;
use Array::Compare;

BEGIN {
    use_ok( 'Statistics::Data::Dichotomize' ) || print "Bail out!\n";
}

my $seq = Statistics::Data::Dichotomize->new();

my $data_aref;
my $cmp_aref = Array::Compare->new;
my @res_data = ();

# match method
my @a = (qw/1 3 3 2 1 5 1 2 4/);
my @b =  (qw/4 3 1 2 1 4 2 2 4/);
@res_data = (qw/0 1 0 1 1 0 0 1 1/);

$data_aref = $seq->match(data => [\@a, \@b]);
diag( "match() method (no lag):\n\texpected\t=>\t", join('', @res_data),"\n\tobserved\t=>\t", join('', @$data_aref));
ok($cmp_aref->simple_compare(\@res_data, $data_aref), "Error in match results");

## - same but with load/read:
$seq->load(a => \@a, b => \@b);
$data_aref = $seq->match(data => [$seq->read(label => 'a'), $seq->read(label => 'b')]);
diag( "match() method (no lag, retrieved data)");
ok($cmp_aref->simple_compare(\@res_data, $data_aref), "Error in match results");

## - same but lag => 0
@a = (qw/c b b b d a c d b d/);
@b = (qw/d a a d b a d c c e/);
@res_data = (qw/0 0 0 0 0 1 0 0 0 0/);
$data_aref = $seq->match(data => [\@a, \@b], lag => 0);
diag( "match() method, lag => 0:\n\texpected\t=>\t", join('', @res_data),"\n\tobserved\t=>\t", join('', @$data_aref));
ok($cmp_aref->simple_compare(\@res_data, $data_aref), "Error in match results");

## - same but lag => +1
@res_data = (qw/0 0 0 1 0 0 1 0 0/);
$data_aref = $seq->match(data => [\@a, \@b], lag => 1);
diag( "match() method, lag => +1:\n\texpected\t=>\t", join('', @res_data),"\n\tobserved\t=>\t", join('', @$data_aref));
ok($cmp_aref->simple_compare(\@res_data, $data_aref), "Error in match results");

## - same but lag => -2
@res_data = (qw/0 0 1 0 1 0 1 0/);
$data_aref = $seq->match(data => [\@a, \@b], lag => -2);
diag( "match() method, lag => -2:\n\texpected\t=>\t", join('', @res_data),"\n\tobserved\t=>\t", join('', @$data_aref));
ok($cmp_aref->simple_compare(\@res_data, $data_aref), "Error in match results");

## - same but lag => 1, loop => 1
@res_data = (qw/1 0 0 0 1 0 0 1 0 0/);
$data_aref = $seq->match(data => [\@a, \@b], lag => 1, loop => 1);
diag( "match() method, lag => 1 (with loop):\n\texpected\t=>\t", join('', @res_data),"\n\tobserved\t=>\t", join('', @$data_aref));
ok($cmp_aref->simple_compare(\@res_data, $data_aref), "Error in match results");

sub equal {
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
