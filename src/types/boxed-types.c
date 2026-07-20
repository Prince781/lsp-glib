#include <glib-object.h>

/*
 * Compact LSP values use explicit ref counting in the C API. Registering them
 * as boxed types also tells GI-based bindings how to retain and release values
 * returned by constructors without changing their representation to GObject.
 */
#define LSP_BOXED_TYPE(TypeName, type_name) \
  typedef struct _##TypeName TypeName; \
  TypeName *type_name##_ref (TypeName *self); \
  void type_name##_unref (TypeName *self); \
  G_DEFINE_BOXED_TYPE ( \
    TypeName, \
    type_name, \
    type_name##_ref, \
    type_name##_unref)

#include "boxed-types.def"
