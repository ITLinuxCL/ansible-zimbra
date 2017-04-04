#!/bin/perl
use Data::Dumper;
my %urls = {};
$urls{NETWORK} = {};
$urls{OSS} = {};

my $REPO_LIST_URL="https://raw.githubusercontent.com/jorgedlcruz/zimbra_bits/master/README.md";
my $TEMP_DWL="/tmp/zimbra_urls";
my $ZM_REPO_URL="https://files.zimbra.com/downloads/";
my $URL_RGXP = "grep https | egrep -v 'patch|sha256|md5' ";

my $DOWNLOAD_COMMAND="curl -k $REPO_LIST_URL | $URL_RGXP | awk -F \"$ZM_REPO_URL\" '{print \$2}' | sed -e 's/\.tgz//'> $TEMP_DWL";

system($DOWNLOAD_COMMAND);
open(URLS, $TEMP_DWL) or die "Couldn't open file $TEMP_DWL, $!";

while(<URLS>) {
	chomp($_);
	my $url = $_;
	$url =~ s/\s+$//;
	my ($version, $file) = split('/', $url);
	my $file_info = getFileInfo($file);
	my $zimbra_distro = $file_info->{zimbra_distro};
	my $os_info = $file_info->{os_info};
	my $file_extension = $file_info->{file_extension};
	
	if (!$urls{$zimbra_distro}{$version}) {
		$urls{$zimbra_distro}{$version} = {};
	}

	if (!$urls{$zimbra_distro}{$version}{$os_info}) {
		$urls{$zimbra_distro}{$version}{$os_info} = {};
	}

	if($version) {
		$urls{$zimbra_distro}{$version}{$os_info} = $file;
	}
}

print "_zimbra_urls:\n";
printYAML("NETWORK");
print "\n";
printYAML("OSS");

sub printYAML {
	my ($zimbra_distro) = @_;
	print("  \L$zimbra_distro:\n");
	foreach my $zimbra_ver ( keys $urls{$zimbra_distro} ) {
	  if ($zimbra_ver) {
	  	print "    $zimbra_ver:\n";
		
		foreach my $os_info ( keys $urls{$zimbra_distro}{$zimbra_ver} ) {
		  print "      $os_info: $urls{$zimbra_distro}{$zimbra_ver}{$os_info}\n";
		}
	  }
	}
}

sub getFileInfo {
	my ($file) = @_;
	my @tmpAry = split(/\./, $file);
	my $file_extension = $tmpAry[-1];
	my ($distro, $os_arch) = split('_', $tmpAry[3]);
	my $arch = $os_arch == 64 ? "x86_64" : "x86";

	my %result = {};
	$result{os_info} = $distro."_".$arch;
	$result{file_extension} = $file_extension;
	$result{zimbra_distro} = $file =~ /NETWORK/ ? "NETWORK" : "OSS";

	return(\%result);
}
