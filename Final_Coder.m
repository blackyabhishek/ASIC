Image_height = 256;
Image_width = 256;
FRAME_INDEX=1:1;
[~,len]=size(FRAME_INDEX);
PSNR=zeros(len,1);
Percentage_compression=zeros(len,1);
RS=0;
GS=0;
BS=0;
YS=0;
US=0;
VS=0;
YS_8=0;
US_8=0;
VS_8=0;
M_YS_8=0;
M_US_8=0;
M_VS_8=0;
for ic=1:len
    ic
    %vid = imread('15s.bmp');
    II =imread(strcat('test_images/',num2str(FRAME_INDEX(ic)),'.jpg'));
    vid = imresize(II,[256,256],'lanczos3');
    % *************************** Forward RCT Transform*********************
    Y = zeros(Image_height,Image_width);
    U = zeros(Image_height,Image_width);
    V = zeros(Image_height,Image_width);
    for i=1:Image_height
        for j=1:Image_width
            Y(i,j) = int16(vid(i,j,1))+2*int16(vid(i,j,2)) + int16(vid(i,j,3));
            Y(i,j) = floor(double(Y(i,j)/4));
            U(i,j) = double(int16(vid(i,j,1))- int16(vid(i,j,2)));
            V(i,j) = double(int16(vid(i,j,2)) - int16(vid(i,j,3)));
        end
    end
    R=vid(1:Image_height,1:Image_width,1);
    t=R';
    RL=t(:);
    G=vid(1:Image_height,1:Image_width,2);
    t=G';
    GL=t(:);
    B=vid(1:Image_height,1:Image_width,3);
    t=B';
    BL=t(:);
    t=Y';
    YL=t(:);
    t=U';
    UL=t(:);
    t=V';
    VL=t(:);
    RS=RS+std(double(RL));
    GS=GS+std(double(GL));
    BS=BS+std(double(BL));
    YS=YS+std(double(YL));
    US=US+std(double(UL));
    VS=VS+std(double(VL));

    %******************* Lets quantise now******************************
     Q = 8;
     for i=1:Image_height
         for j=1:Image_width
             Y(i,j) = floor(((double(Y(i,j)))/(Q/2)))+1;
             U(i,j) = floor(((double(U(i,j)))/(Q/2)))+1;
             V(i,j) = floor(((double(V(i,j)))/(Q/2)))+1;
             
             if(Y(i,j)==64)
                 Y(i,j)=31; 
             else
                 Y(i,j)=floor(double(Y(i,j))/2);
             end
             
             if(U(i,j)==64)
                 U(i,j)=31; 
             else
                 U(i,j)=floor(double(U(i,j))/2);
             end
             
             if(V(i,j)==64)
                 V(i,j)=31; 
             else
                 V(i,j)=floor(double(V(i,j))/2);
             end
             

             
%              Y(i,j) = floor(Y(i,j)/Q);     
%              U(i,j) = floor(U(i,j)/Q);
%              V(i,j) = floor(V(i,j)/Q);
         end
     end
    %************************* Subsampling *************************8
    c=1;
    LINEAR_IMAGE=zeros(54136,3);
    for i=1:Image_height
        for j=1:Image_width
            if((i+j>76) && (i+j<438) && (i-j>-181) && (i-j<181))
                LINEAR_IMAGE(c,1)=Y(i,j);
                LINEAR_IMAGE(c,2)=U(i,j);
                LINEAR_IMAGE(c,3)=V(i,j);
                c=c+1;
            end
        end
    end
    [A,D]=integerDWT_hardware(LINEAR_IMAGE);
    [AA,AD]=integerDWT_hardware(A);
    
             YS_8=YS_8+std(LINEAR_IMAGE(:,1));
             US_8=US_8+std(LINEAR_IMAGE(:,2));
             VS_8=VS_8+std(LINEAR_IMAGE(:,3));
             M_YS_8=M_YS_8+mean(LINEAR_IMAGE(:,1));
             M_US_8=M_US_8+mean(abs(LINEAR_IMAGE(:,2)));
             M_VS_8=M_VS_8+mean(abs(LINEAR_IMAGE(:,3)));

    %******************* DPCM ********************************** 
    
    Diff_Y = LINEAR_IMAGE(:,1);
    Diff_U = AA(1:13534,2);
    Diff_V = AA(1:13534,3);

    for i=2:54136
        Diff_Y(i) = LINEAR_IMAGE(i,1) - LINEAR_IMAGE(i-1,1);
    end


    for i=2:13534
        Diff_U(i) = AA(i,2) - AA(i-1,2);
    end



    for i=2:13534
        Diff_V(i) = AA(i,3) - AA(i-1,3);
    end
    
    Diff_U(13534)=0;
    Diff_V(13534)=0; 
    
    D=D*0;
    AD=AD*0;
    
    % ******************** Static golomb Encoding ********************
    Total_bits=-2;
for YUV=1:3
    if(YUV==1)
        frame_diff = Diff_Y;
    elseif(YUV==2)
        frame_diff = Diff_U;
    else
        frame_diff = Diff_V;
    end
        
    [length,b] = size(frame_diff);
    current_index= 1;
    Output = zeros(1000000,1);
    CWL = zeros(100000,1);
    CW  = zeros(100000,1);
    indexing = 1;
    A0 = 0;
    N=0;
    Nmax = 7;
    glimit = 16;
    parameter = 9;
    % Number of bits of the input
    m_k = 0;
    max_m_k = 0;
    for i=1:length
        for j=1:b
            prev_index = current_index;
            if(N == 0 || A0 ==0)
                m_k = 0;
            else
                m_k = max(0,ceil(log2(double(A0)/(2*N))));
            end

            if(m_k>max_m_k)
                max_m_k = m_k;
            end
            if(m_k>3)
                m_k = 3;
            end
            if(frame_diff(i,j) >= 0)
                temp = 2*frame_diff(i,j);
            else
                temp = 2*abs(frame_diff(i,j)) - 1;
            end
            q  = bitshift(temp,m_k-2*m_k);
            % the condition below checks the glimit case
            temporary = 1;
            if(q > glimit - parameter-1)
                 for l=1:(glimit-parameter)
                      Output(current_index) = 1;
                      current_index = current_index+1;
                 end
                 for l=parameter:-1:1
                     a1 = bitget(temp,l:1:l);
                     Output(current_index) = a1;
                     current_index = current_index+1;
                 end
            else

                while (q>0)
                    Output(current_index) = 1;
                    q = q-1;
                    current_index= current_index+1;
                end
                Output(current_index) = 0;
                current_index = current_index+1;
                if(m_k > 0)
                    a1 = bitget(temp,1:1:m_k);
                    for l=m_k:-1:1
                    Output(current_index) = a1(l);
                    current_index = current_index+1;
                            % this portion is for ddoing the binary coding of the
                            % remainder
                    end
                end
            end
            new_index = current_index;
            CWL1 = new_index-prev_index;
            CWL(indexing) = CWL1;
            CW(indexing) = bi2de(Output(prev_index:new_index-1)','left-msb');
            indexing = indexing+1;
            %%% update parameters after encoding
            if(N == Nmax)
                A0 = bitshift(A0,-1);
                N = 3;
            else
                N = N +1;
                A0 = A0 + temp;
            end
        end
    end
    
    CWL_final = CWL(1:indexing-1);
    Total_bits=Total_bits+sum(CWL_final);
    
    CW_final = CW(1:indexing-1);
end
    Percentage_compression(ic,1) =100- (Total_bits*100/(Image_height*Image_width*3*8))
    Total_bits

    % ******************* Reconstructing the image***************

     % Since DPCM and Golomb encoding are Lossless steps we decode from the
     % subsampled step
        Y_r = (zeros(Image_height,Image_width));
        U_r = (zeros(Image_height,Image_width));
        V_r = (zeros(Image_height,Image_width));
     %****** Dequantize  Y *******************
         %Y = Q*Y;
         %Y_r = double(Y);
         for i=1:Image_height
            for j=1:Image_width
                if((i+j>76) && (i+j<438) && (i-j>-181) && (i-j<181))
                    Y_r(i,j) = Q*Y(i,j);
                end
            end
         end

          %******** Reconstruct U and V by interpolation**********

%         A=integerIDWT_hardware(AA,AD);
%         LINEAR_DECOMPRESSED_IMAGE=integerIDWT_hardware(A,D);
        
        x=1:4:54136;
        xx=1:1:54136;
        yy = spline(x,AA(1:13534,1),xx);
        LINEAR_DECOMPRESSED_IMAGE(:,1)=yy';
        
        yy = spline(x,AA(1:13534,2),xx);
        LINEAR_DECOMPRESSED_IMAGE(:,2)=yy';
        
        yy = spline(x,AA(1:13534,3),xx);
        LINEAR_DECOMPRESSED_IMAGE(:,3)=yy';
        
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
        PSNR(ic,1) = 10*log10(255*255*54136*3/double(error))
end

% csvwrite('PSNR_NEW.csv',PSNR,0,0);
% csvwrite('COMPRESSION_NEW.csv',Percentage_compression,0,0);
% 
RS=RS/len;
GS=GS/len;
BS=BS/len;
YS=YS/len;
US=US/len;
VS=VS/len;
YS_8=YS_8/len;
US_8=US_8/len;
VS_8=VS_8/len;
M_YS_8=M_YS_8/len;
M_US_8=M_US_8/len;
M_VS_8=M_VS_8/len;

C_RG=corr(double(RL),double(GL));
C_GB=corr(double(GL),double(BL));
C_BR=corr(double(BL),double(RL));

C_YU=corr(double(YL),double(UL));
C_UV=corr(double(UL),double(VL));
C_VY=corr(double(VL),double(YL));

M_R=mean(RL);
M_G=mean(GL);
M_B=mean(BL);

M_Y=mean(abs(YL));
M_U=mean(abs(UL));
M_V=mean(abs(VL));


% pdf_Y=1:17;
% pdf_Y=pdf_Y*0;
% for i=1:54136
%     if(Diff_Y(i)>=0)
%         temp=2*Diff_Y(i);
%     elseif(Diff_Y(i)<0)
%         temp=2*abs(Diff_Y(i))-1;
%     end
%     if(temp>7)
%         pdf_Y(17)=pdf_Y(17)+1;
%     else
%         pdf_Y(temp+2)=pdf_Y(temp+2)+1;
%     end
% end
% pdf_Y=pdf_Y/54136;
%         
% x=-256:255;
% x(253+256:256+256)=x(252+256);
% y=floor((floor(double(x)/4) + 1)/2);

% 
%     %Comparing RGB along a row
%     ind=1:256;
%     figure;
%     plot(ind,R(128,1:256),'r',ind,G(128,1:256),'g',ind,B(128,1:256),'b')
%     title('RGB values along a row')
%     xlabel('Column')
%     ylabel('RGB Value')
%     legend('Red','Green','Blue')
% 
%     %Comparing YUV along a row
%     figure;
%     plot(ind,YL(32513:32768),'r',ind,UL(32513:32768),'g',ind,VL(32513:32768),'b')
%     title('YUV values along a row')
%     xlabel('Column')
%     ylabel('YUV Value')
%     legend('Y','U','V')
% 
%     %Quantized YUV along a row
%     figure;
%     plot(ind,Y(128,1:256),'r',ind,U(128,1:256),'g',ind,V(128,1:256),'b')
%     title('Quantized YUV values along a row')
%     xlabel('Column')
%     ylabel('Quantized YUV Value')
%     legend('Y/8','U/8','V/8')
% 
%     %Histogram R
%     figure;
%     histogram(RL)
%     title('Histogram of R')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram G
%     figure;
%     histogram(GL)
%     title('Histogram of G')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram B
%     figure;
%     histogram(BL)
%     title('Histogram of B')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram Y
%     figure;
%     histogram(YL)
%     title('Histogram of Y')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram U
%     figure;
%     histogram(UL)
%     title('Histogram of U')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram V
%     figure;
%     histogram(VL)
%     title('Histogram of V')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram Y/8
%     figure;
%     histogram(Y(:))
%     title('Histogram of Y/8')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram U/8
%     figure;
%     histogram(U(:))
%     title('Histogram of U/8')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram V/8
%     figure;
%     histogram(V(:))
%     title('Histogram of V/8')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
% 
%     [A,D]=integerDWT_hardware(LINEAR_IMAGE);
%     [AA,AD]=integerDWT_hardware(A);
% 
%     %DWT level 1 of U
%     figure;
%     subplot(2,2,1);
%     histogram(A(:,2))
%     title('Histogram of level 1 DWT of lower frequency component of U/8')
%     xlabel('Value')
%     ylabel('Frequrency')
%     axis([-14 14 -inf inf]);
% 
%     subplot(2,2,2);
%     histogram(D(:,2))
%     title('Histogram of level 1 DWT of higher frequency component of U/8')
%     xlabel('Value')
%     ylabel('Frequrency')
%     axis([-14 14 -inf inf]);
% 
%     %DWT level 1 of V
%     subplot(2,2,3);
%     histogram(A(:,3))
%     title('Histogram of level 1 DWT of lower frequency component of V/8')
%     xlabel('Value')
%     ylabel('Frequrency')
%     axis([-14 14 -inf inf]);
% 
%     subplot(2,2,4);
%     histogram(D(:,3))
%     title('Histogram of level 1 DWT of higher frequency component of V/8')
%     xlabel('Value')
%     ylabel('Frequrency')
%     axis([-14 14 -inf inf]);
% 
%     %DWT level 2 of U
%     figure;
%     subplot(2,2,1);
%     histogram(AA(:,2))
%     title('Histogram of level 2 DWT of lower frequency component of U/8')
%     xlabel('Value')
%     ylabel('Frequrency')
%     axis([-14 14 -inf inf]);
% 
%     subplot(2,2,2);
%     histogram(AD(:,2))
%     title('Histogram of level 2 DWT of higher frequency component of U/8')
%     xlabel('Value')
%     ylabel('Frequrency')
%     axis([-14 14 -inf inf]);
% 
%     %DWT level 2 of V
%     subplot(2,2,3);
%     histogram(AA(:,3))
%     title('Histogram of level 2 DWT of lower frequency component of V/8')
%     xlabel('Value')
%     ylabel('Frequrency')
%     axis([-14 14 -inf inf]);
% 
%     subplot(2,2,4);
%     histogram(AD(:,3))
%     title('Histogram of level 2 DWT of higher frequency component of V/8')
%     xlabel('Value')
%     ylabel('Frequrency')
%     axis([-14 14 -inf inf]);
% 
%     %Histogram of DPCM of Y/8
%     figure;
%     subplot(1,3,1);
%     histogram(Diff_Y);
%     title('Histogram of DPCM of Y/8')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram of DPCM of U/8 after DWT
%     subplot(1,3,2);
%     histogram(Diff_U);
%     title('Histogram of DPCM of U/8 after DWT')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram of DPCM of V/8 after DWT
%     subplot(1,3,3);
%     histogram(Diff_V);
%     title('Histogram of DPCM of V/8 after DWT')
%     xlabel('Value')
%     ylabel('Frequrency')
%     
%     %Histogram of DPCM of R
%     figure;
%     subplot(1,3,1);
%     histogram(int16(RL(2:65536,1))-int16(RL(1:65535,1)))
%     title('Histogram of DPCM of R')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram of DPCM of G
%     subplot(1,3,2);
%     histogram(int16(GL(2:65536,1))-int16(GL(1:65535,1)))
%     title('Histogram of DPCM of G')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram of DPCM of B
%     subplot(1,3,3);
%     histogram(int16(BL(2:65536,1))-int16(BL(1:65535,1)))
%     title('Histogram of DPCM of B')
%     xlabel('Value')
%     ylabel('Frequrency')
%     
%     %Histogram of DPCM of Y
%     figure;
%     subplot(1,3,1);
%     histogram(YL(2:65536,1)-YL(1:65535,1))
%     title('Histogram of DPCM of Y')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram  of DPCM of U
%     subplot(1,3,2);
%     histogram(UL(2:65536,1)-UL(1:65535,1))
%     title('Histogram of DPCM of U')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram  of DPCM of V
%     subplot(1,3,3);
%     histogram(VL(2:65536,1)-VL(1:65535,1))
%     title('Histogram of DPCM of V')
%     xlabel('Value')
%     ylabel('Frequrency')
%     
%     %Histogram of DPCM of Y/8
%     figure;
%     subplot(1,3,1);
%     histogram(LINEAR_IMAGE(2:54136,1)-LINEAR_IMAGE(1:54135,1))
%     title('Histogram of DPCM of Y/8')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram of DPCM of U/8
%     subplot(1,3,2);
%     histogram(LINEAR_IMAGE(2:54136,2)-LINEAR_IMAGE(1:54135,2))
%     title('Histogram of DPCM of U/8')
%     xlabel('Value')
%     ylabel('Frequrency')
% 
%     %Histogram of DPCM of V/8
%     subplot(1,3,3);
%     histogram(LINEAR_IMAGE(2:54136,3)-LINEAR_IMAGE(1:54135,3))
%     title('Histogram of DPCM of V/8')
%     xlabel('Value')
%     ylabel('Frequrency')



