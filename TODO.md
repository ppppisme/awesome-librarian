# TO-DO

* provide ability to pass custom notify() function to librarian on init(), so
  it's possible to alter a way of displaying messages
* and so for library downloaders/managers (such as a default git). User should
  be able to provide his own implementation of a thing for downloading/updating
  of libraries
* do I really need 2 installation functions (one for sync and the other for
  async installation process)? how do I arrange it the way to allow different
  library managers to work properly
* because of the idea of abstracting from using only git for managing libraries
  mayby i'll need to reformat options input? it's not all that clear as for now
