function writemda16i(X,fname,append)
if nargin<3,
	append = 0;
end;
writemda(X,fname,'int16',append);
end
