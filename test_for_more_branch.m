clearvars; close all; clc;

%% set trunk parameters
tail = [0 0 0]';
head = [0 0 1]';

%% set branch growth parameters
pers = 0.6;     % persistence
thrsh = 0.2;    % threshold
ang = [40] ;    % growth angle

%% create multiple trees
n_rows = 3;
n_cols = 3;
x_spacing = 1.5;
y_spacing = 1.5;
plt3 = @(a) plot3(a(1,:), a(2,:), a(3,:), 'color', 'k');

% initialize variables to store positions and lengths
trunk_positions = [];
primary_positions = [];
secondary_positions = [];
trunk_lengths = [];
primary_lengths = [];
secondary_lengths = [];
no_use_positions = [];
no_use_lengths = [];

% initialize variables to store head and tail positions of all branches
all_head_positions = [];
all_tail_positions = [];

% initialize variables to store center position of each branch
trunk_centers = [];
primary_centers = [];
secondary_centers = [];
no_use_centers = [];


for row = 1:n_rows
    for col = 1:n_cols
        % calculate position of tree
        x_pos = (col-1)*x_spacing;
        y_pos = (row-1)*y_spacing;
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
            if branch_len > 3*thrsh
                % primary branch
                primary_positions = [primary_positions, center_pos];
                primary_lengths = [primary_lengths, branch_len];
                primary_centers = [primary_centers, center_pos];%check here
            else
                if branch_len > 1.5*thrsh
                % secondary branch
                secondary_positions = [secondary_positions, center_pos];
                secondary_lengths = [secondary_lengths, branch_len];
                secondary_centers = [secondary_centers, center_pos];%check here
                else
                no_use_positions = [no_use_positions, center_pos];
                no_use_lengths = [no_use_lengths, branch_len];
                no_use_centers = [no_use_centers, center_pos];%check here
                end
            end
        end
        
        % save trunk position and length
        trunk_pos = tail + [x_pos; y_pos; z_pos];
        trunk_len = norm(head + [x_pos; y_pos; z_pos] - tail - [x_pos; y_pos; z_pos]);
        trunk_positions = [trunk_positions, trunk_pos];
        trunk_lengths = [trunk_lengths,trunk_len];
        
        % calculte center position of the trunk
        trunk_center_pos = (tail + head) / 2 + [x_pos; y_pos; z_pos];
        trunk_centers = [trunk_centers, trunk_center_pos];

        % display head and tail positions
        fprintf('Tree at row %d, column %d:\n', row, col);
        fprintf('Trunk tail position: [%f, %f, %f]\n', trunk_pos);
        fprintf('Trunk head position: [%f, %f, %f]\n', head + [x_pos; y_pos; z_pos]);
        for i = 1:length(tree)
            fprintf('Branch %d tail position: [%f, %f, %f]\n', i, tree(i).tail + [x_pos; y_pos; z_pos]);
            fprintf('Branch %d head position: [%f, %f, %f]\n', i, tree(i).head + [x_pos; y_pos; z_pos]);
        end
        fprintf('\n');
    end
end

xlabel('x [m]'); ylabel('y [m]')
zlabel('z [m]')
grid('on')
title('OOP fractal recursion tree')
axis('equal')



all_lengths = [trunk_lengths, primary_lengths, secondary_lengths];
%Create a histogram with three bins corresponding to the three categories
figure('color', 'white')
histogram(primary_lengths, 'BinWidth', 0.02, 'FaceColor', 'b')
hold on
histogram(secondary_lengths, 'BinWidth', 0.02, 'FaceColor', 'r')
hold on
histogram(no_use_lengths, 'BinWidth', 0.02, 'FaceColor', 'g')
hold on
legend('Primary Branches', 'Secondary Branches')
xlabel('Branch Length')
ylabel('Frequency')
title('Histogram of Branch Lengths, Categorized by Branch Type')

TPS_center_points = [trunk_centers, primary_centers, secondary_centers];

