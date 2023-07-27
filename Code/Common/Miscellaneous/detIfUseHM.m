function useHM = detIfUseHM(iData)

% initialisations
useHM = false;

% retrieves the flag value (if available)
if isfield(iData,'useHM')
    useHM = iData.useHM;
end