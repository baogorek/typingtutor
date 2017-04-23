# .onAttach for introductory messaging after library()
#
# 

.onAttach <- function(libname, pkgname) {
  if (interactive()) {
    packageStartupMessage("run the command `type_github()` to start typing!")
    if (!has_color()){
      packageStartupMessage(paste("ANSI color support not available. Windows",
                                  "users\n may wish to try the ConEmu",
                                  "terminal emulator"))
    }
  }
}
