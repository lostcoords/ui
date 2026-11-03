require "test_helper"

module Lostcoords::Ui
  class FormBuilderTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.view_context
    end

    def fragment(html) = Nokogiri::HTML.fragment(html)

    def form(project = DocsProject.invalid_example, &block)
      fragment(@view.lc_form_with(model: project, url: "/projects", &block))
    end

    test "fields read the model's errors and connect them to the control" do
      html = form { |f| f.field(:name, hint: "Shown to members") }
      input = html.at_css("input#docs_project_name")
      assert_equal "docs_project[name]", input["name"]
      assert_equal "true", input["aria-invalid"]
      assert_equal "docs_project_name-hint docs_project_name-error", input["aria-describedby"]
      assert_equal "Name can't be blank", html.at_css("[data-slot=field-error]").text
      assert_equal "Name", html.at_css("label[for=docs_project_name]").text
      assert_nil html.at_css(".field_with_errors:not(:has([data-slot]))")
    end

    test "valid attributes are not marked invalid" do
      html = form { |f| f.field(:email, as: :email_field) }
      input = html.at_css("input[type=email]")
      assert_nil input["aria-invalid"]
      assert_equal "team@example.com", input["value"]
      assert_nil html.at_css("[data-slot=field-error]")
    end

    test "controls use library classes and symbol sizes" do
      html = form { |f| @view.safe_join([ f.text_field(:name, size: :sm), f.text_field(:email, size: 20), f.submit("Save", variant: :secondary) ]) }
      small, sized = html.css("input[type=text], input[type=email]")
      assert_includes small["class"].split, "h-control-sm"
      assert_nil small["size"]
      assert_equal "20", sized["size"]
      assert_includes sized["class"].split, "h-control-md"
      submit = html.at_css("input[type=submit]")
      assert_equal "Save", submit["value"]
    end

    test "switches render a labelled checkbox with an unchecked value" do
      html = form { |f| f.switch(:public, hint: "Anyone can view") }
      switch = html.at_css("input[role=switch][type=checkbox]")
      assert_equal "docs_project[public]", switch["name"]
      assert switch["checked"]
      assert_equal "0", html.at_css("input[type=hidden][name='docs_project[public]']")["value"]
      assert_equal "docs_project_public", html.at_css("label[data-slot=switch]")["for"]
    end

    test "custom field blocks receive control attributes" do
      html = form { |f| f.field(:name) { |control| f.text_area(:name, **control.to_hash.except(:id)) } }
      assert_equal "true", html.at_css("textarea")["aria-invalid"]
    end
  end
end
