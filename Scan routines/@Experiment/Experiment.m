classdef Experiment
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = public)
        
        MyPhantom ;
        MyProbe ;
        MyLaser ;
        MySimulationBox;
      
       ScanParam
       Nscan
       BoolActiveList 
       AOSignal
        
    end
    
    properties (Access = private)
        % structure containing all the experiement parameters
       param 

    end
    
    methods
        
        % constructor :
        function obj = Experiment(param)
            % param = structure containing all the simulation parameters
                       % for excitation : sparse probe, use with rectangle
            obj.MyPhantom = Phantom( param.phantom.Positions, param.phantom.Sizes, param.phantom.Types );            
            obj.MySimulationBox = AO_FieldBox(param.Xrange,param.Yrange,param.Zrange,param.Nx,param.Ny,param.Nz);

            % IR laser :
            % if no center is specified, the beam center is the 
            if isfield(param,'center')
            obj.MyLaser = LaserBeam(param.w0,param.center);
            else
            obj.MyLaser = LaserBeam(param.w0,obj.MySimulationBox.GetCenter);
            end
            
            obj.MyProbe = ActuatorProbe(param.N_elements,param.element_height,param.width,...
                          param.no_sub_x,param.no_sub_y,param.kerf,1,param.Rfocus);
                      % for waveform :
                      
            obj.param = param;
            
            obj = ConfigureProbeSequence(obj) ;
            
            
        end
        
        function obj = ConfigureProbeSequence(obj)
            
            switch obj.param.FOC_type
                case 'OF'
                    % get the center position X for each scan line               
                       [Scan, obj.ScanParam] = obj.MyProbe.GetIndex( obj.MySimulationBox.x );
                       Scan(isnan(Scan)) = [] ;  
                       % retreive the total number od scans     
                       obj.Nscan = length(Scan);        
                       % initialization : all actuator actives
                       obj.BoolActiveList = zeros(obj.param.N_elements,obj.Nscan);                       
                       % Dimension in index of active probes lenght
                       ActiveWidth = obj.param.focus/2; % as in the experiement, in m
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
                       obj.BoolActiveList( I , n_scan) = 1 ; 
                       end                     
                       % unsure concersion to boolean type
                       obj.BoolActiveList = logical(obj.BoolActiveList) ;
                       
               case 'OP'
                    if ~isfield(obj.param,'angles')
                        obj.param.angles = (-45:2:45)*pi/180 ; % default scan angles
                    end
                    
                    % retreive the total number od scans     
                       obj.Nscan = length(obj.param.angles); 
                       obj.ScanParam = obj.param.angles ;
                       obj.BoolActiveList = true(obj.param.N_elements,obj.Nscan);   
                
     
            end
           
 
                      
            
        end
            
        function obj = CalculateUSfield(obj,excitation,n_scan)
            
           FullElementList = 1:obj.param.N_elements ;
           ActiveList =  FullElementList(obj.BoolActiveList(:,n_scan)) ;
           
           % probe strcuture initialization :
           obj.MyProbe = ActuatorProbe(obj.param.N_elements,obj.param.element_height,obj.param.width,...
                          obj.param.no_sub_x,obj.param.no_sub_y,obj.param.kerf,ActiveList,obj.param.Rfocus);

            if obj.param.Activated_FieldII == 1
            % define delay law for the probe :
            switch obj.param.FOC_type
                case 'OF'
            obj.MyProbe = obj.MyProbe.Set_ActuatorDelayLaw('focus',[obj.ScanParam(n_scan) 0 obj.param.focus],obj.param.c);
                case 'OP'
            obj.MyProbe = obj.MyProbe.Set_ActuatorDelayLaw('plane',obj.ScanParam(n_scan),obj.param.c);
            end
            % Initialize home-made probe  :
            % focus [0 0 0] will be overwritten by the delay law
            Probe = xdc_rectangles(obj.MyProbe.rect,[10 10 10], [11 0 0]);   

            % calculate impulse response in FIELD II
                t_impulseResponse = (0:1/obj.param.fs:2/obj.param.f0);
                impulse = sin(2*pi*obj.param.f0*t_impulseResponse);
                impulse=impulse.*hanning(length(impulse))'; 
                xdc_impulse (Probe, impulse);
            % set excitation in FIELD II:  
            xdc_excitation (Probe, excitation);
            % set delay law in FIELD II: 
            xdc_focus_times(Probe,-1,obj.MyProbe.DelayLaw);
            % calculate field on MySimulationBox.Points() with FIELD II: 
            [h,t] = calc_hp(Probe,obj.MySimulationBox.Points());
            %h = h/max(h(:));
            % write field results to the current box
            obj.MySimulationBox = obj.MySimulationBox.Get_SimulationResults(t,h,obj.param.fs);
            
            else

            obj.MySimulationBox.time = 0:(1/obj.param.fs_aq):max(abs(obj.MySimulationBox.z))/(obj.param.c) ;
            [X,Y,Z] = meshgrid(obj.MySimulationBox.x,obj.MySimulationBox.y,obj.MySimulationBox.z);
            Field = obj.GaussianPulse(X,Y,Z);
            
            % F : field to match dimension issued by Field II
            F =  repmat( Field(:)',length(obj.MySimulationBox.time) , 1 ); 
            T = (obj.MySimulationBox.time')*ones(1,length(Z(:)));
            ZZ = repmat(Z(:)',length(obj.MySimulationBox.time) , 1 );


             F  =   F.*exp(1i*2*pi*obj.param.f0*(T- ZZ/(obj.param.c))).*...
                    exp(-(T - ZZ/(obj.param.c)).^2/(8/(obj.param.f0))^2);

            obj.MySimulationBox.Field = real(F) ;

            %obj.MySimulationBox.Field = evalField('OF'); % OP and OS to be implmented
            
            end
            
            xdc_free(Probe);
            
        end 
        %same function to use with parfor
        function data = CalculateUSfield_p(obj,excitation,n_scan)
           field_init(0);
           FullElementList = 1:obj.param.N_elements ;
           ActiveList =  FullElementList(obj.BoolActiveList(:,n_scan));
           
           % probe strcuture initialization :
           obj.MyProbe = ActuatorProbe(obj.param.N_elements,obj.param.element_height,obj.param.width,...
                          obj.param.no_sub_x,obj.param.no_sub_y,obj.param.kerf,ActiveList,obj.param.Rfocus);

            if obj.param.Activated_FieldII == 1
            % define delay law for the probe :
            switch obj.param.FOC_type
                case 'OF'
            obj.MyProbe = obj.MyProbe.Set_ActuatorDelayLaw('focus',[obj.ScanParam(n_scan) 0 obj.param.focus],obj.param.c);
                case 'OP'
            obj.MyProbe = obj.MyProbe.Set_ActuatorDelayLaw('plane',angle(n_scan),obj.param.c);
            end
            % Initialize home-made probe  :
            % focus [0 0 0] will be overwritten by the delay law
            Probe = xdc_rectangles(obj.MyProbe.rect,[0 0 0], [0 0 0]);                          
            % calculate impulse response in FIELD II
                t_impulseResponse = (0:1/obj.param.fs:2/obj.param.f0);
                impulse = sin(2*pi*obj.param.f0*t_impulseResponse);
                impulse=impulse.*hanning(length(impulse))'; 
                xdc_impulse (Probe, impulse);
            % set excitation in FIELD II:  
            xdc_excitation (Probe, excitation);
            % set delay law in FIELD II: 
            xdc_focus_times(Probe,-1,obj.MyProbe.DelayLaw);
            % calculate field on MySimulationBox.Points() with FIELD II: 
            [h,t] = calc_hp(Probe,obj.MySimulationBox.Points());

            % write field results to the current box
            obj.MySimulationBox = obj.MySimulationBox.Get_SimulationResults(t,h,obj.param.fs);
            
            else

            obj.MySimulationBox.time = 0:(1/obj.param.fs_aq):max(abs(obj.MySimulationBox.z))/(obj.param.c) ;
            [X,Y,Z] = meshgrid(obj.MySimulationBox.x,obj.MySimulationBox.y,obj.MySimulationBox.z);
            Field = obj.GaussianPulse(X,Y,Z);
            
            % F : field to match dimension issued by Field II
            F =  repmat( Field(:)',length(obj.MySimulationBox.time) , 1 ); 
            T = (obj.MySimulationBox.time')*ones(1,length(Z(:)));
            ZZ = repmat(Z(:)',length(obj.MySimulationBox.time) , 1 );


             F  =   F.*exp(1i*2*pi*obj.param.f0*(T- ZZ/(obj.param.c))).*...
                    exp(-(T - ZZ/(obj.param.c)).^2/(8/(obj.param.f0))^2);

            obj.MySimulationBox.Field = real(F) ;
            
            %obj.MySimulationBox.Field = evalField('OF'); % OP and OS to be implmented
            
            end
            
            data = obj.GetAcquisitionLine(n_scan);
            xdc_free(Probe);
            
        end
        
        function E = GaussianPulse(obj,X,Y,Z)
            
            z_x = obj.param.focus;
           % z_y = obj.param.Rfocus;
           
            Z_x = Z - z_x ;
            %Z_y = Z - obj.z_y ;
            
            w_xi = obj.param.N_elements*obj.param.width/2;
           % w_yi = obj.param.element_height/2;
            
            lambda = obj.param.c/obj.param.f0;
            
             k = 2*pi/lambda ; 
            
            delta_X = w_xi^4 - 4*(z_x)^2*lambda^2/pi^2;
            %delta_Y = w_yi^4 - 4*(obj.param.Rfocus)^2*lambda^2/pi^2;
            
            w0_x = (w_xi^2 + sqrt(delta_X))/(2);
            %w0_y = (w_yi^2 + sqrt(delta_Y))/(2);
            
            Zr_x = pi*(w0_x)^2/lambda;
            %Zr_y = pi*(w0_y)^2/lambda;
               
            W_x = w0_x*sqrt(1+Z_x .^2/(Zr_x)^2);
            %W_y = w0_y*sqrt(1+Z_y.^2/(Zr_y)^2);
            
            XI_x = atan(Z_x/Zr_x);
            R_x = Z_x  + (Zr_x).^2./Z_x ;
            %*exp(-1i*obj.k*Z_x)
            E = (w0_x./W_x).*exp(-X.^2./W_x.^2)...
                .*exp(-1i*k.*Z_x./(2*R_x)).*exp(1i*XI_x);
            
        
            
        end
        
        function obj = GetAcquisitionLine(obj,n)
            [Nx,Ny,Nz] = obj.MySimulationBox.SizeBox();
                       
            % avaluate Gaussian diffuse beam on current simulation box :
            % returns a 1x[Nx,Ny,Nz] vector
            DiffuseLightIntensity = obj.MyLaser.Eval(obj.MySimulationBox.x,...
                                    obj.MySimulationBox.y,obj.MySimulationBox.z) ;
            Absorbers = obj.MyPhantom.CalculatePhantom(obj.MySimulationBox.x,...
                                                       obj.MySimulationBox.y,obj.MySimulationBox.z) ;
                                
            DiffuseLightIntensity = repmat(DiffuseLightIntensity.*Absorbers,length(obj.MySimulationBox.time),1)  ;

            MarkedPhotons = obj.MySimulationBox.Field;
%             MarkedPhotons = (obj.MySimulationBox.Field).*DiffuseLightIntensity ;
            MarkedPhotons = reshape(MarkedPhotons',[Ny,Nx,Nz,length(obj.MySimulationBox.time)]);
%            figure;
%             for i = 1:10:length(obj.MySimulationBox.time)
%             imagesc(squeeze(MarkedPhotons(:,:,:,i))')
%             title(num2str(obj.MySimulationBox.time(i)*1e6))
%             colorbar
%             drawnow
%             end
            
            line = squeeze( sum(sum(sum(MarkedPhotons,1),2),3) );
            % interpolation on simulation box 
            obj.AOSignal(:,n) = interp1(obj.MySimulationBox.time*obj.param.c,line,obj.MySimulationBox.z,'linear',0);
            
            
        end
        
        function [] = ShowAcquisitionLine(obj)
               figure;
            switch obj.param.FOC_type
                case 'OF'
            imagesc(obj.ScanParam*1e3,obj.MySimulationBox.z*1e3,obj.AOSignal)
            xlabel('x (mm)')
                case 'OP'
            imagesc(obj.ScanParam*180/pi,obj.MySimulationBox.z*1e3,obj.AOSignal)
            xlabel('angles (�)')
            end
            ylabel('z = ct (mm) ')
            title('\int_{x,y,z} P(x,y,z,t) dxdydz')
            colorbar

            
        end
       
    end
    
end

