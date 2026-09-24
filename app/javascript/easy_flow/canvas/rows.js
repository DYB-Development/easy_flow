export const amended = (rows, index, name, next) =>
  rows.map((row, at) => (at === index ? { ...row, [name]: next } : row))
