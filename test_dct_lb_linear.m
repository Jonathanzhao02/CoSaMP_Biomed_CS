% Runs DCT-LB Linear on a generic dataset (specified by DSET and the submask mat file)
% All data (.mat) files will be found in a location to be specified later
% Uses learned submask (results in results_learned_submask)

N=256;
DSET="eeg_sliced";
SAVE_FOLDER='ieeg_256';
NUM_WAVE=51;

mkdir(sprintf('./results/%s', SAVE_FOLDER));

load('ieeg_submask.mat');

fprintf('>> Loading %s\n', DSET);
load(DSET + ".mat");

% Generate basis
% Discrete cosine transform basis
ww = dct(diag(ones(N,1)));
mm = idct(diag(ones(N,1)));

Psi=zeros(N);
iPsi=zeros(N);
%omega = randperm(N) - 1; % generates random mask
% Apply mask
for i=1:N
  Psi(i,:) = ww(omega(i)+1,:);
  iPsi(:,i) = mm(:,omega(i)+1);
end

for CR=[2,4,8,16,32]
  logfile = fopen(sprintf('./results/%s/%s_rec_%d.txt', SAVE_FOLDER, DSET, CR), 'w');
  fprintf('>> Starting CR%d\n',CR)
  M=fix(N / CR);

  data_rec = zeros(size(data));

  toc_sum=0;
  PRD_sum=0;
  SNR_sum=0;
  NMSE_sum=0;
  total=size(data,1);
  parfor i=1:total
    fprintf('loading signal %d\n',i);
    x=double(data(i,:)');

    Phi=Psi(1:M,:);
    iPhi = iPsi(:,1:M);
    y = Phi * x;

    tic
    hat_x = real(iPhi * y);
    time_end=toc;
    toc_sum=toc_sum+time_end;
    PRD=norm(x-hat_x)/norm(x - mean(x))*100;
    PRD_sum=PRD_sum+PRD;
    SNR=20*log10(norm(x)/norm(x - hat_x));
    SNR_sum=SNR_sum+SNR;
    NMSE_sum=NMSE_sum+goodnessOfFit(hat_x,x, 'nmse');
    data_rec(i,:)=hat_x;

    if i < 10
      fig=figure();
      plot(x)
      hold on
      plot(hat_x)
      set(fig, 'units', 'inches', 'position', [0 0 10 3])
      exportgraphics(gcf, sprintf('./results/%s/CR%d_sig%d.png', SAVE_FOLDER, CR, i));
    end
  end
  fprintf('>> CR%d, finished \n',CR);

  PRD_aver=PRD_sum/total;
  SNR_aver=SNR_sum/total;
  NMSE_aver=NMSE_sum/total;
  time_aver=toc_sum/total;

  fprintf('>> CR%d SNR: %f PRD: %f NMSE: %f Time: %f\n', CR, SNR_aver, PRD_aver, NMSE_aver, time_aver);
  fprintf(logfile, '>> CR%d SNR: %f PRD: %f NMSE: %f Time: %f\n', CR, SNR_aver, PRD_aver, NMSE_aver, time_aver);

  % Save reconstruction results
  save(sprintf('./results/%s/%s_rec_%d.mat', SAVE_FOLDER, DSET, CR), 'data_rec');
  fclose(logfile);
end

fprintf('>> All Completed <<\n');
