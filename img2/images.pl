#!/usr/bin/perl

#use CGI::Carp 'fatalsToBrowser';

my $dst_path = $ENV{'CGI_DESTINATION_PATH'};
my $src_path = $ENV{'CGI_SOURCE_PATH'};
my $thumb_xsize = $ENV{'CGI_X_SIZE'};
my $thumb_ysize = $ENV{'CGI_Y_SIZE'};
my $jpg_quality = $ENV{'CGI_QUALITY'}|| 75;
my $in_img = $ENV{'CGI_IMAGE_NAME'};
$in_img =~ s/\.\.//g;
$in_img =~ s/[^\d\w\_\-\.]//g;

#print "Content-type: text/plain\n\n";

use Image::Magick;

if(!(-f "$src_path/$in_img")){
	die ("File $in_img not found.\n");
}

if(!(-d "$dst_path/")){
	mkdir("$dst_path/",0755);
}

my($q, $x);
$q = Image::Magick->new;
$x = $q->Read("$src_path/$in_img");
die ("$x\n") if "$x";

($x_size, $y_size) = $q->Get('width', 'height');

if($x_size == 0 || $y_size == 0){
	die ("Image $in_img size error.\n");
}

if((! defined $thumb_xsize || $thumb_xsize == 0) && (! defined $thumb_ysize || $thumb_ysize == 0)){
	die ("\$.CGI_X_SIZE or \$.CGI_Y_SIZE size must be defined.\n");
}

if($thumb_xsize > 0 && (! defined $thumb_ysize)){
	$thumb_ysize = $thumb_xsize * $y_size / $x_size;
}

if($thumb_ysize > 0 && (! defined $thumb_xsize)){
	$thumb_xsize = $thumb_ysize * $x_size / $y_size;
}

$x = $q->Scale(width=>$thumb_xsize, height=>$thumb_ysize); 
die ("$x\n") if "$x";

if($in_img =~ /^.*\.(jp(?=[eg])e?g?|png)$/i){
	$q->Set(quality=>$jpg_quality);
}

if($in_img =~ /^.*\.(gif)$/i){
	$q->Set(compression=>LZW);
}

$x = $q->Write("$dst_path/$in_img");
die ("$x\n") if "$x";