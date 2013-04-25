#!perl -T

use Test::More tests => 5;
use constant EPS => 1e-3;
use Array::Compare;

BEGIN {
    use_ok( 'Statistics::Data::Dichotomize' ) || print "Bail out!\n";
}

my $ddat = Statistics::Data::Dichotomize->new();

my @raw_data = ();
my @res_data = ();
my $val;
my $data_aref;
my $cmp_aref = Array::Compare->new;

# split method																			
@raw_data = (4, 3, 3, 5, 3, 4, 5, 6, 3, 5, 3, 3, 6, 4, 4, 7, 6, 4, 7, 3);
($data_aref, $val) = $ddat->split(data => \@raw_data, value => \&Statistics::Lite::median);
ok(equal($val, 4), "median split value  $val != 4");

($data_aref, $val) = $ddat->split(data => \@raw_data, value => 'median');
ok(equal($val, 4), "median split value  $val != 4");

@res_data = (0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0);
$data_aref = $ddat->split(data => \@raw_data, value => 5);
diag("split() method:\n\texpected\t=>\t", join('', @res_data),"\n\tobserved\t=>\t", join('', @$data_aref), "\n\tvalue\t=>\t", $ddat->{'split_value'} );
ok($cmp_aref->simple_compare(\@res_data, $data_aref), "Error in split results");

# - same but using prior load() of data:
$ddat->load(\@raw_data);
$data_aref = $ddat->split(index => 0, value => 5);
diag( "split() method (with prior data load):\n\texpected\t=>\t", join('', @res_data),"\n\tobserved\t=>\t", join('', @$data_aref), "\n\tvalue\t=>\t", $ddat->{'split_value'} );
ok($cmp_aref->simple_compare(\@res_data, $data_aref), "Error in split results");

sub equal {
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}
