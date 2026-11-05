import sys, math; sys.path.insert(0,'/tmp/claude-0/oe3')
from modell import *
def flotte(k,C):
    v=0.6/k; n=0
    for rate,d,u in [(20,17,1.2),(20,41,1.2),(10,15,1.11),(24,66,1.27)]:
        T=2*d*u/v+200; n+=math.ceil(rate/(C*600/T))
    return n
def robust(p,k,F,C,V,fresh,q=0.75):
    ok,dm,n=x1(p,k,F,C,V,fresh)
    return ok and n[150]<=q*n[dm] and dm in (60,80), n
def run(k, wmin, wmax, legmin, Cs=(10,12,15,20,25,30,40,50)):
    best=[]
    for C in Cs:
      for F in range(1000,40001,500):
        for V in [2,4,8,12,16,20,30,40,60,80]:
          for pg in range(16,241,2):
            if ne(pg,17,k,F,C,V,False,1.2)<legmin: continue
            okg,ng=robust(pg,k,F,C,V,False)
            if not okg or not x2(pg,k,F,C,V,False)[0]: continue
            for pm in range(40,401,5):
              if ne(pm,15,k,F,C,V,True,1.11)<legmin: continue
              okm,nm=robust(pm,k,F,C,V,True)
              if not okm or not x2(pm,k,F,C,V,True)[0]: continue
              w=welt(pg,pm,k,F,C,V)
              if not (wmin<=w<=wmax): continue
              fl=flotte(k,C)
              score=abs(pm-70)/70+abs(pg-28)/28*0.5+fl/20+abs(C-10)/40
              best.append((round(score,3),C,F,V,pg,pm,round(w),fl,round(ne(pg,17,k,F,C,V,False,1.2)),round(ne(pm,15,k,F,C,V,True,1.11))))
    best.sort(); return best
if __name__=="__main__":
    k=int(sys.argv[1]); r=run(k,1000,1400,50)
    print("k",k,len(r))
    for b in r[:10]: print("  ",b)
