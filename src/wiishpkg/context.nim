import opengl

type
  GL* = ref object
  GLContext* = ref object of RootObj
    gl*: GL

proc newGL*(): GL =
  new(result)

proc newGLContext*(): GLContext =
  new(result)
  result.gl = newGL()

