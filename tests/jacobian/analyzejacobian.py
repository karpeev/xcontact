#!/usr/bin/python
import fileinput
import sys
import re
import math
import numpy as np

nlsRE = re.compile("^Nonlinear System:\n$")
varlistFullRE = re.compile("^\s*Variables:\s*\{([^}]+)\}")
varlistStartRE = re.compile("^\s*Variables:\s*\{([^}]+)")
varlistEndRE = re.compile("^\s*([^}]+)\}")
varlistContRE = re.compile("^\s*([^}]+)")
varRE = re.compile("\"([^\"]+)\"")
dofRE  = re.compile("\s*Num DOFs:\s*([\d]+)")
ldofRE = re.compile("\s*Num Local DOFs:\s*([\d]+)")

MfdRE = re.compile("^Finite difference Jacobian \(user-defined state\)")
MhcRE = re.compile("^Hand-coded Jacobian \(user-defined state\)")
MdiffRE = re.compile("^Hand-coded minus finite difference Jacobian \(user-defined state\)")

rowRE = re.compile("row ([\d]+): ")
valRE = re.compile(" \(([\d]+), ([+-.e\d]+)\)")

numvars = 0
dofs = 0;

def analyze() :
  global Mfd
  global Mhc
  global Mdiff
  global nlvars
  global numvars
  global dofs

  fd   = np.zeros((numvars, numvars))
  hc   = np.zeros((numvars, numvars))
  norm = np.zeros((numvars, numvars))

  for i in range(dofs) :
    for j in range(dofs) :
      fd  [i % numvars][j % numvars] += Mfd[i][j]**2
      hc  [i % numvars][j % numvars] += Mhc[i][j]**2
      norm[i % numvars][j % numvars] += Mdiff[i][j]**2

  fd = fd**0.5
  hc = hc**0.5
  norm = norm**0.5

  e = 1e-4

  for i in range(numvars) :
    printed = False

    for j in range(numvars) :
      if norm[i][j] > e*fd[i][j] :
        if not printed :
          print "\nKernel for variable '%s':" % nlvars[i]
          printed = True

        if hc[i][j] == 0.0 :
          problem = "needs to be implemented"
        elif fd[i][j] == 0.0 :
          problem = "should just return  zero"
        else :
          err = math.fabs((hc[i][j]-fd[i][j])/fd[i][j])*100.0
          if err > 20.0 :
            problem = "is wrong (off by %.1f %%)" % err
          elif err > 5.0 :
            problem = "is questionable (off by %.2f %%)" % err
          elif err > 1.0 :
            problem = "is inexact (off by %.3f %%)" % err
          else :
            problem = "is slightly off (by %f %%)" % err

        if i == j :
          print "  (%d,%d) On-diagonal Jacobian %s" % (i, j, problem)
        else :
          print "  (%d,%d) Off-diagonal Jacobian for variable '%s' %s" % (i, j, nlvars[j], problem)


#
# Simple state machine parser for the MOOSE output
#

state = 1
for line in fileinput.input():

  #
  # Read in MOOSE startup info, such as variables and DOFs
  #

  if state == 1 :
    # looking fornon linear system header
    m = nlsRE.match(line)
    if m :
      state = 2
      continue

  if state == 2 :
    # look for DOF numbers
    m = dofRE.match(line)
    if m :
      dofs = int(m.group(1))
      continue
    m = ldofRE.match(line)
    if m :
      ldofs = int(m.group(1))
      continue

    # looking for variables list
    m = varlistFullRE.match(line)
    if m :
      nlvarlist = m.group(1)
      nlvars = varRE.findall(nlvarlist)
      state = 4
      continue

    m = varlistStartRE.match(line)
    if m :
      nlvarlist = m.group(1)
      nlvars = varRE.findall(nlvarlist)
      state = 3
      continue

  if state == 3 :
    # continue looking for variables in a multi line list
    m = varlistEndRE.match(line)
    if m :
      nlvarlist = m.group(1)
      nlvars.extend(varRE.findall(nlvarlist))
      state = 4
      continue

    m = varlistContRE.match(line)
    if m :
      nlvarlist = m.group(1)
      nlvars.extend(varRE.findall(nlvarlist))
      continue

  #
  # Initialization
  #

  if state == 4 :
    if dofs != ldofs :
      print "run in serial for debugging"
      sys.exit(1)

    numvars = len(nlvars)
    state = 5

  #
  # Start of a new set of matrices
  #

  if state == 5 :
    Mfd = np.zeros((dofs, dofs))
    Mhc = np.zeros((dofs, dofs))
    Mdiff = np.zeros((dofs, dofs))
    state = 6

  #
  # Read in PetSc matrices
  #

  if state == 6 :
    m = MfdRE.match(line)
    if m :
      state = 7
      continue

  if state == 7 :
    m = MhcRE.match(line)
    if m :
      state = 8
      continue

  if state == 8 :
    m = MdiffRE.match(line)
    if m :
      state = 9
      continue

  # read data
  if state >= 7 and state <= 9 :
    m = rowRE.match(line)
    vals = valRE.findall(line)
    if m :
      row = int(m.group(1))

      for pair in vals :
        if state == 7 :
          Mfd[row, int(pair[0])] = float(pair[1])
        if state == 8 :
          Mhc[row, int(pair[0])] = float(pair[1])
        if state == 9 :
          Mdiff[row, int(pair[0])] = float(pair[1])

      if state == 9 and row+1 == dofs :
        state = 5

        analyze()
        continue


