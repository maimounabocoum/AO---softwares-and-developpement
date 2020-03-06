%%%%% initialize programm FIELD II %%%%%%%%%%%%
% Ma�mouna BOCOUM - last edited versions 03-04-2019
% note : all parameters are defined in SI units

%%%%%%%%% set parameters %%%%%%%%%%%%%%%%%%%%

% set_field('show_time',1);

param.f0 = 6e6;                     % Transducer center frequency [Hz]
param.fs = 100e6;                   % Sampling frequency in FIELDII[Hz]
param.fs_aq  = 10e6;                % Sampling frequency of the photodiode [Hz]
param.Noc = 4 ;                     % Number of optical cycles
param.c = 1540;                     % Speed of sound [m/s]
param.lambda = param.c/param.f0;    % Wavelength [m]
param.element_height= 6/1000;       % Height of element [m] 6
param.width = 0.2/1000;             % Width of element [m] - 0.11 for 15MhZ probe
param.kerf = 0/1000;                % Distance between transducer elements [m]
param.N_elements = 192;             % 192; % Number of elements for SL10-2 probe
param.X0 = -40/1000  ;              % position min of effective probe shooting (center probe = 0mm)
param.X1 =  40/1000 ;               % position max of effective probe shooting (center probe = 0mm)
param.Rfocus = 35/1000;             % Static Elevation focus
param.attenuation = 0;              % en db/cm/Mhz
param.no_sub_x = 1;
param.no_sub_y = 10; % for designed probes, you should put a value > 2 for proper calculation (10 is good!)


param.farfield = param.width^2/(4*param.lambda); 
param.tau_c    = 4e-6; % camera intergration type for holography detection
param.TrigDelay = 10e-6;
%% type of focalization to apply for the virtual experiment :
% OF : 'Focused Waves'
% OP : 'Plane Waves'
% JM : 'Jean-Michel continuoous waves' (not implemented yet)
% OS : 'Structured Waves ' 

param.FOC_type    = 'OS'; 
param.Bascule     = 'on';              % parameter for JM with / without Talbot Effect
param.focus       = 23/1000;            % Initial electronic focus     - only active in OF mode
param.angles      = 0*pi/180;    % Line Vector Angular scan     - only active in OP and OS mode 


% k0 = (1/1e-3) is the smapling frequence for the decimation
% k0 = (1/(param.N_elements*param.width)) is the smapling frequence for the decimation

param.df0x = (1/(param.N_elements*param.width));  % 24.39; - only active in OP and OS mode 
param.decimation  = 20;  % decimation list of active actuators   - only active in OS mode 
% decimation definition : 
% activeElements are indexed by 
% mod( (1:N_elements) - ElmtBorns(1) , 2*decimation ) ;

param.NbZ         = 10;                         % 8; % Nb de composantes de Fourier en Z, 'JM'
param.NbX         = 10;                         % 20 Nb de composantes de Fourier en X, 'JM'
param.nuZ0 = 1/( (param.c)*20*1e-6 );           % Pas fr�quence spatiale en Z (en mm-1)
param.nuX0 = 1/(param.N_elements*param.width);  % Pas fr�quence spatiale en X (en mm-1) 



param.Activated_FieldII = 1 ;     % 0 to generate field by yourself - 1 FIELDII simulation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% Simulation BOX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Simulation box initialization : 

    param.Xrange = [-10 10]/1000;     % in m [-15 15]
    param.Yrange = 0/1000;          % [-0.1 0.1]/1000 ; (not implemented yet)
    param.Zrange = [0 40]/1000;     % simulation JM : [5 40]/1000;

    param.Nx = 150; % number of interpolating points along Xrange
    param.Ny = 1;   % number of interpolating points along Yrange
    
    % in order to match fs_aq(Hz) along Zrange , and 
    % unshures Nz >=1
    param.Nz = max( 1 , ceil ( param.fs_aq * (abs(param.Zrange(2) - param.Zrange(1)))/(param.c) ) ); % do not edit
%% definition of laser beam
    
% waist of diffuse IR laser beam
param.w0 = [10 10]/1000 ;             % specify the center of the gaussian beam.
param.center = [0 0 23]/1000 ;      % specify the center of the gaussian beam.    
             
                                    % if this value is commented, 
                                    % the beam is by defaukt center on the
                                    % simulation box
%% absorbers positions :
    % fringes : modulation of intensity in direction given by Position
    param.phantom.Positions = [0 0 23 ; 10000 0 23]/1000;  % [x1 y1 z1; x2 y2 z2 ; ....] aborbant position list
    param.phantom.Sizes     = [1.5 ; 1.5]/1000;                  % dimension in all direction [dim ; dim ; ...]
    param.phantom.Types = {'gaussian','gaussian'} ;          % available types exemple : { 'square', 'gaussian', ...}
    

    % parameters used in article
      param.phantom.Positions = [-4 0 23 ; 0 0 23]/1000;   % [x1 y1 z1; x2 y2 z2 ; ....] aborbant position list
%     param.phantom.Sizes     = [0.9 ; 1.5*0.9]/1000;          % dimension in all direction [dim ; dim ; ...]
%     param.phantom.Types = {'gaussian','gaussian'} ;          % available types exemple : { 'square', 'gaussian', ...}
     

    
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

