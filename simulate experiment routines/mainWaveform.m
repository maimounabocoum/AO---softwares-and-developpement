%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% main  program %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% maimouna bocoum 04-01-2017
clear all
clearvars ;

addpath('..\Field_II')
field_init(0);

parameters;

field_info



tic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% definition of the HOME MADE actuator array %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
% Start a new experiment
     CurrentExperiement = Experiment(param);
   % CurrentExperiement.MyProbe = ...
   % ActuatorProbe(N_elements,element_height,width,no_sub_x,no_sub_y,kerf,1:N_elements,Rfocus); % for waveform
   % CurrentExperiement.MyProbe = ...
   % ActuatorProbe(N_elements,element_height,width,no_sub_x,no_sub_y,kerf,ActiveList,Rfocus); % for excitation
   % CurrentExperiement.MyProbe.ShowActuatorCenter();

 % Set a delay law for the probe
 
    CurrentExperiement.MyProbe = CurrentExperiement.MyProbe.Set_ActuatorDelayLaw('focus',param.focus,param.c);
   % CurrentExperiement.MyProbe = CurrentExperiement.MyProbe.Set_ActuatorDelayLaw('plane',0*180/pi,param.c);
   % CurrentExperiement.MyProbe.ShowDelay();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Setting the probe inside FIELD II program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Linear array with electronic focusing defined by focus :
   
   % Probe = xdc_linear_array (param.N_elements, param.width, param.element_height,...
   %                           param.kerf,param.no_sub_x,param.no_sub_y, param.focus);
   
   % Linear array with electronic focusing defined by focus and elevation (static) by Rfocus
   
   % Probe = xdc_focused_array(param.N_elements,param.width,param.element_height,param.kerf,...
                              %param.Rfocus,param.no_sub_x,param.no_sub_y,param.focus);
                              
      % probe using the previously defined array :
      Probe = xdc_rectangles(CurrentExperiement.MyProbe.rect,[0 0 0], param.focus);
      
      
   %   show_xdc (Probe);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Setting the impulse response field (Green function)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Emission signal : I think by befault, the green function is calculated
% for a different frequency

    t_impulseResponse = (0:1/param.fs:2/param.f0);
    impulse = sin(2*pi*param.f0*t_impulseResponse);
    impulse=impulse.*hanning(length(impulse))'; 
    xdc_impulse (Probe, impulse);
    % figure;
    % plot(1e6*t_impulseResponse,impulse);
    % xlabel('time(\mu s)')
    % ylabel('a. u')
    % title('Probe impulse Response setting')



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Definition of excitation function for actuator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %excitation= Actuators.Excitation(1,:);%sin(2*pi*f0*(0:1/fs:2/f0));

    % adding delay law
    Noc = 8; % number of optical cycles
    t_excitation = (0:1/param.fs:Noc*1.5/param.f0);
    excitation =  sin(2*pi*param.f0*t_excitation);
    excitation = excitation.*hanning(length(excitation))';

    xdc_focus_times(Probe,-1,CurrentExperiement.MyProbe.DelayLaw);
    
%      apodisation = hanning(length(excitation))*ones(1,param.N_elements);
%      xdc_apodization(Probe,0*hanning(length(excitation)),apodisation);
 
    xdc_excitation (Probe, excitation);
   
   
   list = zeros(param.N_elements,1);
   list(param.ActiveList) = 1;
  % ele_waveform (Probe,[1:N_elements]', list*excitation);
   
    % field 
    % gaussian : w0 
    % plane : angle of propagation : theta
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% calculation of the emitted Field :
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[h,t] = calc_hp(Probe,CurrentExperiement.MySimulationBox.Points());
h = h/max(h(:));
CurrentExperiement.MySimulationBox = CurrentExperiement.MySimulationBox.Get_SimulationResults(t,h,param.fs);
%SimulationBox.SizeBox()
CurrentExperiement.MySimulationBox.ShowMaxField('XZ'); % XZ : plan (x,z)
%SimulationBox.ShowMaxField('YZ');  
%SimulationBox.ShowFieldPropagation();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% End Program - Free memory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xdc_free(Probe);
field_end;

toc