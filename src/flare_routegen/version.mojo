"""Pinned compatibility metadata for flare-routegen."""

comptime VERSION = "0.1.0"

comptime MOJO_PIN_CI = "1.0.0"
comptime MOJO_RANGE = ">=1.0.0,<1.1.0"

# Git branch used for CI and local Pixi installs. The published pixi-build
# artifact for Flare v0.10.0 cannot be installed with PIXI_PIN_CI.
comptime FLARE_PIN_CI = "main"
comptime FLARE_RANGE = ">=0.10.0,<0.11.0"

comptime PIXI_PIN_CI = "0.70.2"
