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

# binate method
my @raw_data = (qw/a b c a b/);
my @res_data = (1, 0, 0, 1, 0);
$seq->load(@raw_data);
$data_aref = $seq->binate();
diag( "binate() method:\n\texpected\t=>\t", join('', @res_data),"\n\tobserved\t=>\t", join('', @$data_aref));
ok($cmp_aref->simple_compare(\@res_data, $data_aref), "Error in binate results");

## - same but specify what is "1":
@res_data = (0, 1, 0, 0, 1);
$data_aref = $seq->binate(oneis => 'b');
diag( "binate() method (setting oneis):\n\texpected\t=>\t", join('', @res_data),"\n\tobserved\t=>\t", join('', @$data_aref));
ok($cmp_aref->simple_compare(\@res_data, $data_aref), "Error in binate results");


sub equal {
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
