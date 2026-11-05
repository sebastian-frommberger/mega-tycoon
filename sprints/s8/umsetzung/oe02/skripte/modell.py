# Grobmodell Netto je Einheit (Cent) je Strecke; validiert gegen QT-03b x_auswertung (k=4 Getreide d=60: 634 Modell / 632 Sim)
import sys, itertools
def deff(d): return d if d<=60 else 60+0.5*(d-60)
def fz(age, fresh):
    g,dec=(600,1200) if fresh else (3000,6000)
    if age<=g: return 1.0
    if age>=g+dec: return 0.3
    return 1-0.7*(age-g)/dec
def ne(p, d, k, F, C, V, fresh, umweg=1.0):
    v=0.6/k
    path=d*umweg
    T=2*path/v+200
    cost=(F/600*T + 2*V*path)/C
    age=path/v+100
    return p*deff(d)*fz(age,fresh)-cost
def x1(p,k,F,C,V,fresh):
    ds=[10,20,40,60,80,100,150]
    n={d:ne(p,d,k,F,C,V,fresh) for d in ds}
    dmax=max(n,key=n.get); mx=n[dmax]
    ok = 40<=dmax<=80 and n[150]<=0.8*mx and n[20]>=0 and n[40]>=0
    return ok,dmax,n
def x2(p,k,F,C,V,fresh):
    a=ne(p,60,k,F,C,V,fresh); b=ne(p,60,k,F,C,V,fresh,1.6)
    return a>0 and (a-b)/a>=0.2, (a-b)/a if a>0 else None
def welt(pg,pm,k,F,C,V):
    # Plan Minute 30: 20 Getreide 17 F (Weg 1.2), 20 Getreide 41 F (Weg 1.2), Mehl 10 Erl 15 F (1.11), 24 Lind 66 F (1.27); Marge 15 % Mehl
    g=20*ne(pg,17,k,F,C,V,False,1.2)+20*ne(pg,41,k,F,C,V,False,1.2)
    m=1.15*(10*ne(pm,15,k,F,C,V,True,1.11)+24*ne(pm,66,k,F,C,V,True,1.27))
    return (g+m)/100-40  # $/min, minus Werksunterhalt
if __name__=="__main__":
    for k,F,C,V,pg,pm in [(1,6000,10,4,28,70),(4,6000,10,4,28,70),(8,6000,10,4,28,70),(20,6000,10,4,28,70)]:
        print(k, x1(pg,k,F,C,V,False)[:2], x1(pm,k,F,C,V,True)[:2], round(welt(pg,pm,k,F,C,V)))
