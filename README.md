# FLTempPrecipHist

Analysis of Historical Temperature / Precipitation for the State of Florida
The source of the data is the "Florida Climate Center" (https://climatecenter.fsu.edu/climate-data-access-tools/downloadable-data).

All available data was manually downloaded and combined into one csv file - AllSave.csv. At the time of download, data from 90 stations were available (see "Stations.txt").

Missing data is indicated by a negative value (there is more than one negative value that indicates "No Data"). This data was dropped.

It is important to note the Perl source file "FLHistMinMax.pl" examines AllSave.csv, determines the first and last year, then generates four R script files for each station - Minimum Temperature, Mean Temperature, Maximum Temperature, and Precipitation.

When executed from R, these script files produce and save four graphs for each station.

Each graph contains two plots - one for the very first year of full data, and one for the last year of full data.

On these graphs, the x axis is the Julian day, and the y axis is for either temperature or precipitation.

Important: For any given Julian day, if data was not available for BOTH the first and last year specified, that day in it's entirety was not included.

For example, when "FLHistMinMax.pl" is executed using Perl, station 80211 produces four R script files:

1) 80211_1931_2019_M.txt 2) 80211_1931_2019_N.txt, 3) 80211_1931_2019_X.txt, and 4) 80211_1931_2019_P.txt.

80211_1931_2019_M.txt - Historical Minimum Temperature for station 80211

80211_1931_2019_N.txt - Historical Mean Temperature for station 80211

80211_1931_2019_X.txt - Historical Maximum Temperature for station 80211

80211_1931_2019_P.txt - Historical Precipitation for station 80211

When these rscript files when executed from R (ggplot2 is required), the following plots are produced:

80211_1931_2019_M.pdf - Plot comparing Minimum Temperature data for years 1931 and 2019 for station 80211

80211_1931_2019_N.pdf - Plot comparing Mean Temperature data for years 1931 and 2019 for station 80211

80211_1931_2019_X.pdf - Plot comparing Maximum Temperature data for years 1931 and 2019 for station 80211

80211_1931_2019_P.pdf - Plot comparing Precipitation data for years 1931 and 2019 for station 80211

HOW TO USE
----------
1. Download all zip files
2. Unzip all files in a single folder
3. Analyze the finished plots (see pdf files contained in FLTempPrecipHistPlot.zip) OR
4. Regenerate all R script files and plots.
   R must be installed first.
   In order to re-generate the R script files:
      a. Use "FLHistMinMax.exe" (if Perl is not installed(
      b. OR, if Perl is installed, use FLHistMinMax.pl (requires the Perl module "Time::HiRes" is also installed).

FILE DESCRIPTIONS
-----------------
AllSave.zip                 - Zip file of AllSave.csv. All stations, all years, mean temperature, minimum temperature, maximum temperature, and precipitation downloaded from the above site.

                              There should be 360 files (90 stations, 4 files per station), but 4 appear to be missing.

FLTempPrecipHistRscript.zip - Zip file of all r script files (mean temperature, minimum temperature, maximum temperature, and precipitation for all stations)

FLTempPrecipHistPlot.zip    - Zip file of all plots. (mean temperature, minimum temperature, maximum temperature, and precipitation plots for all stations)

FLHistMinMax.pl             - Examines data from AllSave.csv and generates all r script files and FLHistScriptGen.bat files.
                              This program can also be executed for a single station.

FLHistMinMax.exe            - Generated from source FLHistMinMax.pl using "Perl Packer".

FLHistScriptGen.bat         - If R is installed on your machine, execution of this batch file from a command prompt, will read all the r script files and generate 4 plots for each station. Each graph will contains two years - the first and next to the last year.

Stations.txt                - List of all station id's and descriptions

Stations.zip                - Data for each individual station (one file per station)


SOFTWARE VERSIONS USED

PERL
----

This is Perl 5, version 32, subversion 1 (v5.32.1) built for MSWin32-x64-multi-thread

Copyright 1987-2021, Larry Wall

Perl may be copied only under the terms of either the Artistic License or the
GNU General Public License, which may be found in the Perl 5 source kit.

Complete documentation for Perl, including FAQ lists, should be found on
this system using "man Perl" or "perldoc perl".  If you have access to the
Internet, point your browser at http://www.perl.org/, the Perl Home Page.


R
---

R version 4.1.0 (2021-05-18) -- "Camp Pontanezen"
Copyright (C) 2021 The R Foundation for Statistical Computing
Platform: x86_64-w64-mingw32/x64 (64-bit)


