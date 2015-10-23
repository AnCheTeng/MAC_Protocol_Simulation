clc;clear all; close all;
N = 10000;
lambda = 0.5;

for i = 1:N
 	  a = unidrnd(M);
%     a = ceil(M*rand)
    acc(a) = acc(a) + 1;
end

sum(acc)

