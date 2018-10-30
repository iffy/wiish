import opengl

type
  GLContext* = ref object of RootObj

proc newGLContext*(): GLContext =
  new(result)
  loadExtensions()



