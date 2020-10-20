function MultiObjectTracking( file )
    video = VideoReader('traffic.mj2')
    value = 60;detect = false;frame = 1;whiteCarCounter = 0;blackCarCounter = 0;
    seDisk = strel('disk', 2);
    noOfFrames = get(video, 'NumberOfFrames')
    I = read(video, 1);
    I = imresize(I, frame);
    trackedFrames = zeros([size(I,1) size(I,2) 3 noOfFrames], class(I));
    Area1 = [1, 1; 1, size(I,2)*1/5; size(I,1)/2, 1];
    Area2 = [1, size(I,2)*4/5; 1, size(I,2); size(I,1)/2, size(I,2)];
    for f = 1 : noOfFrames
        I = imresize(read(video, f), frame);
        background = imresize(read(video, 120), frame);
        iGray = rgb2gray(I);
        backgroundGray = rgb2gray(background);
        sub = abs(double(iGray) - double(backgroundGray));
        Threshold = sub > 100;
        firstFilter = imclose(Threshold, seDisk);
        firstFilterOpen = bwareaopen(firstFilter, value);
        seDisk2 = strel('disk', 9);
        secondFilter = imclose(firstFilterOpen, seDisk2);
        secondFilterOpen = bwareaopen(secondFilter, 100);
        L = bwlabel(secondFilterOpen);
        trackedFrames(:,:,:,f) = I;
        if any(L(:))
           stats = regionprops(L, iGray, {'centroid','area','BoundingBox','MeanIntensity'});
           areaArray = [stats.Area];
           for idx=1 : length(areaArray)
               center = stats(idx).Centroid;
               center = floor(fliplr(center));
                if ~boundryArea(center, Area1) && ~boundryArea(center, Area2) 
                    boundary = stats(idx).BoundingBox;
                    upperBoundary = ceil(boundary(2));
                    height = boundary(4);
                    lowerBoundary = upperBoundary + height - 1;
                    startColumn = ceil(boundary(1));
                    width = boundary(3);
                    zone = size(I, 1)*2/3;
                   if detect; zone_width = 16; else zone_width = 12; end                   
                   object_front = lowerBoundary; 
                   if object_front >= zone && object_front <= zone + zone_width
                       meanIntensity = stats(idx).MeanIntensity;
                        if meanIntensity > 80; isWhiteColor = true; else; isWhiteColor = false; end
                            if isWhiteColor
                                whiteCarCounter = whiteCarCounter + 1;
                                annotation = ['White Car ', num2str(whiteCarCounter)];
                               else
                                blackCarCounter = blackCarCounter + 1;
                                annotation = ['Dark Car ', num2str(blackCarCounter)];
                               end
                        
                        trackedFrames(:,:,:,f) = insertObjectAnnotation(trackedFrames(:,:,:,f), 'rectangle', boundary, annotation);
                     end
                end
            end
        end
    end
 
 
    frameRate = get(video,'FrameRate');
    implay(trackedFrames,frameRate);
    disp(['Total Number of cars ' num2str(whiteCarCounter + blackCarCounter )]);
    disp(['White Cars ' num2str(whiteCarCounter)]);
    disp(['Dark Cars ' num2str(blackCarCounter)]);
    
 
end

















function [ isInside ] = boundryArea( P, Area)
 
    P1 = Area(1,:);
    P2 = Area(2,:);
    P3 = Area(3,:);
 
    s = det([P1-P2;P3-P1]);
    isInside = s*det([P3-P;P2-P3])>=0 & s*det([P1-P;P3-P1])>=0 & s*det([P2-P;P1-P2])>=0;
    
end
