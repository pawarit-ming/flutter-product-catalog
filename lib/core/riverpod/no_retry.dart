/// Disables Riverpod 3's automatic retry.
///
/// Failed API calls surface as an error state with an explicit Retry button
/// instead of silently re-sending requests in the background.
Duration? noRetry(int retryCount, Object error) => null;
