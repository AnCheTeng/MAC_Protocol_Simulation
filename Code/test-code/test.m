clc;clear all;close all;
N = 10;

state = [0 3 0 3 3 0 1 0 3 0];

% Check for collision
  channel_occupied = 0;
  is_collided = 0;
  for id=1:1:N
    if((state(id)==1 | state(id)==2) & channel_occupied ==0)
      channel_occupied = 1;
    elseif ((state(id)==1 | state(id)==2) & channel_occupied ==1)
      is_collided = 1;
      break;
    end
  end

% Collision handling
  if(is_collided==1)
    for id=1:1:N
      if(state(id)==1)
        state(id)=2;
      end
    end
  end

state