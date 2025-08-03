#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.vladblajovan.Ritualist";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "AccentYellow" asset catalog color resource.
static NSString * const ACColorNameAccentYellow AC_SWIFT_PRIVATE = @"AccentYellow";

/// The "Brand" asset catalog color resource.
static NSString * const ACColorNameBrand AC_SWIFT_PRIVATE = @"Brand";

/// The "Surface" asset catalog color resource.
static NSString * const ACColorNameSurface AC_SWIFT_PRIVATE = @"Surface";

/// The "TextPrimary" asset catalog color resource.
static NSString * const ACColorNameTextPrimary AC_SWIFT_PRIVATE = @"TextPrimary";

#undef AC_SWIFT_PRIVATE
