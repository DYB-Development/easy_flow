module EasyFlow
  module Change
    PHRASING = { "added" => "Added", "updated" => "Updated", "removed" => "Removed",
                 "moved" => "Moved", "connected" => "Connected", "disconnected" => "Disconnected", "returned" => "Returned to" }.freeze

    def self.phrase(change)
      named = Array(change["named"]).compact_blank.map { |name| "“#{name}”" }
      verb = PHRASING.fetch(change["action"], change["action"])

      return "#{verb} #{named.join(' → ')}" if named.any?
      return "#{verb} #{change['detail']}" if change["detail"].present?

      verb
    end
  end
end
