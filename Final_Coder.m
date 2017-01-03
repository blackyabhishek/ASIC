Image_height = 256;
Image_width = 256;
FRAME_INDEX=1:120;
[~,len]=size(FRAME_INDEX);
PSNR=zeros(len,1);
Percentage_compression=zeros(len,1);

for ic=1:len
   
    ic

    vid = imread(strcat('test_images\',num2str(FRAME_INDEX(ic)),'.jpg'));
    %vid = imresize(vid,[Image_height,Image_width],'nearest');
    % *************************** Forward RCT Transform*********************
    Y = zeros(Image_height,Image_width);
    U = zeros(Image_height,Image_width);
    V = zeros(Image_height,Image_width);
    for i=1:Image_height
        for j=1:Image_width
            Y(i,j) = int16(vid(i,j,1))+2*int16(vid(i,j,2)) + int16(vid(i,j,3));
            Y(i,j) = floor(double(Y(i,j))/4);
            U(i,j) = double(int16(vid(i,j,1))- int16(vid(i,j,2)));
            V(i,j) = double(int16(vid(i,j,2)) - int16(vid(i,j,3)));
        end
    end


    %******************* Lets quantise now******************************
     Q = 4;
     for i=1:Image_height
         for j=1:Image_width
             Y(i,j) = floor(((double(Y(i,j)))/(Q/2)))+1;
             U(i,j) = floor(((double(U(i,j)))/(Q/2)))+1;
             V(i,j) = floor(((double(V(i,j)))/(Q/2)))+1;
             
             if(Y(i,j)==512/Q)
                 Y(i,j)=256/Q-1; 
             else
                 Y(i,j)=floor(double(Y(i,j))/2);
             end
             
             if(U(i,j)==512/Q)
                 U(i,j)=256/Q-1; 
             else
                 U(i,j)=floor(double(U(i,j))/2);
             end
             
             if(V(i,j)==512/Q)
                 V(i,j)=256/Q-1; 
             else
                 V(i,j)=floor(double(V(i,j))/2);
             end
             


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

        A=integerIDWT_hardware(double(AA),double(AD));
        LINEAR_DECOMPRESSED_IMAGE=integerIDWT_hardware(double(A),double(D));
        
      
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
        
        Reconstructed_image(:,:,2) = Y_r - floor((U_r - V_r)/4);
        Reconstructed_image(:,:,1) = U_r + Reconstructed_image(:,:,2);
        Reconstructed_image(:,:,3) = Reconstructed_image(:,:,2) - V_r;

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
        error

end

