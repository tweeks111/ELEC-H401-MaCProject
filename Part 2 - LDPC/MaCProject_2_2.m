%-------------------------------------%
%    Modulation and Coding Project    %
%-------------------------------------%
%   Authors : Theo LEPOUTTE           %
%             John ANTOUN             %
%                                     %
%   Date : March 16, 2020             %
%-------------------------------------%
clc;clear;close all;
addpath('../Part 1 - Communication Chain');
%------Parameters------%
Nbps= 4;                                        % Number of bits per symbol (BPSK=1,QPSK=2,16QAM=4,64QAM=6) -> vector to compare 
CutoffFreq= 1e6;                                % CutOff Frequency of the Nyquist Filter
RollOff= 0.3;                                   % Roll-Off Factor
M= 4;                                           % Upsampling Factor
N = 23;                                         % Number of taps (ODD ONLY)
EbN0 = 10;                                      % Eb to N0 ratio  (Eb = bit energy, N0 = noise PSD)  -> vector to compare BER
Tsymb= 1/(2*CutoffFreq);                        % Symbol Period
SymRate= 1/Tsymb;                               % Symbol Rate
Fs = SymRate*M;                                 % Sampling Frequency
BlockSize = 128;
BlockNb=20;
CodeRate = 1/2;
Nb= BlockSize*BlockNb;                         % Number of bits
AverageNb=1;

%%
% Bit Generation
%------------------------

bits_tx = randi(2,1,Nb)-1;               % bits_tx = Binary sequence

%%
% LDPC
%----------------

H0 = makeLdpc(BlockSize, BlockSize/CodeRate,0,1,3);
blocks=reshape(bits_tx,BlockSize,BlockNb);
[checkbits, H] = makeParityChk(blocks, H0, 0);

blocks=blocks.';
checkbits=checkbits.';

codedbits=horzcat(checkbits,blocks);
codedbits_tx=reshape(codedbits,[],1);

%%
% Mapping
%------------------------

if Nbps>1
        signal_tx = mapping(codedbits_tx,Nbps,'qam').';         % Symbols sequence at transmitter
else
        signal_tx = mapping(codedbits_tx,Nbps,'pam').';         % Symbols sequence at transmitter    
end

%%
% Upsampling
%-----------------

upsampled_signal = zeros(1,length(signal_tx)*M);
for i = 1:Nb/Nbps
    upsampled_signal(1+M*(i-1))=signal_tx(i);
    for j = 2:M
        upsampled_signal(j+M*(i-1))=0;
    end
end

%%
% RRC Nyquist Filter TX
%-------------------------
[h_RRC,H_RRC] =  RRC(Fs,Tsymb,N,RollOff,Nbps,AverageNb,M);
filtered_signal_tx = conv(upsampled_signal,h_RRC);


%%
% Noise
%-----------------

SignalEnergy = (trapz(abs(filtered_signal_tx).^2))*(1/Fs);
Eb = SignalEnergy/(2*Nb);

N0 = Eb./(10.^(EbN0/10));
NoisePower = 2*N0*Fs;

noise = zeros(length(EbN0),length(signal_tx)*M+N-1);
signal_rx = zeros(length(EbN0),length(signal_tx)*M+N-1);
for j = 1:length(EbN0)
    noise(j,:) = sqrt(NoisePower(j)/2).*(randn(1,length(signal_tx)*M+N-1)+1i*randn(1,length(signal_tx)*M+N-1));
    signal_rx(j,:) = filtered_signal_tx + noise(j,:);
end


%%
% RRC Nyquist Filter RX
%-------------------------

filtered_signal_rx = zeros(length(EbN0),length(signal_tx)*M+2*(N-1));
cropped_filtered_signal_rx = zeros(length(EbN0),length(signal_tx)*M);
for i =1:length(EbN0)
    filtered_signal_rx(i,:) = conv(signal_rx(i,:),fliplr(h_RRC));
    cropped_filtered_signal_rx(i,:) = filtered_signal_rx(i,N:end-(N-1));
end

%%
% Downsampling
%-------------

downsampled_signal = zeros(length(EbN0),length(signal_tx));
for j = 1:length(EbN0)
    for i = 1:Nb/Nbps
        downsampled_signal(j,i)=cropped_filtered_signal_rx(j,1+M*(i-1));
    end
end

%%
%Demapping
%-----------

codedbits_rx = zeros(length(EbN0),length(codedbits_tx));
for i = 1:length(EbN0)
    if Nbps>1
        codedbits_rx(i,:) = demapping(downsampled_signal(j,:).',Nbps,"qam");
    else
        codedbits_rx(i,:) = demapping(real(downsampled_signal(j,:).'),Nbps,"pam");
    end
end

%%
% Hard Decoding
%----------------

bits_rx=zeros(length(EbN0),Nb);
for i = 1:length(EbN0)
    for j = 1:BlockNb
        codeword = codedbits_rx(i,(j-1)*BlockSize/CodeRate+1:j*BlockSize/CodeRate);
        correctedCodeword=hardDecoding(codeword,H);
        bits_rx(i,(j-1)*BlockSize+1:j*BlockSize)=correctedCodeword(1:BlockSize);
    end
end

%%
% BER
%----------

BER =zeros(length(EbN0),1);
for j = 1:length(EbN0)
    for i=1:Nb
        if(bits_rx(j,i) ~= bits_tx(i))
            BER(j,1) = BER(j,1)+1;
        end
    end
BER(j,1) = BER(j,1)/Nb
end