package Statistics::Data::Dichotomize;

use 5.006;
use strict;
use warnings;
use Statistics::Data;
use vars qw($VERSION @ISA @EXPORT);
use Exporter;
@ISA = qw(Statistics::Data Exporter);
$VERSION = '0.02';
use Carp qw(croak carp);
use Statistics::Lite qw(mean median mode);
use Number::Misc 'is_numeric'; # is_numeric('x'); 

@EXPORT = (qw/split cut pool swing match binate shrink windowize/);

=head1 NAME

Statistics-Data-Dichotomize - Dichotomize one or more numerical or categorical sequences into a single two-valued one

=head1 SYNOPSIS

 use Statistics::Data::Dichotomize;
 my $ddat = Statistics::Data::Dichotomize->new();
 $ddat->load(23, 24, 7, 55); # numerical data
 my $aref = $ddat->split(value => 'median',); # or use swing(), pool(), binate(), shrink()
 # - alternatively, without load()
 $aref = $ddat->split(data => [23, 24, 7, 55], value => 20);
 # or after a multi-sequence load:
 $ddat->load(fiz =>[qw/c b c a a/], gok => [qw/b b b c a/]); # names are arbitary
 $aref = $ddat->binate(data => 'fiz', oneis => 'c',); # returns (1, 0, 1, 0, 0)
 $ddat = $ddat->match(); # or majoritymatch() for more than 2 sequences

 $ddat->print_dataline("%d\t"); # loaded sequence is also cached. prints "" 
 
 $ddat->load([qw/c b c a a/], [qw/b b b c a/]); # categorical (stringy) data
 printf("%d\t", @$ddat, "\n"); # DIY version. prints "0 1 0 0 1"
 
 # plus other methods from Statistics::Data

=head1 DESCRIPTION

Transform one or more sequences into a binomial, dichotomous, two-valued sequence by various methods. Each method returns the dichotomized sequences as a referenced array.

=head1 METHODS

=head2 new

To create class object directly from this module, inheriting all the L<Statistics::Data|Statistics::Data> methods.

=head2 load, add, read, unload

Methods for loading, updating and retrieving data are inherited from L<Statistics::Data|Statistics::Data>. See that manpage for details.

=cut

=head2 Numerical data: Single sequence dichotomization

=head3 split, cut

 $aref = $seq->split(value => 'median', equal => 'gt'); # split loaded data at its median (as per Statistics::Lite)
 ($aref, $val) = $seq->split(data => \@data, value => \&Statistics::Lite::median); # same by reference, giving data, getting back median too
 $aref = $seq->split(value => 23); # split anonymously cached data at a specific value
 $aref = $seq->split(value => 'mean', data => 'blues'); # split named data at its arithmetical mean (as per Statistics::Lite)

Reduce data by categorizing them as to whether they're numerically higher or low than a particular value, e.g., their median value. So the following data, when split over values greater than or equal to 5, yield the dichotomous sequence:

 @orig_data  = (4, 3, 3, 5, 3, 4, 5, 6, 3, 5, 3, 3, 6, 4, 4, 7, 6, 4, 7, 3);
 @split_data = (0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0);

Arguments:

=over 4

=item value => 'mean|median|mode' - or a specific numerical value, or code reference

Specify the value at which the data will be split. This could be the mean, median or mode (as calculated by L<Statistics::Lite|Statistics::Lite>), or a numerical value within the range of the data, or some appropriate subroutine - one that takes a list and returns a single descriptive about it. The default is the I<median>. The split-value, as specified by C<value>, can be retrieved as the second element returned if calling for an array.

=item equal => 'I<gt>|I<lt>|I<0>'

Specify how to split the data should the split-value (as specified by C<value>) be present in the data. The default value is 0: observations equal to the split-value are skipped; the L<Joins|Statistics::Sequences::Joins> test in particular assumes this. If C<equal =E<gt> 'I<gt>'>: all data-values I<greater than or equal to> the split-value will form one group, and all data-values less than the split-value will form another. To split with all values I<less than or equal to> in one group, and higher values in another, use C<equal =E<gt> 'I<lt>'>.

=item data => 'I<string>'

Refer to data to split, if not already loaded.

=back

=cut

sub split {
    my $self = shift;
    my $args = ref $_[0] ? $_[0] : {@_};
    my $dat = ref $args->{'data'} ? $args->{'data'} : $self->read($args);
    croak __PACKAGE__, '::split All data must be numeric for dichotomizing about a split-value' if !$self->all_numeric($dat);
    $args->{'value'} = 'median' if ! defined $args->{'value'};
    $args->{'equal'} = 'gt' if ! defined $args->{'equal'}; 
    my ($val, @seqs) = ();
 
    # Get a split-value:
    if (! is_numeric($args->{'value'})) {
        my $code = delete $args->{'value'};
        no strict 'refs';
        $val = $code->(@{$dat});
    }
    else {
        $val = $args->{'value'};
    }
    # Categorize by number of observations above and below the split_value:
    push @seqs, $_ > $val ? 1 : $_ < $val ? 0 : $args->{'equal'} eq 'gt' ? 1 : $args->{'equal'} eq 'lt' ? 0 : 1 foreach @{$dat};
    $self->{'testdata'} = \@seqs;
    $self->{'split_value'} = $val;
    return wantarray ? (\@seqs, $val) : \@seqs;
}
*cut = \&split;

=head3 swing

 $seq->swing();
 $seq->swing(data => 'reds'); # if more than one are loaded, or a single one was loaded with a name

Group by the rises and falls in the data. Each element in the named data-set is subtracted from its successor, and the result is replaced with a 1 if the difference represents an increase, or 0 if it represents a decrease. For example, the following numerical series (example from Wolfowitz, 1943, p. 283) produces the subsequent dichotomous series.

 @values = (qw/3 4 7 6 5 1 2 3 2/);
 @dichot =   (qw/1 1 0 0 0 1 1 0/);

Dichotomously, the data can be seen as commencing with an ascending run of length 2, followed by a descending run of length 3, and so on. Note that the number of resulting observations is 1 less than the original number.

Note that the critical region of the distribution lies (only) in the upper-tail; a one-tailed test of significance is appropriate.

=over 4

=item equal => 'I<gt>|I<lt>|I<rpt>|I<0>'

The default result when the difference between two successive values is zero is to skip the observation, and move onto the next succession (C<equal =E<gt> 0>). Alternatively, you may wish to repeat the result for the previous succession; skipping only a difference of zero should it occur as the first result (C<equal =E<gt> 'rpt'>). Or, a difference greater than or equal to zero is counted as an increase (C<equal =E<gt> 'gt'>), or a difference less than or equal to zero is counted as a decrease. For example, 

 @values =    (qw/3 3 7 6 5 2 2/);
 @dicho_def = (qw/1 0 0 0/); # First and final results (of 3 - 3, and 2 - 2) are skipped
 @dicho_rpt = (qw/1 0 0 0 0/); # First result (of 3 - 3) is skipped, and final result repeats the former
 @dicho_gt =  (qw/1 1 0 0 0 1/); # Greater than or equal to zero is an increase
 @dicho_lt =  (qw/0 1 0 0 0 0/); # Less than or equal to zero is a decrease

=back

=cut

sub swing {
    my $self = shift;
    my $args = ref $_[0] ? $_[0] : {@_};
    my $dat = ref $args->{'data'} ? $args->{'data'} : $self->read($args);
    croak __PACKAGE__, '::split All data must be numeric for dichotomizing about a split-value' if !$self->all_numeric($dat);
    $args->{'equal'} = 0 if ! defined $args->{'equal'}; #- no default??
    my ($i, $res, @seqs) = ();

    # Replace observations with the succession of rises and falls:
    for ($i = 0; $i < (scalar @{$dat} - 1); $i++) {
        $res = $dat->[($i + 1)] - $dat->[$i];
        if ($res > 0) {
            push @seqs, 1;
        }
        elsif ($res < 0) {
            push @seqs, 0;
        }
        else {
            if ($args->{'equal'} eq 'rpt') {
                push @seqs, $seqs[-1] if scalar @seqs; 
            }
            elsif ($args->{'equal'} eq 'gt') {
                push @seqs, 1;
            }
            elsif ($args->{'equal'} eq 'lt') {
                push @seqs, 0;
            }
            else {
                next;
            }
        }
    }
    $self->{'testdata'} = \@seqs;
    return \@seqs;
}

=head2 Numerical data: Two sequence dichotomization

See also the methods for categorical data where it is ok to ignore any order and intervals in your numerical data.

=head3 pool

 $data_aref = $seq->pool(data => [\@aref1, \@aref2]);
 $data_aref = $seq->pool(data => [$seq->read(index => 0), $seq->read(index => 1)]); # after $seq->load(\@aref1, \@aref2);
 $data_aref = $seq->pool(data => [$seq->read(label => '1'), $seq->read(label => '2')]); # after $seq->load(1 => \@aref1, 2 => \@aref2);

I<This is typically used for a Wald-Walfowitz test of difference between two samples - ranking by median.>

Constructs a single series out of two series of cached I<numerical> data as a ranked pool, i.e., by pooling the data from each series according to the magnitude of their values at each trial, from lowest to heighest. Specifically, the values from both samples are pooled and ordered from lowest to highest, and then dichotomized into runs according to the sample from which neighbouring values come from. Another run occurs wherever there is a change in the source of the values. A non-random effect of, say, higher or lower values consistently coming from one sample rather than another, would be reflected in fewer runs than expected by chance.

=cut

sub pool {
    my $self = shift;
    my $args = ref $_[0] ? $_[0] : {@_};
    my $dat = ref $args->{'data'} ? $args->{'data'} : $self->read($args);
    _check_numerical($self, $_) foreach @{$dat};
    my ($dat1, $dat2) = @{$dat};
    my $sum = scalar(@{$dat1}) + scalar(@{$dat2});
    my ($i, $x, $y, @seqs) = (0);
    my @dat = ();
    $dat[0] = [sort {$a <=> $b} @{$dat1}];
    $dat[1] = [sort {$a <=> $b} @{$dat2}];
    while (scalar(@seqs) < $sum) {
        $x = $dat[0]->[0];
        $y = $dat[1]->[0];
        $i = defined $x && defined $y ? $x < $y ? 0 : 1 : defined $x ? 0 : 1;
        shift @{$dat[$i]};
        push @seqs, $i;
    }
    $self->{'testdata'} = \@seqs;
    return \@seqs;
}
## DEV: consider: List::AllUtils::pairwise:
# @x = pairwise { $a + $b } @a, @b;   # returns index-by-index sums

=head2 Categorical data

=head3 match

 $data_aref = $seq->match(data => [\@aref1, \@aref2], lag => signed integer, loop => 0|1); # with optional crosslag of the two sequences
 $data_aref = $seq->match(data => [$seq->read(index => 0), $seq->read(index => 1)]); # after $seq->load(\@aref1, \@aref2);
 $data_aref = $seq->match(data => [$seq->read(label => '1'), $seq->read(label => '2')]); # after $seq->load(1 => \@aref1, 2 => \@aref2);

Reduce two lists of loaded data to two categories in a single array, according to the match between the elements at each index. Where the data-values are equal at a certain index, they will be represented with a 1; otherwise a 0. Numerical or stringy data can be equated. For example, the following two arrays would be reduced to the third, where a 1 indicates a match of identical values in the two data sources.

 @blues = (qw/1 3 3 2 1 5 1 2 4/);
 @reds =  (qw/4 3 1 2 1 4 2 2 4/);
 @dicho = (qw/0 1 0 1 1 0 0 1 1/);

The following options may be specified.

=over 4

=item data => [\@aref1, \@aref2]

Specify two referenced arrays; no data, or more than 2, gets a C<croak>.

=item lag => I<integer> (where I<integer> < number of observations I<or> I<integer> > -1 (number of observations) ) 

Match the two data-sets by shifting the first named set ahead or behind the other data-set by C<lag> observations. The default is zero. For example, one data-set might be targets, and another responses to the targets:

 targets   =	cbbbdacdbd
 responses =	daadbadcce

Matched as a single sequence of hits (1) and misses (0) where C<lag> = B<0> yields (for the match on "a" in the 6th index of both arrays):

 0000010000

With C<lag> => 1, however, each response is associated with the target one ahead of the trial for which it was observed; i.e., each target is shifted to its +1 index. So the first element in the above responses (I<d>) would be associated with the second element of the targets (I<b>), and so on. Now, matching the two data-sets with a B<+1> lag gives two hits, of the 4th and 7th elements of the responses to the 5th and 8th elements of the targets, respectively:

 000100100

making 5 runs. With C<lag> => 0, there are 3 runs. Lag values can be negative, so that C<lag> => -2 will give:

 00101010

Here, responses necessarily start at the third element (I<a>), the first hits occurring when the fifth response-element corresponds to the the third target element (I<b>). The last response (I<e>) could not be used, and the number of elements in the hit/miss sequence became n-C<lag> less the original target sequence. This means that the maximum value of lag must be one less the size of the data-sets, or there will be no data.

You can, alternatively, preserve all lagged data by looping any excess to the start or end of the criterion data. The number of observations will then always be the same, regardless of the lag. Matching the data in the example above with a lag of +1, with looping, creates an additional match between the final response and the first target (I<d>):

 1000100100

=item loop => 0|1

For circularized lagging), C<loop> => 1, and the size of the returned array is the same as those for the given data. For example, with a lag of +1, the last element in the "response" array is matched to the first element of the "target" array. 

=back

=cut

sub match {
    my $self = shift;
    my $args = ref $_[0] ? $_[0] : {@_};
    my $dat = ref $args->{'data'} ? $args->{'data'} : $self->read($args);
    $dat = $self->crosslag(lag => $args->{'lag'}, data => [$dat->[0], $dat->[1]], loop => $args->{'loop'}) if $args->{'lag'};
    my $lim = scalar @{$dat->[0]} <= scalar @{$dat->[1]} ? scalar(@{$dat->[0]}) : scalar(@{$dat->[1]}); # ensure criterion data-set is smallest
    my ($i, @seqs) = ();
    for ($i = 0; $i < $lim; $i++) {
        next if !defined $dat->[0]->[$i] || !defined $dat->[1]->[$i];
        $seqs[$i] = $dat->[0]->[$i] eq $dat->[1]->[$i] ? 1 : 0;
    }
    $self->{'testdata'} = \@seqs;
    return \@seqs;
}

=head3 binate

 $seq->binate(oneis => 'E'); # optionally specify a state in the sequence to be set as "1"
 $seq->binate(data => \@ari, oneis => 'E'); # optionally specify a state in the sequence to be set as "1"
 # $seq->binate(oneis => 'E', data => 'targets'); # no longer supported

A basic utility to convert a list of dichotomous categories into a list of 1s and zeroes, setting the first element in the list to 1 (or whatever is specified as "oneis") on all its occurrences in the list, and all other values in the list to zero. This is simply useful if you have categorical data with two states that, without assuming they have numerical properties, could still be assessed for, say, runs up-and-down, or turning-points. Naturally, this conversion is not meaningful, and should usually not be used, if the data are not categorically dichotomous, e.g., if they consist of the four DNA letters, or the five Zener symbols.

=cut

sub binate {
    my $self = shift;
    my $args = ref $_[0] ? $_[0] : {@_};
    my $dat = ref $args->{'data'} ? $args->{'data'} : $self->read($args);
    my $oneis = defined $args->{'oneis'} ? delete $args->{'oneis'} : $dat->[0];# What value set to 1 and others to zero?
    my $seqs = [map {$_ eq $oneis ? 1 : 0} @{$dat}]; # replace observations with 1s and 0s
    $self->{'testdata'} = $seqs;
    return $seqs;
}

=head2 Numerical or stringy data: Single sequence dichotimisation

=head3 shrink, boolwin

 $seq->shrink(winlen => number, rule => CODE)

This is a way to take non-overlapping slices, or windows, of a multinomial sequence of a given C<winlen>, and to make a true/false sequence out of them according to whether or not each slice passes a C<rule>. The C<rule> is a code reference that gets the data already L<load|load>ed as an array reference, and so might be something like this: 

 sub { return Statistics::Lite::mean(@$_) > 2 ? 1 : 0; }

If C<length> is set to 3, this rule would make the following numerical sequence of 9 elements shrink into the following dichotomous (Boolean) sequence of 3 elements:

 @data =  (1, 2, 3, 3, 3, 3, 4, 2, 1);
 @means = (2,       3,       2.5    );
 @dico =  (0,       1,       1      );

It's up to the user to make sure the C<rule> method returns boolean values to dichotomize the data, and that the given length makes up equally sized segments (no error is thrown if this isn't the case, the remainder just gets figured in the same way).

=cut

sub shrink {
    my $self = shift;
    my $args = ref $_[0] ? $_[0] : {@_};
    my $dat = ref $args->{'data'} ? $args->{'data'} : $self->read($args);
    my $lim = scalar @{$dat};
    my $len = int(delete $args->{'winlen'});
    $len ||= 1;
    my $code = delete $args->{'rule'};
    croak __PACKAGE__, '::shrink Need a code to Boolean shrink' if !$code or ref $code ne 'CODE';
    my ($i, @seqs);
    for ($i = 0; $i < $lim; $i += $len) {
        push @seqs, $code->([@{$dat}[$i .. ($i + $len - 1)]]);
    }
    $self->{'testdata'} = \@seqs;
    return \@seqs;
}
*boolwin = \&shrink;

sub _check_numerical {# check data for comparison: two arefs to return:
  my $self = shift;
  croak __PACKAGE__, ' All data in must be numerical for the requested operation' unless $self->all_numeric($_[0]);
  return 0;
}

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 REFERENCES

Burdick, D. S., & Kelly, E. F. (1977). Statistical methods in parapsychological research. In B. B. Wolman (Ed.), I<Handbook of parapsychology> (pp. 81-130). New York, NY, US: Van Nostrand Reinhold. [Describes window-boolean reduction.]

Swed, F., & Eisenhart, C. (1943). Tables for testing randomness of grouping in a sequence of alternatives. I<Annals of Mathematical Statistics>, I<14>, 66-87. [Describes pool method and test example.]

Wolfowitz, J. (1943). On the theory of runs with some applications to quality control. I<Annals of Mathematical Statistics>, I<14>, 280-288. [Describes swings "runs up and down" and test example.]

=head1 TO DO

Sort option for pool method ?

=head1 BUGS

Please report any bugs or feature requests to C<bug-Statistics-Data-Dichotomize-0.02 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Data-Dichotomize-0.02>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Data::Dichotomize

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Data-Dichotomize-0.02>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Data-Dichotomize-0.02>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Data-Dichotomize-0.02>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Data-Dichotomize-0.02/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Roderick Garton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Statistics::Data::Dichotomize
