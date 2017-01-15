function Ispot = getSpots(I, xCoord, yCoord, L)
% Ispot = getSpot(I,xCoord,yCoord)

[Ly Lx] = size(I);
xCoord = round(xCoord);
yCoord = round(yCoord);

goodIndx = xCoord-L >= 1 & xCoord+L <= Lx & yCoord-L >= 1 & yCoord+L <= Ly;
xCoord = xCoord(goodIndx);              % get coords that don't fall off
yCoord = yCoord(goodIndx);
%%
for i=1:length(xCoord)
   
    Ispot = I((yCoord(i)-L):(yCoord(i)+L), (xCoord(i)-L):(xCoord(i)+L));
    
%     [X Y] = meshgrid((yCoord(i)-L):(yCoord(i)+L), (xCoord(i)-L):(xCoord(i)+L));
%     
%     g = gmdistribution.fit([X(:) Y(:) Ispot(:)], 1);
%     p = pdf(g,[X(:) Y(:) Ispot(:)]);
%     p = lin2mat(p,size(X));             % Convert from linear to subscripted
    
    figure,surf(X, Y, Ispot)
end
