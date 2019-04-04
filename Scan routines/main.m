%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  main  program  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% maimouna bocoum 04-01-2017
clearvars ;

addpath('..\Field_II')
addpath('..\radon inversion')
addpath('subscripts')
addpath('..\radon inversion\shared functions folder')
field_init(0);

parameters;
IsSaved = 0 ;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% Start an experiment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CurrentExperiement = Experiment(param);

% initial excitation field :

    t_excitation = (0:1/param.fs:param.Noc*1.5/param.f0);
    excitation   =  sin(2*pi*param.f0*t_excitation).*hanning(length(t_excitation)).^2';
    
%     excitation_env = hilbert(excitation);
%     excitation_env= abs(excitation_env);
% 
%     figure;
%     plot(t_excitation*1e6,excitation)
%     hold on 
%     plot(t_excitation*1e6,excitation,'color','red')
%     xlabel('time in \mu s')
%     ylabel('a.u')
%     title('field excitation')
    
    
% evaluate Phantom on simulation Box :
CurrentExperiement = CurrentExperiement.EvalPhantom();
CurrentExperiement.ShowPhantom();
%use param.angles has an input to additionally show Radon transform


% creating memory to save probe delay law
if param.Activated_FieldII == 1 
DelayLAWS = zeros(param.N_elements,CurrentExperiement.Nscan);
end

 [Nx,Ny,Nz]    = SizeBox(CurrentExperiement.MySimulationBox);
 Field_Profile = zeros(Nz,Nx,CurrentExperiement.Nscan);
 
 %% run acquision loop over Nscan
 tic
 Hf = gcf;
 h = waitbar(0,'Please wait...');

 for n_scan = 1:CurrentExperiement.Nscan
 
     CurrentExperiement = CurrentExperiement.InitializeProbe(n_scan);
     CurrentExperiement = CurrentExperiement.CalculateUSfield(t_excitation,excitation,n_scan);
     CurrentExperiement = CurrentExperiement.GetAcquisitionLine(n_scan) ;
     % % option for screening : XY, Xt , XZt

    % CurrentExperiement.MySimulationBox.ShowMaxField('XZt',Hf)    
    % CurrentExperiement.MySimulationBox.ShowMaxField('XZ', Hf)
    
    % field profile
    [Field_max,Tmax] = max(CurrentExperiement.MySimulationBox.Field,[],1);
    % max(obj.Field,[],1) : returns for each colulm
    % the maximum field pressure.
    Field_Profile(:,:,n_scan) = squeeze( reshape(Field_max,[Ny,Nx,Nz]) )';
   
    % retreive delay law for cuurent scan
    if strcmp(param.FOC_type,'OP') || strcmp(param.FOC_type,'OS')
     DelayLAWS( :  ,n_scan) = ...
                CurrentExperiement.MyProbe.DelayLaw ;
    end
          
    waitbar(n_scan/CurrentExperiement.Nscan)
    
 end


 ActiveLIST = CurrentExperiement.BoolActiveList ;
 
 close(h) 
 
 toc
 
 %% show acquisition loop results
 
 
 CurrentExperiement.ShowAcquisitionLine();
 
%  figure
%  imagesc(CurrentExperiement.ScanParam*1e3+20,...
%           CurrentExperiement.MySimulationBox.z*1e3,...
%           CurrentExperiement.AOSignal)
%       
%   x = CurrentExperiement.ScanParam*1e3+20 ;
%   z = CurrentExperiement.MySimulationBox.z*1e3 ;
%   I = CurrentExperiement.AOSignal ;
%   save('C:\Users\mbocoum\Dropbox\self-written documents\acoustic-structured-illumination\images\datas\SimuOF','x','z','I')

% [Nx,Ny,Nz] = CurrentExperiement.MySimulationBox.SizeBox();
% Transmission = squeeze( reshape(CurrentExperiement.DiffuseLightTransmission',[Ny,Nx,Nz]) );
% plot(CurrentExperiement.MySimulationBox.z*1e3,Transmission(75,:))
% hold on
% plot(CurrentExperiement.MySimulationBox.z*1e3,CurrentExperiement.AOSignal(:,64)/max(CurrentExperiement.AOSignal(:,64)))
 
% set(findall(gcf,'-property','FontSize'),'FontSize',15) 
% [cx,cy,c] = improfile;
% figure;
% plot(cx(1) + sqrt((cx-cx(1)).^2 + (cy-cy(1)).^2),c/max(c))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %% save data for reconstruction Iradon %% ONLY SAVING OP
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 if (IsSaved == 1)
     
     % saving folder name with todays date
     SubFolderName = generateSubFolderName('..\radon inversion\saved images') ;
     FileName   = generateSaveName(SubFolderName ,'type',param.FOC_type);
     
 x_phantom = CurrentExperiement.MySimulationBox.x ;
 y_phantom = CurrentExperiement.MySimulationBox.y ;
 z_phantom = CurrentExperiement.MySimulationBox.z ;
 [MyTansmission,R,zR] = CurrentExperiement.ShowPhantom(param.angles);
 
 % same variable as in experiment:
 NbElemts = param.N_elements ;
 pitch = param.width*1e3 ;
 X0 = param.X0*1e3 + (NbElemts*pitch)/2;
 X1 = param.X1*1e3  + (NbElemts*pitch)/2;
 dFx = param.df0x ;
     %--------------------- saving datas -------------
     switch param.FOC_type
         
         case 'OF'
 
 MyImage = OF(CurrentExperiement.ScanParam,CurrentExperiement.MySimulationBox.z,CurrentExperiement.AOSignal,param.fs_aq,param.c); 
 save(FileName,'x_phantom','y_phantom','z_phantom','MyTansmission','MyImage');  
 
         case 'OP'
 
%              AOSignal = CurrentExperiement.AOSignal ;
%              ScanParam = CurrentExperiement.ScanParam;
 MyImage = OP(CurrentExperiement.AOSignal,CurrentExperiement.ScanParam,CurrentExperiement.MySimulationBox.z,param.fs_aq,param.c); 
            
save(FileName,'x_phantom','y_phantom','z_phantom','MyTansmission','MyImage','R','zR');

         case 'OS'
%save('C:\Users\mbocoum\Dropbox\PPT - prez\SLIDES_FRANCOIS\scripts\Simulation_fieldOF.mat','AOSignal','ScanParam') 
  MyImage = OS(CurrentExperiement.AOSignal,CurrentExperiement.ScanParam(:,1),...
             CurrentExperiement.ScanParam(:,2),param.df0x,...
             CurrentExperiement.MySimulationBox.z,...
             param.fs_aq,...
             param.c,[param.X0 , param.X1]); 
     
    save(FileName,'x_phantom','y_phantom','z_phantom','MyTansmission',...
                  'DelayLAWS','ActiveLIST','MyImage','Field_Profile','NbElemts','pitch','X0','X1','dFx')            
             
     end
     %%%%%%%%%%%%%%%%%%%%
 end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% End Program - Free memory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% rmpath('..\radon inversion')
% field_end;