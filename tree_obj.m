classdef tree_obj
    
    properties
       
      tail {mustBeNumeric} % 3x1 initial position vector
      head {mustBeNumeric} % 3x1 end point of matrix, not relative to
      uvec {mustBeNumeric} % unit vector in direction of branch orientation
      
      th {mustBeNumeric} % incidence (about x) [deg]
      el {mustBeNumeric} %   azimuth (about z) [deg]
      
      semi_minor {mustBeNumeric} % semi minor axis [m]
      semi_major {mustBeNumeric} % semi major axis [m]
      len {mustBeNumeric}        % length of cylinder [m]
      
      %% Meter-scale roughness
      diel_r {mustBeNumeric}      % real relative permittivity [F/m]
      diel_i  {mustBeNumeric}     % imag relative permittivity [F/m]

      pers {mustBeNumeric}        % persistence of branch length
      thrsh {mustBeNumeric}       % tree branch threshold
      num_c {mustBeNumeric}       % number of children per node
      
%       node_num {mustBeNumeric} % 
      
      type string = '' % type (trunk, branch, leaf)
      
    end
    
    methods
        function obj = tree_obj(tail,head,pers,thrsh)
            
            % initialize position and displacement of branch
            obj.tail = tail;
            obj.head = head;
            
            obj.len = vecnorm( obj.head - obj.tail ) ;

            % unit vectors of branch
            uvec = (obj.head - obj.tail) ./ obj.len ;
            obj.uvec = uvec ;

            % az and elev of 
            obj.th = acosd( dot( [0 0 1]', uvec) ) ; % incidence (about x) [deg]
            obj.el = atand( -uvec(1) / uvec(2) ) ;   %   azimuth (about z) [deg]

            % rx = @(a) [1 0 0; 0 cosd(a) -sind(a); 0 sind(a) cosd(a)];
            % ry = @(a) [cosd(a) 0 sind(a); 0 1 0; -sind(a) 0 cosd(a)];
            % rz = @(a) [cosd(a) -sind(a) 0; sind(a) cosd(a) 0; 0 0 1];
            % uvec2 = rz(el) * rx(th) & [0 0 1]' ; % sanity check

            obj.pers = pers;
            obj.thrsh = thrsh;
            obj.num_c = 4 ; % 4 branches for 3d

            % assign type
            if isequal( obj.tail, [0 0 0]')
                obj.type = 'trunk' ;
            else
                obj.type = 'branch' ;
            end

            % assign dielectric
            switch obj.type
                case 'trunk'
                    obj.diel_r = 15.6 ; % [F/m]
                    obj.diel_i =  3.8 ; % (+ sqrt(i))
                case 'branch'
                    obj.diel_r = 12.0 ; % [F/m]
                    obj.diel_i = 2.93 ; % (+ sqrt(i))
            end

        end
        
        function o = rx(~, a)
            o = [1 0 0; 0 cosd(a) -sind(a); 0 sind(a) cosd(a)];
       end
        
        function o = ry(~, a)
            o =  [cosd(a) 0 sind(a); 0 1 0; -sind(a) 0 cosd(a)];
        end
        
        function o = rz(~, a)
            o = [cosd(a) -sind(a) 0; sind(a) cosd(a) 0; 0 0 1];
        end
        
        function new_obj = branch( obj, ang, rhan )
            % create a new branch. example inputs:
            % obj -- the current object
            % ang -- the rotation angle [deg]
            % rhan -- the rotation function handle
            %
            % example:
            % num_c = 4;
            % ang = 45;
            % rhan = @obj.rx / @obj.ry / @obj.rz 
            
            vec = obj.head - obj.tail ;
            new_br = rhan(ang) * vec * obj.pers ;
            new_tail = obj.tail + vec;
            new_head = obj.head + new_br ;
            new_obj = tree_obj( ...
                new_tail, new_head, obj.pers, obj.thrsh ) ;
            
        end
        
        function angles = shuffle_ang( obj, angs )
        % shuffle angles if desired, or use a constant angle

        if isequal( numel(angs), 2) 
            angles = rescale( rand( [obj.num_c 1] ), angs(1), angs(2) );
        else
            angles = rescale( rand( [obj.num_c 1] ), angs, angs );
        end
            
        end
        
        function brnchs = gen_branches( obj, angs )
            
            if obj.len < obj.thrsh
                brnchs = obj;
                return;
            end

        % shuffle provided angles
        angles = obj.shuffle_ang(angs) ;
        % alternating signs for rotation angle
        signs = ones( [obj.num_c, 1 ] );
        signs( logical( mod(1:length(signs),2) ) ) = -1 ;
        angles = signs .* angles ;
        
        % gather rotation handles
        hans =  { @obj.rx, @obj.rx, @obj.ry, @obj.ry };
        
        % store new branches here
        nb = obj.empty([0, obj.num_c]);
        
        for i = 1 : obj.num_c
            
            nb(i) = ...
                obj.branch( angles(i), hans{i} ) ;
            if exist('brnchs', 'var')
                brnchs = [brnchs gen_branches( nb(i), angs ) ] ;
            else
                brnchs = gen_branches( nb(i), angs ) ;
            end
            

        end
        
        brnchs = [ obj brnchs ];

            
        end
        
    end
end