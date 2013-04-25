#!perl -T

use Test::More tests => 3;
use constant EPS => 1e-3;
use Array::Compare;

BEGIN {
    use_ok( 'Statistics::Data::Dichotomize' ) || print "Bail out!\n";
}

my $seq = Statistics::Data::Dichotomize->new();

my $data_aref;
my $cmp_aref = Array::Compare->new;

# pool method
## - example from Swed & Eisenhart p. 69
my @a = (qw/1.95 2.17 2.06 2.11 2.24 2.52 2.04 1.95/);
my @b = (qw/1.82 1.85 1.87 1.74 2.04 1.78 1.76 1.86/);
my @res_data = (1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0);

$data_aref = $seq->pool(data => [\@a, \@b]);
diag( "pool() method:\n\texpected\t=>\t", join('', @res_data),"\n\tobserved\t=>\t", join('', @$data_aref));
ok($cmp_aref->simple_compare(\@res_data, $data_aref), "Error in pool results");

## - same but with load/read:
$seq->load(a => \@a, b => \@b);
$data_aref = $seq->pool(data => [$seq->read(label => 'a'), $seq->read(label => 'b')]);
diag( "pool() method (retrieved data):\n\texpected\t=>\t", join('', @res_data),"\n\tobserved\t=>\t", join('', @$data_aref));
ok($cmp_aref->simple_compare(\@res_data, $data_aref), "Error in pool results");

sub equal {
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
