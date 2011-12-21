use MaRa::weblint;
use MaRa::NottsBAprefs;
use File::Copy;
main();

#Main - All html files in top level directory
sub main {

	definitions();
        nextlevel($topdevlib);

        sleep 10;

}

#Generic Definitions
sub definitions {
	print "Initialising...\n";

        $scripts=$MaRa::NottsBAprefs::scripts;
	$templates=$MaRa::NottsBAprefs::templates;
	$topdevlib=$MaRa::NottsBAprefs::topdevlib;
	$toptemplib=$MaRa::NottsBAprefs::toptemplib;
	$toplivelib=$MaRa::NottsBAprefs::toplivelib;

        @head=("startblock","head","logo","endblock");
        @foot=("startblock","sp","home","br","lastupdate","ep","foot","endblock");

# get todays date
        $date = scalar localtime(time);
# strip out the time & replace with a comma
	$date=~s/\s\d+:\d+:\d+/,/;
# swap month & day number
        $date=~s/(\w+) (\d+)/$2 $1/;
        
        $searchfile="skip.txt";
        print "$scripts/$searchfile";
        open(searchfile, "$scripts/$searchfile") or print "1.Can't find $searchfile: $!\n";
        @skip=<searchfile>;
        close(searchfile);
        print " -- $scripts/$searchfile";

}

sub nextlevel {

         my($nextsource)=@_;

         chdir $nextsource;

         opendir(DIR,$nextsource) || die "$!";
         my(@nextlisting)=readdir DIR;
         closedir(DIR);

         my($nexttemplib)=$nextsource;
         $nexttemplib=~s/$topdevlib/$toptemplib/gi;
         mkdir($nexttemplib);
         my($nextsite)=$nextsource;
         $nextsite=~s/$topdevlib/$toplivelib/gi;
         mkdir($nextsite);

	 $count=0;
	 foreach $item (@nextlisting)	{

                 $source=$nextsource;
                 $templib=$nexttemplib;
                 $site=$nextsite;
                 
                 $itempath=$source.'/'.$item;
                 
                if ($item ne "." && $item ne ".." && $item ne $source) {

                   $count++;

                   $skiptonext=0;
                   foreach $skip (@skip) {
                           chomp $skip;
                           $test=$topdevlib."/".$skip;
                           if ($itempath=~m|$test|) {
                           if ($skip!="clubs/*") {
#                              print "\nSkipping : ".$itempath;
                              $skiptonext=1;
                              last;
                           }
                           }
                   }

                   if (-d $itempath) {
                        $_=$item;
                      if (!m|clubs|) {
                         next;                            # jump to next file
                      }
                      print "\nProcessing : ".$itempath;
                      nextlevel($itempath);
                   }
                   else {
                        $_=$item;

                        if (m/nba_.*.htm/ && !$skiptonext) {
                           print "\n *CVT : ".$item;
                           $document=$item;
                           $clubpage=$item;
                           $clubpage=~s/nba_//gi;
                           parsehtml();
                           updatelive();
#                           testupdatelive();
                        }
                   }

                }
	 }

}

sub parsehtml {

	outfile($templib,$document);

        $doctitle=$document;
        $doctitle=~s|.html*||;
        $doctitle=~s|nba_||;
        $doctitle=~s|_||;
        $title="NottsBA : ".$doctitle;
        
	chdir($source);
	$infile="<".$document;

	open($handle, $infile) or print "2.Can't find $file1: $!\n";
	undef $/;
	$indata=<$handle>;
	close $handle;
        $/ = "\n";	

#	@outdata=myscoff($indata);
	@outdata=clubslurp($indata);

#        standard(@head);

        print $outhandle @outdata;
	print $outhandle "\n";

#        standard(@foot);

	close $outhandle;
}


sub updatelive	{
	$live=$site."/".$document;
	$temp=$templib."/".$document;

        $same=mycomparefiles($live,$temp);

	if ($same ne 1)	{

                        copy($temp,$live);

#			outfile($site,$document);

 #			chdir($site);
#			$outfile=">".$document;
#                 	open($outhandle, $outfile) or print "Can't find $outfile: $!\n";

#			chdir($templib);
#			$infile="<".$document;
#			scoff($inhandle,$infile);
	
#			close $outhandle;
			print " - updated";
	}	else	{
			print " - no change";
	}
}

sub testupdatelive	{
	$live=$site."/".$document;
	$temp=$templib."/".$document;

        $same=mycomparefiles($live,$temp);

	if ($same ne 1)	{
			print " - will be updated";
	}	else	{
			print " - no changes";
	}
}

#Open Outfile
sub outfile {

	my($path,$file)=@_;
	mkdir($path,0755);
	chdir($path);
	$outfile=">".$file;
	open($outhandle, $outfile);

}


#Copy from standard templates
sub standard {

	my(@templates)=@_;

	chdir($templates);
	
	foreach $template (@templates)	{
	
		$infile="<".$template.".txt";
		scoff($inhandle,$infile);
	}

}


sub scoff	{
	my($handle,$file)=@_;
	open($handle, $file) or print "3.Can't find $file: $!\n";
	while (<$handle>) {
                s|(<title>).*(</title>)|$1$title$2|gi;
		s|<MAINFOLDER>|$main|gi;
		s|<DATE>|$date|gi;
                s|<clubfile>||gi;
                s|<clubname>||gi;
		print $outhandle $_;
	}
	close $handle;
}

sub clubslurp 	{

    foreach $_ (@_)    {

		s|\n|~~~|gi;   # temoporarily remove line breaks

		s|<!--START[^£]*£-->||gi;   #get rid of old autotext blocks

		s|<title[^<]*</title>||gi;
		s|</title>||gi;
		s|<html[^>]*>||gi;
		s|</html>||gi;
		s|<head[^>]*>||gi;
		s|</head>||gi;
		s|<body[^>]*>||gi;
		s|</body>||gi;
 		s|<meta[^>]*>||gi;

 		s|(</*)FONT|$1font|gi;   # ensure lower case tags
		s|(</*)TBODY|$1tbody|gi;
		s|(</*)H|$1h|gi;
		s|(</*)TR|$1tr|gi;
		s|(</*)TD|$1td|gi;
		s|(</*)P|$1p|gi;
		s|(</*)img|$1img|gi;

 		s|(<img[^>]*)/>|$1>|gi;     # ensure all tags
 		s|(<img[^>]*)>|$1 />|gi;    # are properly closed
		s|<br>|<br />|gi;
		s|<hr>|<hr />|gi;

		s|Results Service Coming Soon|<a href="../summaries/$clubpage">Results Summary</a> Page|gi;

		s|(<[^>]*)~~~([^>]*>)|$1 $2|gi;  # join split tags
		s|(\w{1,})\=(\w{1,})|$1="$2"|g;  # add quotes to attributes

                s|.*<table([^<].*)<tbody|<table$1<tbody|gi;
                s|</table([^<].*)<p([^<].*)<img.*|</table>|gi;

		s|~~~|\n|gi;

        }
      return @_;
}