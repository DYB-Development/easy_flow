import { transform } from "esbuild"
import { readFile } from "node:fs/promises"
import { existsSync } from "node:fs"
import { fileURLToPath, pathToFileURL } from "node:url"
import { dirname, resolve as join } from "node:path"

const EXTENSIONS = [ ".js", ".jsx" ]

export const resolve = async (specifier, context, next) => {
  if (specifier.startsWith(".") && context.parentURL?.startsWith("file:")) {
    const from = dirname(fileURLToPath(context.parentURL))
    const found = EXTENSIONS.map((each) => join(from, specifier + each)).find(existsSync)

    if (found) return { url: pathToFileURL(found).href, shortCircuit: true }
  }

  return next(specifier, context)
}

export const load = async (url, context, next) => {
  if (!url.endsWith(".jsx")) return next(url, context)

  const source = await readFile(fileURLToPath(url), "utf8")
  const { code } = await transform(source, { loader: "jsx", format: "esm", target: "es2020" })

  return { format: "module", source: code, shortCircuit: true }
}
