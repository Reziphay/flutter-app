# Makefile — Reziphay Flutter App
# Author: Vugar Safarzada (@vugarsafarzada)

LOGO_SRC := ../ReziphayLogo.png
LOGO_DST := assets/app_icon.png

# ── Icon update ───────────────────────────────────────────────────────────────
icon:
	@echo "→ Copying logo..."
	@cp $(LOGO_SRC) $(LOGO_DST)
	@echo "→ Generating icons..."
	@dart run flutter_launcher_icons
	@echo "✓ Done"

# ── Get packages ──────────────────────────────────────────────────────────────
get:
	flutter pub get

# ── Analyze ───────────────────────────────────────────────────────────────────
check:
	flutter analyze --no-pub lib/

# ── Run on connected device ───────────────────────────────────────────────────
run:
	flutter run

# ── Run on iPhone specifically ────────────────────────────────────────────────
iphone:
	flutter run -d "Vugar's iPhone"

.PHONY: icon get check run iphone
