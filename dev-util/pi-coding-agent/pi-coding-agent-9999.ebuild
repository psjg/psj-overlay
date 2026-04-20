# Copyright 2026 Gentoo Authors
# Copyright 2026 psj
# Distributed under the terms of the GNU General Public License v2

# Live ebuild tracking HEAD of badlogic/pi-mono

EAPI=8

inherit git-r3

DESCRIPTION="Minimal terminal coding agent"
HOMEPAGE="https://shittycodingagent.ai https://github.com/badlogic/pi-mono"
EGIT_REPO_URI="https://github.com/badlogic/pi-mono.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""

BDEPEND=">=net-libs/nodejs-20.6.0[npm]"

# generate-models in packages/ai fetches live model lists from models.dev,
# OpenRouter, and Vercel AI Gateway at build time.
RESTRICT="network-sandbox"

pkg_pretend() {
	elog "To build a specific tag instead of HEAD, set EGIT_COMMIT:"
	elog "  EGIT_COMMIT=v0.67.68 emerge dev-util/pi-coding-agent"
	elog "Or persistently via /etc/portage/env/"
	ewarn "This ebuild requires network access during src_compile (model list generation)."
}

src_unpack() {
	git-r3_src_unpack
}

src_compile() {
	cd "${S}" || die
	npm install || die "npm install failed"
	npm run build || die "npm run build failed"
}

src_install() {
	local pkgdir="/usr/lib/node_modules/@mariozechner/pi-coding-agent"

	# tsgo bundles all workspace deps — only dist/ needed at runtime
	insinto "${pkgdir}"
	doins -r packages/coding-agent/dist/
	doins packages/coding-agent/package.json
	doins -r node_modules/

    # Replace dangling workspace symlinks with actual built dist/
    for pkg in ai tui agent; do
        local name
        case ${pkg} in
            ai) name="pi-ai" ;;
            tui) name="pi-tui" ;;
            agent) name="pi-agent-core" ;;
        esac
        rm -f "${ED}${pkgdir}/node_modules/@mariozechner/${name}" || die
        insinto "${pkgdir}/node_modules/@mariozechner/${name}"
        doins "packages/${pkg}/package.json"
        doins -r "packages/${pkg}/dist/"
    done

	# Wrapper script
	cat > "${T}/pi" <<-EOF
	#!/bin/sh
	exec node "${pkgdir}/dist/cli.js" "\$@"
	EOF
	chmod +x "${T}/pi" || die
	dobin "${T}/pi"
}
