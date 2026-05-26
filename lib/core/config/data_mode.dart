/// Modo de persistencia: local (SQLite) o remoto (API REST).
enum DataMode {
  /// Por defecto: SQLite en el dispositivo (offline-first).
  local,

  /// Cliente conectado al backend distribuido.
  remote,
}
