Spree::Taxonomy.class_eval do
  scope :filterable, -> { where(kind: 'filter') }

  def filter_name
    "#{name.downcase}_ids"
  end
end
