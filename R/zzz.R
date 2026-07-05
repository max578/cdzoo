# zzz.R -- Load-time hooks.
#
# Wires up the S7 method table and registers the built-in discovery methods into
# the package registry when the namespace loads. User-supplied methods are added
# afterwards with register_method().

.onLoad <- function(libname, pkgname) {
  S7::methods_register()
  .register_builtin_methods()
  .register_suffstat_methods()
  invisible(NULL)
}
