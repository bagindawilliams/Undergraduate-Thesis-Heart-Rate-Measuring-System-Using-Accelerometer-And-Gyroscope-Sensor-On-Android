%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Direct Beat Rate from SCG


clc; clear all; close all;
%% Reading Data
%x = xlsread('DataSECG1xls.xlsx');
%acc = xlsread('scg2.xlsx');% Gyroscope
%acc = xlsread('scg3.xls');
%acc = xlsread('scg4.xls');
%acc = xlsread('scg5.xls');
%acc = xlsread('06_chest_11bpm.xls'); % bpm = 10, with strap;
acc = xlsread('sample 1.xls'); % bpm = 12 IMF 7; 

%acc = xlsread('mbient3.xls');%use 9.8

%%% Using iPhone
%acc = xlsread('scgphone2.xls');
%acc = xlsread('scgphone1kiri.xls');


time=acc(:,1);
x=acc(:,6)* 9.81;
y=acc(:,7)* 9.81;
%accz=acc(:,4);


%%%%% using mbient sensor
%accz=acc(:,4)* 9.81; 
accz=acc(:,7)* 9.81; %
z = accz - 9.81;

%y = y - 9.81;

%%%%%% using iPhone
%z = accz; 
%accz=acc(:,4);%* 9.81; %use 9.8 if using mbient

%x = x - 9.81;

fs =1/(acc(5,1)-acc(4,1));
dt=acc(5,1)-acc(4,1);
t= (0:length(acc)-1)/fs;


%%%% Total Acceleration signal
mag = sqrt((x.*x) + (y.*y) + (z.*z));
%z=z/mag;


%% Baseline Wander Removal (BWR)
%% High Pass filter to remove DC Component on RAW Acc Z
filtCutOff = 4;
[b, a] = butter(1, (filtCutOff)/(fs), 'high');
zHPF = filtfilt(b, a, z);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%Trial 1: 
%%Using LPF on Z axis after BWR
filtCutOff = 30;
[b, a] = butter(1, (filtCutOff)/(fs), 'low');
zLPF = filtfilt(b, a, zHPF);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%Trial 2:
%%Using BPF on Z axis after BWR
[b, a] = butter(1, [10/fs 30/fs], 'bandpass');
zBPF = filtfilt(b, a, zHPF);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Trial 3:
%% Using S-Golay Filter on Z axis after BWR
order = 2;
framelen = 15;
zSGF = sgolayfilt(zHPF,order,framelen);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%% Signal Plot %%%%%%%%%%%%%%%%%
%% Raw ECG and Z axis after BWR
%% We choose BPF
figure('Position', [0 1000 900 200],'Name', 'Z Axis Sensor Data');
set(gcf,'color','w');
set(gca,'FontSize',20);
hold on;
%plot(t,z,'Linewidth',1);% After BWR
plot(t,zHPF,'k','Linewidth',1);% After BWR
hold on
%plot(t,zLPF,'r','Linewidth',2);hold on
%plot(t,zBPF,'b','Linewidth',2);% chosen BPF 
plot(t,zSGF,'Linewidth',3);
hold on;
xlabel('time(s)');
ylabel('m/s^{2}');
%legend('RAW SCG','Baseline Wander', 'Filtered with BPF');
xlim([0 10]);
title('SCG Z-Axis Signal');
hold off

%%%%%%%%%%%%%%%%%%%% Pre Processing %%%%%%%%%%%%

% Taking Absolute Value of BPF
abszBPF = abs(zBPF);

%% Taking positive envelope on Z-axis BPF using Hilbert Function
zHFS = hilbert(zBPF);
posEnvelope=abs(zHFS);


%%% LPF on Postive Envelope Signal
filtCutOff = 10;
[b, a] = butter(1, (filtCutOff)/(fs), 'low');
%zLPF2 = filtfilt(b, a, abszBPF);
zLPF2 = filtfilt(b, a, posEnvelope);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Moving average filter on LPF Envelope
windowWidth = 10; % 
kernel = ones(windowWidth,1) / windowWidth;
zOut = filter(kernel, 1, zLPF2);


%%%%%%%%%%%%%%%%% Plot Processing %%%%%%%%%%%%%%%%%
figure('Position', [0 310 900 300],'Name', 'Signal Envelop');
set(gcf,'color','w');
set(gca,'FontSize',20);
hold on;
%plot(t,z,'Linewidth',1);hold on
plot(t,zBPF,'Linewidth',1);% Z-axis after BWR
hold on;
plot(t,abszBPF,'Linewidth',1);%Absolute value of Z-axis BPF
hold on
%plot(t,zLPF2,'k','Linewidth',3);
hold on;
plot(t,zOut,'k','Linewidth',3);hold on
%plot(t,posEnvelope,'k','Linewidth',1);hold on

%plot(t,abszBPF2,'Linewidth',3);hold on
%plot(t,zLPF2,'Linewidth',3);hold on
%plot(t,zOut,'Linewidth',3);hold on
hold on;
xlabel('time(s)');
ylabel('m/s^{2}');
%legend('RAW SCG', 'BPF','LPF');
%xlim([0 10])
title('Signal Envelope of Absolute Value')
hold off



%%%%%%%%%%%%%%%%% Plot of Ekstraksi %%%%%%%%%%%%%%%%%
figure('Position', [0 25 700 250],'Name', 'AO Detection');
thres = max(zOut)/4;
set(gcf,'color','w');
set(gca,'FontSize',20);
hold on;
plot(t,zOut,'k','Linewidth',3);hold on
[aopeaks,locs] = findpeaks(zOut,t,'MinPeakHeight',thres,...
    'MinPeakDistance',0.40);
plot(locs,aopeaks,'ro','Linewidth',3);
pks = numel(aopeaks);
hold on;
xlabel('time(s)');
legend('Extracted SCG', 'AO Location', 'Orientation','horizontal');
%xlim([0 60])
%ylim([0 0.15])
title({[' Estimated Beat Rate : ',num2str(pks),' bpm']})
grid on;
hold off


%%%%%%%%%%%%% Putting Them All Together %%%%%%%%%%%%%
figure('Position', [900 500 600 900], 'NumberTitle', 'off', 'Name', 'Proses');    

ax(1) = subplot(4,1,1);
hold on;
plot(t,z,'Linewidth',1.5);% After BWR
hold on;
xlabel('time(s)');
ylabel('m/s^{2}');
%xlim([0 5]);
set(gcf,'color','w');
set(gca,'FontSize',16);grid on;
legend('Raw SCG','Orientation','horizontal','Location','SouthEast');
hold off   

ax(2) = subplot(4,1,2);
hold on;
plot(t,zHPF,'Linewidth',1);% After BWR
hold on;
plot(t,zBPF,'r','Linewidth',1.5);% After BWR
xlabel('time(s)');
ylabel('m/s^{2}');
legend('Baseline Wander','Filtered SCG','Orientation','horizontal','Location','SouthEast');
%xlim([0 5]);
%ylim([0 10]);
set(gcf,'color','w');
set(gca,'FontSize',16);grid on;
hold off   

ax(3) = subplot(4,1,3);
hold on;
plot(t,zBPF,'Linewidth',1);% Z-axis after BWR
hold on;
plot(t,abszBPF,'r','Linewidth',1.5);%Absolute value of Z-axis BPF
hold on
%plot(t,zOut,'k','Linewidth',3);hold on
hold on;
xlabel('time(s)');
legend('Filtered SCG', 'Absolute','Orientation','horizontal','Location','SouthEast');
%xlim([0 5])
%ylim([-0.175 0.175])
set(gcf,'color','w');
set(gca,'FontSize',16);grid on;
hold off   

ax(4) = subplot(4,1,4);
hold on;
plot(t,abszBPF,'b','Linewidth',1);%Absolute value of Z-axis BPF
hold on
plot(t,zOut,'r','Linewidth',3);hold on
hold on;
xlabel('time(s)');
legend('Absolute', 'Hilbert Envelope','Orientation','horizontal','Location','NorthWest');
%xlim([0 5])
set(gcf,'color','w');
set(gca,'FontSize',16);grid on;
hold off   


