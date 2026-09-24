module EasyFlow
  class EditHistory
    def initialize(flow)
      @flow = flow
    end

    def undoable?
      undoable.any?
    end

    def redoable?
      undone.any?
    end

    def undoable
      @flow.undo_history.to_a + @flow.changes_since_version.to_a
    end

    def undo_change
      undone_change = undoable.last
      return unless undone_change

      @flow.update!(document: undone_change["before"],
        undone_changes: undone + [ undone_change.merge("after" => @flow.document) ],
        undo_history: @flow.undo_history.to_a[0...-1],
        changes_since_version: @flow.changes_since_version.to_a[0...-1])
    end

    def redo_change
      redone = undone.last
      return unless redone

      @flow.update!(document: redone["after"], undone_changes: undone[0...-1],
        changes_since_version: @flow.changes_since_version.to_a + [ redone.except("after") ])
    end

    def record(edited, action, steps, before)
      @flow.update!(document: edited.to_h, undone_changes: [],
        changes_since_version: with(edited, action, steps, before))
    end

    def edit_document(payload)
      @flow.update!(document: payload, undone_changes: [],
        changes_since_version: @flow.changes_since_version.to_a + [ edited_by_hand ])
    end

    private

    def with(edited, action, steps, before)
      return @flow.changes_since_version.to_a unless action

      @flow.changes_since_version.to_a +
        [ { "action" => action.to_s, "steps" => steps.map(&:to_s),
            "named" => steps.map { |id| named(edited, id) }, "before" => before } ]
    end

    def named(edited, id)
      Name.of(edited.node(id.to_s) || document.node(id.to_s))
    end

    def document
      Document.new(@flow.document || @flow.definition || {})
    end

    def undone
      @flow.undone_changes.to_a
    end

    def edited_by_hand
      { "action" => "edited", "steps" => [], "named" => [ "the definition" ], "before" => @flow.document }
    end
  end
end
