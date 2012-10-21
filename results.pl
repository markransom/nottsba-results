
main();

#Main
sub main {

	$club      = "testclub";
	$newseason = "2012-2013";

	definitions();

	print "\n\nProcessing Current Season Results...";
	loadnew();
	folderloop();
	print "\n\n";
}

#loop clubs
sub folderloop {
	$count = 0;
	print $year."\n";
	foreach $folder (@folders) {

		assessfiles();

		foreach $document (@documents) {
			$count++;

			print "\n";
			processdoc();
			updatelive();

		}

	}
}

#loadnew
sub loadnew {
	$previous = 0;
	getnewyear();
	@folders = ( "ladies", "mixed", "mens" );
}

# new season details
sub getnewyear {
	$year = $newseason;
}

#Generic Definitions
sub definitions {
	print "Initialising...\n";

	use Cwd;
	$here=getcwd;

    	$templates=$here."/Templates";
	$toptemplib=$here."/temp";
	$toplivelib=$here."/live";
#	$topdevlib="C:/NottsBA";
	$topdevlib=$here."/source";

	$main = $here;

}

#Main - All html files in directory
sub assessfiles {

	$source  = $topdevlib . "/" . $folder;
	$templib = $toptemplib . "/" . $folder;
	$site    = $toplivelib . "/" . $folder;

	mkdir($source);
	mkdir($templib);
	mkdir($site);

	opendir( PAGES, $source ) || die "AF.Cannot open directory $source: $!";
	@documents = grep( /\.htm/, readdir PAGES );
	closedir(PAGES);
}

sub processdoc {

	$document =~ s/.htm//;
	$title = $document;
	$title =~ s/_/ /gi;
	$title =~ s/(.*)/\u$1/gi;

	$title =~ s/(\w*) all/All $1/gi;
if ($1 ne "") {
$summary="Y";
}
else {
$summary="N";
}
	$title =~ s/div(.*)/Division $1/gi;
	$title =~ s/(\w*) Prem/Premier \u$1/gi;
	$pagetitle = "NottsBA : " . $title . " : results";

    $document=lc($document);

	chdir($templib);
	$phpfile = ">$document.php";
	open( $phphandle, $phpfile );

	$outputdocument = "$document.php";
	print $outputdocument;
	$spacer = substr( "                    ", 0, 20 - length($outputdocument) );
	print $spacer;

	# get number of days since last modified
	$inputdocument = "$document.htm";
	chdir $source;
	$offset = ( -M $inputdocument );

	# calc actual date
	$date = scalar localtime( time - $offset * 24 * 3600 );

	# strip out the time & replace with a comma
	$date =~ s/\s\d+:\d+:\d+/,/;

	# swap month & day number
	$date =~ s/(\w+) (\d+)/$2 $1/;

	print "[".$inputdocument."]";
	stripcontent($inputdocument);

	close $phphandle;
}

sub updatelive {
	$live = $toplivelib . "/$folder/" . $outputdocument;
	$temp = $toptemplib . "/$folder/" . $outputdocument;

if (-e $live) {
	$same = mycomparefiles( $live, $temp );
} else {
    print "New file $outputdocument being created\n";
    $same=0;
}


	if ( $same ne 1 ) {

		chdir( $toplivelib . "/$folder" );
		$outfile = ">" . $outputdocument;
		open( $outhandle, $outfile )
		  or print "UL.Can't find $toplivelib/$folder/$outfile: $!\n";

		chdir( $toptemplib . "/$folder" );

		$infile = "<" . $outputdocument;

		scoff( $inhandle, $infile );

		close $outhandle;

		print " - updated  ";
	}
	else {
		print " - no change";
	}
}

sub testupdatelive {
	$live = $toplivelib . "/$folder/" . $document;
	$temp = $toptemplib . "/$folder/" . $document;

	$same = mycomparefiles( $live, $temp );

	if ( $same ne 1 ) {
		print " - will be updated";
	}
	else {
		print " - no changes     ";
	}
}


#Open Outfile
sub outfile {

	my ( $path, $file ) = @_;
	mkdir( $path, 0755 );
	chdir($path);
	$outfile = ">" . $file;
	open( $outhandle, $outfile ) or print "O.Can't find $path/$outfile: $!\n";

}

sub scoff {
	my ( $handle, $file ) = @_;
	open( $handle, $file ) or print "S.Can't find $file: $!\n";

	while (<$handle>) {
		s|:PAGETITLE:|$pagetitle|gi;
		s|:TITLE:|$title|gi;
		s|<DATE>|$date|gi;
		s|<MAINFOLDER>|$main|gi;

		s|<CLUBNAME>|$club|gi;
		s|<SEASON>|$year|gi;

		if ( $previous == 1 ) {
			s|>ladies/|>prev-ladies/|gi;
			s|>mens/|>prev-mens/|gi;
			s|>mixed/|>prev-mixed/|gi;
		}

		print $outhandle $_;
	}
	close $handle;
}

sub getclubs {
	$searchfile = "clubs.txt";
	open( _searchfile, "$templates/$searchfile" )
	  or print "GC.Can't find $templates/$searchfile: $!\n";

	close(_searchfile);
}

sub stripcontent {

	my ($searchfile) = @_;

	chdir $source;

	open( _searchfile, "$searchfile" )
	  or print "SC.Can't find $source/$searchfile: $!\n";
	undef $/;
	$rawdata = <_searchfile>;
	close(_searchfile);
	$/ = "\n";

	$indata    = $rawdata;
	@table     = striptable($indata);
	@withlinks = addextras(@table);
	print $phphandle @withlinks;

}

sub striptable {

	foreach $_ (@_) {

		s|\n|~~~|gi;           # temporarily remove line breaks

		s|<!--START[^£]*£-->||gi;    #get rid of old autotext blocks

		s|<a [^>]*>||gi;
		s|</a>||gi;

		s|.*<table|<br /><table|gi;
        s|<table[^>]*>|<table class="scoretable">|gi;
        s|<tr.*Nottinghamshire[^<]*</td>|<tr>|gi;
		s|<span[^<]*</span>||g;

		s|(<[^>]*)~~~([^>]*>)|$1 $2|gi;    # join split tags
		s|(\w{1,})\=(\w{1,})|$1="$2"|g;    # add quotes to attributes

		s|(\w)~~~[\s~]*(\w)|$1 $2|gi;
		s|(&amp;)~~~[\s~]*(\w)|$1 $2|gi;

		s|</body>||gi;
		s|</html>||gi;
		s|</div>||gi;

		s|<tr[^>]*>|<tr>|g;
		s|<td[^>]*>|<td>|g;

		s|x:str\="[\w ]*"||g;
		s| x:num="[^"]*"||g;
		s| x:num||g;
		s| style\='mso[^<]*'||g;
		s| valign\="\w{1,}"||g;
		s|<!--[-]*-->|<!-- // -->|g;
		s|<!\[if[^!]*!\[endif\]>||gi;
		s|<tr>[^<]*</tr>||g;
		s|<u [^\/]*/u>||g;

		s|<font[^>]*>||gi;
		s|</font>||gi;
		s|<span[ ]*>[ ]*</span>||gi;    # these are not normal spaces!!

		s|(<col [^<]*>)|$1</col>|gi;
		s|(<col.*</col>)[^<]*<tr|<colgroup>~~~$1~~~</colgroup>~~~<tr|g;

		s|style='HEIGHT:[0-9.]*pt'||gi;
		s|style='WIDTH:[0-9.]*pt'||gi;
		s|class="xl[0-9]*"||gi;
		s|align="[a-z]*"||gi;
		s|width="[0-9]*"||gi;
		s|height="[0-9]*"||gi;
		s|"|'|gi;
		s|style='[a-z;:\-]*'||gi;
		s|&nbsp;||gi;

		s|style='[^']*'||gi;

		s|<td[\s]*>|<td>|gi;
		s|<col[\s]*>|<col>|gi;
		s|colspan='[0-9]'||gi;

		s|<td>\s*-\s*</td>[\s~]*<td>\s*</td>|<td>-</td><td>0</td>|gi;
		s|<td>\s*</td>[\s~]*<td>\s*-\s*</td>|<td>0</td><td>-</td>|gi;
		s|<td>([0-9]{1,2})</td>[\s~]*<td>[\s~]*</td>[\s~]*<td>([0-9]{1,2})</td>|<td>$1</td><td>-</td><td>$2</td>|gi;

		s|<tr>[\s~]*<td[\s]*></td>|<tr>|gi;
		s|<tr>[\s~]*</tr>||gi;

		s|<[/]*colgroup>||gi;
		s|<[/]*col[\s]*>||gi;
		s|<col[\s]*span='[0-9]'>||gi;

		s|w/o||gi;
		s|Home||gi;
		s|Away||gi;
		s|Date||gi;
		s|no c||gi;
		s|#VALUE||gi;

		s|<td[\s]*>[\s]*|<td>|gi;
		s|<td>~*</td>||gi;

		s|<tr>[\s~]*<td\s*>\s*Matches Played up to|</table><br /><table class="scoretable"><tr><td class="score_td_hdr">Matches  Played|gi;
		s|<td>[0-9]*-[\w]*-[0-9]*</td>||gi;

		s|<tr>[\s~]*<td>\s*0\s*</td>|<tr>|gi;


		s|League[^<]*Table|League Table|gi;
		s|</td>[</trd>\s~]*League Table[</trd>\s~]*S T A N D I N G S</td>|</td>|gi;
		s|<tr>[\s~]*(<td>[^~]*)[~\s]*(<td>[^~]*)[~\s]*[</trd>\s~]*League Table</td>([</trdpwlrfas>\s~]*)<td>S T A N D I N G S</td>|<tr>$1~~~$3~~~$2|gi;
		s|<!--.*||gi;

		s|([0-9;])~{1,*}\s*|$1 |gi;

		s|<td>p</td>|<td class='score_pts'>p</td>|gi;
		s|<td>w</td>|<td class='score_pts'>w</td>|gi;
		s|<td>l</td>|<td class='score_pts'>l</td>|gi;
		s|<td>rf</td>|<td class='score_pts'>rf</td>|gi;
		s|<td>ra</td>|<td class='score_pts'>ra</td>|gi;
		s|<td>pts</td>|<td class='score_pts'>pts</td>|gi;
		s|<td>[\s]*(-?[0-9]{1,2})[\s]*</td>|<td class='score_td'>$1</td>|gi;

		s|<tr>[\s~]*<td>\s*&#8722\s*</td>[\s~]*</tr>||gi;
		s|<td>[\s]*(&#8722;)[\s]*</td>|<td class='score_td'>$1</td>|gi;
		s|<td>[\s]*([#-–])[\s]*</td>|<td class='score_td'>-</td>|gi;
		s|<td>[\s]*([!])[\s]*</td>||gi;

		s|<tr><td class='score_td'>-</td>[^~]*[\s~]*</tr>||gi;
		s|<tr>[\s~]*<td class='score_td'>0</td>[^~]*[\s~]*</tr>||gi;

		s|>-<|><|gi;

if ($summary eq "N") {
		s|<tr>[\s~]*<td [^>]*></td>|<tr>|gi;
		s|<tr>[\s~]*<td [^>]*></td>|<tr>|gi;
		s|<tr>[\s~]*<td [^>]*></td>|<tr>|gi;
		s|<tr>[\s~]*<td [^>]*></td>|<tr>|gi;
		s|<tr>[\s~]*<td [^>]*></td>|<tr>|gi;
		s|<tr>[\s~]*<td [^>]*></td>|<tr>|gi;
		s|<tr>[\s~]*<td [^>]*></td>|<tr>|gi;
		s|<tr>[\s~]*<td [^>]*></td>|<tr>|gi;
}

                s|[\s]*<tr>[\s~]*</tr>||gi;

		s|~~~|\n|gi;
		s|\n[\s]*\n|\n|gi;
	}
	return @_;
}

sub addextras {

	@intext = @_;

	addClubLinks();

	addDivisionLinks();

	addRuleLinks();

    foreach $intext (@intext)    {
               $search="<td>";
               $replace="<td class='score_td_rule'>";
               $intext=~s/$search/$replace/gi;
    }

	return @intext;
}

sub addClubLinks {

	$searchfile = "clublinks.txt";

	open( _searchfile, "$templates/$searchfile" )
	  or print "ACL.Can't find $templates/$searchfile: $!\n";
	@searchfile = <_searchfile>;
	close(_searchfile);

	foreach $club (@searchfile) {

		$search = $club;
		$search =~ s/\s*[*]\s*//g;
		$search =~ s/<[^>]*>//g;
		$search =~ s/[^a-zA-Z\s0-9]//g;
		$search =~ s/<^\s+>//g;
		$search =~ s/<\s+$>//g;

		$nullcheck = $search;
		$nullcheck =~ s/\s//g;
		chomp $nullcheck;

		$replacetype = "club_tables";
		$prefix      = "?cnm=";
        $class="score_td_name";


		if ( $nullcheck ne "" ) {
			$search = $club;
			chomp $search;

			replacechomp($search);

		}

	}

}

sub addDivisionLinks {

	$searchfile = "divisions.txt";

	open( _searchfile, "$templates/$searchfile" )
	  or print "ADL.Can't find $templates/$searchfile: $!\n";
	@searchfile = <_searchfile>;
	close(_searchfile);

	foreach $division (@searchfile) {

		$search = $division;
		$search =~ s/\s*[*]\s*//g;
		$search =~ s/<[^>]*>//g;
		$search =~ s/[^a-zA-Z\s0-9]//g;
		$search =~ s/<^\s+>//g;
		$search =~ s/<\s+$>//g;

		$nullcheck = $search;
		$nullcheck =~ s/\s//g;
		chomp $nullcheck;

		$replacetype = "division_tables";
		$prefix      = "?dnm=";
        $class="score_td_hdr";

		if ( $nullcheck ne "" ) {

			$search = $division;
			chomp $search;

			replacechomp($search);

		}

	}
}

sub addRuleLinks {

	foreach $intext (@intext) {

		$found = 1;
		while ( $found == 1 ) {

			$found = 0;
			if ( $alttext =~ m|>rule\s([0-9]{0,2}[a-z]{0,1})</td>|i ) {

				$rulenumber = $1;
				$searchtext = "rule " . $rulenumber;
				$search     = ">rule " . $rulenumber . "</td>";

				$text1 = ' <a href="../';
				$text2 = 'senior_competition_rules.php#rule_';
				$text3 = $rulenumber;
				$text4 = '">';
				$text5 = $searchtext;
				$text6 = '</a>';
				$replacetext =
				  $text1 . $text2 . $text3 . $text4 . $text5 . $text6;

				$replace = ">" . $replacetext . "</td>";
				$alttext =~ s/$search/$replace/gi;
				$found = 1;
			}
		}

		if ( $alttext ne $intext ) {
			$intext = $alttext;
		}

	}

}

sub replacechomp {

	my ($searchtext) = @_;

	$text1 = ' <a href="./';
	$text2 = $replacetype.".php";
	$text3 = '';
	$text4 = $prefix;
	$text5 = lc($searchtext);
	$text5 =~ s/(\s)*&[amp;]*(\s)*/_/g;
	$text5 =~ s/\s/_/g;
	$text6 = '">';
	$text7 = $searchtext;
	$text8 = '</a>';
	$replacetext =
	  $text1 . $text2 . $text3 . $text4 . $text5 . $text6 . $text7 . $text8;


		foreach $intext (@intext) {

		$alttext = $intext;

		$found = 1;
		while ( $found == 1 ) {

			$found = 0;

            if ($alttext =~ m|<td>([\s]*)$searchtext([\s]*[1-8A-H]{0,1}[st]{0,2}[nd]{0,2}[rd]{0,2}[th]{0,2}(<span[^<]*</span>)*[\s]*)</td>|i) {

               $search="<td>".$1.$searchtext.$2."</td>";
               $replace="<td class='$class'>".$replacetext.$2."</td>";
				$alttext =~ s/$search/$replace/gi;
				$found = 1;
			}


			if ( $searchtext =~ m|Div([0-9A-C]{1,2})| ) {
				$search = $searchtext;
				$search =~ s/($1)/ision $1/;
				$replace = $replacetext;
				$replace =~ s/>$searchtext</>$search</;
				if ( $document !~ m/_all/ ) {
					$replace=$search;
				}
                $search="<td>".$search."</td>";
                $replace="<td class='$class'>".$replace."</td>";
				$alttext =~ s/$search/$replace/gi;
			}

			if ( $searchtext =~ m|(\w*) Div([0-9A-C]{1,2})| ) {
				$search  = $1 . " " . $2;
				$replace = $replacetext;
				$replace =~ s/>$searchtext</>$search</;
				if ( $document !~ m/_all/ ) {
					$replace=$search;
				}
                $search="<td>".$search."</td>";
                $replace="<td class='$class'>".$replace."</td>";
				$alttext =~ s/$search/$replace/gi;
			}

			if ( $searchtext =~ m|(\w*) Div([0-9A-C]{1,2})| ) {
				$search  = $1 . " Div " . $2;
				$replace = $replacetext;
				$replace =~ s/>$searchtext</>$search</;
				if ( $document !~ m/_all/ ) {
					$replace=$search;
				}
                $search="<td>".$search."</td>";
                $replace="<td class='$class'>".$replace."</td>";
				$alttext =~ s/$search/$replace/gi;
			}

			if ( $searchtext =~ m|(\w*) Prem| ) {
				$search  = "Premier " . $1;
				$replace = $replacetext;
				$replace =~ s/>$searchtext</>$search</;
				if ( $document !~ m/_all/ ) {
					$replace=$search;
				}
                $search="<td>".$search."</td>";
                $replace="<td class='$class'>".$replace."</td>";
				$alttext =~ s/$search/$replace/gi;
			}

			if ( $searchtext =~ m|(\w*) Prem| ) {
				$search  = $1 . " Premier";
				$replace = $replacetext;
				$replace =~ s/>$searchtext</>$search</;
				if ( $document !~ m/_all/ ) {
					$replace=$search;
				}
                $search="<td>".$search."</td>";
                $replace="<td class='$class'>".$replace."</td>";
				$alttext =~ s/$search/$replace/gi;
			}

			if ( $searchtext =~ m|(\w*) Div1| ) {
				$search  = $1 . " Division One";
				$replace = $replacetext;
				$replace =~ s/>$searchtext</>$search</;
				if ( $document !~ m/s_all/ ) {
					$replace=$search;
				}
                $search="<td>".$search."</td>";
                $replace="<td class='$class'>".$replace."</td>";
				$alttext =~ s/$search/$replace/gi;
			}

		}

		if ( $alttext ne $intext ) {

			$intext = $alttext;
		}

	}

}

sub mycomparefiles {

	my ( $file1, $file2 ) = @_;
	open( $handle1, $file1 );
	open( $handle2, $file2 );
	undef $/;
	$test1 = <$handle1>;
	$test2 = <$handle2>;

	# strip out the dates as these always change
	$test1 =~ s|Last updated:.*\n||;
	$test2 =~ s|Last updated:.*\n||;
	close $handle1;
	close $handle2;
	$/ = "\n";

	if ( $test1 eq $test2 ) {
		return 1;
	}

	return 0;
}