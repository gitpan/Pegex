#line 1
package TestML;
use strict;
use warnings;
use 5.006001;

use TestML::Runtime;

$TestML::VERSION = '0.20';

our @EXPORT = qw(str num bool list WWW XXX YYY ZZZ);

our $DumpModule = 'YAML::XS';
sub WWW { require XXX; local $XXX::DumpModule = $DumpModule; XXX::WWW(@_) }
sub XXX { require XXX; local $XXX::DumpModule = $DumpModule; XXX::XXX(@_) }
sub YYY { require XXX; local $XXX::DumpModule = $DumpModule; XXX::YYY(@_) }
sub ZZZ { require XXX; local $XXX::DumpModule = $DumpModule; XXX::ZZZ(@_) }

sub str { TestML::Str->new(value => $_[0]) }
sub num { TestML::Num->new(value => $_[0]) }
sub bool { TestML::Bool->new(value => $_[0]) }
sub list { TestML::List->new(value => $_[0]) }

sub import {
    my $run;
    my $bridge = '';
    my $testml;
    my $skipped = 0;

    strict->import;
    warnings->import;

    if (@_ > 1 and $_[1] eq '-base') {
        goto &TestML::Base::import;
    }

    my $pkg = shift;
    while (@_) {
        my $option = shift(@_);
        my $value = (@_ and $_[0] !~ /^-/) ? shift(@_) : '';
        if ($option eq '-run') {
            $run = $value || 'TestML::Runtime::TAP';
        }
        # XXX - 2010-08-22
        elsif ($option eq '-document') {
            die "TestML '-document' option has been changed to '-testml'";
        }
        elsif ($option eq '-testml') {
            $testml = $value;
        }
        elsif ($option eq '-bridge') {
            $bridge = $value;
        }
        # XXX skip_all should call skip_all() from runner subclass
        elsif ($option eq '-skip_all') {
            my $reason = $value;
            die "-skip_all option requires a reason argument"
                unless $reason;
            $skipped = 1;
            require Test::More;
            Test::More::plan(
                skip_all => $reason,
            );
        }
        elsif ($option eq '-require_or_skip') {
            my $module = $value;
            die "-require_or_skip option requires a module argument"
                unless $module and $module !~ /^-/;
            eval "require $module; 1" or do {
                $skipped = 1;
                require Test::More;
                Test::More::plan(
                    skip_all => "$module failed to load"
                );
            } 
        }
        else {
            die "Unknown option '$option'";
        }
    }

    sub END {
        no warnings;
        return if $skipped;
        if ($run) {
            eval "require $run; 1" or die $@;
            $bridge ||= 'main';
            $run->new(
                testml => ($testml || \ *main::DATA),
                bridge => $bridge,
            )->run();
        }
        elsif ($testml or $bridge) {
            die "-testml or -bridge option used without -run option\n";
        }
    }

    require Exporter;
    @_ = ($pkg);
    goto &Exporter::import;
}

1;

=encoding utf-8

#line 199
