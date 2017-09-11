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
use POSIX "uname";
use IO::Compress::Zip qw(zip $ZipError) ;
use File::Temp qw(tempdir);
use File::Path qw(rmtree);

$chisel_pl=abs_path($0);
$chiselscripts_bindir=dirname($chisel_pl);
$chiselscripts_dir=dirname($chiselscripts_bindir);
$chiselscripts_libdir="$chiselscripts_dir/lib";

($sysname,$nodename,$release,$version,$machine) = POSIX::uname();

if ($sysname =~ /CYGWIN/) {
	$pathsep=";";
} else {
	$pathsep=":";
}


$cmd=$ARGV[0];

sub printhelp();
sub compile();
sub generate();
sub collect_jars($);
sub run_java(@);

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
	my(@cmdline,@files,@dirstack);
	my($arg,$classdir,$output);
	my($proc_options) = 1;
	my($delete_classdir) = 1;
	
	for ($i=1; $i<=$#ARGV; $i++) {
		$arg=$ARGV[$i];
		
		if ($arg =~ /^-/) {
			if ($arg eq "-classdir") {
				$i++;
				$classdir=$ARGV[$i];
				$delete_classdir = 0;
			} elsif ($arg =~ /^-L/) {
				$arg = substr($arg, 2);
				if ($classpath eq "") {
					$classpath .= resolve_path($arg);
				} else {
					$classpath .= $pathsep . resolve_path($arg);
				}
			} elsif ($arg eq "-classpath") {
				$i++;
				if ($classpath eq "") {
					$classpath .= resolve_path($ARGV[$i]);
				} else {
					$classpath .= $pathsep . resolve_path($ARGV[$i]);
				}
			} elsif ($arg eq "-o") {
				$i++;
				$output = $ARGV[$i];
			} else {
				print "Error: unknown compile option $arg\n";
				printhelp();
				exit(1);
			}
		} else {
			$proc_options = 0;
			if (-f $arg) {
				push(@files, $arg);
			} elsif (-d $arg) {
				my($dir) = $arg;
				my(@dirstack);
				
				push(@dirstack, $dir);
				
				# Directory
				do {
					$dir = pop(@dirstack);
					
					opendir (my $dh, $dir);
					
					while (my $file = readdir($dh)) {
						unless ($file eq "." || $file eq "..") {
							if ( -d "$dir/$file") {
								push(@dirstack, "$dir/$file");
							} else {
								push(@files, "$dir/$file");
							}
						}
					}
					closedir($dh);
				} while ($#dirstack >= 0);
			} else {
				print "Error: unknown argument $arg\n";
				printhelp();
				exit(1);
			}
		}
	}
	
	if ($classdir eq "") {
		$classdir = tempdir("chisel_XXXXXX");
		print "classdir=$classdir\n";
	}
	
	if ($output eq "") {
		$output = "output.zip";
	}
	
	unless (-d $classdir) {
		system("mkdir -p $classdir");
	}
	
	if ($#files < 0) {
		die "No source files specified";
	}
	
	push(@cmdline, "-classpath");
	push(@cmdline, $classpath);
	push(@cmdline, "scala.tools.nsc.Main");
	
	push(@cmdline, "-d");
	push(@cmdline, $classdir);
	
	push(@cmdline, @files);
	
	run_java(@cmdline);

	my(@classes) = collect_classes($classdir);
	zip	\@classes => $output,
		FilterName => sub { s[^$classdir/][] } ;
		
	if ($delete_classdir) {
		rmtree($classdir);
	}
}

sub collect_classes($) {
	my($classdir) = @_;
	my(@classes,@dirstack);
	my($dir);
	
	push(@dirstack, $classdir);
	
	do {
		$dir = pop(@dirstack);
		
		opendir (my $dh, $dir);
					
		while (my $file = readdir($dh)) {
			unless ($file eq "." || $file eq "..") {
				if ( -d "$dir/$file") {
					push(@dirstack, "$dir/$file");
				} elsif ($file =~ /.class$/) {
					push(@classes, "$dir/$file");
				}
			}
		}
		closedir($dh);
	} while ($#dirstack >= 0);
	
	return @classes;
}

sub generate() {
	my($classpath) = collect_jars($chiselscripts_libdir . "/cache");
	my(@cmdline,@args);
	my($proc_options) = 1;
	
	for ($i=1; $i<=$#ARGV; $i++) {
		$arg=$ARGV[$i];
		
		if ($proc_options && $arg =~ /^-/) {
			if ($arg eq "-classdir") {
				$i++;
				$classdir=$ARGV[$i];
			} elsif ($arg eq "-classpath") {
				$i++;
				$classpath .= $pathsep . $ARGV[$i];
			} elsif ($arg =~ /^-L/) {
				$arg = substr($arg, 2);
				if ($classpath eq "") {
					$classpath .= resolve_path($arg);
				} else {
					$classpath .= $pathsep . resolve_path($arg);
				}				
			} else {
				print "Error: unknown generate option $arg\n";
				printhelp();
				exit(1);
			}
		} else {
			$proc_options = 0;
			push(@args, $arg);
		}
	}
	
#	if ($classdir eq "") {
#		$classdir = "class";
#	}
#
#	$classpath = $classdir . $pathsep . $classpath;	

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
			my($path) = resolve_path($lib_dir . "/" . $file);
			
			if ($classpath eq "") {
				$classpath = $path;
			} else {
				$classpath .= $pathsep . $path;
			}
		}
	}
	
	closedir($dir);
	
	return $classpath;
}

sub resolve_path($) {
	my($path) = @_;
	
	if ($sysname =~ /CYGWIN/ && $path =~ /^\/cygdrive/) {
		$path =~ s%/cygdrive/([a-zA-Z])%$1:%;
	}

	return $path;	
}

sub run_java(@) {
	my(@jargs) = @_;
	my(@args);
	
	push(@args, "java");
	push(@args, "-Dscala.home=" . $chiselscripts_dir);
	push(@args, "-Dscala.usejavacp=true");
	push(@args, @jargs);
	
#	print "args=@args\n";
	
	system(@args) == 0 or die "java failed to run @args\n";
}


