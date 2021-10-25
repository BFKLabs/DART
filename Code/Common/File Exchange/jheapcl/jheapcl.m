function jheapcl()

rm = javax.swing.RepaintManager.currentManager([]);
dim = rm.getDoubleBufferMaximumSize();
rm.setDoubleBufferMaximumSize(java.awt.Dimension(0,0));  % clear
rm.setDoubleBufferMaximumSize(dim);  %restore original dim
java.lang.System.gc();  % garbage-collect