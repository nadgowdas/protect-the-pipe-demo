#/usr/bin/bash

syft -o cyclonedx-json --file sbom.json ghcr.io/tap8stry/cosign@sha256:7843ede52ccd61a9883fd90bbb51f69944b6892fcaf651c35580b69be6699c6f
grype -o json --file vulnerability.json ghcr.io/tap8stry/cosign@sha256:7843ede52ccd61a9883fd90bbb51f69944b6892fcaf651c35580b69be6699c6f
cosign attest --key ../cosign.key --force --predicate vulnerability.json --type vuln ghcr.io/tap8stry/cosign@sha256:7843ede52ccd61a9883fd90bbb51f69944b6892fcaf651c35580b69be6699c6f
cosign attest --key ../cosign.key --force --predicate sbom.json --type https://cyclonedx.org/BOM/v1 ghcr.io/tap8stry/cosign@sha256:7843ede52ccd61a9883fd90bbb51f69944b6892fcaf651c35580b69be6699c6f


syft -o cyclonedx-json --file sbom.json ghcr.io/tap8stry/alpine@sha256:69704ef328d05a9f806b6b8502915e6a0a4faa4d72018dc42343f511490daf8a
grype -o json --file vulnerability.json ghcr.io/tap8stry/alpine@sha256:69704ef328d05a9f806b6b8502915e6a0a4faa4d72018dc42343f511490daf8a
cosign attest --key ../cosign.key --force --predicate vulnerability.json --type vuln ghcr.io/tap8stry/alpine@sha256:69704ef328d05a9f806b6b8502915e6a0a4faa4d72018dc42343f511490daf8a
cosign attest --key ../cosign.key --force --predicate sbom.json --type https://cyclonedx.org/BOM/v1 ghcr.io/tap8stry/alpine@sha256:69704ef328d05a9f806b6b8502915e6a0a4faa4d72018dc42343f511490daf8a


syft -o cyclonedx-json --file sbom.json ghcr.io/tap8stry/syft@sha256:c03549c863ccc4c60e795d7299624bb7e686248c537adff4246b8031904c7743
grype -o json --file vulnerability.json ghcr.io/tap8stry/syft@sha256:c03549c863ccc4c60e795d7299624bb7e686248c537adff4246b8031904c7743
cosign attest --key ../cosign.key --force --predicate vulnerability.json --type vuln ghcr.io/tap8stry/syft@sha256:c03549c863ccc4c60e795d7299624bb7e686248c537adff4246b8031904c7743
cosign attest --key ../cosign.key --force --predicate sbom.json --type https://cyclonedx.org/BOM/v1 ghcr.io/tap8stry/syft@sha256:c03549c863ccc4c60e795d7299624bb7e686248c537adff4246b8031904c7743

syft -o cyclonedx-json --file sbom.json ghcr.io/tap8stry/executor@sha256:c812530c2ea981d3316c7544b180289abfbd9adf1dde6f1345692b8fb0a65cb0
grype -o json --file vulnerability.json ghcr.io/tap8stry/executor@sha256:c812530c2ea981d3316c7544b180289abfbd9adf1dde6f1345692b8fb0a65cb0
cosign attest --key ../cosign.key --force --predicate vulnerability.json --type vuln ghcr.io/tap8stry/executor@sha256:c812530c2ea981d3316c7544b180289abfbd9adf1dde6f1345692b8fb0a65cb0
cosign attest --key ../cosign.key --force --predicate sbom.json --type https://cyclonedx.org/BOM/v1 ghcr.io/tap8stry/executor@sha256:c812530c2ea981d3316c7544b180289abfbd9adf1dde6f1345692b8fb0a65cb0
