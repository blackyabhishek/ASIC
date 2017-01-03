Frame = imread('15s.bmp');
fileID = fopen('testbench.txt','w');
Image_Height=256;
Image_Width=256;
S='';
%S=['initial',char(10),'begin',char(10),'    CLK=1''b0;',char(10),'    RESET=1''b1;',char(10),'    #7488 RESET=1''b0;',char(10)];
%fprintf(fileID,S);
for i=1:Image_Height
    for j=1:Image_Width
        for k=1:3
            S=['    #2496 RGB=8''d',num2str(Frame(i,j,k)),';',char(10)];
            fprintf(fileID,S);
        end
    end
end
%S=['end',char(10),char(10),'always',char(10),'begin',char(10),'    #1248 CLK=~CLK;',char(10),'end',char(10)];
%fprintf(fileID,S);
