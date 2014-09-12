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
#include "SparsityBasedGluedContactConstraint.h"

#include "SystemBase.h"
#include "PenetrationLocator.h"

// libMesh includes
#include "libmesh/string_to_enum.h"

template<>
InputParameters validParams<SparsityBasedGluedContactConstraint>()
{
  MooseEnum orders("CONSTANT, FIRST, SECOND, THIRD, FOURTH", "FIRST");

  InputParameters params = validParams<NodeFaceConstraint>();
  params.addRequiredParam<BoundaryName>("boundary", "The master boundary");
  params.addRequiredParam<BoundaryName>("slave", "The slave boundary");
  params.addRequiredParam<unsigned int>("component", "An integer corresponding to the direction the variable this kernel acts in. (0 for x, 1 for y, 2 for z)");
  params.addCoupledVar("disp_x", "The x displacement");
  params.addCoupledVar("disp_y", "The y displacement");
  params.addCoupledVar("disp_z", "The z displacement");
  params.addRequiredCoupledVar("nodal_area", "The nodal area");

  params.set<bool>("use_displaced_mesh") = true;
  params.addParam<Real>("penalty", 1e8, "The penalty to apply.  This can vary depending on the stiffness of your materials");
  params.addParam<Real>("tangential_tolerance", "Tangential distance to extend edges of contact surfaces");
  params.addParam<Real>("normal_smoothing_distance", "Distance from edge in parametric coordinates over which to smooth contact normal");
  params.addParam<std::string>("normal_smoothing_method","Method to use to smooth normals (edge_based|nodal_normal_based)");
  params.addParam<MooseEnum>("order", orders, "The finite element order");
  return params;
}

SparsityBasedGluedContactConstraint::SparsityBasedGluedContactConstraint(const std::string & name, InputParameters parameters) :
    NodeFaceConstraint(name, parameters),
  _component(getParam<unsigned int>("component")),
  _updateContactSet(true),
  _time_last_called(-std::numeric_limits<Real>::max()),
  _penalty(getParam<Real>("penalty")),
  _residual_copy(_sys.residualGhosted()),
  _x_var(isCoupled("disp_x") ? coupled("disp_x") : 99999),
  _y_var(isCoupled("disp_y") ? coupled("disp_y") : 99999),
  _z_var(isCoupled("disp_z") ? coupled("disp_z") : 99999),
  _vars(_x_var, _y_var, _z_var),
  _nodal_area_var(getVar("nodal_area", 0)),
  _aux_system( _nodal_area_var->sys() ),
  _aux_solution( _aux_system.currentSolution() )
{
//  _overwrite_slave_residual = false;

  if (parameters.isParamValid("tangential_tolerance"))
  {
    _penetration_locator.setTangentialTolerance(getParam<Real>("tangential_tolerance"));
  }
  if (parameters.isParamValid("normal_smoothing_distance"))
  {
    _penetration_locator.setNormalSmoothingDistance(getParam<Real>("normal_smoothing_distance"));
  }
  if (parameters.isParamValid("normal_smoothing_method"))
  {
    _penetration_locator.setNormalSmoothingMethod(parameters.get<std::string>("normal_smoothing_method"));
  }

  _penetration_locator.setUpdate(false);
}

void
SparsityBasedGluedContactConstraint::timestepSetup()
{
  if (_component == 0)
  {
    _penetration_locator._unlocked_this_step.clear();
    _penetration_locator._locked_this_step.clear();
    bool beginning_of_step = false;
    if (_t > _time_last_called)
    {
      beginning_of_step = true;
      _penetration_locator.saveContactStateVars();
    }
    updateContactSet(beginning_of_step);
    _updateContactSet = false;
    _time_last_called = _t;
  }
}

void
SparsityBasedGluedContactConstraint::jacobianSetup()
{
  if (_component == 0)
  {
    if (_updateContactSet)
    {
      updateContactSet();
    }
    _updateContactSet = true;
  }
}

void
SparsityBasedGluedContactConstraint::updateContactSet(bool beginning_of_step)
{
  std::set<unsigned int> & has_penetrated = _penetration_locator._has_penetrated;
  std::map<unsigned int, unsigned> & unlocked_this_step = _penetration_locator._unlocked_this_step;
  std::map<unsigned int, unsigned> & locked_this_step = _penetration_locator._locked_this_step;
  std::map<unsigned int, Real> & lagrange_multiplier = _penetration_locator._lagrange_multiplier;

  std::map<unsigned int, PenetrationInfo *>::iterator it = _penetration_locator._penetration_info.begin();
  std::map<unsigned int, PenetrationInfo *>::iterator end = _penetration_locator._penetration_info.end();

  for (; it!=end; ++it)
  {
    PenetrationInfo * pinfo = it->second;

    if (!pinfo)
    {
      continue;
    }

    const unsigned int slave_node_num = it->first;
    std::set<unsigned int>::iterator hpit = has_penetrated.find(slave_node_num);

    if (beginning_of_step)
    {
      if (hpit != has_penetrated.end())
        pinfo->_penetrated_at_beginning_of_step = true;
      else
        pinfo->_penetrated_at_beginning_of_step = false;

      pinfo->_starting_elem = it->second->_elem;
      pinfo->_starting_side_num = it->second->_side_num;
      pinfo->_starting_closest_point_ref = it->second->_closest_point_ref;
    }

    if (pinfo->_distance >= 0)
      if (hpit == has_penetrated.end())
        has_penetrated.insert(slave_node_num);
  }
}

bool
SparsityBasedGluedContactConstraint::shouldApply()
{
  std::set<unsigned int>::iterator hpit = _penetration_locator._has_penetrated.find(_current_node->id());
  return (hpit != _penetration_locator._has_penetrated.end());
}

Real
SparsityBasedGluedContactConstraint::computeQpSlaveValue()
{
  PenetrationInfo * pinfo = _penetration_locator._penetration_info[_current_node->id()];
  return _u_slave[_qp];
}

Real
SparsityBasedGluedContactConstraint::computeQpResidual(Moose::ConstraintType type)
{
  switch(type)
  {
    case Moose::Slave:
    {
      PenetrationInfo * pinfo = _penetration_locator._penetration_info[_current_node->id()];
      Real distance = (*_current_node)(_component) - pinfo->_closest_point(_component);
      Real pen_force = _penalty * distance;

      Real resid = pen_force;
      pinfo->_contact_force(_component) = resid;
      pinfo->_mech_status=PenetrationInfo::MS_STICKING;

      return _test_slave[_i][_qp] * resid;
    }
    case Moose::Master:
    {
      PenetrationInfo * pinfo = _penetration_locator._penetration_info[_current_node->id()];

      long int dof_number = _current_node->dof_number(0, _vars(_component), 0);
      Real resid = _residual_copy(dof_number);

      pinfo->_contact_force(_component) = -resid;
      pinfo->_mech_status=PenetrationInfo::MS_STICKING;

      return _test_master[_i][_qp] * resid;
    }
  }

  return 0;
}

Real
SparsityBasedGluedContactConstraint::computeQpJacobian(Moose::ConstraintJacobianType type)
{
  switch(type)
  {
    case Moose::SlaveSlave:
    {
      return _penalty*_phi_slave[_j][_qp]*_test_slave[_i][_qp];
    }
    case Moose::SlaveMaster:
    {
      return _penalty*-_phi_master[_j][_qp]*_test_slave[_i][_qp];
    }
    case Moose::MasterSlave:
    {
      double slave_jac = (*_jacobian)(_current_node->dof_number(0, _vars(_component), 0), _connected_dof_indices[_j]);
      return slave_jac*_test_master[_i][_qp];
    }
    case Moose::MasterMaster:
      return 0;
  }

  return 0;
}

void
SparsityBasedGluedContactConstraint::computeJacobian()
{

  _connected_dof_indices.clear();

#if defined(LIBMESH_HAVE_PETSC) && !PETSC_VERSION_LESS_THAN(3,3,0)
  // An ugly hack: have to extract the row and look at it's sparsity structure, since otherwise I won't get the dofs connected to this row by virtue of intervariable coupling
  // This is easier than sifting through all coupled variables, selecting those active on the current subdomain, dealing with the scalar variables, etc.
  // Also, importantly, this will miss coupling to variables that might have introduced by prior constraints similar to this one!
  PetscMatrix<Number>* petsc_jacobian = dynamic_cast<PetscMatrix<Number> *>(_jacobian);
  mooseAssert(petsc_jacobian, "Expected a PETSc matrix");
  Mat jac = petsc_jacobian->mat();
  PetscErrorCode ierr;
  PetscInt ncols;
  const PetscInt *cols;
  ierr = MatGetRow(jac,_var.nodalDofIndex(),&ncols,&cols,PETSC_NULL);CHKERRABORT(libMesh::COMM_WORLD, ierr);
  bool debug = false;
  if(debug) {
    libMesh::out << "_connected_dof_indices: adding " << ncols << " dofs from Jacobian row[" << _var.nodalDofIndex() << "] = [";
  }
  for (PetscInt i = 0; i < ncols; ++i) {
    if(debug) {
      libMesh::out << cols[i] << " ";
    }
    _connected_dof_indices.push_back(cols[i]);
  }
  if (debug) {
    libMesh::out << "]\n";
  }
  ierr = MatRestoreRow(jac,_var.nodalDofIndex(),&ncols,&cols,PETSC_NULL);CHKERRABORT(libMesh::COMM_WORLD, ierr);
#else

  std::vector<unsigned int> & elems = _node_to_elem_map[_current_node->id()];
  std::set<unsigned int> unique_dof_indices;

  // Get the dof indices from each elem connected to the node
  for(unsigned int el=0; el < elems.size(); ++el)
  {
    unsigned int cur_elem = elems[el];

    std::vector<unsigned int> dof_indices;
    _var.getDofIndices(_mesh.elem(cur_elem), dof_indices);

    for(unsigned int di=0; di < dof_indices.size(); di++)
      unique_dof_indices.insert(dof_indices[di]);
  }

  for(std::set<unsigned int>::iterator sit=unique_dof_indices.begin(); sit != unique_dof_indices.end(); ++sit)
    _connected_dof_indices.push_back(*sit);
#endif
  //  DenseMatrix<Number> & Kee = _assembly.jacobianBlock(_var.number(), _var.number());
  DenseMatrix<Number> & Ken = _assembly.jacobianBlockNeighbor(Moose::ElementNeighbor, _var.number(), _var.number());

  //  DenseMatrix<Number> & Kne = _assembly.jacobianBlockNeighbor(Moose::NeighborElement, _var.number(), _var.number());
  DenseMatrix<Number> & Knn = _assembly.jacobianBlockNeighbor(Moose::NeighborNeighbor, _var.number(), _var.number());

  _Kee.resize(_test_slave.size(), _connected_dof_indices.size());
  _Kne.resize(_test_master.size(), _connected_dof_indices.size());

  _phi_slave.resize(_connected_dof_indices.size());

  _qp = 0;

  // Fill up _phi_slave so that it is 1 when j corresponds to this dof and 0 for every other dof
  // This corresponds to evaluating all of the connected shape functions at _this_ node
  for(unsigned int j=0; j<_connected_dof_indices.size(); j++)
  {
    _phi_slave[j].resize(1);

    if(_connected_dof_indices[j] == _var.nodalDofIndex())
      _phi_slave[j][_qp] = 1.0;
    else
      _phi_slave[j][_qp] = 0.0;
  }

  for (_i = 0; _i < _test_slave.size(); _i++)
    // Loop over the connected dof indices so we can get all the jacobian contributions
    for (_j=0; _j<_connected_dof_indices.size(); _j++)
      _Kee(_i,_j) += computeQpJacobian(Moose::SlaveSlave);

  for (_i=0; _i<_test_slave.size(); _i++)
    for (_j=0; _j<_phi_master.size(); _j++)
      Ken(_i,_j) += computeQpJacobian(Moose::SlaveMaster);

  for (_i=0; _i<_test_master.size(); _i++)
    // Loop over the connected dof indices so we can get all the jacobian contributions
    for (_j=0; _j<_connected_dof_indices.size(); _j++)
      _Kne(_i,_j) += computeQpJacobian(Moose::MasterSlave);

  for (_i=0; _i<_test_master.size(); _i++)
    for (_j=0; _j<_phi_master.size(); _j++)
      Knn(_i,_j) += computeQpJacobian(Moose::MasterMaster);
}

