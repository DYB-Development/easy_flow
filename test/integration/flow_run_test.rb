require "test_helper"

module EasyFlow
  class FlowRunTest < ActionDispatch::IntegrationTest
    def flowed
      @flowed ||= Definition.create!(host: "dummy", slug: "flowed").tap do |flow|
        flow.record_definition(flowing(
          "slug" => "flowed", "entry" => "budget",
          "nodes" => [ { "id" => "budget", "type" => "question", "text" => "What is your budget?", "tag" => "money", "required" => true,
                         "options" => [ { "value" => "low", "label" => "Modest", "weight" => 1 },
                                        { "value" => "high", "label" => "Generous", "weight" => 5 } ] },
                       { "id" => "gate", "type" => "condition", "step" => "budget", "output" => "answer", "comparison" => "is", "answer" => "high" },
                       { "id" => "posh", "type" => "question", "text" => "Which premium tier?",
                         "options" => [ { "value" => "a", "weight" => 3 } ] },
                       { "id" => "plain", "type" => "question", "text" => "Which basic tier?",
                         "options" => [ { "value" => "b", "weight" => 1 } ] } ],
          "edges" => [ { "from" => "budget", "to" => "gate" },
                       { "from" => "gate", "to" => "posh", "on" => true },
                       { "from" => "gate", "to" => "plain", "on" => false } ]
        ))
        flow.publish
      end
    end

    def looping
      @looping ||= Definition.create!(host: "dummy", slug: "looping").tap do |flow|
        flow.record_definition(flowing(
          "slug" => "looping", "entry" => "job",
          "nodes" => [ { "id" => "job", "type" => "question", "text" => "Which job?", "options" => [ "mow", "edge" ] },
                       { "id" => "more", "type" => "question", "text" => "Another?", "options" => [ "yes", "no" ] },
                       { "id" => "again", "type" => "condition", "step" => "more", "output" => "answer", "comparison" => "is", "answer" => "yes" },
                       { "id" => "done", "type" => "question", "text" => "Done?", "options" => [ "ok" ] } ],
          "edges" => [ { "from" => "job", "to" => "more" },
                       { "from" => "more", "to" => "again" },
                       { "from" => "again", "to" => "job", "on" => true },
                       { "from" => "again", "to" => "done", "on" => false } ]
        ))
        flow.publish
      end
    end

    test "a flow keeping nothing carries the time the question just answered was answered on to the next step" do
      travel_to(Time.zone.local(2026, 10, 12, 9, 30)) do
        get easy_flow.flow_step_path(flowed.slug), params: { answers: { budget: "high" }, asked: "budget" }
      end

      assert_select "input[type=hidden][name=?][value=?]", "answered_at[budget]", Time.zone.local(2026, 10, 12, 9, 30).iso8601
    end

    test "a flow keeping nothing carries an earlier answer's time on unchanged" do
      get easy_flow.flow_step_path(looping.slug), params: { answers: { job: "mow", more: "no" }, answered_at: { job: "2026-10-12T09:30:00Z" }, asked: "more" }

      assert_select "input[type=hidden][name=?][value=?]", "answered_at[job]", Time.zone.parse("2026-10-12T09:30:00Z").iso8601
    end

    test "a flow keeping nothing drops an answer time it cannot read" do
      get easy_flow.flow_step_path(looping.slug), params: { answers: { job: "mow", more: "no" }, answered_at: { job: "2026-13-45T09:30:00Z" }, asked: "more" }

      assert_select "input[name=?]", "answered_at[job]", count: 0
    end

    test "pressing Back on a flow keeping nothing asks the previous question again" do
      get easy_flow.flow_step_path(flowed.slug), params: { answers: { budget: "high" }, asked: "posh", back: "1" }

      assert_select "input[type=hidden][name=asked][value=?]", "budget"
    end

    test "pressing Back on a flow keeping nothing keeps the answers before the previous question" do
      get easy_flow.flow_step_path(looping.slug), params: { answers: { job: "mow", more: "no" }, asked: "done", back: "1" }

      assert_select "input[type=hidden][name=?][value=?]", "answers[job]", "mow"
    end

    test "a flow keeping nothing carries the answer to a question asked again on to the next step" do
      get easy_flow.flow_step_path(looping.slug), params: { answers: { job: "mow", more: "yes", "job@2": "edge" }, asked: "job@2" }

      assert_select "input[type=hidden][name=?][value=?]", "answers[job@2]", "edge"
    end

    test "a flow keeping a run at the end stores it once the flow finishes" do
      flowed.update!(persists: :on_finish)

      assert_difference -> { Run.count }, 1 do
        get easy_flow.flow_step_path(flowed.slug), params: { answers: { budget: "high", posh: "a" } }
      end
    end

    test "a flow keeping nothing stores no run when it finishes" do
      assert_no_difference -> { Run.count } do
        get easy_flow.flow_step_path(flowed.slug), params: { answers: { budget: "high", posh: "a" } }
      end
    end

    test "a finished flow shows what was said" do
      get easy_flow.flow_step_path(flowed.slug), params: { answers: { budget: "low", plain: "b" } }

      assert_select "[data-answer=?]", "budget"
    end

    test "a visitor can see the intro of a flow" do
      get easy_flow.flow_path(flowed.slug)

      assert_response :success
    end

    test "the intro links into the flow" do
      get easy_flow.flow_path(flowed.slug)

      assert_select "a[href=?]", easy_flow.flow_step_path(flowed.slug)
    end

    test "a visitor is asked the step the flow begins at" do
      get easy_flow.flow_step_path(flowed.slug)

      assert_select "legend", text: /What is your budget\?/
    end

    test "a visitor is offered a labelled choice for each option" do
      get easy_flow.flow_step_path(flowed.slug)

      assert_select "label", text: /Generous/
    end

    test "answering sends the visitor down the branch their answer selects" do
      get easy_flow.flow_step_path(flowed.slug), params: { answers: { budget: "high" } }

      assert_select "legend", text: /Which premium tier\?/
    end

    test "the other answer sends them down the other branch" do
      get easy_flow.flow_step_path(flowed.slug), params: { answers: { budget: "low" } }

      assert_select "legend", text: /Which basic tier\?/
    end

    test "a visitor reaching the end is told the run is complete" do
      get easy_flow.flow_step_path(flowed.slug), params: { answers: { budget: "low", plain: "b" } }

      assert_response :success
    end

    test "a step drawn for a saved session is shown the run it is asked in" do
      flow = Definition.create!(host: "dummy", slug: "for-the-run").tap do |defined|
        defined.record_definition(flowing("slug" => "for-the-run", "entry" => "asked", "nodes" => [ { "id" => "asked", "type" => "for_the_run" } ]))
        defined.publish
      end
      run = Run.start(flow)

      get easy_flow.run_path(run)

      assert_select "[data-drawn-by=notify] p", text: "Asked in run #{run.id}"
    end

    def ticking
      @ticking ||= Definition.create!(host: "dummy", slug: "ticking").tap do |flow|
        flow.record_definition(flowing("slug" => "ticking", "entry" => "conditions",
          "nodes" => [ { "id" => "conditions", "type" => "checklist", "question" => "What must they do?",
                         "answers" => [ { "value" => "proof", "label" => "Shows proof" }, { "value" => "on_time", "label" => "Pays on time" } ] } ]))
        flow.publish
      end
    end

    test "a checklist is drawn as a box to tick for each answer" do
      get easy_flow.run_path(Run.start(ticking))

      assert_equal [ "proof", "on_time" ], css_select("input[type=checkbox][name='answers[conditions][]']").map { |box| box["value"] }
    end

    test "a saved session keeps every answer ticked on a checklist" do
      run = Run.start(ticking)

      patch easy_flow.run_path(run), params: { answers: { conditions: [ "", "proof", "on_time" ] } }

      assert_equal [ "proof", "on_time" ], run.reload.recorded[:conditions]
    end

    test "a question's answer given info shows it behind an info button" do
      flow = Definition.create!(host: "dummy", slug: "explained").tap do |defined|
        defined.record_definition(flowing("slug" => "explained", "entry" => "kind",
          "nodes" => [ { "id" => "kind", "type" => "question", "question" => "Which kind?",
                         "answers" => [ { "value" => "anti", "label" => "Anti-guarantee", "info" => "No refunds, said as a reason to buy" } ] } ]))
        defined.publish
      end

      get easy_flow.run_path(Run.start(flow))

      assert_select ".ks-radio-card-disclosure", text: "No refunds, said as a reason to buy"
    end

    test "a checklist's answer given info shows it behind an info button" do
      flow = Definition.create!(host: "dummy", slug: "explained-checklist").tap do |defined|
        defined.record_definition(flowing("slug" => "explained-checklist", "entry" => "conditions",
          "nodes" => [ { "id" => "conditions", "type" => "checklist", "question" => "What must they do?",
                         "answers" => [ { "value" => "proof", "label" => "Shows proof", "info" => "They send photos of the work" } ] } ]))
        defined.publish
      end

      get easy_flow.run_path(Run.start(flow))

      assert_select ".ks-radio-card-disclosure", text: "They send photos of the work"
    end

    test "a flow keeping nothing carries every answer ticked on a checklist on to the next step" do
      flow = Definition.create!(host: "dummy", slug: "ticking-then-asking").tap do |defined|
        defined.record_definition(flowing("slug" => "ticking-then-asking", "entry" => "conditions",
          "nodes" => [ { "id" => "conditions", "type" => "checklist", "question" => "What must they do?",
                         "answers" => [ { "value" => "proof", "label" => "Shows proof" }, { "value" => "on_time", "label" => "Pays on time" } ] },
                       { "id" => "name", "type" => "question", "question" => "Which name?", "answers" => [ "plain" ] } ],
          "edges" => [ { "from" => "conditions", "to" => "name" } ]))
        defined.publish
      end

      get easy_flow.flow_step_path(flow.slug), params: { answers: { conditions: [ "", "proof", "on_time" ] }, asked: "conditions" }

      assert_equal [ "proof", "on_time" ], css_select("input[type=hidden][name='answers[conditions][]']").map { |field| field["value"] }
    end

    test "a flow keeping nothing moves past a checklist left with nothing ticked" do
      flow = Definition.create!(host: "dummy", slug: "ticking-nothing").tap do |defined|
        defined.record_definition(flowing("slug" => "ticking-nothing", "entry" => "conditions",
          "nodes" => [ { "id" => "conditions", "type" => "checklist", "question" => "What must they do?", "answers" => [ "proof" ] },
                       { "id" => "name", "type" => "question", "question" => "Which name?", "answers" => [ "plain" ] },
                       { "id" => "colour", "type" => "question", "question" => "Which colour?", "answers" => [ "red" ] } ],
          "edges" => [ { "from" => "conditions", "to" => "name" }, { "from" => "name", "to" => "colour" } ]))
        defined.publish
      end
      get easy_flow.flow_step_path(flow.slug), params: { answers: { conditions: [ "" ] }, asked: "conditions" }
      carried = css_select("form input[type=hidden][name^=answers]").map { |field| [ field["name"], field["value"] ] }

      get easy_flow.flow_step_path(flow.slug), params: { answers: carried.group_by(&:first).transform_keys { |name| name[/answers\[(.+?)\]/, 1] }.transform_values { |pairs| pairs.map(&:last) }.merge("name" => "plain"), asked: "name" }

      assert_select "legend", text: /Which colour\?/
    end

    test "a saved session walks the same flow" do
      run = Run.start(flowed)

      patch easy_flow.run_path(run), params: { answers: { budget: "high" } }
      get easy_flow.run_path(run)

      assert_select "legend", text: /Which premium tier\?/
    end

    test "a saved session records the answer against the step that asked it" do
      run = Run.start(flowed)

      patch easy_flow.run_path(run), params: { answers: { budget: "high" } }

      assert_equal({ budget: "high" }, run.reload.recorded)
    end

    test "a visitor runs the published version, not what the author is editing" do
      flow = flowed
      flow.publish
      flow.update!(document: { "slug" => flow.slug, "entry" => "gone", "nodes" => [], "edges" => [] })

      get easy_flow.flow_step_path(flow.slug)

      assert_select "legend", text: /What is your budget\?/
    end

    test "a visitor keeps running the published version after a newer one is created" do
      flow = flowed
      flow.publish
      flow.update!(document: { "slug" => flow.slug, "entry" => "later",
        "nodes" => [ { "id" => "later", "type" => "question", "question" => "Something else?" } ], "edges" => [] })
      flow.create_version

      get easy_flow.flow_step_path(flow.slug)

      assert_select "legend", text: /What is your budget\?/
    end

    test "a visitor cannot start on a version that has been retired" do
      flow = flowed
      flow.retire_version(flow.live_version)

      get easy_flow.flow_step_path(flow.slug)

      assert_response :not_found
    end

    test "a saved session records nothing when the answer is left blank" do
      run = Run.start(flowed)

      patch easy_flow.run_path(run), params: { answers: { budget: "" } }

      assert_empty run.reload.recorded
    end

    test "a visitor is asked the same step again when they leave its answer blank" do
      get easy_flow.flow_step_path(flowed.slug), params: { asked: "budget", answers: { budget: "" } }

      assert_select "legend", text: /What is your budget\?/
    end

    test "a saved session tells the visitor to answer when they leave the answer blank" do
      run = Run.start(flowed)

      patch easy_flow.run_path(run), params: { answers: { budget: "" } }
      follow_redirect!

      assert_match "Fill this in to go on.", response.body
    end

    test "a visitor is told to answer when they leave a step's answer blank" do
      get easy_flow.flow_step_path(flowed.slug), params: { asked: "budget" }

      assert_match "Fill this in to go on.", response.body
    end

    test "a saved session records a blank answer to a step that is not required and moves on" do
      run = Run.start(flowed)

      patch easy_flow.run_path(run), params: { answers: { budget: "high" } }
      patch easy_flow.run_path(run), params: { answers: { posh: "" } }

      assert_equal({ budget: "high", posh: "" }, run.reload.recorded)
    end

    test "a saved session records nothing when nothing is chosen on a required step" do
      run = Run.start(flowed)

      patch easy_flow.run_path(run), params: { asked: "budget" }

      assert_empty run.reload.recorded
    end

    test "a visitor moves on when they leave a step that is not required blank" do
      flowed.update!(persists: :on_finish)

      assert_difference -> { Run.count }, 1 do
        get easy_flow.flow_step_path(flowed.slug), params: { asked: "plain", answers: { budget: "low" } }
      end
    end
  end
end
