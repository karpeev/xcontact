#include "SplitContactApp.h"
#include "ModulesApp.h"
#include "Moose.h"
#include "AppFactory.h"

#include "GluedContactConstraint.h"

template<>
InputParameters validParams<SplitContactApp>()
{
  InputParameters params = validParams<MooseApp>();
  return params;
}

SplitContactApp::SplitContactApp(const std::string & name, InputParameters parameters) :
    MooseApp(name, parameters)
{
  srand(processor_id());

  Moose::registerObjects(_factory);
  ModulesApp::registerObjects(_factory);
  SplitContactApp::registerObjects(_factory);

  Moose::associateSyntax(_syntax, _action_factory);
  ModulesApp::associateSyntax(_syntax, _action_factory);
  SplitContactApp::associateSyntax(_syntax, _action_factory);
}

SplitContactApp::~SplitContactApp()
{
}

void
SplitContactApp::registerApps()
{
  registerApp(SplitContactApp);
}

void
SplitContactApp::registerObjects(Factory & factory)
{
}

void
SplitContactApp::associateSyntax(Syntax & syntax, ActionFactory & action_factory)
{
}
