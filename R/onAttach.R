# .onAttach for introductory messaging after library()
#
# 

.onAttach <- function(libname, pkgname) {
  if (interactive()) {
    packageStartupMessage("Enter `type_github()` to start typing!")
    packageStartupMessage("Enter `visit_site()` to visit companion website!")
    if (!crayon::has_color()){
      msg <- paste("\nANSI color support is not available. Windows users may",
                   "wish to try the ConEmu terminal emulator")
      packageStartupMessage(msg)
    }
  }
}
