% When l0 even

function [A,D]=integerDWT_hardware(X)
    [l0,DIM]=size(X);
    l1=floor(l0/2);
    l2=l1+1;
    l3=l1-1;
    A=zeros(l2,DIM);
    D=zeros(l2,DIM);
    for i=1:DIM
        D(1,i)=X(2,i)-floor((X(3,i)+X(1,i))/2);
        A(1,i)=X(1,i)+floor(D(1,i)/4+0.5);
        for j=2:l3
            D(j,i)=X(2*j,i)-floor((X(2*j+1,i)+X(2*j-1,i))/2);
            A(j,i)=X(2*j-1,i)+floor((D(j,i)+D(j-1,i))/4+0.5);
        end
        D(l1,i)=X(l0,i)-floor(X(l0-1,i)/2);
        A(l1,i)=X(l0-1,i)+floor((D(l1,i)+D(l3,i))/4+0.5);
        A(l2,i)=floor(D(l1,i)/4+0.5);
    end
end
