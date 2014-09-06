#include "XContactApp.h"
#include "ModulesApp.h"
#include "Moose.h"
#include "AppFactory.h"

#include "GluedContactConstraint.h"

template<>
InputParameters validParams<XContactApp>()
{
  InputParameters params = validParams<MooseApp>();
  return params;
}

XContactApp::XContactApp(const std::string & name, InputParameters parameters) :
    MooseApp(name, parameters)
{
  srand(processor_id());

  Moose::registerObjects(_factory);
  ModulesApp::registerObjects(_factory);
  XContactApp::registerObjects(_factory);

  Moose::associateSyntax(_syntax, _action_factory);
  ModulesApp::associateSyntax(_syntax, _action_factory);
  XContactApp::associateSyntax(_syntax, _action_factory);
}

XContactApp::~XContactApp()
{
}

void
XContactApp::registerApps()
{
  registerApp(XContactApp);
}

void
XContactApp::registerObjects(Factory & factory)
{
}

void
XContactApp::associateSyntax(Syntax & syntax, ActionFactory & action_factory)
{
}
