module ShowcaseHelper
  def showcase_evaluate(example)
    example.calls.transform_values { |call| instance_eval(call) }
  end

  def showcase_form
    @showcase_form ||= ActionView::Helpers::FormBuilder.new(:showcase, nil, self, {})
  end

  def showcase_signatures(section)
    Lostcoords::Ui::Builders.all.select { |builder| section.builders.include?(builder.name) }.map(&:signature)
  end
end
