function jCol = getJavaColour(rgbArr)

jCol = javaObject('java.awt.Color',rgbArr(1),rgbArr(2),rgbArr(3));