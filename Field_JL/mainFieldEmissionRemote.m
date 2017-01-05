% Jeremy Bercoff 2002
% Field simulation for philips beamforming
clear all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%savePression =1;
%name ='cigarefield_7';
%path ='f:\jeremy\donnees\remote\simulation\field\';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initializing field
field_init(0);
Rho = 1000;                % Density
fs = 200e6;                % Sampling frequency [Hz]
c = 1540;                  % Speed of sound [m/s]
attenuation = 0.6;         % en db/cm/Mhz
set_sampling(fs);
set_field('c',c);
set_field('Freq_att',attenuation*100/1e6);
set_field('att',2.6*100);
set_field('use_att',1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initializing tranducer parameters
f0 = 4.3e6;                % Transducer center frequency [Hz]
lambda = c/f0;             % Wavelength  
No_elements = 128;        % Number of physical elements
width = 0.33/1000;
kerf = 0*lambda;           % Kerf [m] - explain
height = 10/1000;        % Height of elements in transducer [m]
Rfocus = 40/1000; % Elevation focus
InfoBeam.focus = 40;
focus = [0 0 InfoBeam.focus]/1000; % Fixed focal point [m]
no_sub_x = 1;
no_sub_y = 10;
farfield = width^2/(4*lambda); 
times = 0;
%delays = zeros(1,No_elements);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Emission Transducer Definition
te = xdc_focused_array(No_elements,width,height,kerf,Rfocus,no_sub_x,no_sub_y,focus);
%te = xdc_linear_array(No_elements,width,height,kerf,no_sub_x,no_sub_y,focus);
%image_xdc(te);
%delays = xdc_get(te,'focus');
%figure; plot(delays(2:end)*1e6);
% focus2 = [0 0 40]/1000; 
% delays = makedelays(No_elements,focus2,c,width,1);
% xdc_times_focus(te,0,delays);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Emission signal
impulse = sin(2*pi*f0*(0:1/fs:2/f0));
impulse = impulse.*hanning(max(size(impulse)))';
xdc_impulse (te, impulse);

RI = MakeRI_Remote(f0,fs,50);
Tpulse = length(RI)/fs;

xdc_excitation(te,RI);
apodisation = ones(No_elements,1);
%apodisation = apodisation.*hanning(length(apodisation));
%apodisation = apodisation.*bercoffwin(length(apodisation),40);
xdc_apodization(te,times,apodisation')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Emitted field
InfoBeam.XDebut  = -0.45;  InfoBeam.XFin  = 0.45 ;  InfoBeam.pasX  = 0.05;
InfoBeam.ZDebut  = 35.05;  InfoBeam.ZFin  = 44.95;   InfoBeam.pasZ  = 0.2;
InfoBeam.YDebut  = -1;  InfoBeam.YFin  = 1;    InfoBeam.pasY  = 0.5;
if (InfoBeam.ZDebut*1e-3<farfield) disp('attention, champ proche!'); end; 
[points,ampl,InfoBeam] = ZoneImageRemote(InfoBeam);

Hf1 = figure(1);
set(Hf1,'name','position of detection')
scatter3(points(:,1)*1e3,points(:,2)*1e3,points(:,3)*1e3)
xlabel('x(mm)')
ylabel('y(mm)')
zlabel('z(mm)')


[champs ,ti] = calc_hp(te,points);
MaxChamps = max(max(champs));
champs = champs/max(max(champs));
P0 = 40e5; % Pression mesure au foyer en manip
champs = champs*P0;
%N = ti*fs; 

%figure; plot(champs);
% for i = 1:size(champs,2)
%     champsM(i) = max(abs(champs(:,i)));
% end;
champsM = max(champs,[],1); % line vector correponding to max value of each champs
%champsMoy = sum(champs,1);%*Tpulse;



%P0=1;
%champsM = champsM*P0;
Z = Rho*c;
C = attenuation*f0*1e-6*1e2/8.7/Rho/c^2;
%Force = C*champsM.^2;
Force = champsM;

Dpl = reshape(Force,InfoBeam.NbY,InfoBeam.NbX,InfoBeam.NbZ); % resize to initial box
champF=zeros(InfoBeam.NbY,InfoBeam.NbX,InfoBeam.NbZ);
champF=Dpl;
figure;
for i=1:InfoBeam.NbY
    toto = (squeeze(champF(i,:,:)))';
    imagesc(toto);  colorbar; title('champ diffract� ds l''espace');
    pause;
     %champF(:,:,i)=(champF(:,:,i)).^2; %champF(:,:,i) = champF(:,:,i)./max(max(champF(:,:,i))); 
end
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Enregistrement des donn�es pour la palpation simul�e
 if savePression == 1   
    fid=fopen([path name '.bin'],'wb');
    fid2=fopen([path 'zone' name '.bin'],'wb');
    fwrite(fid,Force,'float');
    fwrite(fid2,points,'float');
    save([path 'Info' name],'InfoBeam');
end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xdc_free(te);
field_end;
fclose all;