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

use Cwd;
use Cwd 'abs_path';
use File::Basename;
use POSIX "uname";
use IO::Compress::Zip qw(zip $ZipError) ;
use File::Temp qw(tempdir);
use File::Path qw(rmtree);
use IO::Handle;

$| = 1; # Force auto-flush of stdout

$chisel_pl=abs_path($0);
$chiselscripts_bindir=dirname($chisel_pl);
$chiselscripts_dir=dirname($chiselscripts_bindir);
$chiselscripts_libdir="$chiselscripts_dir/lib";

($sysname,$nodename,$release,$version,$machine) = POSIX::uname();

# print "sysname=$sysname\n";
if ($sysname =~ /CYGWIN/ || $sysname =~ /MINGW/ || $sysname =~ /MSYS/) {
	$pathsep=";";
} else {
	$pathsep=":";
}

# $ENV{MSYS2_ARG_CONV_EXCL}="*";

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
				$output = resolve_path($ARGV[$i]);
			} else {
				print "Error: unknown compile option $arg\n";
				printhelp();
				exit(1);
			}
		} else {
			$proc_options = 0;
			if (-f $arg) {
				push(@files, resolve_path($arg));
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
								push(@dirstack, resolve_path("$dir/$file"));
							} else {
								push(@files, resolve_path("$dir/$file"));
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
	}
	
	if ($output eq "") {
		$output = "output.jar";
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
	
	print("Note: compiling Chisel library ${output}\n");
	select(STDOUT)->flush();
	
	run_java(@cmdline);

#    my($output_a) = abs_path($output);
    print "output=$output\n";
    my($output_dir) = abs_path(dirname($output));
    my($output_file) = basename($output);
    print("dirname(output)=$output_dir output_file=$output_file\n");
    
     my($classdir_a) = abs_path($classdir);
#    my($cwd) = getcwd();
#	chdir($clssdir_a);
#    my($new_cwd) = getcwd();
#    print "CWD=$new_cwd afer chdir to $classdir_a\n";
    system("cd $classdir_a ; zip -r ${output_dir}/${output_file} *")
            && die "Failed to create ${output_dir}/${output_file}";

#    print("--> collect_classes\n");
#	my(@classes) = collect_classes(".");
#    print("<-- collect_classes\n");
#	zip	\@classes => $output,
#		FilterName => sub { s[^$classdir/][] } ;
#    print("--> zip\n");
#	zip	\@classes => $output_a;
#    print("<-- zip\n");

#    chdir($cwd);
		
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
	my($generator) = "";
	my($outdir) = "";
	
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
			} elsif ($arg eq "-outdir") {
				$i++;
				$outdir = $ARGV[$i];
			} else {
				print "Error: unknown generate option $arg\n";
				printhelp();
				exit(1);
			}
		} else {
			$proc_options = 0;
			if ($generator eq "") {
				$generator = $arg;
			}
			push(@args, $arg);
		}
	}
	
#	if ($classdir eq "") {
#		$classdir = "class";
#	}
#
#	$classpath = $classdir . $pathsep . $classpath;	

	print("Note: Running Chisel generator ${generator}\n");
	select(STDOUT)->flush();
	push(@cmdline, "-classpath");
	push(@cmdline, $classpath);
	push(@cmdline, "scala.tools.nsc.MainGenericRunner");
	
	unless ($outdir eq "") {
		my($outdir_name) = basename($outdir);
		
		print "outdir_name=$outdir_name outdir=$outdir\n";
		
		if (-d $outdir) {
			# Clean up first
			print "Removing outdir $outdir\n";
			system("rm -rf $outdir");
		}
		print "Creating outdir $outdir\n";
		system("mkdir -p $outdir");	
		push(@args, "-o");
		push(@args, resolve_path($outdir) . "/${outdir_name}_tmp.v");
	}
	push(@cmdline, @args);
	
	run_java(@cmdline);	
	
	unless ($outdir eq "") {
		my($header);
		my($line);
		my($done) = 0;
		my($outdir_r) = resolve_path(abs_path($outdir));
		my($outdir_name) = basename($outdir);
		my($module_name);
		
		print "outdir_name=$outdir_name outdir=$outdir\n";
		
		print "Post-processing output file\n";
		open(my $fh, "<", "$outdir/${outdir_name}_tmp.v") || 
			die "Failed to open root module file $outdir/${outdir_name}.v";
		open(my $fh_f, ">", "$outdir/${outdir_name}.f") || 
			die "Failed to open filelist $outdir/${outdir_name}.f";
		
		# First read all lines leading up to the first module
		while (<$fh>) {
			$line = $_;
			if ($line =~ /^module /) {
				last;
			} else {
				$prefix .= $line;
			}
		}

		while ($done == 0) {
			# Already have $line
			$module_name = $line;
			chomp($module_name);
			$module_name =~ s/^module ([a-zA-Z0-9_][a-zA-Z0-9_]*).*$/$1/g;
			print "Create module file $outdir/${module_name}.v\n";
			open(my $fh_m, ">", "$outdir/${module_name}.v") || 
				die "Failed to open module file $outdir/${module_name}.v";
			print $fh_m "$prefix";
			print $fh_m "$line"; # module declaration
			print $fh_f "${outdir_r}/${module_name}.v\n";
			
			while (1) {
				$line = <$fh>;
			
				if ($line eq "") {
					print "Done\n";
					$done = 1;
					last;
				} else {
					if ($line =~ /^module /) {
						last;
					} else {
						print $fh_m "$line";
					}
				}
			}
			close($fh_m);
		}	
		close($fh_f);
		close($fh);
		system("rm -f $outdir/${outdir_name}_tmp.v");
	}
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
	} elsif ($sysname =~ /MSYS/ || $sysname =~ /MINGW/) {
		$path =~ s%^/([a-zA-Z])%$1:%;
	}

	return $path;	
}

sub run_java(@) {
	my(@jargs) = @_;
	my(@args);
	
	push(@args, "java");
	push(@args, "-Dscala.home=" . resolve_path($chiselscripts_dir));
	push(@args, "-Dscala.usejavacp=true");
	push(@args, @jargs);
	
#	print "args=@args\n";
	
	system(@args) == 0 or die "java failed to run @args\n";
}


