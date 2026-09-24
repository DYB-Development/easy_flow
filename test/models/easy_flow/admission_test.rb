require "test_helper"

module EasyFlow
  class AdmissionTest < ActiveSupport::TestCase
    def published
      easy_flow_definitions(:db_guide)
    end

    test "it refuses a flow with nothing published as unpublished" do
      unpublished = Definition.create!(host: "dummy", slug: "nothing-published")

      assert_raises(NotPublished) { Admission.of(unpublished, permitted: true) }
    end

    test "it refuses a visitor the host declined as not permitted" do
      assert_raises(NotPermitted) { Admission.of(published, permitted: false) }
    end

    test "it returns the flow when it is published and permitted" do
      assert_equal published, Admission.of(published, permitted: true)
    end

    test "it stops a run whose version was withdrawn" do
      run = Run.start(published)
      run.definition_version.update!(status: :withdrawn)

      assert_raises(Withdrawn) { Admission.of_run(run) }
    end

    test "it lets a run on a superseded version carry on" do
      run = Run.start(published)
      run.definition_version.update!(status: :superseded)

      assert_equal run, Admission.of_run(run)
    end

    test "it lets a run on a retired version carry on" do
      run = Run.start(published)
      run.definition_version.update!(status: :retired)

      assert_equal run, Admission.of_run(run)
    end

    test "it refuses a visitor when the flow is inactive" do
      published.update!(status: :inactive)

      assert_raises(NotPermitted) { Admission.of(published, permitted: true) }
    end

    test "it stops a run under way when the flow is inactive" do
      run = Run.start(published)
      published.update!(status: :inactive)

      assert_raises(NotPermitted) { Admission.of_run(run) }
    end

    test "it admits a visitor with the link when the flow is hidden" do
      published.update!(status: :hidden)

      assert_equal published, Admission.of(published, permitted: true)
    end

    test "it lets a run carry on when the flow is hidden" do
      run = Run.start(published)
      published.update!(status: :hidden)

      assert_equal run, Admission.of_run(run)
    end
  end
end
