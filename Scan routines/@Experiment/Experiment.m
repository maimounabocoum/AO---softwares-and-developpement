classdef Experiment
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = public)
        
        MyPhantom ;
        MyProbe ;
        MyLaser ;         % LaserBeam
        MySimulationBox;  % AO_FieldBox
        MyExcitation
        MyAO;             % AOmodulator type
        
        % phantom on simulation bow transmission profile
        DiffuseLightTransmission
      
       ScanParam       % Parameter used for the scan
       Nscan           % number of scans performed in the experiement
       BoolActiveList  % active actuator encoded on boolean table, where each column describe 
                       % one scan, and the line index matches the actuator
                       % index
       AOSignal
        
    end
    
    properties (Access = private)
        % structure containing all the experiement parameters
       param 

    end
    
methods ( Access = 'protected' )
        
        obj= SetShootLim(obj)
        BoolActiveList = SetDecimate(obj,decimation,BoolActiveList,type) 
            
end
    
methods ( Access = 'public' )
        
        % constructor :
        function obj = Experiment(param)
            % param = structure containing all the simulation parameters
                       % for excitation : sparse probe, use with rectangle
            obj.MyPhantom = Phantom( param.phantom.Positions, param.phantom.Sizes, param.phantom.Types );            
            

            % IR laser :
            % if no center is specified, the beam center is the 
            if isfield(param,'center')
            obj.MyLaser = LaserBeam(param.w0,param.center);
            else
            obj.MyLaser = LaserBeam(param.w0,obj.MySimulationBox.GetCenter);
            end
            
            obj.MyProbe = ActuatorProbe(param.N_elements,param.element_height,param.width,...
                          param.no_sub_x,param.no_sub_y,param.kerf,param.Rfocus);
                      
            % initialization for self-defined field (propagation using FFT)
            % obj.MyExcitation = ExcitationField(obj.MyProbe,param.f0,param.fs,param.Noc);
               
            obj.MySimulationBox = AO_FieldBox(param.Xrange,param.Yrange,param.Zrange,param.Nx,param.Ny,param.Nz);
        
            obj.MyAO  = AOmodulator(param.tau_c,param.fs);
               
            obj.param = param;
            
            obj = ConfigureProbeSequence(obj) ;
            
        end   
      
        function obj = ConfigureProbeSequence(obj)
                        
            % configure activated list:
            switch obj.param.FOC_type
                
                case 'OF'
                    % get the piezo center positions X between X0 and X1, used for each scan line               
                       [Scan, obj.ScanParam] = obj.MyProbe.GetIndex( obj.param.X0 , obj.param.X1 );
                       Scan(isnan(Scan)) = [] ;  
                       % retreive the total number od scans     
                       obj.Nscan = length(Scan);        
                       % initialization : all actuator non-actives
                       obj.BoolActiveList = false(obj.param.N_elements,obj.Nscan);                       
                       % Dimension in index of active probes lenght
                       ActiveWidth = 0.5*obj.param.focus; % as in the experiement, in m
                       ActiveWidth = ceil(ActiveWidth/obj.param.width) ; % convert to index 
                       n_actives = (1:ActiveWidth)  - floor(mean(1:ActiveWidth)) ;
                       % definition of the Translation Matrix :
                       for n_scan = 1:obj.Nscan
                           % to be completed with the width
                           I = Scan(n_scan) + n_actives ;                
                           % removing out of probe elements
                           I(I < 1) = [] ;
                           I(I > obj.param.N_elements) = [] ;   
                           % define transducers as active:
                       obj.BoolActiveList( I , n_scan) = true ; 
                       end                     

                       
               case 'OP'
                   
                    if ~isfield(obj.param,'angles')
                        obj.param.angles = (-45:2:45)*pi/180 ; % default scan angles
                    end
                    
                    % retreive the total number of scans     
                       obj.Nscan = length(obj.param.angles); 
                       obj.ScanParam = obj.param.angles ;
                       
                       % reindexation of X0, X1 for 0 to Lmax of the probe
                       X0 = obj.param.X0 + (1/2)*obj.param.N_elements*obj.param.width;
                       X1 = obj.param.X1 + (1/2)*obj.param.N_elements*obj.param.width;
                       
                       ElmtBorns   = [min(obj.param.N_elements,max(1,round(X0/obj.param.width))),...
                                      max(1,min(obj.param.N_elements,round(X1/obj.param.width)))];
                       ElmtBorns   = sort(ElmtBorns); % in case X0 and X1 are mixed up
                       MedElmtList = ElmtBorns(1):ElmtBorns(2);  
                       obj.BoolActiveList = false(obj.param.N_elements,obj.Nscan);   
                       obj.BoolActiveList(MedElmtList,:) = true ;
                       
                case 'JM'
                    
                    if ~isfield(obj.param,'NbZ')
                        obj.param.NbZ  = -1:1; % default scan angles
                    end
                       
                    if ~isfield(obj.param,'NbX')
                        obj.param.NbX  = 1; % default scan angles
                    end
                    
                       % retreive the total number of scans     


                       [NBX, NBZ] = meshgrid( obj.param.NbX , obj.param.NbZ ) ;
                       obj.Nscan = length(NBX(:)); 
                       
                       
                       obj.ScanParam = [NBX(:), NBZ(:)];
                       % reindexation of X0, X1 for 0 to Lmax of the probe
                       X0 = obj.param.X0 + (1/2)*obj.param.N_elements*obj.param.width;
                       X1 = obj.param.X1 + (1/2)*obj.param.N_elements*obj.param.width;
                       ElmtBorns   = [min(obj.param.N_elements,max(1,round(X0/obj.param.width))),...
                                      max(1,min(obj.param.N_elements,round(X1/obj.param.width)))];
                       ElmtBorns   = sort(ElmtBorns); % in case X0 and X1 are mixed up
                       MedElmtList = ElmtBorns(1):ElmtBorns(2);  
                       obj.BoolActiveList = false(obj.param.N_elements,obj.Nscan);   
                       obj.BoolActiveList(MedElmtList,:) = true ;                   
                   
                       % update the AO reference beam
                       obj.MyAO  = obj.MyAO.AOsequenceGenerate(obj.param,obj.ScanParam);
                    
                case 'OS'
                    
                    if ~isfield(obj.param,'angles')
                        obj.param.angles = 0 ; % default scan angles
                    end
                    
                    if ~isfield(obj.param,'decimation')
                        obj.param.decimation = 2 ; % default decimate
                    end
                    
                    obj.Nscan = 4*length(obj.param.angles)*length(obj.param.decimation)...
                                + length(obj.param.angles) ; 
                    % we operate the full 4-phases decimation scan for every
                    % successive angle to scan +  fondamental
                    if ~isempty(obj.param.decimation)
                    decimation = [1;1;1;1]*(obj.param.decimation) ;
                    else
                    decimation = [];
                    end
                    
                    [DEC,THETA] = meshgrid([0;decimation(:)],obj.param.angles);
                    obj.ScanParam = [THETA(:),DEC(:)];
                    
                    % initialization : all actuator non-actives
                    % BoolActiveList columns : list of active element table
                    % for a given shoot
                    obj.BoolActiveList = true(obj.param.N_elements,obj.Nscan); 
            
                    for i_decimate = 1:length(obj.param.decimation)
                       
                        % selection of column index to modify for a given
                        % decimation
                        
                       i_cos      = 4*i_decimate - 3 ;
                       i_ncos     = 4*i_decimate - 2 ;
                       i_sin      = 4*i_decimate - 1 ;
                       i_nsin     = 4*i_decimate - 0 ;
                       
                       I = (1:length(obj.param.angles)) + length(obj.param.angles) ;
                       
                       Icos  = I + ( i_cos-1 )*length(obj.param.angles) ;  % index of column with same decimate
                       Incos = I + (i_ncos-1 )*length(obj.param.angles) ;  % index of column with same decimate
                       Isin  = I + (i_sin-1  )*length(obj.param.angles) ;  % index of column with same decimate
                       Insin = I + (i_nsin-1 )*length(obj.param.angles) ;  % index of column with same decimate

                        fx = obj.param.df0x*obj.param.decimation(i_decimate);
%                        Neff = 1/(fx*obj.param.width);
%                        fx   = 1/(Neff*obj.param.width);
                       
                       obj.BoolActiveList( : , Icos ) = ...
                       SetDecimate(obj,fx,obj.BoolActiveList(:,Icos),'cos') ;
                       
                       obj.BoolActiveList( : , Incos ) = ...
                       ~obj.BoolActiveList( : , Icos );
                   
                       obj.BoolActiveList( : , Isin ) = ...
                       SetDecimate(obj,fx,obj.BoolActiveList(:,Isin),'sin') ;
                   
                       obj.BoolActiveList( : , Insin ) = ...
                       ~obj.BoolActiveList( : , Isin );
                   
                    end
 
                    obj = SetShootingLim(obj) ;

     
            end
            
            % update time of simulation :
           %obj.MySimulationBox.time = 0:(1/obj.param.fs_aq):max(abs(obj.MySimulationBox.z))/(obj.param.c) ;
           
           % data Result Size initialization 
           
           obj.AOSignal = zeros(obj.param.Nz,obj.Nscan) ;
                      
            
        end
        
        function obj = InitializeProbe(obj,n_scan)
            % take the parameter of current shoot to initialize probe
            % characteristics : 
           FullElementList = 1:obj.param.N_elements ;
           ActiveList =  FullElementList(obj.BoolActiveList(:,n_scan)) ;
           Nactive = length(ActiveList);
            % probe strcuture initialization :
            
           obj.MyProbe = obj.MyProbe.Set_ActiveList(ActiveList) ;
           
%            ActuatorProbe(obj.param.N_elements,obj.param.element_height,obj.param.width,...
%                           obj.param.no_sub_x,obj.param.no_sub_y,obj.param.kerf,ActiveList,obj.param.Rfocus);
%            
           % define delay law for the probe :
              switch obj.param.FOC_type
                
                 case 'OF' 
                    obj.MyProbe = obj.MyProbe.Set_ActuatorDelayLaw('focus',[obj.ScanParam(n_scan) 0 obj.param.focus],obj.param.c);
                                % configure temporal profile excitation :
                    obj.MyExcitation = ExcitationField(Nactive,obj.param.FOC_type,obj.param.Noc,obj.param.f0,obj.param.fs);
                  case 'OP'
                    obj.MyProbe = obj.MyProbe.Set_ActuatorDelayLaw('plane',obj.ScanParam(n_scan),obj.param.c);
                 case 'OS'
                    obj.MyProbe = obj.MyProbe.Set_ActuatorDelayLaw('plane',obj.ScanParam(n_scan,1),obj.param.c);
              end
              
              
              

            
        end
            
        function obj = CalculateUSfield(obj,n_scan)
            
            %% generate emission array
            Nactive = sum(obj.BoolActiveList(:,n_scan));
            switch obj.param.FOC_type
             
                case {'OF','OP','OS'} 
                t_excitation = (0:1/obj.param.fs:obj.param.Noc*1.5/obj.param.f0);
                excitation   =  sin(2*pi*obj.param.f0*t_excitation);%.*hanning(length(t_excitation)).^2'; 
                EXCITATION = repmat(excitation,Nactive,1) ;
                case 'JM'
             Xs        = (0:Nactive-1)*obj.param.width;             % Echelle de graduation en X
            [~,~,~,EXCITATION] = CalcMatHole(obj.param.f0*1e-6,obj.ScanParam(n_scan,1),obj.ScanParam(n_scan,2),...
                                               obj.param.nuX0*1e-3,obj.param.nuZ0*1e-3,Xs*1e3,...
                                               obj.param.fs*1e-6,obj.param.c, obj.param.Bascule ); % Calculer la matrice
            
             EXCITATION = EXCITATION';                              
             %EXCITATION = repmat(EXCITATION',1,6);

            % test study FFT
            
            
            end
            
%            MyFFT = TF_t(2^(3+nextpow2(size(EXCITATION,2))),obj.param.fs);
%            PaddedField = padarray(EXCITATION',MyFFT.N - size(EXCITATION',1)  ,0);
%            Result = MyFFT.fourier(PaddedField);
%            
%            figure(8);
%            subplot(211)
%            imagesc(EXCITATION')
%            subplot(212)
%            plot(MyFFT.f*1e-6 , abs(Result(:,90)),'-o')
%            xlabel('frequency (MHz)')
%            title('profile on first column')
            
%%
        if obj.param.Activated_FieldII == 1
            % in field, the excitation fieldII should be real

                    % Initialize home-made probe  :
                    % focus [0 0 0] will be overwritten by the delay law
                    % 
                    
                    % check for empty field :
                    
                    if isempty(obj.MyProbe.rectActive)
                    
                    % set field to zero when no piezo is active
                    % if not - xdc_rectangles generates error
                    z_min = min(obj.MySimulationBox.z) ;
                    z_max = max(obj.MySimulationBox.z) ;
                    c = obj.param.c ;
                    
                    tmin = z_min/c - max(t_excitation)/2; 
                    tmax = z_max/c + max(t_excitation)/2; 
                    
                    h = zeros( floor((obj.param.fs)*(tmax-tmin))  , size(obj.MySimulationBox.Points,1));
                    obj.MySimulationBox = obj.MySimulationBox.Get_SimulationResults(tmin,h,obj.param.fs);

                    else
                    
                    % generate pointer "Probe" to transducer aperture:
                    % xdc_rectangles doesnt allow empty rectActive List
                    Probe = xdc_rectangles(obj.MyProbe.rectActive,[10 10 10], [11 0 0]);   

                    % calculate impulse response in FIELD II
                        t_impulseResponse = (0:1/obj.param.fs:2/obj.param.f0);
                        impulse           = sin(2*pi*obj.param.f0*t_impulseResponse);
                        impulse           = impulse.*hanning(length(impulse))'; 
                        xdc_impulse (Probe, impulse);
                        
                    % set excitation in FIELD II:  
                    % xdc_excitation (Probe, excitation);
                    %obj.MyExcitation.EXCITATION
                     ele_waveform(Probe,(1:Nactive)',EXCITATION)
                    
                    % set delay law in FIELD II: 
                     switch obj.param.FOC_type
                         case {'OF','OP','OS'}
                      xdc_focus_times(Probe,-1,obj.MyProbe.DelayLaw(obj.BoolActiveList(:,n_scan)));
                         case 'JM'
                      xdc_focus_times(Probe,-1, 0*(1:Nactive) );
                     end

                    % calculate field on MySimulationBox.Points() with FIELD II: 
                    % h : returned field evaluated on [x,y,z] as fucntion
                    % line : time coordinate
                    % column : number of point ( list obj.MySimulationBox.Points() )
                    % t : simulation start time (single value)
                  
                    [h,t] = calc_hp( Probe , obj.MySimulationBox.Points() );
                    
                    % write field results to the current box
                    switch obj.param.FOC_type
                    case {'OF','OP','OS'}
                    tmin = t - max(t_excitation)/2;
                    case 'JM'
                    tmin = t ;    
                    end
                    
                    obj.MySimulationBox = obj.MySimulationBox.Get_SimulationResults(tmin,h,obj.param.fs);
                    xdc_free(Probe);
                    
                    end
                    
        else
           
         %%================= implementation without use of FILEDII=====================
         
          switch obj.param.FOC_type
              
                case 'OF'
                    
                   tmin = (obj.param.Zrange(1)/(obj.param.c)) ;
                   tmax = (max(abs(obj.MySimulationBox.z))/(obj.param.c) + max(t_excitation)) ;
                   
                case 'OP'
                           
                   tmin = ( obj.param.Zrange(1)*cos(obj.ScanParam(n_scan)) )/(obj.param.c) ;
                   tmax = (max(abs(obj.MySimulationBox.z))/(obj.param.c) + max(t_excitation));
                   
                case 'OS' 
                  
                   tmin = ( obj.param.Zrange(1)*cos(obj.ScanParam(n_scan)) )/(obj.param.c) ;
                   tmax = (max(abs(obj.MySimulationBox.z))/(obj.param.c) + max(t_excitation));
           end
           
           obj.MySimulationBox.time = tmin:(1/obj.param.fs):tmax ;
                                 
           [X,Y,Z] = meshgrid(obj.MySimulationBox.x,obj.MySimulationBox.y,obj.MySimulationBox.z);

           T = (obj.MySimulationBox.time')*ones(1,length(Z(:)));
   
           switch obj.param.FOC_type
               
                case 'OF'
                    
            [Field,phi]= obj.GaussianPulse(X-obj.ScanParam(n_scan),Y,Z);   
            % F : field to match dimension issued by Field II
             PHI = repmat(phi(:)',length(obj.MySimulationBox.time) , 1 );
             FIELD =  repmat( Field(:)',length(obj.MySimulationBox.time) , 1 ); 
            
            F = interp1(t_excitation,excitation,T - PHI/(2*pi*obj.param.f0)+ max(t_excitation)/2,'linear',0)  ;  

            obj.MySimulationBox.Field = real(F.*FIELD) ;
            
               case 'OP'
                   
              ZZ = repmat(Z(:)',length(obj.MySimulationBox.time) , 1 );
              XX = repmat(X(:)',length(obj.MySimulationBox.time) , 1 );
%            % F : field to match dimension issued by Field II
%            % setting the rotation inveration to center of the simulation
% 
              XI = (XX*sin(obj.ScanParam(n_scan)) + ZZ*cos(obj.ScanParam(n_scan))) ; 
%             
%             % rotated variable by angle theta
%             obj.MyProbe.DelayLaw = XX*sin(obj.ScanParam(n_scan)) ;
              F = interp1(t_excitation,excitation,...
              T - XI/(obj.param.c),'linear',0)  ;     
          
          % profil due to decimation :
          profil0 = 0*obj.MyProbe.center(:,1) ;
          profil0(obj.MyProbe.ActiveList) = 1 ;
          P = interp1(obj.MyProbe.center(:,1),profil0,...
                      X-Z*tan(obj.ScanParam(n_scan)),'linear',0) ;
          
          PP = repmat(P(:)',length(obj.MySimulationBox.time) , 1 );
          

              % END old code 
 
             obj.MySimulationBox.Field = real(F.*PP) ;  
             
               case 'OS'
                    
              ZZ = repmat(Z(:)',length(obj.MySimulationBox.time) , 1 );
              XX = repmat(X(:)',length(obj.MySimulationBox.time) , 1 );
%            % F : field to match dimension issued by Field II
%            % setting the rotation inveration to center of the simulation
% 
              XI = (XX*sin(obj.ScanParam(n_scan)) + ZZ*cos(obj.ScanParam(n_scan))) ; 
%             
%             % rotated variable by angle theta
%             obj.MyProbe.DelayLaw = XX*sin(obj.ScanParam(n_scan)) ;
              F = interp1(t_excitation,excitation,...
              T - XI/(obj.param.c),'linear',0)  ;     
          
          % profil due to decimation :
          profil0 = 0*obj.MyProbe.center(:,1) ;
          profil0(obj.MyProbe.ActiveList) = 1 ;

          P = interp1(obj.MyProbe.center(:,1),profil0,...
                      X-Z*tan(obj.ScanParam(n_scan)),'linear',0) ;
          
          PP = repmat(P(:)',length(obj.MySimulationBox.time) , 1 );
          

              % END old code 
 
             obj.MySimulationBox.Field = real(F.*PP) ;  
             
                  
           end

       
        end
            
            
            
        end 
        %same function to use with parfor   
        function [E,PHI] = GaussianPulse(obj,X,Y,Z)
            
            z_x = obj.param.focus;
            z_y = obj.param.Rfocus;
           
            Z_x = Z - z_x ;
            Z_y = Z - z_y ;
            
            w_xi = obj.param.N_elements*obj.param.width/2;
            w_yi = obj.param.element_height/2;
            
            lambda = obj.param.c/obj.param.f0;
            
             k = 2*pi/lambda ; 
            
            delta_X = w_xi^4 - 4*(z_x)^2*lambda^2/pi^2;
            delta_Y = w_yi^4 - 4*(obj.param.Rfocus)^2*lambda^2/pi^2;
            
            w0_x = (w_xi^2 + sqrt(delta_X))/(2);
            w0_y = (w_yi^2 + sqrt(delta_Y))/(2);
            
            Zr_x = pi*(w0_x)^2/lambda;
            Zr_y = pi*(w0_y)^2/lambda;
               
            W_x = w0_x*sqrt(1+Z_x .^2/(Zr_x)^2);
            W_y = w0_y*sqrt(1+Z_y.^2/(Zr_y)^2);
            
            XI_x = atan(Z_x/Zr_x);
            R_x = Z_x  + (Zr_x).^2./Z_x ;

            E = (w0_x./W_x).*exp(-X.^2./W_x.^2);
                
            % propagation phae + guy phase + sperical wave phase contributions : 
            PHI = k.*Z - XI_x +k*X.^2./(2*R_x);
            
        
            
        end
        
        function obj = EvalPhantom(obj)
            % Evaluate diffuse beam profile on current simulation box :
            % returns a 1x[Nx,Ny,Nz] vector
            DiffuseLight= obj.MyLaser.Eval(obj.MySimulationBox.x,...
                                    obj.MySimulationBox.y,obj.MySimulationBox.z) ;
            % Evaluate absorber position on current simulation box :
            % returns a 1x[Nx,Ny,Nz] vector                     
            Absorbers = obj.MyPhantom.CalculatePhantom(obj.MySimulationBox.x,...
                                                       obj.MySimulationBox.y,obj.MySimulationBox.z) ;
                                                   
            obj.DiffuseLightTransmission = DiffuseLight.*Absorbers ;
          
        end
        
        function [Transmission,R,zR] = ShowPhantom(obj,varargin)
            
            [Nx,Ny,Nz] = obj.MySimulationBox.SizeBox();
            Transmission = squeeze( reshape(obj.DiffuseLightTransmission',[Ny,Nx,Nz]) );
             % check if dimension agree
             if length(obj.MySimulationBox.x) == size(obj.MySimulationBox.x*1e3,2)
                 Transmission = Transmission';
             end
             
             figure;
             if nargin == 2 
                 theta = 180*varargin{1}/pi ;
                 subplot(121)
                 imagesc(obj.MySimulationBox.x*1e3,obj.MySimulationBox.z*1e3,Transmission)
                 xlabel('x(mm)')
                 ylabel('z(mm)')
                 title('diffused light transmission profile')
                 colorbar
                 % interpolate over refined gris before performing
                 % R-transform :
                 dz = (obj.MySimulationBox.z(2) - obj.MySimulationBox.z(1)); % sampling 
                 x = obj.MySimulationBox.x(1):dz:obj.MySimulationBox.x(end);

                 T = interp1(obj.MySimulationBox.x,Transmission',x,'linear',0);
                 [R,zp] = radon(T',theta + 90);
                 zR = mean(obj.MySimulationBox.z) + zp*dz ; % equivalent z sampling 
                 subplot(122)
                 imagesc(theta,zR*1e3,R)
                 ylim(1e3*[min(obj.MySimulationBox.z) max(obj.MySimulationBox.z)])
                 xlabel('\theta(�)')
                 ylabel('z(mm)')
                 title('Radon transform')
                 colorbar
             else
   
             imagesc(obj.MySimulationBox.x*1e3,obj.MySimulationBox.z*1e3,Transmission)
             xlabel('x(mm)')
             ylabel('z (mm)')
             title('diffused light transmission profile')
             colorbar
             zR = [] ;
             R = [];
             
             
            end
                
        end
        
        function obj = GetAcquisitionLine(obj,n)



            [Nx,Ny,Nz] = obj.MySimulationBox.SizeBox();
            % full profile calculated here to optimize loop Scan calulation :     
            
            LightTransmission = repmat(obj.DiffuseLightTransmission,length(obj.MySimulationBox.time),1)  ;
            Enveloppe = envelope(obj.MySimulationBox.Field,300).^2;
            MarkedPhotons = Enveloppe.^2.*LightTransmission ;
            MarkedPhotons = reshape(MarkedPhotons',[Ny,Nx,Nz,length(obj.MySimulationBox.time)]);
            line = squeeze( sum(sum(sum(MarkedPhotons,1),2),3) );
            % interpolation on simulation box 
            obj.AOSignal(:,n) = interp1((obj.MySimulationBox.time)*obj.param.c,line,obj.MySimulationBox.z,'square',0);

            
        end
        
        function [] = ShowAcquisitionLine(obj)
            FigHandle = figure;
            %set(FigHandle,'WindowStyle','docked'); 
            obj.param.FOC_type
            switch obj.param.FOC_type
                
                case 'OF'
            imagesc(obj.ScanParam*1e3+20,obj.MySimulationBox.z*1e3,obj.AOSignal)
            xlabel('x (mm)')
                case 'OP'
            imagesc(obj.ScanParam*180/pi,obj.MySimulationBox.z*1e3,obj.AOSignal)
            xlabel('angles (�)')
                case 'OS'
            imagesc(obj.ScanParam(:,2),obj.MySimulationBox.z*1e3,obj.AOSignal)
            xlabel('scan param')
                case 'JM'
            imagesc(obj.ScanParam(:,2),obj.MySimulationBox.z*1e3,obj.AOSignal)
            xlabel('scan param')
            end
            ylabel('z = ct (mm) ')
            title('\int_{x,y,z} P(x,y,z,t) dxdydz')
            cb = colorbar ;
            ylabel(cb,'a.u')
            set(findall(FigHandle,'-property','FontSize'),'FontSize',15) 

            
        end
        
        function Iout = ShowFieldCorrelation(obj,plane,FigHandle,TrigDelay,nscan)
            
            [Nx,Ny,Nz]       = SizeBox(obj.MySimulationBox);
            
            if ~ishandle(FigHandle)
                FigHandle = figure ;
            end     
            
            switch plane
                
                
                case 'XZ'
                    
                if (Ny == 1)
                    I_plane = 1;
                else
                    prompt = {'Enter Y coordinate (program will look for closest value):'};
                    dlg_title = 'Y plane select (mm)';
                    num_lines = 1;
                    answer = inputdlg(prompt,dlg_title,num_lines,{'0'});
                    V_plane = str2double(answer{1})*1e-3;                    
                    I_plane = Closest(V_plane,obj.y); 
               end
                
                set(FigHandle,'name','(XZ) maximum field (t) values');
                %% define field correlator
                output      = obj.MySimulationBox.Field;
                t           = obj.MySimulationBox.time(:);
                
                %Eref        = repmat( exp(-1i*2*pi*obj.param.f0*t(:)), 1 , size( output , 2 )  ); 
                Eref        = repmat( obj.MyAO.Event(:,nscan) , 1 , size( output , 2 )  );  
                E_tagged    = hilbert(output);

                
                %TrigDelay = obj.param.TrigDelay;
                % change size of Eref depending on parameter
                E_tagged(~(t>TrigDelay),:) = []; 
                
                Nref = size(Eref,1);
                Ntagged = size(E_tagged,1);
                if( Nref > Ntagged )
                Eref(Nref+1:end,:) = [];    
                elseif( Nref < Ntagged )
                    %find index of point greater then delay      
                E_tagged((Nref+1):end,:) = [];    
                end
                
                
                myField = E_tagged.*Eref  ; % correlation on each column
                                
                myField = abs(sum(myField,1));
                myField = reshape(myField ,[Ny,Nx,Nz]);     
                myField = squeeze( myField(I_plane,:,:) ) ;
                myFieldm = reshape( max(envelope(output,300)),[Ny,Nx,Nz]);  
                myFieldm= squeeze( myFieldm(I_plane,:,:) ) ; 
                subplot(121)
                        imagesc(obj.MySimulationBox.x*1e3,obj.MySimulationBox.z*1e3, myField' );
                        xlabel('x (mm)')
                        ylabel('z (mm)')
                        ylim([min(obj.MySimulationBox.z*1e3) max(obj.MySimulationBox.z*1e3)])
                        title(['P(t) on XZ, \tau_c =',num2str(1e6*obj.param.tau_c ),'\mu s']) 
                        cb = colorbar ;
                        ylabel(cb,'a.u')
                        drawnow
              subplot(122)
                        imagesc(obj.MySimulationBox.x*1e3,obj.MySimulationBox.z*1e3, myFieldm' );
                        xlabel('x (mm)')
                        ylabel('z (mm)')
                        ylim([min(obj.MySimulationBox.z*1e3) max(obj.MySimulationBox.z*1e3)])
                        title(['P(t) on XZ, \tau_c =',num2str(1e6*obj.param.tau_c ),'\mu s']) 
                        cb = colorbar ;
                        ylabel(cb,'a.u')
                        drawnow

            end
            
            
        end
       
       
    end
    
end

