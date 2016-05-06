Image_height=256;
Image_width=256;

input_bits = csvread('OB_all.txt',175568,0);
vid=imread('11.jpg');

q = size(input_bits')
length = q(2);
A0 = 0;
N = 0;
k=0;
AY = 0;
AU = 0;
AV = 0;
NY = 0;
NV = 0;
NU = 0;
counter = 0;
Nmax = 7;
glimit = 16;
%limit k_max = 3;
i = 1;
parameter = 9;
output = zeros(100000,1);
output_index = 1;
YUV = 1;
counter2 = 0;
% parameter is the number of input bits to the encoder
% i is number of bits read
while (i<=length)
    if(counter2 ==0 || counter2==1 || counter2==2)
        A0 = AY;
        N = NY;
        YUV = 1;
        counter2 = counter2+1;
    else
        if(counter == 0 || counter== 1 || counter == 2 || counter==3)
            A0 = AY;
            N = NY;
            YUV = 1;
        elseif(counter == 4)
            A0 = AU;
            N = NU;
            YUV = 2;
        else
            A0 = AV;
            N = NV;
            YUV = 3;
        end
        counter = mod((counter + 1),6);
    end
    
    if(N ==0 || A0==0)
        k=0;
    else
        k = max(0,ceil(log2(double(A0)/(2*N))));
    end
    if(k > 3)
        k=3;
    end
    
    temp2 = i;
    while (input_bits(i) == 1 && i-temp2 < (glimit-parameter))
        i=i+1;
    end
    
    if((i-temp2)==(glimit-parameter))
        % generate output
        temp = 0;
        shift = 0;
        for j=(i):1:(i+parameter-1)
            temp = temp + input_bits(j)*(bitshift(1,shift));
            shift = shift+1;
        end
        output(output_index) = temp;
        output_index = output_index+1;
        i = i+parameter;
    else
        temp = i-temp2;
        remainder = 0;
        shift = 0;
        if(k >0)
            
            for j=i+1:1:i+k
                remainder = remainder + input_bits(j)*(bitshift(1,shift));
                shift= shift+1;
            end
        end
        temp = bitshift(temp,k) + remainder;
        output(output_index) = temp;
        %read k bits
        %generate output
        output_index = output_index+1;
        i = i+k+1;
    end
   % output(output_index-1)
   if(N==Nmax)
       A0 = bitshift(A0,-1);
     
       N = 3;
   else
       N = N+1;
       A0 = A0 + output(output_index-1);
   end
   if(YUV ==1)
       NY = N;
       AY = A0;
   elseif(YUV==2)
       NU = N;
       AU = A0;

   else
       NV = N;
       AV = A0;
   end
end  
%----- Demapping the output--------------%
Final_Output = zeros(output_index-1,1);
for l=1:output_index-1
    if(mod(output(l),2)==0)
        Final_Output(l) = output(l)/2;
    else
        Final_Output(l) = int16(output(l)/2);
        Final_Output(l) = -Final_Output(l);
    end
end

S1 = Final_Output;
Ydho=zeros(54136,1);
Udho=zeros(13534,1);
Vdho=zeros(13534,1);
cy=4;
cu=1;
cv=1;
for i=1:3
    if(S1(i)>255)
        S1(i)=S1(i)-512;
    end
    Ydho(i)=S1(i);
end
for i=4:81202
    j=mod(i-4,6);
    if(S1(i)>255)
        S1(i)=S1(i)-512;
    end
    if(j==0 || j==1 || j==2 || j==3)
        Ydho(cy)=S1(i);
        cy=cy+1;
    end
    if(j==4)
        Udho(cu)=S1(i);
        cu=cu+1;
    end
    if(j==5)
        Vdho(cv)=S1(i);
        cv=cv+1;
    end
end

Y=zeros(54136,1);
AA=zeros(13534,3);
Y(1,1)=Ydho(1);
AA(1,2)=Udho(1);
AA(1,3)=Vdho(1);

for i=2:54136
    Y(i)=Ydho(i)+Y(i-1);
end

for i=2:13534
    AA(i,2)=Udho(i)+AA(i-1,2);
    AA(i,3)=Vdho(i)+AA(i-1,3);
end

        Y_r = (zeros(Image_height,Image_width));
        U_r = (zeros(Image_height,Image_width));
        V_r = (zeros(Image_height,Image_width));
     %****** Dequantize  Y *******************
         c=1;
         Q=8;
         for i=1:Image_height
            for j=1:Image_width
                if((i+j>76) && (i+j<438) && (i-j>-181) && (i-j<181))
                    Y_r(i,j) = Q*Y(c,1);
                    c=c+1;
                end
            end
         end

          %******** Reconstruct U and V by interpolation**********
        AD=zeros(13534,3);
        D=zeros(27068,3);
        A=integerIDWT_hardware(AA,AD);
        LINEAR_DECOMPRESSED_IMAGE=integerIDWT_hardware(A,D);
        LINEAR_DECOMPRESSED_IMAGE=LINEAR_DECOMPRESSED_IMAGE(1:54136,:);
        c=1;
        for i=1:Image_height
            for j=1:Image_width
                if((i+j>76) && (i+j<438) && (i-j>-181) && (i-j<181))
                    U_r(i,j)=LINEAR_DECOMPRESSED_IMAGE(c,2);
                    V_r(i,j)=LINEAR_DECOMPRESSED_IMAGE(c,3);
                    c=c+1;
                end
            end
        end

        U_r=U_r*Q;
        V_r=V_r*Q;

        % ****************  Inverse RCT Transform ********************

        Reconstructed_image = zeros(Image_height,Image_width,3);
        Reconstructed_image(:,:,1) = (Y_r + V_r/4 + 3*U_r/4);
        Reconstructed_image(:,:,2) = (Y_r + V_r/4 - U_r/4);
        Reconstructed_image(:,:,3) = (Y_r - U_r/4 - 3*V_r/4);
        %imshow (vid);
        %figure;
        %imshow(uint8(Reconstructed_image));



        % ************** Check PSNR ******************************
        
        I1 = uint8(vid);
        I2 = uint8(Reconstructed_image);

        error = 0.0;
        for i = 1:3
            for j=1:Image_height
                 for k=1:Image_width                     
                     if((j+k>76) && (j+k<438) && (j-k>-181) && (j-k<181))
                        error = error + double(int16(I1(j,k,i)) - int16(I2(j,k,i)))*double(int16(I1(j,k,i))-int16(I2(j,k,i)));
                     end
                 end
             end
        end
        
        [l,b]=size(input_bits);
        Compression = (1-(l/(Image_height*Image_width*3*8)))*100
        PSNR = 10*log10(255*255*54136*3/double(error))


