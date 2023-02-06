% This simulation platform is based on Matlab 5G Toolbox. It utilize
% objects and functions of it's New Radio set so it mostly follows default
% toolbox notation. One can find additional explanation on the 5G New Radio
% Polar Coding page in the 5G Toolbox documentation

% Parameters from the Task Description
R = 1/2; % Effective code rate (r), R*E > 30
E = 100; % Rate matched block length (n), E <= 8192
snrdB = 1; % Signal-to-noise ratio, dB
tx_max = 3; % Max number of retransmissions

% Dependent parameters
K = floor(R*E); % % Message length in bits, including CRC
% snrdB = 10*log10(signal_variance / noise_variance)
% noise_varriance = signal_variance / (10^(snrdB/10))
% assuming signal_variance = 1:
noiseVar = 10.^(-snrdB/10); % Noise variance

% Simulation parameters
nExpMax = 1e5; % Maximum number of experiments per snrdB point
nErrMax = 100; % Maximum number of errors to collect.

% AWGN Channel
chan = comm.AWGNChannel('NoiseMethod','Variance','Variance',noiseVar);
bps
