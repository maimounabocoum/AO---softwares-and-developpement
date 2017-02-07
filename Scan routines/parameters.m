%%%%% initialize programm FIELD II %%%%%%%%%%%%

%%%%%%%%% set parameters %%%%%%%%%%%%%%%%%%%%

% set_field('show_time',1);

param.f0=6e6; % Transducer center frequency [Hz]
param.fs=10e6; % Sampling frequency [Hz]
param.c=1540; % Speed of sound [m/s]
param.lambda=param.c/param.f0; % Wavelength [m]
param.element_height= 6/1000; % Height of element [m]
param.width = 0.2/1000; % Width of element [m]
param.kerf= 0; % Distance between transducer elements [m]
param.N_elements = 256;%128; % Number of elements
%param.ActiveList = 50:5:128 ;
param.Rfocus = 40/1000; % Elevation focus
param.attenuation = 0;         % en db/cm/Mhz
param.no_sub_x = 1;
param.no_sub_y = 10; % for designed probes, you should put a value > 2 for proper calculation (10 is good!)
param.farfield = param.width^2/(4*param.lambda); 

%% type of focalization to apply for the virtual experiment :
% OF : 'Focused Waves'
% OP : 'Plane Waves'
% OS : 'Structured Waves ' 
param.FOC_type = 'OF'; 
param.focus = 40/1000; % Initial electronic focus [m,m,m]

% waist of diffuse IR laser beam
param.w0 = 10/1000 ; % in m 
% param.center = [10 10 10]/1000 ; specify the center of the gaussian beam.
% if this value is commented, the beam is by defaukt center on the
% simulation bow

% temporal field 

param.Activated_FieldII =  1; % 0 to generate field by yourself

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% Simulation BOX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Simulation box initialization : 

    param.Xrange = [-10 10]/1000; % in m
    param.Yrange = 0/1000;%[-0.1 0.1]/1000;
    param.Zrange = [35 50]/1000; % in m

    param.Nx = 50;
    param.Ny = 1;
    % in order to match the number of point in Z direction , and 
    % unshures Nz >=1
    param.Nz = max( 1 , ceil ( param.fs * (abs(param.Zrange(2) - param.Zrange(1)))/(param.c) ) ); % do not edit


%% Probe defintion :
% Set the sampling frequency
if param.Activated_FieldII == 1 
field_debug(0);
set_sampling(param.fs);
set_field('c',param.c);
set_field('Freq_att',param.attenuation*100/1e6);
set_field('att',0*2.6*100);
set_field ('att_f0',0*param.f0); 
set_field('use_att',1);
end

% screen field parameters :
