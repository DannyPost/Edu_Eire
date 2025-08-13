/// Generic status enum for screen states.
enum Status {
  idle,       // nothing happening
  loading,    // waiting for a response
  success,    // we have data
  error,      // something failed
}
