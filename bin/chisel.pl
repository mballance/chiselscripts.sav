#!/usr/bin/perl
#****************************************************************************
#* chisel.pl
#*
#* Front-end scripts to Chisel3 workflow
#*
#* chisel.pl [command] options] [files_and_directories]
#*
#* By default, 
#****************************************************************************

use Cwd 'abs_path';
use File::Basename;

$chisel_pl=abs_path($0);
$chiselscripts_bindir=dirname($chisel_pl);
$chiselscripts_dir=dirname($chiselscripts_bindir);
$chiselscripts_libdir="$chiselscripts_dir/lib";

$cmd=$ARGV[0];

sub printhelp();
sub compile();
sub generate();
sub collect_jars($);
sub run_java(@);

for ($i=0; $i<=$#ARGV; $i++) {
	if ($ARGV[$i] eq "-help" || 
		$ARGV[$i] eq "--help" ||
		$ARGV[$i] eq "-h" ||
		$ARGV[$i] eq "--h" ||
		$ARGV[$i] eq "-?") {
		printhelp();
		exit(0);
	}
}

if ($cmd eq "compile") {
	compile();
} elsif ($cmd eq "generate") {
	generate();
} elsif ($cmd eq "") {
	print "Error: no sub-command specified\n";
	printhelp();
	exit(1);	
} else {
	print "Error: unknown sub-command $cmd\n";
	printhelp();
	exit(1);
}

sub printhelp() {
	
}

sub compile() {
	my($classpath) = collect_jars($chiselscripts_libdir . "/cache");
	my(@cmdline,@files);
	my($arg,$classdir);
	
	for ($i=1; $i<=$#ARGV; $i++) {
		$arg=$ARGV[$i];
		
		if ($arg =~ /^-/) {
			if ($arg eq "-classdir") {
				$i++;
				$classdir=$ARGV[$i];
			} elsif ($arg eq "-classpath") {
				$i++;
				$classpath .= ":" . $ARGV[$i];
			} else {
				print "Error: unknown compile option $arg\n";
				printhelp();
				exit(1);
			}
		} else {
			if (-f $arg) {
				push(@files, $arg);
			} elsif (-d $arg) {
				# Directory
			} else {
				print "Error: unknown argument $arg\n";
				printhelp();
				exit(1);
			}
		}
	}
	
	if ($classdir eq "") {
		$classdir = "class";
	}
	
	unless (-d $classdir) {
		system("mkdir -p $classdir");
	}
	
	push(@cmdline, "-classpath");
	push(@cmdline, $classpath);
	push(@cmdline, "scala.tools.nsc.Main");
	
	push(@cmdline, "-d");
	push(@cmdline, $classdir);
	
	push(@cmdline, @files);

	run_java(@cmdline);
}

sub generate() {
	my($classpath) = collect_jars($chiselscripts_libdir . "/cache");
	my(@cmdline,@args);
	
	for ($i=1; $i<=$#ARGV; $i++) {
		$arg=$ARGV[$i];
		
		if ($arg =~ /^-/) {
			if ($arg eq "-classdir") {
				$i++;
				$classdir=$ARGV[$i];
			} elsif ($arg eq "-classpath") {
				$i++;
				$classpath .= ":" . $ARGV[$i];
			} else {
				print "Error: unknown compile option $arg\n";
				printhelp();
				exit(1);
			}
		} else {
			push(@args, $arg);
		}
	}
	
	if ($classdir eq "") {
		$classdir = "class";
	}

	$classpath = $classdir . ":" . $classpath;	

	push(@cmdline, "-classpath");
	push(@cmdline, $classpath);
	push(@cmdline, "scala.tools.nsc.MainGenericRunner");
	push(@cmdline, @args);
	
	run_java(@cmdline);	
}

sub collect_jars($) {
	my($lib_dir) = @_;
	my($classpath);
	
	opendir(my $dir, $lib_dir) or die $!;

	while (my $file = readdir($dir)) {
		if ($file =~ /.jar/) {
			if ($classpath eq "") {
				$classpath = $lib_dir . "/" . $file;
			} else {
				$classpath .= ":" . $lib_dir . "/" . $file;
			}
		}
	}
	
	closedir($dir);
	
	return $classpath;
}

sub run_java(@) {
	my(@jargs) = @_;
	my(@args);
	
	push(@args, "java");
	push(@args, "-Dscala.home=" . $chiselscripts_dir);
	push(@args, "-Dscala.usejavacp=true");
	push(@args, @jargs);
	
	print "args=@args\n";
	
	system(@args) == 0 or die "java failed to run @args\n";
}


