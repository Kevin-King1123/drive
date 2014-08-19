
% Get DICOM for analysis
[dicomImageFile.filename, dicomImageFile.pathname] = ...
    uigetfile('*.dcm,*.DCM','Pick a DICOM file');
addpath(genpath(dicomImageFile.pathname))

dicomImage = dicomread(dicomImageFile.filename);
dicomImage = permute(dicomImage, [1 2 4 3]);

% Display
dicomViewer(dicomImage)

%%
bioimpedanceFile = uigetfile('*.*','Pick an ACQ file');
acq = load_acq(bioimpedanceFile);

ohmsPerVolt = 20;

bioimpedanceArm = acq.data(:,1)*ohmsPerVolt;
bioimpedanceLeg = acq.data(:,2)*ohmsPerVolt;
biomipedanceChest = acq.data(:,3)*ohmsPerVolt;
bioimpedanceForearm = acq.data(:,4)*ohmsPerVolt;

dtBioimpedance = acq.hdr.graph.sample_time;
timeStartBioimpedance = acq.hdr.graph.first_time_offset/1000;

day = 60*60*24;
timeStartBioimpedance6 = str2double(datestr(timeStartBioimpedance/day,'HHMMSS'));

shift = 0;
% Find markers in ACQKnowledge data
timeMarkerBioimpedance = zeros(1,length(acq.markers.lSample));
timeMarkerBioimpedanceInd = zeros(1,length(acq.markers.lSample));
for nMarkers = 1:length(acq.markers.lSample)
    if acq.markers.lSample(nMarkers) == 0
        shift = shift + 1;
    else
        x = str2double(datestr(timeStartBioimpedance/day+...
            (double(acq.markers.lSample(nMarkers)/200)/day),'HHMMSS'));
        timeMarkerBioimpedance(nMarkers-shift) = x;
        clipName{1,nMarkers-shift} = acq.markers.szText{1,nMarkers}(11:end);
        timeMarkerBioimpedanceInd(nMarkers-shift) = acq.markers.lSample(nMarkers);
    end
end
clear x

timeMarkerBioimpedance = unique(timeMarkerBioimpedance);
clipName = unique(clipName);

% Impedance analysis
Fs = 200;
dt = 1/Fs;
totalTime = 10; % second
offset = 0.75;

timeBioimpedance = offset:dt:totalTime;





bioimpedanceLegSMOOTH = smooth(bioimpedanceLeg,Fs/2);
bioimpedanceLegSMOOTH = smooth(bioimpedanceLegSMOOTH, 20);
respLegSMOOTH = smooth(bioimpedanceLegSMOOTH, 200);
cardLegSMOOTH = smooth(bioimpedanceLegSMOOTH - respLegSMOOTH);

bioimpedanceArmSMOOTH = smooth(bioimpedanceArm,Fs/2);
bioimpedanceArmSMOOTH = smooth(bioimpedanceArmSMOOTH, 20);






DATA_TO_ANALYZE = 1;
% LEG DATA
figure, subplot(3,1,1), plot(timeBioimpedance', ...
    bioimpedanceLegSMOOTH(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*offset:...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*totalTime)) ...
    - mean(bioimpedanceLegSMOOTH(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*offset:...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*totalTime))))
title(clipName(DATA_TO_ANALYZE))

subplot(3,1,2), plot(timeBioimpedance', ...
    respLegSMOOTH(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*offset:...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*totalTime)) ...
    - mean(respLegSMOOTH(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*offset:...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*totalTime))))
title('Respiratory Signal')

subplot(3,1,3), plot(timeBioimpedance', ...
    cardLegSMOOTH(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*offset:...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*totalTime)) ...
    - mean(cardLegSMOOTH(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*offset:...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*totalTime))))
title('Cardiac Signal')


%%
plot(bioimpedanceLeg(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*offset:...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*totalTime))...
    - mean(bioimpedanceLegSMOOTH(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*offset:...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*totalTime))))

hold on, plot(bioimpedanceLegSMOOTH(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*offset:...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*totalTime)) ...
    - mean(bioimpedanceLegSMOOTH(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*offset:...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*totalTime))),'y')

%%
plot(timeBioimpedance,bioimpedanceLeg(1:length(timeBioimpedance)))
hold on, plot(timeBioimpedance,bioimpedanceLegSMOOTH(1:length(timeBioimpedance)),...
    'g','LineWidth',2)

[ymax,imax,ymin,imin] = extrema(bioimpedanceLegSMOOTH(1:length(timeBioimpedance)));
hold on, plot(timeBioimpedance(imax),ymax,'r*',timeBioimpedance(imin),ymin,'ro')

% 
% cardStuff = bioimpedanceLeg(1:length(timeBioimpedance)) ...
%     - bioimpedanceLegSMOOTH(1:length(timeBioimpedance));
% 
% figure, plot(timeBioimpedance,cardStuff)




%% Extra filter stuff that isn't/can't work
% Filters
% Remove 60 Hz
[b, a] = butter(9,60/(Fs/2),'low'); % Remove 50Hz and above
bioimpedanceLegFILT = filter(b,a,bioimpedanceLeg);
plot(bioimpedanceLegFILT)


respCutoff = 1; % Hz
[zResp, pResp, kResp] = ...
    butter(8,respCutoff./Fs,'low');
sosResp = zp2sos(zResp,pResp,kResp);

cardCutoff = [1 3]; % Hz
[zCard, pCard, kCard] = ...
    butter(8,cardCutoff./Fs,'bandpass');



% FFT
NFFT = 2^nextpow2(length(timeBioimpedance));
B = fft(bioimpedanceLeg(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE):...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*totalTime)), NFFT)...
    /length(timeBioimpedance);
f = Fs/2*linspace(0,1,NFFT/2+1);

% 
% 
plot(f,abs(B(1:NFFT/2+1)))

figure, subplot(2,1,1), plot(timeBioimpedance', ...
    bioimpedanceLegFILT(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*offset:...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*totalTime)) ...
    - mean(bioimpedanceLegFILT(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*offset:...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+Fs*totalTime))))
title(clipName(DATA_TO_ANALYZE))