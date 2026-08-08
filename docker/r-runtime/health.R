#* @get /health
function() {
  list(status = "ok", service = "r-runtime", version = R.version.string)
}
