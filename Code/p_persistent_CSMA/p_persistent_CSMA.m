clc;clear all;close all;

%% P-Persistent CSMA Simulation
% Author: An-Che Teng
% Time: 2015/10/21

% N: Number of stations
% L: Fixed fram size
% TOTAL_SLOT_NUMBER: Total slots we used (Simulation Time)
% Random Backoff: [0, RANDOM_WAITING_TIME-1]
% SAMPLE_POINTS_NUM: Number of sample points of q
% G: Attempts per frame time
% Suc: Throughput per frame time
% p : p of p-persistent

N=10;
L=10;
TOTAL_SLOT_NUMBER= 10000;
RANDOM_WAITING_TIME = 16;
SAMPLE_POINTS_NUM = 10;
G = zeros(SAMPLE_POINTS_NUM,1);
Suc = zeros(SAMPLE_POINTS_NUM,1);
p = 0.5;

% You need to try a small value q here and then increase it gradually
q = linspace(0.00003, 0.004, SAMPLE_POINTS_NUM);
% q = q(length(q));
% Ave_Iteration: Average for experiment
Ave_Iteration = 1;


%% Simulation Main
for iteration = 1:1:SAMPLE_POINTS_NUM
  for repeat = 1:1:Ave_Iteration

    % System log
    record_buffer = zeros(N, TOTAL_SLOT_NUMBER);
    record_state = zeros(N, TOTAL_SLOT_NUMBER);
    record_block = zeros(N,TOTAL_SLOT_NUMBER);
    record_wait = zeros(N,TOTAL_SLOT_NUMBER);
    record_suc = zeros(1,TOTAL_SLOT_NUMBER);
    record_channel = zeros(1,TOTAL_SLOT_NUMBER);
    record_collision = zeros(1, TOTAL_SLOT_NUMBER);

    success = 0;
    attempts = 0;
    generated = 0;

    %% System Parameter

    % An array to store for the number of remaining frames in a station j (j=1 to N);
    buffered_number =zeros(N,1);

    % An array to store for the number of remaining slots a sending station j (j=1 to N) has to transmitt until the end of its transmission;
    blocked_time=zeros(N,1);

    % An array to store for the number of remaining slots a sending station j (j=1 to N) has to wait until the wait is over;
    wait_time=zeros(N,1) ;

    % An array to store the state of station j (j=1 to N)  0 : idle (no data), 1: transmission, 2: collision, 3: wait
    state = zeros(N,1);

    %% Time Driven Simulation
    t=0;
    channel_occupied = 0;
    while (t<TOTAL_SLOT_NUMBER)
        t = t + 1;
        % ==========================Logging System State by time==========================
        record_channel(1,t) = channel_occupied;
        % ==========================Logging System State by time==========================

    % new data frame arrival for each station
        for id=1:1:N
          % Bernoulli Arrival for every time slot
          is_arrival = rand;
          if is_arrival < q(iteration)
            buffered_number(id) = buffered_number(id) + 1;
            generated = generated + 1;
          end
          %% Poisson Arrival for every time slot
          % is_arrival = rand;
          % while is_arrival>=exp(-1*q(iteration))
          %   % record the number of data frames in the queue
          %   buffered_number(id) = buffered_number(id) + 1;
          %   generated = generated + 1;
          %   is_arrival = rand*is_arrival;
          % end
        end

    % below is how you implement the protocol using the state variables "blocked_time", "wait_time" and "state"
        % Renew the station state
        for id=1:1:N
          switch(state(id))
            % ------------------Case 0: the station is idle------------------
            case 0
              % New frame arrival
              if buffered_number(id) > 0
                state(id) = 3;
                % Sense the channel, idle: prepare to transmitt; busy: waiting
                if channel_occupied == 0
                  % Prepared to transmitt
                  blocked_time(id) = L;
                end
              end
            % ------------------Case 1: the station is transmitting------------------
            case 1
              if blocked_time(id) > 0
                blocked_time(id) = blocked_time(id) - 1;
              elseif blocked_time(id) == 0
                buffered_number(id) = buffered_number(id) - 1;
                success = success + 1;
                % change to state-0 or transmitt next frame
                if buffered_number(id) == 0
                  state(id) = 0;
                else
                  state(id) = 3;
                  if channel_occupied == 0
                    % Prepared to transmitt
                    blocked_time(id) = L;
                  end
                end
              end
            % ------------------Case 2: frames are colliding------------------
            case 2
              if blocked_time(id) > 0
                blocked_time(id) = blocked_time(id) - 1;
              elseif blocked_time(id) == 0
                wait_time(id) = (unidrnd(RANDOM_WAITING_TIME)-2);
                state(id) = 3;
                % Sense the channel first.
                if wait_time(id) == -1
                  if channel_occupied == 0
                    wait_time(id) = 0;
                    blocked_time(id) = L;
                  end
                end
              end
            % ------------------Case 3: the station is waiting for a random time------------------
            case 3
              if wait_time(id) > 0
                wait_time(id) = wait_time(id) - 1;
              elseif wait_time(id) == 0
                if channel_occupied == 1
                  % Channel is busy, keep waiting
                  blocked_time(id) = 0;
                elseif channel_occupied == 0 && blocked_time(id) ~= L
                  % Prepared to transmitt
                  blocked_time(id) = L;
                elseif blocked_time(id) == L && rand<p
                  % Transmitt the frame
                  state(id) = 1;
                  blocked_time(id) = L-1;
                  attempts = attempts + 1;
                end
              end
          end
        end

    % Check for channel state
        channel_state = 0;
        % About channel_state: Cumulate only state-1 or state-2
        %  1. all state are 0 or 3--------------------> channel_state = 0
        %  2. only one state-1------------------------> channel_state = 1
        %  3. state-1 with other state-1/state-2------> channel_state > 1
        is_collision = 0;
        channel_occupied = 0;

        for id=1:1:N
          if (state(id) == 1 || state(id) == 2)
            channel_state = channel_state + 1;
          end
        end

        % channel_state = 0: all state are 0 or 3, is_collision & channel_occupied remain 0
        % channel_state = 1: only one state-1, is_collision = 0 & channel_occupied = 1
        if channel_state == 1
          channel_occupied = 1;
          for id=1:N
            if state(id) == 3 && blocked_time(id) == L
                blocked_time(id) = 0;
            end
          end
        % channel_state > 1: state-1 with other state-1/state-2, collision occur
        elseif channel_state >=2
          is_collision = 1;
          channel_occupied = 1;
          for id=1:N
            % set the colliding state to state-2
            if state(id) == 1
                state(id) = 2;
            % sensing at the end of slot
            elseif state(id) == 3 && blocked_time(id) == L
                blocked_time(id) = 0;
            end
          end
        end

        % Renew channel state for the next slot
        for id=1:1:N
          if ( (state(id)==1 || state(id)==2) && blocked_time(id) ==0 )
            channel_occupied = 0;
          end
        end

    % ==========================Logging System State by time==========================
        for id=1:1:N
            record_state(id,t) = state(id);
            record_block(id,t)=blocked_time(id);
            record_wait(id,t) = wait_time(id);
            record_buffer(id,t)=buffered_number(id);
        end
        record_suc(1,t)=success;
        record_collision(1,t) = is_collision;
    % ==========================Logging System State by time==========================


    end

    % Cumulate every "repeat" result
    G(iteration) = G(iteration) + attempts / (TOTAL_SLOT_NUMBER/L);
    Suc(iteration) = Suc(iteration) + success / (TOTAL_SLOT_NUMBER/L);

  end

  % Averaging the cumulation
  G(iteration) = G(iteration) / Ave_Iteration;
  Suc(iteration) = Suc(iteration) / Ave_Iteration;

  % Display the simulation progress
  disp(['Simulation Progress: '  num2str(100/SAMPLE_POINTS_NUM*iteration)  '%'])

end

disp(['================================================================'])
disp(['Simulation Complete.'])

%% plot the throughput
plot(G,Suc);
title('System Throughput versus Traffic');
xlabel('G (attempts per frame time)');
ylabel('S (throughput per frame time)');
grid on

% N_arrival = generated / (TOTAL_SLOT_NUMBER/L )
G
Suc

%% Plot the System State, including Total-System-Buffer, Channel-Usage, Collision, ...etc.
figure

subplot(3,2,1)
plot(record_suc)
title('Successful Transmitt');
xlabel('Time (slot)');
ylabel('Number of frames');

subplot(3,2,2)
plot(sum(record_buffer))
title('Total System Buffer');
xlabel('Time (slot)');
ylabel('Number of frames');

subplot(3,2,3)
plot(sum(record_wait))
title('Total Station Waiting time (per slot)');
xlabel('Time (slot)');
ylabel('Slot');

subplot(3,2,4)
plot(record_collision)
title('Record Collision');
xlabel('Time (slot)');
ylabel('Is Collision');

subplot(3,2,5)
plot(sum(record_state))
title('Record State (sum of all station)');
xlabel('Time (slot)');
ylabel('Sum of State');

subplot(3,2,6)
plot(record_channel)
title('Record Channel State');
xlabel('Time (slot)');
ylabel('Is Busy');

% System Snapshot, checking for system state at specific time
checking_point = 1;
disp('============================System Snapshot============================');
disp('record_buffer');
record_buffer(:, checking_point:checking_point+35)
disp('record_block');
record_block(:, checking_point:checking_point+35)
disp('record_wait');
record_wait(:, checking_point:checking_point+35)
disp('record_state');
record_state(:, checking_point:checking_point+35)
disp('record_suc');
record_suc(:, checking_point:checking_point+35)
disp('record_channel');
record_channel(:, checking_point:checking_point+35)
disp('record_collision');
record_collision(:, checking_point:checking_point+35)
