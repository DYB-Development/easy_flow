export const readingOrder = (nodes) => [ ...nodes ].sort((a, b) => a.row - b.row)
