# print "Setting up Homebrew..."

# Homebrew (if installed) - Ensure it takes precedence
if [ -x "$(command -v brew)" ]; then
  eval "$($(command -v brew) shellenv)"
fi
