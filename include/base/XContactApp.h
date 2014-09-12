#ifndef XCONTACTAPP_H
#define XCONTACTAPP_H

#include "MooseApp.h"

class XContactApp;

template<>
InputParameters validParams<XContactApp>();

class XContactApp : public MooseApp
{
public:
  XContactApp(const std::string & name, InputParameters parameters);
  virtual ~XContactApp();

  static void registerApps();
  static void registerObjects(Factory & factory);
  static void associateSyntax(Syntax & syntax, ActionFactory & action_factory);
};

#endif /* XCONTACTAPP_H */
