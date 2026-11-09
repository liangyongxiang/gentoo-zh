# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES=""
RUST_MIN_VER="1.89.0"

inherit cargo virtualx

DESCRIPTION="Desktop automation CLI for AI agents using native accessibility APIs"
HOMEPAGE="https://github.com/vercel-labs/agent-desktop"
SRC_URI="
	https://github.com/vercel-labs/agent-desktop/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/gentoo-zh-drafts/agent-desktop/releases/download/dist-v${PV}/${P}-crates.tar.xz
"

LICENSE="Apache-2.0"
# Dependent crate licenses
LICENSE+=" MIT Unicode-3.0 ZLIB"
SLOT="0"
KEYWORDS="~amd64"
IUSE="wayland"

RDEPEND="
	app-accessibility/at-spi2-core
	sys-apps/dbus
	wayland? ( gui-apps/wl-clipboard )
"
BDEPEND="
	test? (
		app-accessibility/at-spi2-core
		sys-apps/dbus
	)
"

QA_FLAGS_IGNORED="
	usr/bin/agent-desktop
	usr/bin/agent-desktop-linux-clipboard-owner
"

src_prepare() {
	default
	sed -i -e '/^[[:space:]]*\(opt-level\|lto\|codegen-units\|strip\)[[:space:]]*=/d' \
		Cargo.toml || die
	# This test binds a Unix socket; the package build path can exceed SUN_LEN.
	sed -i '/let path = std::env::current_dir()/,+1c\    let path = std::env::temp_dir()' \
		crates/linux/src/system/overlay/cursor_overlay_tests.rs || die
}

src_configure() {
	cargo_src_configure --frozen -p agent-desktop -p agent-desktop-core -p agent-desktop-linux
}

src_test() {
	# The CLI tests create Unix sockets below TMPDIR.
	local -x TMPDIR=/tmp
	virtx cargo_src_test
}

src_install() {
	dobin "$(cargo_target_dir)/agent-desktop" \
		"$(cargo_target_dir)/agent-desktop-linux-clipboard-owner"
	dodoc README.md LICENSE
}
