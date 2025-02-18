
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=true
LATESTARTSERVICE=true


print_modname() {
 sleep 2
 ui_print "*************************"
 ui_print " Welcome To Recall  "
 ui_print "*************************"
 ui_print " Information About :"
 ui_print " $(getprop ro.product.model)"
 ui_print " $(getprop ro.hardware)"
 ui_print ""
 ui_print ""
 ui_print " Thanks to contribute: "
 ui_print " @hirauki "
}

# Copy/extract your module files into $MODPATH in on_install.

on_install() {
  # The following is the default implementation: extract $ZIPFILE/system to $MODPATH
  # Extend/change the logic to whatever you want
  ui_print "- Extracting module files"
  unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2
}

# Only some special files require specific permissions
# This function will be called after on_install is done
# The default permissions should be good enough for most cases
  ui_print " unleash ability your phone"

set_permissions() {
  # The following is the default rule, DO NOT remove
  set_perm_recursive $MODPATH 0 0 0755 0644
  set_perm  $MODPATH/system/bin/daemon 0 0 0755
}

