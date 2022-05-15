#!/usr/bin/bash

IMAGES=(
'ghcr.io/tap8stry/executor:v1.5.1@sha256:c812530c2ea981d3316c7544b180289abfbd9adf1dde6f1345692b8fb0a65cb0'
'ghcr.io/tap8stry/imagedigestexporter:v0.16.2@sha256:542d437868a0168f0771d840233110fbf860b210b0e9becce5d75628c694b958'
'ghcr.io/tap8stry/jq:latest@sha256:3d349004b4332571a9a14acf8c26088c7d289cf6a6d69ada982001a8779d2bbf'
'ghcr.io/tap8stry/cosign:1.7.2@sha256:7843ede52ccd61a9883fd90bbb51f69944b6892fcaf651c35580b69be6699c6f'
'ghcr.io/tap8stry/git-init:v0.21.0@sha256:322e3502c1e6fba5f1869efb55cfd998a3679e073840d33eb0e3c482b5d5609b'
'ghcr.io/tap8stry/alpine:latest@sha256:69704ef328d05a9f806b6b8502915e6a0a4faa4d72018dc42343f511490daf8a'
'ghcr.io/tap8stry/k8s-kubectl:latest@sha256:00e810f695528eb20ce91ce11346ef2ba59f1ea4fafc0d0d44101e63991d1567'
'ghcr.io/tap8stry/syft:v0.27.0@sha256:c03549c863ccc4c60e795d7299624bb7e686248c537adff4246b8031904c7743'
'ghcr.io/tap8stry/bash:latest@sha256:b69c5fe80a41b5c9053db41c81074dd894bbb47bf292e5763d053440eddaafdc'
'ghcr.io/tap8stry/anchore-grype:0.23@sha256:0e948bb5e7534c2191d2877352e52a317dc91e52192e8723749bf7ff018168da'
)

NAMES=(
'executor' 
'imagedigestexporter' 
'jq'
'cosign'
'git-init'
'alpine'
'k8s-kubectl'
'syft'
'bash'
'anchore-grype'
)


declare -i i=0

while [ "${IMAGES[i]}" -a "${NAMES[i]}" ]; do
    echo "scanning ${IMAGES[i]}"
    grype "${IMAGES[i]}" -o json > "scan-${NAMES[i]}.json"
    echo "creating attestation https://grype.anchore.io/scan for ${NAMES[i]}"
    cosign attest "${IMAGES[i]}" --predicate "scan-${NAMES[i]}.json" --type "https://grype.anchore.io/scan" --key ../keys/cosign.key
    echo "creating SBOM for ${IMAGES[i]}"
    syft "${IMAGES[i]}" -o cyclonedx-json > "scan-${NAMES[i]}.json"
    echo "creating attestation https://cyclonedx.org/BOM/v1 for ${NAMES[i]}"
    cosign attest "${IMAGES[i]}" --predicate "sbom-${NAMES[i]}.json"  --type "https://cyclonedx.org/BOM/v1" --key ../keys/cosign.key
    echo "\n"
    ((i++))
done

exit 0
