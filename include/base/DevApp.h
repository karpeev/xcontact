#ifndef DEVAPP_H
#define DEVAPP_H

#include "MooseApp.h"

class DevApp;

template<>
InputParameters validParams<DevApp>();

class DevApp : public MooseApp
{
public:
  DevApp(const std::string & name, InputParameters parameters);
  virtual ~DevApp();

  static void registerApps();
  static void registerObjects(Factory & factory);
  static void associateSyntax(Syntax & syntax, ActionFactory & action_factory);
};

#endif /* DEVAPP_H */
