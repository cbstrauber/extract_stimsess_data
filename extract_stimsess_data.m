% Written 6/19/19 by Ben Strauber

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
outputFilePath = "~/Documents/Audiovisual_Norcialab/";

% 3. Enter the ID prefix of participants whose behavioral data you want here.
% Make sure you've already exported the stim session data using "Export to Matlab"!
% Alternatively, enter the individual IDs of participants you want. Make
% sure to comment out the line you're not using.
participantIDPrefix = "BLC";
% participantIDs = ["BLC_001", "BLC_007", "BLC_008"];

% you're ready to go! hit run!


%% code code code
trueResponseColumnIndex = 1;
givenResponseColumnIndex = 2;
reactionTimeIndex = 3;

participantDataArray = [];

if exist("participantIDPrefix")
    participantFolders = dir(participantFolderPath + participantIDPrefix + "*"); 
    participantIDs = string({participantFolders.name}); 
end
    
for participantIndex = 1:length(participantIDs)    
    participantID = participantIDs(participantIndex);
    participantFolder = participantFolderPath + participantID;
    behavioralDataFiles = dir(participantFolder + "/*Ssn/Exp_MATL/RTSeg*");
    
    if isempty(behavioralDataFiles) && ~contains(participantID, ".zip")
        fprintf("You're missing files for %s! Make sure the folder name contains 'StimSsn'\n and that you've exported the stimulation session to matlab.\n", participantID);
    end
    
    conditionNumbers = [];
    
    for fileIndex = 1:length(behavioralDataFiles)
        behavioralFileDirectory = behavioralDataFiles(fileIndex).folder;
        behavioralFileName = behavioralDataFiles(fileIndex).name;
        load(behavioralFileDirectory + "/" + behavioralFileName);
        if SegmentInfo.taskMode == "Odd Step" 
            for trialIndex = 1:length([TimeLine.trlNmb])
                conditionNumber = TimeLine(trialIndex).cndNmb;
                conditionNumbers(conditionNumber) = conditionNumber;
            end
        end
    end
    
    nConditions = length(conditionNumbers);
    trueResponseTotals = zeros(1, nConditions);
    hitTotals = zeros(1, nConditions);
    missTotals = zeros(1, nConditions);
    falseAlarmTotals = zeros(1, nConditions);
    correctRejectionTotals = zeros(1, nConditions);
    hitReactionTimeTotals = zeros(1, nConditions);
    missReactionTimeTotals = zeros(1, nConditions);
    falseAlarmReactionTimeTotals = zeros(1, nConditions);
    correctRejectionReactionTimeTotals = zeros(1, nConditions);
    dprimes = zeros(1, nConditions);
    
    
    for fileIndex = 1:length(behavioralDataFiles)
        behavioralFileDirectory = behavioralDataFiles(fileIndex).folder;
        behavioralFileName = behavioralDataFiles(fileIndex).name;
        load(behavioralFileDirectory + "/" + behavioralFileName);
        if SegmentInfo.taskMode == "Odd Step" 
            for trialIndex = 1:length([TimeLine.trlNmb])
                conditionNumber = TimeLine(trialIndex).cndNmb;
                for stepNumber = 1:size(TimeLine(trialIndex).stepData, 1)
                    trueResponse = TimeLine(trialIndex).stepData(stepNumber, trueResponseColumnIndex);
                    givenResponse = TimeLine(trialIndex).stepData(stepNumber, givenResponseColumnIndex);
                    reactionTime = TimeLine(trialIndex).stepData(stepNumber, reactionTimeIndex);
                    if trueResponse == 1
                        trueResponseTotals(conditionNumber) = trueResponseTotals(conditionNumber) + 1;
                        if givenResponse == 1
                            hitTotals(conditionNumber) = hitTotals(conditionNumber) + 1;
                            hitReactionTimeTotals(conditionNumber) = hitReactionTimeTotals(conditionNumber) + reactionTime;
                        else
                            missTotals(conditionNumber) = missTotals(conditionNumber) + 1;
                        end
                    else
                        if givenResponse == 1
                            falseAlarmTotals(conditionNumber) = falseAlarmTotals(conditionNumber) + 1;
                            falseAlarmReactionTimeTotals(conditionNumber) = falseAlarmReactionTimeTotals(conditionNumber) + reactionTime;
                        else
                            correctRejectionTotals(conditionNumber) = correctRejectionTotals(conditionNumber) + 1;
                        end
                    end
                end
            end
            

        end
    end
    
    for conditionID = 1:length(conditionNumbers)
        dateTime = datetime(SegmentInfo.dateTime, 'InputFormat','dd-MM-yyyy HH:mm:ss');
        currentDate = dateTime;
        currentTime = dateTime;
        currentDate.Format = 'MM-dd-yyyy';
        currentDate = string(currentDate);
        currentTime.Format = 'HH:mm:ss';
        currentTime = string(currentTime);
        correctPercentage(conditionID) = hitTotals(conditionID) / trueResponseTotals(conditionID);
        falseAlarmPercentage(conditionID) = falseAlarmTotals(conditionID) / trueResponseTotals(conditionID);
        
        if correctPercentage(conditionID) == 0
            hitPercentageForDprime(conditionID) = (hitTotals(conditionID) + 1) / trueResponseTotals(conditionID);
        elseif correctPercentage(conditionID) == 1
            hitPercentageForDprime(conditionID) = (hitTotals(conditionID) - 1) / trueResponseTotals(conditionID);
        else
            hitPercentageForDprime(conditionID) = correctPercentage(conditionID);
        end
        
        if falseAlarmPercentage(conditionID) == 0
            falseAlarmPercentageForDprime(conditionID) = (falseAlarmTotals(conditionID) + 1) / trueResponseTotals(conditionID);
        elseif falseAlarmPercentage(conditionID) == 1
            falseAlarmPercentageForDprime(conditionID) = (falseAlarmTotals(conditionID) - 1) / trueResponseTotals(conditionID);
        else
            falseAlarmPercentageForDprime(conditionID) = falseAlarmPercentage(conditionID);
        end
        
        dprimes(conditionID) = norminv(hitPercentageForDprime(conditionID)) - norminv(falseAlarmPercentageForDprime(conditionID));
        
        if hitTotals(conditionID) ~= 0
            hitReactionTimeAverage(conditionID) = hitReactionTimeTotals(conditionID) / hitTotals(conditionID);
        else
            hitReactionTimeAverage(conditionID) = 'NA';
        end
        
        falseAlarmReactionTimeAverage(conditionID) = falseAlarmReactionTimeTotals(conditionID) / falseAlarmTotals(conditionID);
        newRow = [participantID currentDate currentTime conditionID hitTotals(conditionID) trueResponseTotals(conditionID) falseAlarmTotals(conditionID) correctPercentage(conditionID) dprimes(conditionID) hitReactionTimeAverage(conditionID)];
        participantDataArray = [participantDataArray; newRow];
    end    
end

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
