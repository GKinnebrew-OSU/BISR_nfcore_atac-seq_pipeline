cat("Testing immunarch installation...\n")
tryCatch({
  library(immunarch)
  cat("immunarch loaded successfully!\n")
  cat("Version:", packageVersion("immunarch"), "\n")
}, error = function(e) {
  cat("Error loading immunarch:", e$message, "\n")
})

cat("Available packages:\n")
installed_packages <- installed.packages()[, c("Package", "Version")]
if ("immunarch" %in% rownames(installed_packages)) {
  cat("immunarch", installed_packages["immunarch", "Version"], "\n")
} else {
  cat("immunarch not found in installed packages\n")
}