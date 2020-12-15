% --- converts the quantity Q (in units of S1) to that of given in S2
function Qc = convertTime(Q,S1,S2)

% calculates the quantity so it is in terms of seconds
switch lower(S1)
    case {'day','days','d'} % case is days
        Y = Q*60*60*24;
    case {'hour','hours','hrs','h'} % case is hours
        Y = Q*60*60;
    case {'minute','minutes','min','mins','m'} % case is minutes
        Y = Q*60;
    case {'second','seconds','sec','secs','s'} % case is for seconds
        Y = Q;
    otherwise % otherwise, output an error        
        Qc = NaN;
        eStr = 'Error! Incorrect time quantity specified.';
        waitfor(errordlg(eStr,'Invalid Time Quantity','modal'))
        return
end

% converts the time in seconds to the second quantity
switch lower(S2)
    case {'day','days','d'} % case is days
        Qc = Y/(60*60*24);
    case {'hour','hours','hrs','h'} % case is hours
        Qc = Y/(60*60);
    case {'minute','minutes','min','mins','m'} % case is minutes
        Qc = Y/60;
    case {'second','seconds','sec','secs','s'} % case is for seconds
        Qc = Y;
    otherwise % otherwise, output an error        
        Qc = NaN;
        eStr = 'Error! Incorrect time quantity specified.';
        waitfor(errordlg(eStr,'Invalid Time Quantity','modal'))
        return
end