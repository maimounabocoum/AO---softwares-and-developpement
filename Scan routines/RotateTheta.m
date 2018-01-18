function [Iout,Mcorner] = RotateTheta(X,Z,Iin,theta)
% created by maimouna bocoum 
% 25/10/2017

X = X - mean(X(:));
Z = Z - mean(Z(:));

% matrix of rotation

M = [cos(theta), sin(theta) ; -sin(theta), cos(theta)];

MM = M*[X(:)';Z(:)'] ;
Mcorner =  M*[ min(X(:))- mean(X(:)) ; min(Z(:))- mean(Z(:)) ] ;
Xout = MM(1,:);
Zout = MM(2,:);

% reshape variable into original size
Xout = reshape(Xout,[size(X,1),size(X,2)]);
Zout = reshape(Zout,[size(X,1),size(X,2)]);

Iout = interp2(X,Z,Iin,Xout,Zout,'linear',0) ;

end
