import React from "react"

const Explanation = ({ text }) => (
  <span className="text-gray-500 dark:text-gray-400" style={{ display: "block", fontSize: 11, lineHeight: 1.4, marginBottom: 12 }} data-setting-explanation>{text}</span>
)

export default Explanation
