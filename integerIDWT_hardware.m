function X=integerIDWT_hardware(A,D)
    [LENGTH,DIM]=size(D);
    %D=int16(D);
    %A=int16(A);
    LENGTH=2*LENGTH;
    X=zeros(LENGTH,DIM);
    for i=1:DIM
        X(1,i)=A(1,i)-floor(D(1,i)/4+0.5);
        for j=3:2:LENGTH
            X(j,i)=A((j+1)/2,i)-floor((D((j+1)/2,i)+D((j-1)/2,i)+2)/4);
        end
        for j=2:2:LENGTH-1
            X(j,i)=D(j/2,i)+floor((X(j-1,i)+X(j+1,i))/2);
        end
        X(LENGTH,i)=D(LENGTH/2,i)+floor(X(LENGTH-1,i)/2);
    end
end