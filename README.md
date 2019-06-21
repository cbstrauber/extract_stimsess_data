# extract_stimsess_data

The script “extract_stimsess_data.m” is for the automatic extraction of behavioral task data from stimulation session files.

The script requires you to have exported the stimulation session to Matlab, which is an option in the File menu when the stimulation
session is open. The script also assumes the current file structure we have been using in the BLC (a main folder for each participant,
inside which is a folder whose label contains "StimSsn"). It only provides behavioral data for Odd Step tasks (which include the 1-back
and size change tasks).

To use the script, you will need to specify several things near the top, namely (1) the input directory (the directory containing the
participant files), (2) the output directory (where the csv containing summary data will be saved), and (3) whether you want to analyze
data for all participants in the directory whose IDs have the given prefix (set now as "BLC"), or if not, the names of specific
participants whose data you want. Beyond that, you just hit run and it will instantly provide a csv, so it could in theory be used for
looking quickly at summary behavioral data between sessions. 

The script will save summary data for all participants analyzed in a given batch into the same csv file, which can be easily imported
to R for further analysis. 
