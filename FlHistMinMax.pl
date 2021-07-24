# FLHistMinMax.pl
#
# Generate r script files for each station based on the first and last years of data.
#
# COOPID, YEAR, MONTH, DAY, PRECIPITATION, MAX TEMP, MIN TEMP, MEAN TEMP
#
# COOPID = station
#
# For all stations:
#     perl FLHistMinMax.pl
#
# For a specific station:
#     perl FLHistMinMax.pl -s 80288 -y1 1935 -y2 2019 -o C:\tmp\ -t X
#     perl FLHistMinMax.pl -s 80369 -y1 1894 -y2 2018 -o C:\tmp\ -t N
#     perl FLHistMinMax.pl -o "c:\tmp\data"
#
use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);

our $input_file = 'allsave.csv';
our $output_path = "";
our $pathdel = "";  # path delmiter, either "/" or "\\"
our $pd = "";       # if the last character is not "/" or "\\" then set to "/", otherwise ""

our $fhI;
our $fhO;
our $fb;
our $slash = "";  # set to "" if the path has a traling "/" or "\", otherwise set to "\\"

our $total = 0;
our $idx = 0;
our $idx1 = 0;
our $idx2 = 0;
our $idx3 = 0;
our $idx4 = 0;
our $cnt = 0;
our $cntparam = 0;
our $ln = "";
our $stationcnt = 0;  # count of stations generated
our $scriptcnt = 0;   # count of script files generated, 4 script files for every station

our $station = "";
our $ftype = "A";     # default is to build for all types!
our $yearminL = "";
our $yearmin = "";
our $yearmaxL = "";
our $yearmax = "";
our $stationL = "";

our $coopid = "";
our $yearL = "";
our $year = "";
our $month = "";
our $day = "";
our $precipitation = "";
our $maxtemp = "";
our $mintemp = "";
our $meantemp = "";
our $skipped = 0;   # total count of number of lines skipped (because one or more values in any field is negative)

# Elapsed time
our $elapsed = 0;
our $t0 = 0;

sub help()
{
   print "
  Example that generates all r script files (and corresponding batch file) for all stations:
      perl FLHistMinMax.pl -o \"c:\\tmp\\FL\"
 
  Example that generates four r script files for a specific station, specific minimum, specific maximum, all types:
      perl FLHistMinMax.pl -s 80288 -y1 1935 -y2 2019 -o C:\\tmp\\FL -t A

  Example that generates one r script for a specific station, specific minimum and maximum years, specific type:
      perl FLHistMinMax.pl -s 80369 -y1 1894 -y2 2018 -o C:\\tmp\\FL -t X
      perl FLHistMinMax.pl -s 80369 -y1 1894 -y2 2018 -o C:\\tmp\\FL -t M
      perl FLHistMinMax.pl -s 80369 -y1 1894 -y2 2018 -o C:\\tmp\\FL -t N
      perl FLHistMinMax.pl -s 80369 -y1 1894 -y2 2018 -o C:\\tmp\\FL -t P
  
  ";
}

sub get_arg
{
   my $_i = $_[0];

   my $_j = $_i + 1;
   my $_arg1 = lc($ARGV[$_i]);
   if ( ($_arg1 eq "-h") || ($_arg1 eq "-help")  || ($_arg1 eq "/?"))
   {
      help();
      exit;
   } else {
      my $_arg2 = lc($ARGV[$_j]);
      #print "arg1: '$_arg1'\n";
      #print "arg2: '$_arg2'\n";

      if ($_arg1 eq "-s") {
         $station = $_arg2;
      } elsif ($_arg1 eq "-y1") {
         $yearmin = $_arg2;
      } elsif ($_arg1 eq "-y2") {
         $yearmax = $_arg2;
      } elsif ($_arg1 eq "-o") {
         $output_path = $_arg2;
      } elsif ($_arg1 eq "-t") {
         $ftype = uc($_arg2);
      }
   }
}

sub get_args
{
   my $_cnt = @ARGV;

   if ($_cnt == 1)
   {
      get_arg(0);
   } else {
      $cntparam = $_cnt;
      for (my $i = 0; $i < $_cnt-1; $i++)
      {
        get_arg($i);
      }

      if ($ftype eq "")
      {
        $ftype = "A";    # set default to build for all types
      }
   }
}


# Check to ensure all paramters are defined
sub check_parameters
{
   my $_station    = $_[0];
   my $_yearmin    = $_[1];
   my $_yearmax    = $_[2];
   my $_ftype      = $_[3];  # only A, P, X, N, M (A - all, P - precipitation, X - Maximum temperature, N - Minimum temperature, M - Mean temperature  

   my $ok = 0;

   if ( (defined $_station) && ($_station ne "") )
   {
      if ( (defined $_yearmin) && ($_yearmin ne "") )
      {
         if ( (defined $_yearmax) && ($_yearmax ne "") )
         {
           if ( (defined $_ftype) && ($_ftype ne "") )
           {
               print "153. Generating r script for station: '$_station'  yearmin: '$_yearmin'   yearmax: '$_yearmax   type:'$_ftype'\n";
               $ok = 1;
           }
         }
      }
   } elsif ( (defined $_station) && ($_station ne "") ) {
      if ( (defined $_yearmin) && ($_yearmin ne "") )
      {
         if ( (defined $_yearmax) && ($_yearmax ne "") )
         {
            print "163. Generating r script for station: '$_station'  yearmin: '$_yearmin'   yearmax: '$_yearmax   type:'$_ftype'\n";
            $ok = 1;
         }
      }
   } else {
      #print "163. Generating r script files for all stations\n";
   }
   return $ok;
}

# Get the path delimiter
# If the path has a trailing "\" or "/", then the delimiter is null
# If the path does not have a trailing "/" or "/", then set to "/"
sub check_for_trailing_slash
{
   my $path_ref = $_[0];

   my $slash = "";
   my $i = -1;
   my $_del = "";

   $i = index($$path_ref, "/");
   if ($i > -1)
   {
      $pathdel = "/";
      $_del = "/";
   }
   $i = index($$path_ref, "\\");
   if ($i > -1)
   {
      $pathdel = "\\";
      $_del = "\\";
   }

   my $len  = length($$path_ref);
   my $ch = substr($$path_ref, length($$path_ref)-1, 1);
   #print "ch: '$ch'\n";
   #print "len: $len\n";

   if ( ($ch eq "/") || ($ch eq "\\") )
   {
      $slash = "";
   } else {
      $slash = $_del;
      $$path_ref = $$path_ref . "\\";
   }
}

# generate rscript file for station based on first and last year
sub rscript
{
   my $_station    = $_[0];
   my $_yearmin    = $_[1];
   my $_yearmax    = $_[2];
   my $_ftype      = $_[3];  # only P, X, N, M (P - precipitation, X - Maximum temperature, N - Minimum temperature, M - Mean temperature  
   
   my $_title = "";
   my $_subtitle = "";
   my $_yaxis = "";
   my $_fld = "";   # 5, 6, 7, or 8
   my $_fldname = "";

   #print "225. Generating r script for station: '$_station'   yearmin:'$_yearmin'   yearmax:'$_yearmax'    ftype:'$_ftype'\n";

      if ($_ftype eq 'P')
      {
         $_title = "Precipitation";
         $_yaxis = "Precipitation (inches)";
         $_fld = "5";
         $_fldname = "PRECIPITATION";
      } elsif  ($_ftype eq 'X') {
         $_title = "Maximum Temperature";
         $_yaxis = "Maximum Temperature (F)";
         $_fld = "6";
         $_fldname = "MAX\.TEMP";
      } elsif  ($_ftype eq 'N') {
         $_title = "Minimum Temperature";
         $_yaxis = "Minimum Temperature (F)";
         $_fld = "7";
         $_fldname = "MIN\.TEMP";
      } else {
         $_title = "Mean Temperature";
         $_yaxis = "Mean Temperature (F)";
         $_fld = "8";
         $_fldname = "MEAN\.TEMP";
      }

      if ( (length($_station) > 0) && (length($_yearmin) > 0) && (length($_yearmax) > 0)  && (length($_ftype) > 0))
      {
         print "252. Generating script file for '$_station' '$_yearmin' '$_yearmax'\n";

         my $_base = $_station . "_" . $_yearmin . "_" . $_yearmax . "_" . $_ftype;
         my $_outname = $output_path . $_base . ".txt";
         #print "247. Generating r script file '$_outname'\n\n";
         print $fb "rscript $_outname\n";

         open $fhO, '>', $_outname or die $!;

         # Generate script file
         # NOTE #, ( and ) MUST BE ESCAPED!
         printf $fhO qq(\# Station: $_station   Year Min: $_yearmin   Year Max: $_yearmax\n);
         printf $fhO qq(\# $_fld - $_title\n\n);
         printf $fhO qq(\# Read and process entire file AllSave.csv\n);
         printf $fhO qq(dfAll5 \<- read.table("AllSave.csv", header = TRUE, nrows = 5, sep = ",")\n);
         printf $fhO qq(classes <- sapply(dfAll5, class)\n);
         printf $fhO qq(dfAll \<- read.table("AllSave.csv", header = TRUE, colClasses = classes, sep = ",", nrow = 2849030)\n\n);
         printf $fhO qq(\# Add DATE column to end\n);
         printf $fhO qq(dfAll\$DATE <- as.Date\(with\(dfAll, paste\(YEAR, MONTH, DAY,sep="-"\)\), "%%Y-%%m-%%d"\)\n);
         printf $fhO qq(dfAll5\$DATE <- as.Date\(with\(dfAll5, paste\(YEAR, MONTH, DAY,sep="-"\)\), "%%Y-%%m-%%d"\)\n);
         printf $fhO qq(dfAll5\$DAYOFYEAR <- strftime\(dfAll5\$DATE, format = "%%j"\)\n);
         printf $fhO qq(head\(dfAll\)\n);
         printf $fhO qq(tail\(dfAll\)\n\n);
         printf $fhO qq(dfsub1 <- subset\(dfAll, COOPID == "$_station" & YEAR == "$_yearmin"\)\n);
         printf $fhO qq(dfsub1 <- dfsub1[dfsub1\$$_fldname >= 0, ]\n);
         printf $fhO qq(dfsub1\$DATE <- as.Date\(with\(dfsub1, paste\(YEAR, MONTH, DAY,sep="-"\)\), "%%Y-%%m-%%d"\)\n);
         printf $fhO qq(df1 <- dfsub1[,c\(1,2,3,4,$_fld,9\)] \# $_fld = $_fldname\n);
         printf $fhO qq(\#head\(df1\)\n\n);
         printf $fhO qq(dfsub2 <- subset\(dfAll, COOPID == "$_station" & YEAR == "$_yearmax"\)\n);
         printf $fhO qq(dfsub2 <- dfsub2[dfsub1\$$_fldname >= 0, ]\n);
         printf $fhO qq(dfsub2\$DATE <- as.Date\(with\(dfsub2, paste\(YEAR, MONTH, DAY,sep="-"\)\), "%%Y-%%m-%%d"\)\n);
         printf $fhO qq(df2 <- dfsub2[,c(1,2,3,4,$_fld,9)] \# $_fld = $_fldname\n);
         printf $fhO qq(\#head\(df2\)\n\n);
         printf $fhO qq(df <- NULL\n);
         printf $fhO qq(df <- merge\(df1, df2, by=c\("MONTH","DAY"\)\)\n);
         printf $fhO qq(\# df <- rbind\(df1,df2\)\n);
         printf $fhO qq(df\$DAYOFYEAR <- strftime\(df\$DATE.x, format = "%%j"\)\n);
         printf $fhO qq(nrow\(df\)\n);
         printf $fhO qq(head\(df\)\n);
         printf $fhO qq(tail\(df\)\n\n);
         printf $fhO qq(\# Remove any lines with negative values\n);
         printf $fhO qq( df <- df[df\$$_fldname.y >= 0, ]\n);
         printf $fhO qq( df <- df[df\$$_fldname.x >= 0, ]\n\n);
         printf $fhO qq(\# Subsitute for negative numbers\n);
         printf $fhO qq(\# Depends on 5,6,7,8\n);
         printf $fhO qq(\# df\$$_fldname.x <- replace\(df\$$_fldname.x, df\$$_fldname.x < 0, 0\)   \# $_fld\n);
         printf $fhO qq(\# df\$$_fldname.y <- replace\(df\$$_fldname.y, df\$$_fldname.y < 0, 0\)   \# $_fld\n);
         printf $fhO qq(\# head\(df\)\n);
         printf $fhO qq(\# tail\(df\)\n\n);
         printf $fhO qq(p <- ggplot\(df\) +\n);
         printf $fhO qq(           geom_point\(aes\(x=DATE.x,y=$_fldname.y\), color='red'\) +\n);
         printf $fhO qq(           \#labs\(x = "Date", y = "$_yaxis", title = "$_title", subtitle = "Station:$_station Years:$_yearmin,$_yearmax", caption="red=$_yearmax, blue=$_yearmin"\) +\n);
         printf $fhO qq(           \#scale_x_date\(aes\(x=DATE.x,y=$_fldname.y\), name="Month", date_breaks="1 month", minor_breaks=NULL, date_labels="%%b"\) +\n);
         printf $fhO qq(           geom_smooth\(aes\(x=DATE.x,y=$_fldname.y\), method = "lm", formula = y ~ poly\(x, 3\), se = FALSE, color = "red"\) +\n);
         printf $fhO qq(           geom_point\(aes\(x=DATE.x,y=$_fldname.x\), color='blue'\) +\n);
         printf $fhO qq(           labs\(x = "Date", y = "$_yaxis", title = "$_title", subtitle = "Station:$_station Years:$_yearmin,$_yearmax", caption="red=$_yearmax, blue=$_yearmin"\) +\n);
         printf $fhO qq(           scale_x_date\(aes\(x=DATE.x,y=$_fldname.x\), name="Month", date_breaks="1 month", minor_breaks=NULL, date_labels="%%b"\) +\n);
         printf $fhO qq(           geom_smooth\(aes\(x=DATE.x,y=$_fldname.x\), method = "lm", formula = y ~ poly\(x, 3\), se = FALSE, color = "blue"\)\n);
         printf $fhO qq(p\n);
         printf $fhO qq(ggsave\("$_base.pdf"\)\n);
         close $fhO;
         $scriptcnt++;
      }
}

sub one_station
{
   my $_station    = $_[0];
   my $_yearmin    = $_[1];
   my $_yearmax    = $_[2];
   my $_ftype      = $_[3];  # only A, P, X, N, M (A - all, P - precipitation, X - Maximum temperature, N - Minimum temperature, M - Mean temperature  

   print "324. Generating r script files for one station to folder '$output_path' using input file '$input_file'\n";
   print "325. See station: $_station  yearmin: $_yearmin   yearmax: $_yearmax    type: $_ftype\n\n";

   my $batchname = "FLHistScriptGenOne.bat";    # batch file that contains rscript executions
   open $fb, '>', $batchname;

   if ($ftype eq "A")
   {
       print "332. Generating r script files for station: '$_station', year minimum: '$_yearmin', year maximum: '$_yearmax, and all types\n";
       rscript($_station,$_yearmin,$_yearmax,"P");
       rscript($_station,$_yearmin,$_yearmax,"X");
       rscript($_station,$_yearmin,$_yearmax,"N");
       rscript($_station,$_yearmin,$_yearmax,"M");
       $idx3 = 4;
   } elsif ( (length($_station) > 0) && (length($_yearmin) > 0) && (length($_yearmax) > 0) && (length($_ftype) > 0) ) {
       print "339. Generating r script files for station: '$_station', year minimum: '$_yearmin', year maximum: '$_yearmax, and type: '$_ftype'\n";
       rscript($_station ,$_yearmin, $_yearmax, $_ftype);
       $idx3 = 1;
   } else {
       print "343. Invalid parameters for building one station\n";
   }

   close($fb);
}

sub all_stations
{
   my $batchname = "FLHistScriptGenAll.bat";    # batch file that contains rscript executions
   open $fb, '>', $batchname;

   $yearL = "";
   $stationL = "";
   $yearminL = "";
   $yearmaxL = "";

   print "359. Generating r script files for all stations to folder '$output_path' using input file '$input_file'\n\n";

   open $fhI, '<', $input_file or die $!;
   while (<$fhI>)
   {
      $ln = $_;
      chomp $ln;
      my $len = length($ln);
      #print "len: $len  ln: $ln\n";
      if (($len > 0) && ($idx1 > 0)) {   # skip header
         my @flds = split(',',$ln);
         $idx4 = index($ln, "-");
         if ($idx4 > -1)
         {
             #print "found\n";
             $skipped++;
         } else {

             $station = $flds[0];
             $year = $flds[1];
             $month = $flds[2];
             $day = $flds[3];
             $precipitation = $flds[4];
             $maxtemp = $flds[5];
             $mintemp = $flds[6];
             $meantemp = $flds[7];
         
             #print "stationL: '$stationL'   station:'$station'\n";
             if ( ($station ne "") && ($yearminL ne "") && ($yearmaxL ne "") )
             {
                if ($stationL ne $station)
                {
                   #print "Generating stationL: '$stationL'   yearminL: '$yearminL'  yearmax: '$yearmaxL'\n";
                   $yearmaxL--;

                   if ($ftype eq "A")
                   {
                      rscript($stationL,$yearminL,$yearmaxL,"P");
                      rscript($stationL,$yearminL,$yearmaxL,"X");
                      rscript($stationL,$yearminL,$yearmaxL,"N");
                      rscript($stationL,$yearminL,$yearmaxL,"M");
                   } else {
                      rscript($stationL,$yearminL,$yearmaxL,$ftype);
                   }

                   if ($station ne "")
                   {
                      $stationL = $station;
                      $yearminL = $year;
                   }
                }
             }

             if ($idx3 == 1) {
                $yearminL = $year;
                $yearmaxL = $year;
                $stationL = $station;
             }
             $yearmaxL = $year;

             $idx3++;
         }
         $idx2++;
      }
      $idx1++;
   }

   $yearmaxL--;
   if ($ftype eq "A")
   {
      rscript($stationL,$yearminL,$yearmaxL,"P");
      rscript($stationL,$yearminL,$yearmaxL,"X");
      rscript($stationL,$yearminL,$yearmaxL,"N");
      rscript($stationL,$yearminL,$yearmaxL,"M");
   } else {
      rscript($stationL,$yearminL,$yearmaxL,$ftype);
   }

   close $fhI;
   close $fb;
}

sub main
{
   get_args();

   check_for_trailing_slash(\$output_path);
   #print "output_path: '$output_path'\n";

   check_parameters($station, $yearmin, $yearmax, $ftype);

   my $ok = 0;
   $t0 = [gettimeofday];

   #print "441. cntparam: $cntparam\n";
   if ( ($cntparam == 8) || ($cntparam == 10) )
   {
       one_station($station, $yearmin, $yearmax, $ftype);
   } else {
       all_stations();
   }

   $elapsed = tv_interval($t0);

   #print "elapsed time:  $user\n";
   #print "elapsed time:  $system\n";
   print "elapsed time:   $elapsed\n";
   print "total lines:    $idx2\n";
   print "generated:      $idx3\n";
   print "total skipped:  $skipped\n";
   print "total stations: $stationcnt\n";
   print "total scripts:  $scriptcnt\n";

}

main();

