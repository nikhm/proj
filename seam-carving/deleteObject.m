function [ out ] = deleteObject( img )
% DELETEOBJECT 
% img may either be in RGB colorspace or grayscale
% Give an image and specify boundary.

    cImg = img;
    if size(img,3) > 0
        img = rgb2gray(img);
    end

% User is involved here.
    figure, imshow(img);
    disp('Select region you want to remove.');
    h = imfreehand;
    f = double(createMask(h));
    px = regionprops(f,'Extrema'); 
    px = px.Extrema;
    
    fd = zeros(size(f));
    % Ask if user wants to protect some region.
    decision = input('Do you want to protect any part of the image? (1/0)\n');
    if decision == 1
        h = imfreehand;
        fd = double(createMask(h));
    end
    
    %choose direction to seam-carve
    top = min(px(1,1),px(2,1)); bottom = max(px(5,1),px(6,1));
    ver = bottom - top;
    left = min(px(7,2),px(8,2)); right = max(px(3,2),px(4,2));
    hor = right - left;
    %edit 
    hor_width=max(sum(f'));
    ver_width=max(sum(f));
    
    %end of edit
    dir = 0;
    num = hor; % This isn't used.
    if ver_width<hor_width
        dir = 1;
        num = ver;
    end
    if dir == 1
        img = img';
        cImg = permute(cImg,[2 1 3]);
        f = f'; fd = fd';
    end
    fX = [1 0 -1]; fY = [1;0;-1];
    
    if sum(sum(f.*fd)) ~= 0
        disp('Protected area and deletion area share common area!\n');
        out = -1;
        return;
    end
    
    while sum(sum(f))
        [r,c] = size(img);
        Gx = conv2(double(img),fX,'same'); Gy = conv2(double(img),fY,'same');
        
        G = abs(Gx) + abs(Gy);
        flag = true;
%         if flag 
%             max(max(G))
%             flag = false;
%         end
        mask = f;
        mask2 = fd;
        G = G + (mask*(-10000)) + (mask2*(10000));
        % figure;
        % subplot(2,1,1); imshow(img,[]);
        % subplot(2,1,2); imshow(G,[]);
        
        % Find energy functions
        e = G;
        for i = 2:r
            for j = 1:c
                if ( j>=2 && j<=c-1 )
                    e(i,j) = e(i,j) + min([e(i-1,j),e(i-1,j-1),e(i-1,j+1)]);
                elseif( j<2 )
                    e(i,j) = e(i,j) + min([e(i-1,j),e(i-1,j+1)]);
                else
                    e(i,j) = e(i,j) + min([e(i-1,j),e(i-1,j-1)]);
                end
            end
        end
        % figure, imshow(e,[]);
        
        ind = 1; curMin = 100000;
        for i = 1:c
            if curMin > e(r,i)
                curMin = e(r,i);
                ind = i;
            end
        end
        
        path = zeros(r,1); path(r,1) = ind;
        % With the index found, backtrack to go back and find path
        for i = r-1:-1:1
            tmpInd = -1; curMin = 100000000;
            if (ind >= 2 && ind < c)
                if curMin > e(i,ind-1)
                    curMin = e(i,ind-1);
                    tmpInd = ind-1;
                end
                if curMin > e(i,ind)
                    curMin = e(i,ind);
                    tmpInd = ind;
                end
                if curMin > e(i,ind+1)
                    curMin = e(i,ind+1);
                    tmpInd = ind+1;
                end
            elseif (ind == 1)
                if curMin > e(i,ind)
                    curMin = e(i,ind);
                    tmpInd = ind;
                end
                if curMin > e(i,ind+1)
                    curMin = e(i,ind+1);
                    tmpInd = ind+1;
                end
            else
                if curMin > e(i,ind-1)
                    curMin = e(i,ind-1);
                    tmpInd = ind-1;
                end
                if curMin > e(i,ind)
                    curMin = e(i,ind);
                    tmpInd = ind;
                end
            end
            ind = tmpInd; path(i,1) = ind; img(i,ind) = 255;
        end
        figure; subplot(2,1,1); imshow(img,[]);subplot(2,1,2); imshow(f,[]);
        
        % With path found, for each row move columns to left
        for i = 1:r
            index = path(i,1);
            img(i,index:c-1) = img(i,index+1:c);
            cImg(i,index:c-1,:) = cImg(i,index+1:c,:);
            f(i,index:c-1) = f(i,index+1:c); fd(i,index:c-1) = fd(i,index+1:c);
        end
        img = img(:,1:c-1); f = f(:,1:c-1); fd = fd(:,1:c-1);
        cImg = cImg(:,1:c-1,:);
    end
    
    
    if dir == 1
        out = permute(cImg,[2 1 3]);
    else
        out = cImg;
    end   
end

