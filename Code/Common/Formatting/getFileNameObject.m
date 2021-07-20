% --- retrieves the file chooser name object
function hFn = getFileNameObject(jFileC)

jPanel = jFileC.getComponent(2).getComponent(2);
hFn = handle(jPanel.getComponent(2).getComponent(1),'CallbackProperties');