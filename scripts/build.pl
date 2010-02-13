#!/usr/bin/perl

use warnings;
use strict;
use Config;
use File::Copy;
use Config::AutoConf;
use Config::AutoConf::Linker;
use ExtUtils::CBuilder;



## Build PODs
print "\nBuilding manpages...\n";
my @pods = <btparse/doc/*.pod>;
for my $pod (@pods) {
    my $man = $pod;
    $man =~ s!pod$!3!;
    print " - $pod to $man\n";
    `pod2man --section=3 --center="btparse" --release="btparse, version $VERSION" $pod $man`;
    move($man, 'blib/man3/');
}

my %programs =
  (
   ## Build dumpnames (noinst)
   ## DONE ## "btparse/progs/dumpnames" => ["btparse/progs/dumpnames.c"],

   ## Build biblex (noinst)
   ## DONE ## "btparse/progs/biblex" => ["btparse/progs/biblex.c"],

   ## Build bibparse
   ## DONE ## "btparse/progs/bibparse" => [map {"btparse/progs/$_"} qw!bibparse.c args.c getopt.c getopt1.c!],

   ## Tests
   ## DONE ## "btparse/tests/simple_test" => [map {"btparse/tests/$_"} qw!simple_test.c testlib.c!],
   ## DONE ## "btparse/tests/read_test" => [map {"btparse/tests/$_"} qw!read_test.c testlib.c!],
   ## DONE ## "btparse/tests/postprocess_test" => ["btparse/tests/postprocess_test.c"],
   # These are developers tests
   ## DONE ## "btparse/tests/macro_test" => ["btparse/tests/macro_test.c"],
   ## DONE ## "btparse/tests/case_test" => ["btparse/tests/case_test.c"],
   ## DONE ## "btparse/tests/name_test" => ["btparse/tests/name_test.c"],
   ## DONE ## "btparse/tests/purify_test" => ["btparse/tests/purify_test.c"],
  );

for my $prog (keys %programs) {
    my_link_program($CC, $CCL, "$prog$EXE", @{$programs{$prog}});
}
copy("btparse/progs/bibparse", "blib/bin");
copy("btparse/src/libbtparse$LIBEXT", "blib/lib");


open DUMMY, ">_dummy_" or die "Can't create timestamp file";
print DUMMY localtime;
close DUMMY;
print "\n -- back to normal Perl build system\n\n";

sub get_version {
    my $version = undef;
    open PM, "BibTeX.pm" or die "Cannot open file [BibTeX.pm] for reading\n";
    while(<PM>) {
        if (m!^our\s+\$VERSION\s*=\s*'([^']+)'!) {
            $version = $1;
            last;
        }
    }
    close PM;
    die "Could not find VERSION on your .pm file. Weirdo!\n" unless $version;
}


sub my_link_program {
    my ($CC,$CCL, $program, @sources) = @_;

    print "\nCompiling ${program}...\n";
    my @objects = map {
        $CC->compile(include_dirs => ['btparse/src','btparse/pccts'],
                     source => $_ )
    } @sources;

    $CCL->($CC,
           exe_file => $program,
           extra_linker_flags => "-Lbtparse/src -lbtparse ",
           objects => \@objects);
}

sub interpolate {
	my ($from, $to, %config) = @_;
	
	print "Generating $to...\n";
	open FROM, $from or die "Cannot open file [$from] for reading.\n";
	open TO, ">", $to or die "Cannot open file [$to] for writing.\n";
	while (<FROM>) {
		s/\[%\s*(\S+)\s*%\]/$config{$1}/ge;		
		print TO;
	}
	close TO;
	close FROM;
}
