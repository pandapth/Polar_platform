% This simulation platform is based on Matlab 5G Toolbox. It utilize
% objects and functions of it's New Radio set so it mostly follows default
% toolbox notation. One can find additional explanation on the 5G New Radio
% Polar Coding page in the 5G Toolbox documentation. I tried to keep as
% much parameters default as possible to avoid the code overload.
% To run the simulation just run this script.
clc;
clear;
% Parameters from the Task Description
R = 0.2389; % Effective code rate (r), R*E > 30
E = 180; % Rate matched block length (n), E <= 8192
snrdB = 1:0.2:2; % Signal-to-noise ratio, dB
tx_max = 1; % Max number of retransmissions

% Dependent parameters
K = floor(R*E); % % Message length in bits, including CRC

% snrdB = 10*log10(signal_variance / noise_variance)
% noise_varriance = signal_variance / (10^(snrdB/10))
% assuming signal_variance = 1:
noiseVar = 10.^(-snrdB/10); % Noise variance

% 24-bit CRC is a default scheme for nrPolarDecode. If you want to change
% it don't forget to properly change the call of nrPolarDecode below.
crcLen = 24; % number of CRC bits in the message
poly = '24C'; % CRC polynom type; change in accordance to crcLen

L = 8; % SCL decoding list size

% Simulation parameters
nExpMax = 1e5; % Maximum number of experiments per snrdB point
nBlErrMax = 20; % Maximum number of errors to collect.
modType = 'BPSK'; % Modulation type

avBer = zeros(1, length(noiseVar));
avBler = zeros(1, length(noiseVar));
avTx = zeros(1, length(noiseVar));
pool = parpool(5); % initiating parallel pool.
parfor ind = 1:length(noiseVar)
   chan = comm.AWGNChannel('NoiseMethod','Variance'); % AWGN Channel
   chan.Variance =  noiseVar(ind);
   nExp = 0; % Total number of experiments per snr point
   nErr = 0; % Total number of errors per snr point
   nBlErr = 0; % Total number of block errors per snr point
   nTx = 0; % Total number of transmissions per snr point
   while (nExp < nExpMax)&&(nBlErr < nBlErrMax)
       nExp = nExp + 1;      
       
       info = randi([0 1],K-crcLen,1); % generating information message
       msgcrc = nrCRCEncode(info,poly); % message with CRC, length = K
       encoded = nrPolarEncode(msgcrc, E); % NR polar encoding
       
       % Actual Polar codeword length must be a power of 2. However 5G NR
       % scheme utilize rate matching scheme to fit the block to required 
       % length <= 2^nMax
       N = length(encoded); % Full length of Polar codeword
       
       matched = nrRateMatchPolar(encoded,K,E); % Rate matching
       modulated = nrSymbolModulate(matched,'QPSK'); % BPSK modulation
       
       % Retransmission loop
       % A simplest form of HARQ scheme is implemented below: when got nack
       % it just send same message again. Only the message obtained from
       % the last retransmission will be considered for BER analysis.
       txCount = 0;
       ack = 0;
       while(txCount < tx_max)&&(ack == 0)
           txCount = txCount + 1;
           
           noised = chan(modulated); % adding awgn
           % soft-output demodulation
           llrs = nrSymbolDemodulate(noised,'QPSK',noiseVar(ind));
           decMatched = nrRateRecoverPolar(llrs,K,N);
           decoded = nrPolarDecode(decMatched, K, E, L); % , crcLen
           
           % Here is the simplest ack/nack check: if crc bits of decoded
           % message matches with crc check calculated from the info bits
           % of decoded message we assume transmission is successful.
           crcCheck = nrCRCEncode(decoded(1:K-crcLen), poly);
           if decoded(K-crcLen+1:end) == crcCheck(K-crcLen+1:end)
               ack = 1;
           end
       end
       nTx = nTx + txCount;
       % Error calculating
       ber = biterr(decoded(1:K-crcLen), info);
       nErr = nErr + ber;
       if ber > 0
           nBlErr = nBlErr + 1;
       end
   end
   avBer(ind) = nErr/nExp;
   avBler(ind) = nBlErr/nExp;
   avTx(ind) = nTx/nExp;
   disp(['BER: ', num2str(avBer(ind)), ' at SNR: ', num2str(snrdB(ind))])
   disp(['BLER: ', num2str(avBler(ind)), ' at SNR: ', num2str(snrdB(ind))])
   disp(['Average transmission number: ', num2str(avTx(ind))])
end
delete(pool);
semilogy(snrdB, avBer);
grid on;

