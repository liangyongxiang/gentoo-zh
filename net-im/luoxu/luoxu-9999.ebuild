# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..15} )
DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=setuptools
CRATES="
	eyre@0.6.12
	heck@0.5.0
	indenter@0.3.4
	lazy_static@1.5.0
	libc@0.2.183
	memchr@2.8.0
	nom@8.0.0
	once_cell@1.21.4
	opencc-rust@1.1.19
	pkg-config@0.3.32
	portable-atomic@1.13.1
	proc-macro2@1.0.106
	pyo3@0.28.2
	pyo3-build-config@0.28.2
	pyo3-ffi@0.28.2
	pyo3-macros@0.28.2
	pyo3-macros-backend@0.28.2
	quote@1.0.45
	syn@2.0.117
	target-lexicon@0.13.5
	unicode-ident@1.0.24
"

inherit cargo git-r3 distutils-r1

EGIT_REPO_URI="https://github.com/lilydjwg/luoxu.git"

DESCRIPTION="A Telegram userbot to index Chinese and Japanese group contents"
HOMEPAGE="https://github.com/lilydjwg/luoxu"
SRC_URI="${CARGO_CRATE_URIS}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="-* ~amd64"

RDEPEND="
	acct-group/luoxu
	acct-user/luoxu
	app-i18n/opencc:=
	dev-python/aiohttp[${PYTHON_USEDEP}]
	dev-python/asyncpg[${PYTHON_USEDEP}]
	dev-python/telethon[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-python/setuptools-rust[${PYTHON_USEDEP}]
	virtual/pkgconfig
"

# needs a Telegram account and a configured PostgreSQL database
RESTRICT="test"

PATCHES=(
	# replace the unstable Iterator::intersperse with plain loop code
	# so the extension builds on stable rustc
	"${FILESDIR}"/${PN}-intersperse-stable.patch
)

src_unpack() {
	git-r3_src_unpack
	cargo_src_unpack
}

src_prepare() {
	# pyproject declares a dynamic version without a source; pin it for the live ebuild
	sed -i -e '/^dynamic = /d' -e '/^name = "luoxu"$/a version = "9999"' pyproject.toml || die

	distutils-r1_src_prepare
}

src_install() {
	distutils-r1_src_install

	dodoc config.toml.example dbsetup.sql

	insinto /etc/luoxu
	newins config.toml.example config.toml.example

	# plain helpers instead of the systemd eclass: its name differs
	# between repo snapshots (systemd vs systemd-utils)
	insinto /lib/systemd/system
	doins "${FILESDIR}"/luoxu.service
	newinitd "${FILESDIR}"/luoxu.initd luoxu
	newconfd "${FILESDIR}"/luoxu.confd luoxu
}

pkg_postinst() {
	elog "luoxu is a userbot that indexes Telegram groups with your own account;"
	elog "upstream warns that userbot usage carries a ban risk."
	elog ""
	elog "Setup: create a database with the pgroonga extension, import dbsetup.sql"
	elog "(shipped in /usr/share/doc/${PF}), then create /etc/luoxu/config.toml"
	elog "from config.toml.example and complete the one-time Telegram login for"
	elog "the service user (the session file is created by any Telethon login, e.g."
	elog "with python3 -m luoxu.ls_dialogs from an interactive shell)."
	elog "For the group-list helper and further details see the upstream README."
}
