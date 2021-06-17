% --- retrieves the java object handle from a tab group
function jTab = getTabGroupJavaObj(hTabGrp)

jTab0 = findjobj(hTabGrp);
jTab = jTab0(arrayfun(@(x)(strContains(class(x),'MJTabbedPane')),jTab0));