String vendorRouteForDeepLink(String raw) {
  final path = Uri.tryParse(raw)?.path ?? raw;
  final normalized = path.toLowerCase();
  return switch (normalized) {
    _ when normalized.contains('/dropshipping') => '/dropshipping',
    _ when normalized.contains('/bookings') => '/bookings',
    _ when normalized.contains('/orders') => '/orders',
    _ when normalized.contains('/settlements') => '/settlements',
    _ when normalized.contains('/payments') => '/payments',
    _ when normalized.contains('/products') => '/products',
    _ when normalized.contains('/services') => '/services',
    _ when normalized.contains('/availability') => '/availability',
    _ when normalized.contains('/media') => '/media',
    _ when normalized.contains('/bank') => '/bank',
    _ when normalized.contains('/kyc') => '/kyc',
    _ when normalized.contains('/plans') => '/plans',
    _ when normalized.contains('/profile') => '/profile',
    _ when normalized.contains('/reviews') => '/reviews',
    _ when normalized.contains('/analytics') => '/analytics',
    _ when normalized.contains('/support') => '/support',
    _ when normalized.contains('/settings') => '/settings',
    _ when normalized.contains('/notifications') => '/notifications',
    _ => '/',
  };
}
