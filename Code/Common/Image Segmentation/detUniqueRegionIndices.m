% --- determines the unique blob map indices surrounding the blob
%     (to a distance of dTolT) from a blob with linear indices, iG
function indU = detUniqueRegionIndices(iG,Imap,dTolT)

% sets the default input arguments
if ~exist('dTolT','var'); dTolT = 0; end

% initialisations
sz = size(Imap);

% retrieves the sub-images surrounding the blobs
[ImapL,~,pOfs] = getBlobSubImage(iG,Imap,[],sz,dTolT);
iGL = glob2loc(iG,pOfs,sz,size(ImapL));

% determines the 
BD = bwdist(setGroup(iGL,size(ImapL))) < dTolT;
ImapBL = ImapL(BD);
indU = unique(nonzeros(ImapBL(~isnan(ImapBL))));
