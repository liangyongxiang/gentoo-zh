# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CRATES=""
RUST_MIN_VER="1.88.0"

inherit cargo optfeature

DESCRIPTION="Browser automation CLI for AI agents with an embedded dashboard"
HOMEPAGE="https://agent-browser.dev https://github.com/vercel-labs/agent-browser"
SRC_URI="
	https://github.com/vercel-labs/agent-browser/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/gentoo-zh-drafts/agent-browser/releases/download/dist-v${PV}/${P}-crates.tar.xz
	https://github.com/gentoo-zh-drafts/agent-browser/releases/download/dist-v${PV}/${P}-web.tar.xz
"
S="${WORKDIR}/${P}/cli"

LICENSE="Apache-2.0"
# Dependent crate and dashboard licenses
LICENSE+="
	BSD BSD-2 CDLA-Permissive-2.0 ISC MIT OFL-1.1
	UoI-NCSA Unicode-3.0 Unlicense ZLIB
"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="x11-misc/xdg-utils"

src_prepare() {
	default
	sed -i -e '/^[[:space:]]*\(opt-level\|lto\|codegen-units\|strip\)[[:space:]]*=/d' \
		Cargo.toml || die
	mv "${WORKDIR}/out" ../packages/dashboard/out || die
}

src_configure() {
	cargo_src_configure --frozen
}

src_test() {
	local -x TMPDIR=/tmp
	cargo_src_test
}

src_install() {
	# Skill discovery follows the upstream bin/../skill-data layout.
	exeinto /usr/libexec/${PN}/bin
	doexe "$(cargo_target_dir)/${PN}"
	dosym -r /usr/libexec/${PN}/bin/${PN} /usr/bin/${PN}
	insinto /usr/share/${PN}
	doins -r ../skills ../skill-data
	local data
	for data in skills skill-data; do
		dosym -r /usr/share/${PN}/${data} /usr/libexec/${PN}/${data}
	done
	dodoc ../README.md ../LICENSE
	dodoc -r "${WORKDIR}/web-licenses"
}

pkg_postinst() {
	optfeature "local browser automation" www-client/chromium www-client/google-chrome
	optfeature "video recording" "media-video/ffmpeg[vpx,x264]"
	optfeature "custom CA certificates in local Chrome" "dev-libs/nss[utils]"
	optfeature "Git worktree session scopes" dev-vcs/git
}
