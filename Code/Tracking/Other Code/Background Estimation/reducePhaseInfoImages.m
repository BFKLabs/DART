function iMov = reducePhaseInfoImages(iMov,iApp)

% reduces down the filter/reference images
iMov.phInfo.hmFilt{iApp} = setupHMFilter(iMov.iR{iApp},iMov.iC{iApp});