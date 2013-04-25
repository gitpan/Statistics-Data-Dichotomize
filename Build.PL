use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::Data::Dichotomize',
    license             => 'perl',
    dist_author         => q{Roderick Garton <rgarton@cpan.org>},
    dist_version_from   => 'lib/Statistics/Data/Dichotomize.pm',
    configure_requires => {
        'Module::Build' => '0.36',
    },
    build_requires => {
        'Test::More' => 0,
        'Statistics::Lite' => '3.2',
        'Scalar::Util' => '1.18',
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Statistics-Data-Dichotomize-0.01-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
