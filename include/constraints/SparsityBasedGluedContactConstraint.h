/****************************************************************/
/*               DO NOT MODIFY THIS HEADER                      */
/* MOOSE - Multiphysics Object Oriented Simulation Environment  */
/*                                                              */
/*           (c) 2010 Battelle Energy Alliance, LLC             */
/*                   ALL RIGHTS RESERVED                        */
/*                                                              */
/*          Prepared by Battelle Energy Alliance, LLC           */
/*            Under Contract No. DE-AC07-05ID14517              */
/*            With the U. S. Department of Energy               */
/*                                                              */
/*            See COPYRIGHT for full restrictions               */
/****************************************************************/

#ifndef SPARSITYBASEDGLUEDCONTACTCONSTRAINT_H
#define SPARSITYBASEDGLUEDCONTACTCONSTRAINT_H

//MOOSE includes
#include "NodeFaceConstraint.h"

//Contact modules includes
//#include "ContactMaster.h"

//Forward Declarations
class SparsityBasedGluedContactConstraint;

template<>
InputParameters validParams<SparsityBasedGluedContactConstraint>();

/**
 * A SparsityBasedGluedContactConstraint forces the value of a variable to be the same on both sides of an interface.
 */
class SparsityBasedGluedContactConstraint :
  public NodeFaceConstraint
{
public:
  SparsityBasedGluedContactConstraint(const std::string & name, InputParameters parameters);
  virtual ~SparsityBasedGluedContactConstraint(){}

  virtual void timestepSetup();
  virtual void jacobianSetup();

  virtual void updateContactSet(bool beginning_of_step = false);

  virtual Real computeQpSlaveValue();

  virtual Real computeQpResidual(Moose::ConstraintType type);

  virtual void computeJacobian();

  virtual Real computeQpJacobian(Moose::ConstraintJacobianType type);

  bool shouldApply();
protected:
  const unsigned int _component;
  bool _updateContactSet;
  Real _time_last_called;

  Real _penalty;

  NumericVector<Number> & _residual_copy;

  unsigned int _x_var;
  unsigned int _y_var;
  unsigned int _z_var;

  RealVectorValue _vars;

  MooseVariable * _nodal_area_var;
  SystemBase & _aux_system;
  const NumericVector<Number> * _aux_solution;
};

#endif
