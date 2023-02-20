clearvars; close all; clc;

% set trunk parameters
tail = [0 0 0]'; 
head = [0 0 1]';

% set branch growth parameters
pers = 0.6;     % persistence
thrsh = 0.3;    % threshold
ang = [15 45] ;    % growth angle, can be one value of range [min max]

% create multiple trees
n_rows = 10; % rows*column gives us number of tree
n_cols = 7;
x_range = 2; % range of x positions
y_range = 2; % range of y positions
plt3 = @(a) plot3(a(1,:), a(2,:), a(3,:), 'color', 'k');

% initialize variables to store positions and lengths
trunk_positions = [];
primary_positions = [];
secondary_positions = [];
trunk_lengths = [];
primary_lengths = [];
secondary_lengths = [];

% initialize variables to store head and tail positions of all branches
all_head_positions = [];
all_tail_positions = [];

% initialize variables to store center position of each branch
trunk_centers = [];
primary_centers = [];
secondary_centers = [];

for row = 1:n_rows
    for col = 1:n_cols
        % generate random position within range
        x_pos = (rand-0.5)*2*x_range;
        y_pos = (rand-0.5)*2*y_range;
        z_pos = 0;
        
        % create tree at position
        trunk = tree_obj( tail + [x_pos; y_pos; z_pos], head + [x_pos; y_pos; z_pos], pers, thrsh );
        tree = trunk.gen_branches(ang);
        
        % plot tree
        for i = 1:length(tree)
            % add offset to head and tail positions
            tail_pos = tree(i).tail + [x_pos; y_pos; z_pos];
            head_pos = tree(i).head + [x_pos; y_pos; z_pos];
            plt3([ tail_pos, head_pos ]); hold('on');

            % save head and tail positions of the branch
            all_head_positions = [all_head_positions, head_pos];
            all_tail_positions = [all_tail_positions, tail_pos];

            % calculate center position of the branch
            center_pos = tail_pos + (head_pos - tail_pos) / 2;
            
            % save branch position and length
            branch_len = norm(head_pos - tail_pos);
            %branch_pos = head_pos;
            if branch_len > thrsh % CAN DEFINE more condition to diff branch size
                % primary branch
                primary_positions = [primary_positions, center_pos];
                primary_lengths = [primary_lengths, branch_len];
                primary_centers = [primary_centers, center_pos];
            else
                % secondary branch
                secondary_positions = [secondary_positions, center_pos];
                secondary_lengths = [secondary_lengths, branch_len];
                secondary_centers = [secondary_centers, center_pos];
            end
           

        end
        
        % save trunk position and length
        trunk_pos = tail + [x_pos; y_pos; z_pos];
        trunk_len = norm(head + [x_pos; y_pos; z_pos] - tail - [x_pos; y_pos; z_pos]);
        trunk_positions = [trunk_positions, trunk_pos];
        trunk_lengths = [trunk_lengths,trunk_len];
        
        % calculate center position of the trunk
        trunk_center_pos = (tail + head) / 2 + [x_pos; y_pos; z_pos];
        trunk_centers = [trunk_centers, trunk_center_pos];

%         % display head and tail positions
%         fprintf('Tree at row %d, column %d:\n', row, col);
%         fprintf('Trunk tail position: [%f, %f, %f]\n', trunk_pos);
%         fprintf('Trunk head position: [%f, %f, %f]\n', head + [x_pos; y_pos; z_pos]);
%         for i = 1:length(tree)
%             fprintf('Branch %d tail position: [%f, %f, %f]\n', i, tree(i).tail + [x_pos; y_pos; z_pos]);
%             fprintf('Branch %d head position: [%f, %f, %f]\n', i, tree(i).head + [x_pos; y_pos; z_pos]);
%         end
%         fprintf('\n');
    end
end

xlabel('x [m]'); ylabel('y [m]')
zlabel('z [m]')
grid('on')
title('OOP fractal recursion tree')
axis('equal')
hold on
%TPS_center_points = [trunk_centers primary_centers, secondary_centers];
TPS_center_points = [primary_centers, secondary_centers];
scatter3(TPS_center_points(1,:), TPS_center_points(2,:), TPS_center_points(3,:),'b.')
hold on

%%
% % Receiver location and view angle
receiver_position = [1.5, 0.5, 0.1]; % [x,y,z]
scatter3(1.5, 0.5, 0.1,'filled','ro'); % enetered manually, make change here
view_angle = 40; % in degrees, one side from the +z axis

% Generate random particle positions
%n_particles = 100000;
%particle_positions = 500*rand(n_particles, 3) - 250; % random positions between -250 and 250

% Generate L-fractal forest particle center position
particle_positions = TPS_center_points';

% Calculate particle vectors relative to receiver location
particle_vectors = particle_positions - receiver_position;

% Calculate angles between particle vectors and receiver view direction
receiver_direction = [0, 0, 1]; % upward direction
cos_angles = dot(particle_vectors, repmat(receiver_direction, ...
    size(particle_vectors, 1), 1), 2) ./ vecnorm(particle_vectors, 2, 2);
angles = acosd(cos_angles);

% Find particles within the view cone
in_view = find(angles <= view_angle); % used for view angle condition

% Plot the particles in the view cone
%figure;
scatter3(particle_positions(in_view,1), particle_positions(in_view,2), particle_positions(in_view,3), 'filled', 'g');
title('Particles in the receiver view');
xlabel('X');
ylabel('Y');
zlabel('Z');
axis equal;
grid on;


%% Histogram Test

% if exist('branch_positions', 'var')
%     all_positions = [trunk_positions, primary_positions];
% else
%     all_positions = primary_positions;
% end
% all_positions = [trunk_positions, primary_positions, secondary_positions];
% center_position = mean(all_positions);
% all_positions = [trunk_positions, primary_positions, secondary_positions];
% all_heads = all_positions(:, 1:2:end);
% all_tails = all_positions(:, 2:2:end);

all_lengths = [trunk_lengths, primary_lengths, secondary_lengths];

% Create a histogram with three bins corresponding to the three categories
figure('color', 'white')
histogram(trunk_lengths, 'BinWidth', 0.02, 'FaceColor', 'b')
hold on
histogram(primary_lengths, 'BinWidth', 0.02, 'FaceColor', 'r')
hold on
histogram(secondary_lengths, 'BinWidth', 0.02, 'FaceColor', 'g')
hold on
legend('Primary Branches', 'Secondary Branches')
xlabel('Branch Length')
ylabel('Frequency')
title('Histogram of Branch Lengths, Categorized by Branch Type')

%%
%TPS_center_points = [trunk_centers primary_centers, secondary_centers];

% %%
% %all_branch_angle = calculate_angles(all_head_positions', 
% % all_tail_positions');
% % calculate positive z-axis vector
% branch_angles=[];
% z_axis = [0 0 1];
% 
% % loop over all branches
% for i = 1:length(all_head_positions)
%     % calculate vector representing branch direction
%     branch_dir = all_head_positions(:,i) - all_tail_positions(:,i);
%     
%     % calculate cosine of angle between positive z-axis and branch direction
%     cos_angle = dot(z_axis, branch_dir) / norm(branch_dir);
%     
%     % calculate angle in radians
%     angle_rad = acos(cos_angle);
%     
%     % convert angle to degrees
%     angle_deg = angle_rad * 180 / pi;
%     
%     %fprintf('Branch %d angle: %.2f degrees\n', i, angle_deg);
% 
%     branch_angles = [branch_angles angle_deg];
% 
% end


%%

% Thinking to assign attributes such as radius, dielectric value and 
% other scobi parameter  in structures array in the object function


%% store azimuth and elevation angle for all branches

branch_el_angles=[];
branch_az_angles=[];
% Positive z-axis vector
z_axis = [0 0 1];

% Positive x-y axis vector
x_axis = [1 0];
%y_axis = [0 1 0];
%x_axis = reshape(x_axis, 1, 2);
%branch_dir_2d = branch_dir(1:2);
%branch_dir_2d = reshape(branch_dir_2d, 2, 1);

% Loop over all branches
for i = 1:length(all_head_positions)
    % Calculate vector representing branch direction
    branch_dir = all_head_positions(:,i) - all_tail_positions(:,i);
    
    % Calculate cosine of angle between positive z-axis and branch direction
    cos_elevation = dot(z_axis, branch_dir) / norm(branch_dir);
    
    % Calculate elevation angle in radians
    angle_elevation_rad = acos(cos_elevation);
    
    % Convert elevation angle to degrees
    angle_elevation_deg = angle_elevation_rad * 180 / pi;
    
    
    %branch_dir_2d = branch_dir(1:2);
    %branch_dir_2d = reshape(branch_dir_2d, 2, 1);

    % Calculate cosine of angle between positive x-axis and branch direction projected onto x-y plane
    cos_azimuth = dot(x_axis', branch_dir(1:2)) / norm(branch_dir(1:2));
    %cos_azimuth = dot(x_axis', branch_dir_2d) / norm(branch_dir_2d);
    %sin_azimuth = dot(y_axis', branch_dir(1:2)) / norm(branch_dir(1:2));
    
    % Calculate azimuth angle in radians
    angle_azimuth_rad = acos(cos_azimuth);
    
    % Convert azimuth angle to degrees
    angle_azimuth_deg = angle_azimuth_rad * 180 / pi;

    
    % Display angles
    %fprintf('Branch %d elevation angle: %.2f degrees, azimuth angle: %.2f degrees\n', i, angle_elevation_deg, angle_azimuth_deg);
    
    branch_az_angles = [branch_az_angles angle_azimuth_deg];
    branch_el_angles = [branch_el_angles angle_elevation_deg];

end

%%
% If want to add moving antenna, look for 
% Moving_ant_to_find_particle algo to integrate with this one
