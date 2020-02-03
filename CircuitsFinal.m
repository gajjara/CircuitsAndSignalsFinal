%% Get DAC
s = daq.createSession('ni');
ch = addAnalogInputChannel(s, 'Dev1', 'ai0', 'Voltage');

%% Get Data
samplingfrequncy = 600;
s.Rate = samplingfrequncy;
s.DurationInSeconds = 10;
[data, time] = s.startForeground();
save('Lab16ECGSignal1.mat', 'time', 'data');

%% ParksMcClellan Filter
% Define parameters
samplingfrequency = 600;
lowercutoff = 150;
uppercutoff = 250;
dev = [0.01 0.05];

% Create filter
[order, fo, ao, w] = firpmord([lowercutoff uppercutoff], [1 0], ...
    dev, samplingfrequency);
b = firpm(order, fo, ao, w);
a = 1;
[h_pcm,f] = freqz(b, a, length(data), samplingfrequency);
%pcmfilt_time = filter(b, a, data);

% Using fourier transform to implement parks mcclellan filter 
fourier_data = fft(data);
pcmfilt_freq = h_pcm.*fourier_data;
pcmfilt_time = (ifft(pcmfilt_freq));

% Plot data
figure;
subplot(2,1,1); plot(f, abs(h_pcm));
title("Magnitude of Transfer Function of Parks McClellan Filter");
xlabel("Frequency (Hz)"); ylabel("Magnitude");
subplot(2,1,2); plot(f, angle(h_pcm));
title("Phase of Transfer Function of Parks McClellan Filter");
xlabel("Frequency (Hz)"); ylabel("Phase (radians)");
figure;
subplot(2,2,1); plot(time, data);
title("Initial ECG Data");
xlabel("Time"); ylabel("Voltage (V)");
subplot(2,2,2);  plot(time, pcmfilt_time); 
title("Filtered ECG using Parks McClellan");
xlabel("Time"); ylabel("Voltage (V)");
subplot(2,2,3); plot(f, abs(fourier_data)); xlim([0 300]);
title("Fourier Transform of Initial Data");
xlabel("Frequency (Hz)"); ylabel("Signal Strength");
subplot(2,2,4); plot(f, abs(pcmfilt_freq)); xlim([0 300]);
title("Fourier Transform of Filtered Data");
xlabel("Frequency (Hz)"); ylabel("Signal Strength");


%% Exercise 2: Remove 60Hz interference and harmonics
% Option 1: Notch Filter of 60-240Hz
notchfilt_time = pcmfilt_time;
for i = 60:60:240
    wo = i/(samplingfrequency/2);
    bw = wo/20;
    [b,a] = iirnotch(wo,bw);
    if(i <= 60)
        b_60 = b; a_60 = a;
    end
    notchfilt_time = filter(b,a, notchfilt_time);
end
notchfilt_freq = fft(notchfilt_time);

% Show 60Hz notch filter
fvtool(b_60,a_60);

% Plot data
figure;
subplot(2,2,1); plot(time, pcmfilt_time);
title("Initial ECG Data");
xlabel("Time");
ylabel("Voltage (V)");
subplot(2,2,2); plot(time, notchfilt_time);
title("Filtered ECG using Notch");
xlabel("Time");
ylabel("Voltage (V)");
subplot(2,2,3); plot(f, abs(pcmfilt_freq));
title("Fourier Transform of Initial Data");
xlabel("Frequency (Hz)");
ylabel("Signal Strength");
subplot(2,2,4); plot(f, abs(notchfilt_freq));
title("Fourier Transform of Filtered Data");
xlabel("Frequency (Hz)");
ylabel("Signal Strength");

%% Exercise 3: Detect Heart Rate
% Find location of maximum of fourier transform of filtered data
found = find(notchfilt_freq == max(notchfilt_freq));
rate = f(found) + 1; % Account for off by 1 error
bpm = rate*60;
disp("Detected Frequency (Hz)");
disp(rate)
disp("Detected Heart Rate (bpm)");
disp(bpm);