#!perl -T

use Test::More tests => 2;
use constant EPS => 1e-3;
use Array::Compare;

BEGIN {
    use_ok( 'Statistics::Data::Dichotomize' ) || print "Bail out!\n";
}

my $seq = Statistics::Data::Dichotomize->new();

my $data_aref;
my $cmp_aref = Array::Compare->new;

# shrink (windowize) method
my @raw_data = (1, 2, 3, 3, 3, 3, 4, 2, 1);
my @res_data = (0, 1, 1);
$seq->load(@raw_data);
$data_aref = $seq->shrink(winlen => 3, rule => sub { require Statistics::Lite; my $data_aref = shift; return Statistics::Lite::mean(@$data_aref) > 2 ? 1 : 0;});
diag( "shrink() method:\n\texpected\t=>\t", join('', @res_data),"\n\tobserved\t=>\t", join('', @$data_aref));
ok($cmp_aref->simple_compare(\@res_data, $data_aref), "Error in shrink results");

sub equal {
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
