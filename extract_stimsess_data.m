% Updated 7/12/19 by Ben Strauber

% This script takes in a folder name containing participant files and generates a csv file
% with averages of each participant's behavioral data by condition extracted 
% from xDiva stimulation sessions. The file structure should be like that 
% in the BLC, with a main participant folder containing the stimulation session 
% folder(s). 
% If you need another structure, please let me know!

clear all

%% Please provide the following three things:

% 1. This is where to find the participant folders.
participantFolderPath = "~/Documents/Dropbox/2019_Synapse_Data/";

% 2. This is where the output file will go.
outputFilePath = "~/Documents/EdNeuro_Initiative/synapse_behavioral_data/";

% 3. Enter the ID prefix of participants whose behavioral data you want here.
% Make sure you've already exported the stim session data using "Export to Matlab"!
% Alternatively, enter the individual IDs of participants you want. Make
% sure to comment out the line you're not using.
participantIDPrefix = "BLC";
% participantIDs = ["BLC_001", "BLC_006", "BLC_010"];

% you're ready to go! hit run!


%% code code code
trueResponseColumnIndex = 1;
givenResponseColumnIndex = 2;
reactionTimeIndex = 3;

participantDataArray = [];

% gets all participants in directory whose folder names start with prefix
if exist("participantIDPrefix")
    participantFolders = dir(participantFolderPath + participantIDPrefix + "*"); 
    participantIDs = string({participantFolders.name}); 
end

% warning message and exit if no participants
if ~exist("participantIDs")
    fprintf("You don't have any participants! Make sure you've chosen the right prefix.");
    return;
end

% loops through each participant, ultimately adding summary data for each 
% condition for that participant to an array
for participantIndex = 1:length(participantIDs)    
    participantID = participantIDs(participantIndex);
    participantFolder = participantFolderPath + participantID;
    behavioralDataFiles = dir(participantFolder + "/**/*RTSeg*");
    behavioralDataFiles = behavioralDataFiles(contains(convertCharsToStrings({behavioralDataFiles(:).folder}), "StimSsn", 'IgnoreCase', true));
    
    % TODO: separate condition calculations by ssn folder
    
    % TODO: accommodate other file structures (eg stimssn files from different 
    % participants in same folder) (can take lastname field from
    % SegmentInfo, but should also consider renaming issue)
    
    % gives warning message if no files for participant, and skips to next
    % participant
    if isempty(behavioralDataFiles)
        if ~(contains(participantID, ".zip"))
            fprintf("You're missing files for %s! Make sure the folder name contains 'StimSsn'\n and that you've exported the stimulation session to matlab.\n", participantID);
        end
        continue;
    end
    
    trialCounter = 0;
    allTrials = struct;
    
    % creates a struct of all trials in session
    for fileIndex = 1:length(behavioralDataFiles)
        behavioralFileDirectory = behavioralDataFiles(fileIndex).folder;
        behavioralFileName = behavioralDataFiles(fileIndex).name;
        behavioralFilePath = behavioralFileDirectory + "/" + behavioralFileName;
        load(behavioralFilePath);
        if SegmentInfo.taskMode == "Odd Step" 
            for trialIndex = 1:length([TimeLine.trlNmb])
                trialCounter = trialCounter + 1;
                allTrials(trialCounter).condition = TimeLine(trialIndex).cndNmb;
                allTrials(trialCounter).stepData = TimeLine(trialIndex).stepData;      
            end
        end
    end
    
    % gets only unique conditions
    conditions = unique([allTrials.condition]);
    nConditions = length(conditions);
    
    % for each condition in struct, loops through all trials and gets data  
    % for each trial, creating summary data and adding it to an array
    for conditionIndex = 1:nConditions
        conditionNumber = conditions(conditionIndex);
        conditionTrials = allTrials(([allTrials.condition] == conditionNumber));
        [trueResponseTotal, hitTotal, hitRTTotal, falseAlarmTotal, falseAlarmRTTotal, correctRejectionTotal] = deal(0);
        for trialIndex = 1:length(conditionTrials)
            for stepNumber = 1:size(conditionTrials(trialIndex).stepData, 1)
                trueResponse = conditionTrials(trialIndex).stepData(stepNumber, trueResponseColumnIndex);
                givenResponse = conditionTrials(trialIndex).stepData(stepNumber, givenResponseColumnIndex);
                reactionTime = conditionTrials(trialIndex).stepData(stepNumber, reactionTimeIndex);
                if trueResponse == 1
                    trueResponseTotal = trueResponseTotal + 1;
                    if givenResponse == 1
                        hitTotal = hitTotal + 1;
                        hitRTTotal = hitRTTotal + reactionTime;
                    end
                else
                    if givenResponse == 1
                        falseAlarmTotal = falseAlarmTotal + 1;
                        falseAlarmRTTotal = falseAlarmRTTotal + reactionTime;
                    else
                        correctRejectionTotal = correctRejectionTotal + 1;
                    end
                end
            end         
        end    
        
        sessionDateTime = datetime(SegmentInfo.dateTime, 'InputFormat','dd-MM-yyyy HH:mm:ss');
        sessionDate = sessionDateTime;
        sessionTime = sessionDateTime;
        sessionDate.Format = 'MM-dd-yyyy';
        sessionDate = string(sessionDate);
        sessionTime.Format = 'HH:mm:ss';
        sessionTime = string(sessionTime);
        
        correctPercentage = hitTotal / trueResponseTotal;
        falseAlarmPercentage = falseAlarmTotal / trueResponseTotal;
        
        if correctPercentage == 0
            hitPercentageForDprime = (hitTotal + 1) / trueResponseTotal;
        elseif correctPercentage == 1
            hitPercentageForDprime = (hitTotal - 1) / trueResponseTotal;
        else
            hitPercentageForDprime = correctPercentage;
        end
        
        if falseAlarmPercentage == 0
            falseAlarmPercentageForDprime = (falseAlarmTotal + 1) / trueResponseTotal;
        elseif falseAlarmPercentage >= 1
            falseAlarmPercentageForDprime = (trueResponseTotal - 1) / trueResponseTotal;
        else
            falseAlarmPercentageForDprime = falseAlarmPercentage;
        end
        
        dprime = norminv(hitPercentageForDprime) - norminv(falseAlarmPercentageForDprime);
        
        if hitTotal ~= 0
            hitReactionTimeAverage = hitRTTotal / hitTotal;
        else
            hitReactionTimeAverage = "NA";
        end
        
        falseAlarmReactionTimeAverage = falseAlarmRTTotal / falseAlarmTotal;
        newRow = [participantID sessionDate sessionTime conditionNumber hitTotal trueResponseTotal falseAlarmTotal correctPercentage dprime hitReactionTimeAverage];
        participantDataArray = [participantDataArray; newRow];       
    end
end

% converts table to an array and sorts by subject, then date, then condition
participantDataTable = array2table(participantDataArray, 'VariableNames', {'SubjectID', 'Date', 'Time', 'Condition', 'Hits', 'TotalPresented', 'FalseAlarms', 'Accuracy', 'Dprime', 'HitReactionTime'});
participantDataTable = sortrows(participantDataTable, {'SubjectID', 'Date', 'Condition'});

currentDate = datetime('now');
currentDate.Format = 'MMM-dd-yyyy';
currentDate = string(currentDate);

currentTime = datetime('now');
currentTime.Format = 'HHmmss';
currentTime = string(currentTime);
outputFileName = outputFilePath + "behavioral_data_" + currentDate + "_" + currentTime + ".csv";
writetable(participantDataTable, outputFileName);

fprintf("Done! A csv containing the participant data is waiting for you to explore it.\n");

% note: blc17 in blc25 folder