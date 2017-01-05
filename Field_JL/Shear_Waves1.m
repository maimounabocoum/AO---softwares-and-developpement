clear all
close all
clc

% Diplacement field

load('phantom_amplitudes.mat')
load('phantom_positions.mat')

%load('Dpl_tot.mat')
load('Dir1.mat');
load('Dir2.mat');
load('Dir3.mat');
load('InfoPressureField3D_6.mat');
InfoBeam.pasX = InfoBeam.pasX/1000;
InfoBeam.pasY = InfoBeam.pasY/1000;
InfoBeam.pasZ = InfoBeam.pasZ/1000;
InfoBeam.XDebut = InfoBeam.XDebut/1000;
InfoBeam.YDebut = InfoBeam.YDebut/1000;
InfoBeam.ZDebut = InfoBeam.ZDebut/1000;


% Translate
trX = 0/1000;
trY = 0/1000;
trZ = 0/1000; 

disp('Data Loaded')

for timing = 1:1:size(Dpl_dir1,4)
    timing
    phantom_wave(:,:,timing) = phantom_positions(:,:);
    for i = 1:1:size(phantom_positions,1)
        


for timing = 1:1:size(Dpl_dir1,4)
    timing
    phantom_wave(:,:,timing) = phantom_positions(:,:);
    for X0 = 1:1:size(Dpl_dir1,1)
        X = trX + InfoBeam.XDebut + (X0 - 1)*InfoBeam.pasX;
        for Y0 = 1:1:size(Dpl_dir1,2)
            Y = trY + InfoBeam.YDebut + (Y0 - 1)*InfoBeam.pasY;
            for Z0 = 1:1:size(Dpl_dir1,3)
                Z = trZ + InfoBeam.ZDebut + (Z0 - 1)*InfoBeam.pasZ;
                A = find((phantom_positions(:,1)>=(X-InfoBeam.pasX/2)) & (phantom_positions(:,1)<(X+InfoBeam.pasX/2)) & (phantom_positions(:,2)>=(Y-InfoBeam.pasY/2)) & (phantom_positions(:,2)<(Y+InfoBeam.pasY/2)) & (phantom_positions(:,3)>=(Z-InfoBeam.pasZ/2)) & (phantom_positions(:,3)<(Z+InfoBeam.pasZ/2)));
                if length(A)>0
                    for i=1:1:length(A)
                        phantom_wave(i,1,timing) =  phantom_positions(i,1) + Dpl_dir1(X0,Y0,Z0,timing);
                        phantom_wave(i,2,timing) =  phantom_positions(i,2) + Dpl_dir2(X0,Y0,Z0,timing);
                        phantom_wave(i,3,timing) =  phantom_positions(i,3) + Dpl_dir3(X0,Y0,Z0,timing);
                    end
                end
            end
        end
    end
end
save(['phantom_wave'],'phantom_wave');              
