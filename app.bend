object App { init, update } # render

def App/init(app):
  open App: app
  return app.init

def App/update(app):
  open App: app
  return app.update

def init_():
  return 0

def update(state):
  return state + 1

def main():
  app = App { init: init_, update: update }
  app_init = App/init(app)
  app_update = App/update(app)
  state = app_init
  return app_update(state)

# def main1():
#   state0 = init_
#   state1 = update(state0)
#   state2 = update(state0)
#   return state1 + state2
