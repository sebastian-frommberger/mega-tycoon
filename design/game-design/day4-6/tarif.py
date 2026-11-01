import sys
sys.path.insert(0, "/tmp/claude-0/gd/sprint2/day1-3/tobias")
import t05_modell as m
C = {"Agrar":4500,"Hafen":4500,"Bergbau":7000,"Handel":5000}
for arch in ["Agrar","Hafen","Bergbau","Handel"]:
    rL  = m.simulate(arch,"L", target="V", C=C[arch], horizon=40, ai=False)
    rLa = m.simulate(arch,"L", target="V", C=C[arch], horizon=40, ai=True, ai_start=15)
    rK  = m.simulate(arch,"K0",target="V", C=C[arch], horizon=40, ai=True, ai_start=15)
    def net(r,t): return r["rows"][t-1]["net"]
    print(arch, "S0=",round(rL["S0"]), "Lp=",{k:round(v) for k,v in rL["Lp"].items()}, "K=",rL["K"],
          "| net/min L min10:",net(rL,10)," L+KI min20:",net(rLa,20)," Besitz V+KI min20:",net(rK,20),
          "| cash L min5/10/15/20/25/30:",[rL["rows"][t-1]["cash"] for t in (5,10,15,20,25,30)],
          "| cash L+KI min20/25/30:",[rLa["rows"][t-1]["cash"] for t in (20,25,30)])
