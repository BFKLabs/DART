function Y = calcBimodalBoltz(p,x)

Y = p.A./((1+exp(p.k1*(x-p.xH1))).*(1+exp(p.k2*(x-p.xH2))));