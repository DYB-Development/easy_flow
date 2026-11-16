import React from "react"

const Joint = ({ link }) => (
  <div data-joint={link?.id} className="relative h-7 w-full sm:h-auto sm:w-7 sm:self-stretch">
    {link && <div className="absolute left-1/2 top-0 h-full w-px bg-gray-400 sm:left-0 sm:top-1/2 sm:h-px sm:w-full dark:bg-zinc-500" />}
  </div>
)

export default Joint
