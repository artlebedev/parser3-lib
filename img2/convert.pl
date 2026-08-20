#!/usr/bin/perl

#use CGI::Carp 'fatalsToBrowser';

my $file_image = $ENV{'CGI_FILE_IMAGE'};
my $format = $ENV{'CGI_FORMAT'};

#print "Content-type: text/plain\n\n";

use Image::Magick;

if(!(-f "$file_image")){
	die ("File $file_image not found.\n");
}

my($q, $x);
$q = Image::Magick->new;
$x = $q->Read("$file_image");
die ("$x\n") if "$x";

if(defined $format){
	$q->Set(magick=>$format);
	$file_image =~ s/^(.*?)temp_(.*?\.)[a-z]{3,4}$/$1$2$format/i;
	$x = $q->Write("$file_image");
	die ("$x\n") if "$x";
}