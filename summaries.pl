
main();

#Main
sub main {

	$main="MAIN";
	$newseason="2011-2012";

	definitions();

	getclubs();

	print "\n\nProcessing Current Season Summaries...";
        loadnew();
        clubloop();
}

#loadnew
sub loadnew {
	getnewyear();
	$previous=0;
	$summaries="/summaries";
}


#clubloop
sub clubloop {
        $clubcount=0;
        print $year."\n";
        foreach $club (@clubs) {
                chomp $club;
                if ($club ne "") {
                   print "\n";
                   print ++$clubcount." ";
                   scantables($club);

                   $document=lc($summaryfilename);
                   print $club;
                   $spacer=substr("                         ",0,25-length($club));
                   print $spacer;

                   print " : php ";

		   $document=~s/.htm/.php/gi;
		   $document=~s/[<>]//gi;

                    updatelive();
                }
        }

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

        $clubhead="../clubs/nba_";

# get toady date
	$date = scalar localtime(time);

# strip out the time & replace with a comma
	$date=~s/\s\d+:\d+:\d+/,/;

# swap month & day number
        $date=~s/(\w+) (\d+)/$2 $1/;
}

sub updatelive	{
	$live=$toplivelib.$summaries."/".$document;
	$temp=$toptemplib.$summaries."/".$document;

if (-e $live) {
	$same = mycomparefiles( $live, $temp );
} else {
    print "New file $document being created\n";
    $same=0;
}

	if ($same ne 1)	{

			chdir($toplivelib.$summaries);
			$outfile=">".$document;
                 	open($outhandle, $outfile) or print "1.Can't find $outfile: $!\n";

			chdir($toptemplib.$summaries);
			$infile="<".$document;
			scoff($inhandle,$infile);

			close $outhandle;

			print " - updated  ";
	}	else	{
			print " - no change";
	}

	# write team summaries to include on club details page
	if ($menscount+$mixedcount+$ladiescount gt 0) {
			chdir($toplivelib.$summaries);
			$outfile=">ts_".$document;
                 	open($outhandle, $outfile) or print "1.Can't find $outfile: $!\n";
                        print $outhandle "<tr><td><strong>Number of Teams</strong></td>";
                        print $outhandle "<td>Mixed x ".$mixedcount;
                        print $outhandle "<br />Mens x ".$menscount;
                        print $outhandle "<br />Ladies x ".$ladiescount;
                        print $outhandle "</td></tr>";
			close $outhandle;
        }

}


#Open Outfile
sub outfile {

	my($path,$file)=@_;
	mkdir($path,0755);
	chdir($path);
	$outfile=">".$file;
	open($outhandle, $outfile) or print "2.Can't find $outfile: $!\n";

}

sub scoff	{
	my($handle,$file)=@_;
	open($handle, $file) or print "3.Can't find $file: $!\n";

        $file=lc($club).".htm";
        $file=~s/ /_/g;

   	$replaceheader="othersummaryhead.file";

        $replaceheader2=$clubhead.$file;

	while (<$handle>) {
		s|:PAGETITLE:|$pagetitle|gi;
		s|:TITLE:|$title|gi;
		s|<DATE>|$date|gi;
		s|<MAINFOLDER>|$main|gi;
		s|<CLUBNAME>|$club|gi;
		s|<SEASON>|$year|gi;
		s|<SUMMARYFILE>|$replaceheader|gi;
		s|<DETAILFILE>|$replaceheader2|gi;

                if ($previous==1) {
                   s|>ladies/|>prev-ladies/|gi;
		   s|>mens/|>prev-mens/|gi;
		   s|>mixed/|>prev-mixed/|gi;
                }

		print $outhandle $_;
	}
	close $handle;
}

# new season details
sub getnewyear {

	$year=$newseason;
}


sub getclubs {
        $searchfile="clubs.txt";
        open(_searchfile, "$templates/$searchfile") or print "4.Can't find $searchfile: $!\n";
        @clubs=<_searchfile>;
        close(_searchfile);
}

sub scantables {

	my($searchtext)=@_;

        $pagetitle="NottsBA : ".$searchtext." : summary : ".$year;

$title=$searchtext;
$title=~s/_/ /gi;
$title=~s/(.*)/\u$1/gi;

        my($templib)="$toptemplib/summaries";
        mkdir($templib);

        my($livelib)="$toplivelib/summaries";
        mkdir($livelib);

        $search_text=lc($searchtext);
        $search_text=~s/(\s)*&[amp;]*(\s)*/_/g;
        $search_text=~s/ /_/g;

        chdir($templib);
        $summaryfile=">$search_text.php";
        $summaryfilename="$search_text.php";
        open($summaryhandle, $summaryfile);

        $outhandle=$summaryhandle;

        $type="mens";
        $searchfolder="$topdevlib/$type/";      
        scandir($searchfolder,$searchtext);
        $menscount=$foundcount;

        $type="mixed";
        $searchfolder="$topdevlib/$type/";      
        scandir($searchfolder,$searchtext);
        $mixedcount=$foundcount;

        $type="ladies";
        $searchfolder="$topdevlib/$type/";      
        scandir($searchfolder,$searchtext);
        $ladiescount=$foundcount;

        $outhandle=$summaryhandle;

        close $outhandle;


}

sub scandir {

         my($searchlib,$searchtext)=@_;

         chdir $searchlib;

         opendir(DIR,$searchlib) || die "$!";
         my(@listing)=readdir DIR;
         closedir(DIR);

         $joinedlist=join "£",@listing;
         $joinedlist=~s/_prem/_div0/gi;
         @splitlist=split "£",$joinedlist;
         @sortedlist=sort(@splitlist);
         $joinedlist=join "£",@sortedlist;
         $joinedlist=~s/_div0/_prem/gi;
         @splitlist=split "£",$joinedlist;

	 $count=0;
         $foundcount=0;
	 foreach $item (@splitlist)	{

                if ($item ne "." && $item ne ".." && $item ne $searchlib) {

                   $count++;
                        $_=$item;
                        if ((m/.htm/) && (! m/_all.htm/)) {
                           $document=$item;

                           readdoc($document,$searchtext);
                           if ($found) {
                              stripcontent($document,$searchtext);
                              $foundcount++;
                           }
                        }

                }
	 }

}

sub readdoc {

         my($searchfile,$searchtext)=@_;

        $found=0;

    open(_searchfile, "$searchfile") or print "6.Can't find $searchfile: $!\n";

    undef $/;
    $currenthtml=<_searchfile>;
    close(_searchfile);
    $/ = "\n";

    $currenthtml=~s/\n//gi;
    $currenthtml=~s/[ ]{1,}/ /gi;

        if ($currenthtml =~ />$searchtext(\<\/a\>)*[\s]*[1-8A-H]{0,1}[st]{0,2}[nd]{0,2}[rd]{0,2}[th]{0,2}(<span[^<]*<\/span>)*[\s]*<\/td>/i) {
                   $found++;
        }

}

sub stripcontent 	{

    my($searchfile,$searchtext)=@_;

    open(_searchfile, "$searchfile") or print "7.Can't find $searchfile: $!\n";
    undef $/;
    $rawdata=<_searchfile>;
    close(_searchfile);
    $/ = "\n";

    $indata=$rawdata;
    @table=striptable($indata);
    @withlinks=addextras(@table);
    print $summaryhandle @withlinks;

}


sub striptable 	{

    foreach $_ (@_)    {

		s|\n|~~~|gi;    # temporarily remove line breaks

		s|<!--START[^£]*£-->||gi;    #get rid of old autotext blocks

                s|.*<table|<br /><table|gi;
                s|<table[^>]*>|<table class="scoretable">|gi;
s|<tr.*Nottinghamshire[^<]*</td>|<tr>|gi;
                s|</table>.*|</table>|gi;
                s|<td[^<]*Matches Played up to date[^<]*</td>.*|</tr></table>|gi;
s|<u [^\/]*/u>||g;
		s|(<[^>]*)~~~([^>]*>)|$1 $2|gi;    # join split tags
		s|(\w{1,})\=(\w{1,})|$1="$2"|g;    # add quotes to attributes

                s|</body>||gi;
                s|</html>||gi;
                s|</div>||gi;

                s|>_<|><|gi;

		s|style='HEIGHT:[0-9.]*pt'||gi;
		s|style='WIDTH:[0-9.]*pt'||gi;
		s|class="xl[0-9]*"||gi;
		s|align="[a-z]*"||gi;
		s|width="[0-9]*"||gi;
		s|height="[0-9]*"||gi;
		s|"|'|gi;
		s|style='[a-z;:\-]*'||gi;
		s|&nbsp;||gi;
		s|x:str='[^']*'||gi;


s| x:num=['"\.0-9]*||gi;
s| x:num||gi;

		s|<td[\s]*>|<td>|gi;

		s|<[/]*colgroup>||gi;
		s|<[/]*col[^>]*>||gi;

		s|<td[\s]*></td>||gi;

		s|</td>[</trd>\s~]*League Table[</trd>\s~]*S T A N D I N G S</td>|</td>|gi;

		s|<a [^>]*>||gi;
		s|</a>||gi;

		s|<td>p</td>|<td class='score_pts'>p</td>|gi;
		s|<td>w</td>|<td class='score_pts'>w</td>|gi;
		s|<td>l</td>|<td class='score_pts'>l</td>|gi;
		s|<td>rf</td>|<td class='score_pts'>rf</td>|gi;
		s|<td>ra</td>|<td class='score_pts'>ra</td>|gi;
		s|<td>pts</td>|<td class='score_pts'>pts</td>|gi;
		s|<td>[\s]*(-?[0-9]{1,2})[\s]*</td>|<td class='score_td'>$1</td>|gi;

		s|(\w)\s*~~~\s*(\w)|$1 $2|gi;

		s|~~~|\n|gi;
		s|\n[\s]*\n|\n|gi;

      }
      return @_;
}

sub addextras {

        @intext=@_;

        addClubLinks();

        addDivisionLinks();

    foreach $intext (@intext)    {
               $search="<td>";
               $replace="<td class='score_td_name'>";
               $intext=~s/$search/$replace/gi;
    }

return @intext;
}

sub addClubLinks {

        $searchfile="clublinks.txt";

        open(_searchfile, "$templates/$searchfile") or print "CL.Can't find $searchfile: $!\n";
        @searchfile=<_searchfile>;
        close(_searchfile);

        foreach $clubfound (@searchfile) {

                $search=$clubfound;
                $search=~s/\s*[*]\s*//g;
                $search=~s/<[^>]*>//g;
                $search=~s/[^a-zA-Z\s0-9]//g;
                $search=~s/<^\s+>//g;
                $search=~s/<\s+$>//g;

                $nullcheck=$search;
                $nullcheck=~s/\s//g;
                chomp $nullcheck;

               $replacetype="club_tables";
               $prefix="?cnm=";
               $class="score_td_name";

                if ($nullcheck ne "") {
                   $search=$clubfound;
                   chomp $search;

                   replacechomp($search);

                }

        }

}

sub addDivisionLinks {

        $searchfile="divisions.txt";

        open(_searchfile, "$templates/$searchfile") or print "DL.Can't find $searchfile: $!\n";
        @searchfile=<_searchfile>;
        close(_searchfile);

        foreach $division (@searchfile) {

                $search=$division;
                $search=~s/\s*[*]\s*//g;
                $search=~s/<[^>]*>//g;
                $search=~s/[^a-zA-Z\s0-9]//g;
                $search=~s/<^\s+>//g;
                $search=~s/<\s+$>//g;

                $nullcheck=$search;
                $nullcheck=~s/\s//g;
                chomp $nullcheck;

                $replacetype="division_tables";
                $prefix="?dnm=";
        	    $class="score_td_hdr";

                if ($nullcheck ne "") {

                   $search=$division;
                   chomp $search;

                   replacechomp($search);

                }

        }
}


sub replacechomp 	{

    my($searchtext)=@_;

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
    $replacetext=$text1.$text2.$text3.$text4.$text5.$text6.$text7.$text8;

    foreach $intext (@intext)    {

            $alttext=$intext;

            $found=1;
            while ($found == 1) {

            $found=0;
            if ($alttext =~ m|<td>([\s]*)$searchtext([\s]*[1-8A-H]{0,1}[st]{0,2}[nd]{0,2}[rd]{0,2}[th]{0,2}(<span[^<]*</span>)*[\s]*)</td>|i) {

               $search="<td>".$1.$searchtext.$2."</td>";
				if ($club eq $searchtext) {
					$replacetext="<strong>$searchtext</strong>";
					$classext="_highlight";
				} else {
					$classext="";
				}
               $replace="<td class='".$class.$classext."'>".$replacetext.$2."</td>";


               $alttext=~s/$search/$replace/gi;
               $found=1;

            }

            if ($searchtext =~ m|Div([0-9A-C]{1,2})|) {
               $search=$searchtext;
               $search=~s/($1)/ision $1/;
               $replace=$replacetext;
               $replace=~s/>$searchtext</>$search</;
               $search="<td>".$search."</td>";
               $replace="<td class='$class'>".$replace."</td>";
               $alttext=~s/$search/$replace/gi;
            }

            if ($searchtext =~ m|(\w*) Div([0-9A-C]{1,2})|) {
               $search=$1." ".$2;
               $replace=$replacetext;
               $replace=~s/>$searchtext</>$search</;
               $search="<td>".$search."</td>";
               $replace="<td class='$class'>".$replace."</td>";
               $alttext=~s/$search/$replace/gi;
            }

            if ($searchtext =~ m|(\w*) Div([0-9A-C]{1,2})|) {
               $search=$1." Div ".$2;
               $replace=$replacetext;
               $replace=~s/>$searchtext</>$search</;
               $search="<td>".$search."</td>";
               $replace="<td class='$class'>".$replace."</td>";
               $alttext=~s/$search/$replace/gi;
            }

            if ($searchtext =~ m|(\w*) Div([0-9A-C]{1,2})|) {
               $search=$1." Division ".$2;
               $replace=$replacetext;
               $replace=~s/>$searchtext</>$search</;
               $search="<td>".$search."</td>";
               $replace="<td class='$class'>".$replace."</td>";
               $alttext=~s/$search/$replace/gi;
            }

            if ($searchtext =~ m|(\w*) Prem|) {
               $search=$1." Premier";
               $replace=$replacetext;
               $replace=~s/>$searchtext</>$search</;
               $search="<td>".$search."</td>";
               $replace="<td class='$class'>".$replace."</td>";
               $alttext=~s/$search/$replace/gi;
            }

            if ($searchtext =~ m|(\w*) Prem|) {
               $search="Premier ".$1;
               $replace=$replacetext;
               $replace=~s/>$searchtext</>$search</;
               $search="<td>".$search."</td>";
               $replace="<td class='$class'>".$replace."</td>";
               $alttext=~s/$search/$replace/gi;
            }

            if ($searchtext =~ m|(\w*) Div1|) {
               $search=$1." Division One";
               $replace=$replacetext;
               $replace=~s/>$searchtext</>$search</;
               $search="<td>".$search."</td>";
               $replace="<td class='$class'>".$replace."</td>";
               $alttext=~s/$search/$replace/gi;
            }

            }


            if ($alttext ne $intext) {
               $intext=$alttext;
            }

    }

}

sub highlightchomp 	{

    my($searchtext)=@_;

    $text1=' <b>';
    $text2=$searchtext;
    $text3='</b> ';
    $replacetext=$text1.$text2.$text3;

    foreach $intext (@intext)    {

            $alttext=$intext;

            $found=1;
            while ($found == 1) {

            $found=0;
            if ($alttext =~ m|>$searchtext([\s]*[1-8A-H]{0,1}[st]{0,2}[nd]{0,2}[rd]{0,2}[th]{0,2}(<span[^<]*</span>)*[\s]*)</td>|i) {

               $search=">".$searchtext.$1."</td>";
               $replace=">".$replacetext.$1."</td>";
               $alttext=~s/$search/$replace/gi;
               $found=1;
            }


            }

            if ($alttext ne $intext) {
               $intext=$alttext;
            }

    }

}


sub mycomparefiles {

        my($file1,$file2)=@_;
	open($handle1, $file1);
	open($handle2, $file2);
	undef $/;
	$test1=<$handle1>;
	$test2=<$handle2>;

# strip out the dates as these always change
        $test1=~s|Last updated:.*\n||;
        $test2=~s|Last updated:.*\n||;
        close $handle1;
        close $handle2;
        $/ = "\n";

        if ($test1 eq $test2)     {
           return 1;
        }

        return 0;
}