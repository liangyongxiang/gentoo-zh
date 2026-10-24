# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

POSTGRES_COMPAT=( 14 15 16 17 18 )
POSTGRES_USEDEP="server"

inherit postgres-multi meson

DESCRIPTION="Full-text search extension for PostgreSQL usable with all languages"
HOMEPAGE="https://pgroonga.github.io/"
SRC_URI="https://github.com/pgroonga/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="POSTGRESQL"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+msgpack"
REQUIRED_USE="${POSTGRES_REQ_USE}"

DEPEND="
	>=app-text/groonga-14.1.0
	dev-libs/xxhash
	${POSTGRES_DEP}
	msgpack? ( dev-libs/msgpack:= )
"
RDEPEND="${DEPEND}"

# Needs a running PostgreSQL server with pg_regress
RESTRICT="test"

pg_configure() {
	# multibuild's BUILD_DIR is a copy of the source tree; meson needs a separate dir
	local BUILD_DIR="${BUILD_DIR}-build"
	local emesonargs=(
		-Dpg_config="${PG_CONFIG}"
		-Dmessage_pack=$(usex msgpack enabled disabled)
		-Dxxhash=enabled
		-Dtest=false
	)
	meson_src_configure
}

src_configure() {
	postgres-multi_foreach pg_configure
}

pg_compile() {
	local BUILD_DIR="${BUILD_DIR}-build"
	meson_src_compile
}

src_compile() {
	postgres-multi_foreach pg_compile
}

pg_install() {
	local BUILD_DIR="${BUILD_DIR}-build"
	meson_src_install
}

src_install() {
	postgres-multi_foreach pg_install
}
