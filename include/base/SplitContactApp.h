#ifndef SPLITCONTACTAPP_H
#define SPLITCONTACTAPP_H

#include "MooseApp.h"

class SplitContactApp;

template<>
InputParameters validParams<SplitContactApp>();

class SplitContactApp : public MooseApp
{
public:
  SplitContactApp(const std::string & name, InputParameters parameters);
  virtual ~SplitContactApp();

  static void registerApps();
  static void registerObjects(Factory & factory);
  static void associateSyntax(Syntax & syntax, ActionFactory & action_factory);
};

#endif /* SPLITCONTACTAPP_H */
