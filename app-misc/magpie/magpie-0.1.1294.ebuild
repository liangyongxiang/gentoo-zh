# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop go-module optfeature xdg

DESCRIPTION="Model and account manager with a local gateway for AI coding agents"
HOMEPAGE="https://usemagpie.ai/"
# the repo carries no vendor/ tree, so the Go module cache comes from the
# gentoo-deps bundle built for this exact ${P} (see overlay.toml deps)
SRC_URI="
	https://github.com/yetone/magpie/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/gentoo-zh/gentoo-deps/releases/download/${P}/${P}-deps.tar.xz
"

LICENSE="Apache-2.0 BSD BSD-2 ISC MIT MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="gui"

DEPEND="
	gui? (
		dev-libs/glib:2
		dev-libs/wayland
		media-libs/fontconfig
		net-libs/libsoup:3.0
		net-libs/webkit-gtk:4.1
		x11-libs/gdk-pixbuf:2
		x11-libs/gtk+:3
		x11-libs/libX11
	)
"
RDEPEND="
	${DEPEND}
	gui? ( !app-misc/magpie-bin )
	x11-misc/xdg-utils
"
BDEPEND=">=dev-lang/go-1.26.8"

src_compile() {
	local my_ldflags="-X main.version=v${PV}"

	# static no-cgo build, as the upstream Makefile cli target
	CGO_ENABLED=0 ego build -o magpie-cli -tags nogui -trimpath -ldflags="${my_ldflags}" .
	if use gui; then
		ego build -o magpie -tags "production gtk3" -trimpath -ldflags="${my_ldflags}" .
	fi
}

src_install() {
	dobin magpie-cli
	if use gui; then
		dobin magpie
		newicon -s 256 internal/gui/icon-256.png magpie.png
		make_desktop_entry magpie Magpie magpie Development
	fi
}

pkg_postinst() {
	xdg_pkg_postinst
	optfeature "OpenAI Codex CLI support" dev-util/codex
	optfeature "Google Gemini CLI support" dev-util/gemini-cli
	elog "Disable upstream automatic updates with: magpie update auto off"
	elog "Use Portage to update magpie; do not use its built-in updater."
}

pkg_postrm() {
	xdg_pkg_postrm
}
