function sObjC = copyClassObj(sObj)

cStream = getByteStreamFromArray(sObj);
sObjC = getArrayFromByteStream(cStream);