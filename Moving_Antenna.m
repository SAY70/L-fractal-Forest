%Test for moving antenna
% Initial receiver position  
receiver_position = [0, 0, 1];

% Define the number of particles and their positions in a cube
% n_particles = 1000;
% cube_size = 50;
% particle_positions = cube_size*(2*rand(n_particles, 3) - 1); % random positions between -cube_size and cube_size
n_particles = 1000;
cube_size = 5;
particle_positions = cube_size*(2*rand(n_particles, 2) - 1);
particle_positions(:,3) = abs(cube_size*rand(n_particles, 1));




% Define the view angle of the receiver and the direction it is pointing
view_angle = 30; % in degrees
receiver_direction = [0, 0, 1]; % upward direction

velocity = [0.1, 0.1]; % Define the initial velocity of the receiver in x and y directions

% Define the time step and the total time for sim
dt = 1; % time step in sec
total_time = 10; % total sim time in sec

% particle count and position arrays intializtaion
particle_count = zeros(total_time, 1);
particle_positions_in_view = cell(total_time, 1);

% Simulate the movement of the receiver and count the particles in its view at each time step
for t = 1:total_time
    % calculate the new position of the receiver based on its velocity
    receiver_position(1:2) = receiver_position(1:2) + velocity*dt;
    
    % calculate particle vectors relative to receiver location
    particle_vectors = particle_positions - receiver_position;

    % Calculate angles between particle vectors and receiver view direction
    cos_angles = dot(particle_vectors, repmat(receiver_direction, size(particle_vectors, 1), 1), 2) ./ vecnorm(particle_vectors, 2, 2);
    angles = acosd(cos_angles);

    % find particles within the view cone
    in_view = find(angles <= view_angle);

    % Record the particle count and its positions in view for this time step
    particle_count(t) = numel(in_view);
    particle_positions_in_view{t} = particle_positions(in_view, :);
end

% movement of the receiver and the particles in its view visulization
figure;
hold on;
scatter3(particle_positions(:,1), particle_positions(:,2), particle_positions(:,3), '.', 'b');
view(3);
axis equal;
grid on;
xlabel('X');
ylabel('Y');
zlabel('Z');

% PLOTING for time step
for t = 1:total_time
    % Plot the particles in the view cone at this time step
    scatter3(particle_positions_in_view{t}(:,1), particle_positions_in_view{t}(:,2), particle_positions_in_view{t}(:,3), 'filled', 'g');
    
    % Plot the receiver at this time step
    plot3(receiver_position(1), receiver_position(2), receiver_position(3), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
    
    % Pause for a short time to show the movement
    pause(0.1);
    
    % Calculate the new position of the receiver based on its velocity
    receiver_position(1:2) = receiver_position(1:2) + velocity*dt;
end
