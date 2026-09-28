/// When a user's journey began: the moment they allowed Health access.
/// Only steps after it count (docs/PRODUCT.md).
///
/// `startedAt` is a UTC instant; `timezone` is the IANA zone at that
/// moment, e.g. `Europe/Kyiv`.
typedef JourneyStart = ({String userId, DateTime startedAt, String timezone});
