# .onAttach for introductory messaging after library()
#
# 

.onAttach <- function(libname, pkgname) {
  if (interactive()) {
    packageStartupMessage("run the command `type_github()` to start typing!")
  }
}
