from __future__ import print_function
from lammps import lammps
import sys, time
import matplotlib.pyplot as plt

lmp = lammps()

def go():
  global runflag
  runflag = 1
def stop():
  global runflag
  runflag = 0
def settemp(value):
  global temptarget
  temptarget = slider.get()
def quit():
  global breakflag
  breakflag = 1
infile = sys.argv[1]
nfreq = int(sys.argv[2])
nsteps = int(sys.argv[3])
compute = sys.argv[4]

me = 0


argv = sys.argv
if len(argv) != 5:
  print("Syntax: plot.py in.lammps Nfreq Nsteps compute-ID")
  sys.exit()

infile = sys.argv[1]
nfreq = int(sys.argv[2])
nsteps = int(sys.argv[3])
compute = sys.argv[4]

me = 0

lmp.file(infile)
lmp.command("thermo %d" % nfreq)

breakflag = 0
runflag = 0
temptarget = 1.0
lmp.command("run 0 pre yes post no")
value = lmp.extract_compute(compute,0,0)
ntimestep = 0
xaxis = [ntimestep]
yaxis = [value]

if me == 0:
  fig = plt.figure()
  line, = plt.plot(xaxis, yaxis)
  plt.xlim([0, nsteps])
  plt.title(compute)
  plt.xlabel("Timestep")
  plt.ylabel("Temperature")
  plt.show(block=False)
  
  # initialization code from slider
  try:
    from Tkinter import *
  except:
    from tkinter import *
  tkroot = Tk()
  tkroot.withdraw()
  root = Toplevel(tkroot)
  root.title("LAMMPS GUI")

  frame = Frame(root)
  Button(frame,text="Go",command=go).pack(side=LEFT)
  Button(frame,text="Stop",command=stop).pack(side=LEFT)
  slider = Scale(frame,from_=0.0,to=5.0,resolution=0.1,
                 orient=HORIZONTAL,label="Temperature")
  slider.bind('<ButtonRelease-1>',settemp)
  slider.set(temptarget)
  slider.pack(side=LEFT)
  Button(frame,text="Quit",command=quit).pack(side=RIGHT)
  frame.pack()
  tkroot.update()



running = 0
temp = temptarget
seed = 12345

lmp.command("fix 2 all langevin %g %g 0.1 %d" % (temp,temp,seed))


while ntimestep < nsteps:
  lmp.command("run %d pre no post no" % nfreq)
  ntimestep += nfreq
  value = lmp.extract_compute(compute,0,0)
  xaxis.append(ntimestep)
  yaxis.append(value)
  if me == 0:
    line.set_xdata(xaxis)
    line.set_ydata(yaxis)
    ax = plt.gca()
    ax.relim()
    ax.autoscale_view(True, True, True)
    plt.pause(0.001)
    tkroot.update()
  if temp != temptarget:
    temp = temptarget
    seed += me+1
    lmp.command("fix 2 all langevin %g %g 0.1 %d" % (temp,temp,seed))
    running = 0
  if runflag and running:
    lmp.command("run %d pre no post no" % nfreq)
  elif runflag and not running:
    lmp.command("run %d pre yes post no" % nfreq)
  elif not runflag and running:
    lmp.command("run %d pre no post yes" % nfreq)
  if breakflag: break
  if runflag: running = 1
  else: running = 0
  time.sleep(0.01)

lmp.command("run 0 pre no post yes")

# uncomment if running in parallel via mpi4py
#print("Proc %d out of %d procs has" % (me,nprocs), lmp)

if me == 0:
  if sys.version_info[0] == 3:
      input("Press Enter to exit...")
  else:
      raw_input("Press Enter to exit...")


