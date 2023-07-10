## Changelog

When you make a change, include a description of the change as one or more new markdown files in the `changes/` directory.

The filename should follow this format:

```
changes/TYPE-TITLE.md
```

where `TYPE` is one of:

- `fix` = for bug fixes
- `new` = for new features
- `break` = for breaking changes
- `other` = for every other kind of change

and `TITLE` is a unique name for your change (the purpose is just to avoid conflicts).  It could include an issue number.

If the change fixes a GitHub issue, include that in the change file like this: `(#103)`

## Design Plan

Wiish components are meant to be replaceable and expendable.  For instance:

- You should be able to use the `wiish` command line tool without importing anything from `wiish` in your app.  

- Auto-updating and logging should be usable no matter what GUI library you use.

In other words, components shouldn't be interwined so much that they're inseparable.  Instead, they should be easily replaced.  Also, you should always be able to drop down to a lower level if needed.

## Running tests

```
nimble test
```

