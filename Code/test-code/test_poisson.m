clc;clear all; close all;
N = 100000;
P = 1;
lambda = 0.01;

count = 0;
arrival = zeros(N,1);
for i = 1:N
    UP = rand*P;
	
	while UP>=exp(-1*lambda)
		P = UP;
		count = count+1;
        arrival(i) = arrival(i)+1;
		UP = rand*P;
    end
    
	P=1;    
end

count/N