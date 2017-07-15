# .onAttach for introductory messaging after library()
#
# 

.onAttach <- function(libname, pkgname) {
  if (interactive()) {
    packageStartupMessage("Enter `type_github()` to start typing!")
    packageStartupMessage("Enter `visit_site()` to visit companion website!")
    if (!crayon::has_color()){
      msg <- paste("\nNote: ANSI color support (optional) is not available.",
                   "For a more colorful\nexperience, Windows users may",
                   "wish to try the ConEmu terminal emulator; Mac\nusers may",
                   "wish to try iTerm2.\n")
      packageStartupMessage(msg)
    }
  }
}
