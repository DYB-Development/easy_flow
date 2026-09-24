export const standing = ({ version, published }) => {
  if (!version) return "No version yet"
  if (!published) return `Version ${version} · never published`
  if (published === version) return `Version ${version} · live`

  return `Version ${version} · visitors still on ${published}`
}
