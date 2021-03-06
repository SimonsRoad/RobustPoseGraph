function iterativeMain(inputFilesCreated, outputFilesCreated, prFileName, groundTruth, ateFileName, autTsFile, gtTsFile)
%ONESHOTMAIN heat embedded thresholding algorithm for removing wrong loop closures
%clear all; close all; clc;
%inputFilesCreated='intelDataset/intelFilesCreated.txt';
%outputFilesCreated='intelAUTDataset/intelAUTFilesCreated.txt';
%prFileName='intelAUTDataset/prPerformance.txt';
%groundTruth='intelDCS.mat';

%% Initialization

% -- tests to be made
dcsTests = 1;
cauchyTests = 1;
rrrTests = 1;

% -- Read input Directory
idx       = find(inputFilesCreated == '/');
idx       = idx(end);
inputDir = inputFilesCreated(1:idx);
% fprintf('Input Directory: %s\n',inputDir);


% -- Check if output directory exists, else make it.
% ---- Extract output Directory

idx       = find(outputFilesCreated == '/');
idx       = idx(end);
outputDir = outputFilesCreated(1:idx);
% fprintf('Output Directory: %s\n',outputDir);

% ---- Check if directory exists
ex=exist(outputDir,'dir');

% ---- Action based on check
if ( ex == 0)
    % ------ Make the directory
    mkdir(outputDir);
end
% -- If outputFilesCreated exists, make sure it is deleted
% This is handled that we would open the file in write only mode, which
% would delete any traces of the old data remaining in the file.
outFile = fopen(outputFilesCreated,'w');

% -- load ground truth for calculating tScale
load(groundTruth);

% -- Read the inputFilesCreated file
inFile  = fopen(inputFilesCreated,'r');
tline   = fgetl(inFile);
count   = 1;

% -- reset the prFile

% -- reset the prFile
prFileDotIdx = find(prFileName=='.');
prFileDotIdx = prFileDotIdx(end);
prFileDotIdx = prFileDotIdx - 1;
prRRRFileName = [prFileName(1:prFileDotIdx),'-RRR.txt'];
if (exist(prRRRFileName,'file') == 2)
    delete(prRRRFileName);
end
if (exist(prFileName,'file') == 2)
    delete(prFileName);
end
prFileID = fopen(prFileName,'w');

% -- Relate Poses to Timestamp
tic;
[gtMapAutPose] = relatePosetoTimestamp(autTsFile, gtTsFile);
fprintf(1,'Relating poses to Timestamp: ');
toc;

while ischar(tline)
    % -- convert .g2o file to .mat file
    idx = find(tline == '.');
    idx = idx(end) - 1;
    inputg2oFileBasis = strcat(inputDir,tline(1:idx));
    inputMatFileName = strcat(inputDir,tline(1:idx),'.mat');
    inputg2oFileName = strcat(inputDir,tline(1:idx),'.g2o');
    % -- check if file exists
    if (exist(inputMatFileName,'file') ~= 2)
        fprintf('ERROR: %s does not exist!\n', inputMatFileName);
        if (exist(inputg2oFileName,'file') ~= 2)
            fprintf('ERROR: %s does not exist!\n', inputg2oFileName);
            tline = fgetl(inFile);
            continue;
        else
            readg2oFile(inputg2oFileName,'fc.txt',1);
        end
    end
    outputFileNameBasis=strcat(outputDir,tline(1:idx),'-AUT');
    fprintf(1,'Output File Name: %s\n',outputFileNameBasis);
    [precision, recall] = checkIter(inputMatFileName, groundTruth, outputFileNameBasis, gtMapAutPose);
    fprintf(prFileID,'%f %f\n',precision, recall);
    fprintf(outFile,'%s.g2o\n',outputFileNameBasis);
    calculatePerformanceATEwithTS(outputFileNameBasis, inputg2oFileBasis, groundTruth, dcsTests, cauchyTests, rrrTests, ateFileName, prRRRFileName, gtMapAutPose);
    fprintf(1,'-------------------------------------------------------------\n');
    % -- next step of loop
    count = count +1;
%     if ( count > 1)
%       fclose(outFile);
%       fclose(inFile);
%       return;
%     end
    tline = fgetl(inFile);
end
fclose(outFile);
fclose(inFile);
fclose(prFileID);

end
