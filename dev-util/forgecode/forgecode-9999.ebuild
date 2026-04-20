# Copyright 2026 Gentoo Authors
# Copyright 2026 psj
# Distributed under the terms of the GNU General Public License v2

# Live ebuild tracking HEAD of tailcallhq/forgecode

EAPI=8

# Eclasses to inherit from
# you can set EGIT_COMMIT=hash
inherit cargo git-r3

# Meta data for emerge and eix etc.
DESCRIPTION="Model-agnostic AI coding agent"
HOMEPAGE="https://forgecode.dev https://github.com/tailcallhq/forgecode"
EGIT_REPO_URI="https://github.com/tailcallhq/forgecode.git"

LICENSE="Apache-2.0"
# Dependent crate licenses
# approximated from versioned ebuild; may drift with HEAD
LICENSE+=" Apache-2.0 BSD Boost-1.0 CC0-1.0 CDLA-Permissive-2.0 GPL-3+ ISC MIT MPL-2.0 Unicode-3.0 ZLIB"

# just one slot
SLOT="0"

# No keywords for live ebuilds
KEYWORDS=""

# Upstream enables telemetry by default; this flag allows opting in.
# See: https://github.com/tailcallhq/forgecode (FORGE_TRACKER env var)
IUSE="telemetry"

BDEPEND="dev-libs/protobuf"

# NOTE(psj): as far as I know the gentoo eco system does not have some way to
# inform people of build instructions so putting it here... let me know if that
# is not the way it is supposed to go.
pkg_pretend() {
	elog "To build a specific git commit instead of HEAD, set EGIT_COMMIT:"
	elog "  EGIT_COMMIT=<hash> emerge dev-util/forgecode"
	elog "Or persistently via /etc/portage/env/"
}

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

src_install() {
	cargo_src_install --path crates/forge_main

	# install env.d file to disable telemetry unless the use flag is set
	if ! use telemetry; then
		echo "FORGE_TRACKER=false" > "${T}/99forgecode"
		doenvd "${T}/99forgecode"
	fi
}

pkg_postinst() {
	# Warn the user if telemetry was enabled
	if use telemetry; then
		ewarn "Telemetry is enabled. ForgeCode will send usage data including"
		ewarn "git user emails and SSH directory information to upstream."
		ewarn "Rebuild with USE=-telemetry to disable."
	fi
}
