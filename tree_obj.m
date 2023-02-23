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
	  pos    {mustBeNumeric} 	  % tree position (head + tail) / 2 [m]
      diel_r {mustBeNumeric}      % real relative permittivity [F/m]
      diel_i {mustBeNumeric}      % imag relative permittivity [F/m]

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
            obj = obj.get_pos();

            % unit vectors of branch
            uvec = (obj.head - obj.tail) ./ obj.len ;
            obj.uvec = uvec ;

            % az and elev of 
            obj.th = acosd( dot( [0 0 1]', uvec) ) ; % incidence (about x) [deg]
            obj.el = atand( -uvec(1) / uvec(2) ) ;   %   azimuth (about z) [deg]
            
            if isnan(obj.el)
                obj.el = 0 ;
            end
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
        
        function brnchs = shinozaki_pipe(obj, dbh, d0)
            
            % an implementation based on the Shinozaki pipe model theory of
            % plant cylinder construction.
            % https://doi.org/10.18960/seitai.14.3_97
            % with implementation based on the description of 
            % https://algorithmicbotany.org/papers/colonization.egwnp2007.pdf
            %
            % instead of using an adjustment parameter [Runions 2007, eq.1],
            % pipes are formed by determining the total number of children 
            % for the plant. the counts are then scaled to fit between a
            % maximum of the diameter at breast height and the minimum
            % desired radius for terminal branch nodes.
            %
            % this code is designed for cylindrical branches with equal
            % semi-major and semi-minor axes. space is made to compute
            % semi-major and semi-minor independently, though i'm sure
            % there are several considerations for the orientation of the
            % cylinder along the growing structure.
            %
            % inputs %
            % dbh -- diameter at breast height [m]
            % d0  -- diameter of the terminal branches [m]
            %% find terminal branches
            
            h = [obj(:).head];
            t = [obj(:).tail];

            % lambda functions
            ufndc = @(a,b) find( sum( a ==  b, 1) == 3 );
            get_par   = @(ch) ufndc( ch, h ) ;
            get_child = @(ch) ufndc( ch, t ) ;

            ts = zeros([1 size(h,2)]); % terminal points
            % d0 = 0.5;             % radius of terminal branches [m]
            as = zeros(size(ts)); % semi-major axis [m] (typically a==b)
            bs = zeros(size(ts)); % semi-minor axis [m] (typically a==b)
            is = [];

            % find terminal branches
            for i = 1:length(h)
                if ~ismember(h(:,i)', t', 'rows')
                    is = [is i];
                end
            end

            % initialize terminal points with terminal diameter
            as(is) = d0;
            bs(is) = d0;

            next_cis = is ;
            max_its = 1000;
            its = 0;
            
            % determine diameter of all branches
            while any(as==0)
                % reset parameters on while loop
                cis = next_cis;
                next_cis = [] ;
                % loop over current end points
                for i =1:length(cis)
                    
                    % check the radius of current branch's children
                    cind = cis(i);
                    ch = t(:, cis(i)) ;
                    child = get_child( ch );

                    % if any of the children are not defined, then
                    % come back later
                    if any(as(child) == 0)
                        next_cis = [next_cis cind] ;
                    else
                    % if all children have defined diameter, calculate next
                    % diameter
                    par = get_par( ch );

                    new_a = 0;
                    new_b = 0;
                    for ii = 1:length(child)
                        cur_ci = child(ii) ;
                        new_a = new_a + as(cur_ci) ;
                        new_b = new_b + bs(cur_ci) ;
                    end

                    as( par ) = new_a ;
                    bs( par ) = new_b ;
                    
                    % this iteration's tail = next iteration's head
                    next_cis = [next_cis par] ;
                    end

                end
                
                % emergency break code
                % since we're in a while loop
                if isequal(cis, next_cis)
                    its = its + 1;
                end
                % break if we exceed desired iterations
                if its == max_its
                    warning('shinozaki pipe model ended unexpectedly')
                    break
                end

            end
            
            aso = rescale( as, d0, dbh ) ;
            bso = rescale( bs, d0, dbh) ;
            
            for i = 1:size(h,2)
                obj(i).semi_major = aso(i) ;
                obj(i).semi_minor = bso(i) ;
                
            end
            
            brnchs = obj ;

        end
        
		function obj = get_pos(obj)
            % return position [m]
            obj.pos = (1/2) .* ( obj.head + obj.tail) ;
        end
		
    end
end