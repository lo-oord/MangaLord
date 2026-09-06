const ERROR_TYPE_NETWORK = "NETWORK_ERROR";
const ERROR_TYPE_PERMISSION = "PERMISSION_ERROR";
const ERROR_TYPE_TIME = "TIME_ERROR";
const ERROR_TYPE_UNDER_REVIEW = "UNDER_VIEW_ERROR";

// Error types used to display friendly messages
String errorType(String error) {
  if (error.contains("timeout") ||
      error.contains("connection refused") ||
      error.contains("deadline") ||
      error.contains("connection abort")) {
    return ERROR_TYPE_NETWORK;
  }
  if (error.contains("permission denied")) {
    return ERROR_TYPE_PERMISSION;
  }
  if (error.contains("time is not synchronize")) {
    return ERROR_TYPE_TIME;
  }
  if (error.contains("under review")) {
    return ERROR_TYPE_UNDER_REVIEW;
  }
  return "";
}
