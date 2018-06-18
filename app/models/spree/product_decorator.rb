Spree::Product.class_eval do

  if ActiveRecord::Base.connection.table_exists? 'spree_property_translations'
    searchkick ({
      index_prefix: Rails.configuration.elasticsearch_index_name.nil? ? "" : Rails.configuration.elasticsearch_index_name,
      callbacks: :async,
      word_start: ([:name] << Spree::Property.all.map { |prop| prop.name.downcase.to_sym}).flatten!,
      searchable: ([:name, :format_ref, :ref_code, :barcode, :sku] << Spree::Property.all.map { |prop| prop.name.downcase.to_sym}).flatten!,
      settings: ({ number_of_replicas: 0 } unless respond_to?(:searchkick_index))
    })
  end

  def self.autocomplete_fields
    [:name]
  end

  def self.search_fields
    [:name]
  end

  def search_data
    json = {
      id: id,
      name: name,
      barcode: master.barcode,
      ref_code: ref_code,
      format_ref: format_ref,
      available_for_free: available_for_free,
      sku: master.sku,
      active: available?,
      created_at: created_at,
      role_prices: variants.map {|v| v.role_prices.map { |p| {amount: p.amount, role_id: p.spree_role_id} } }.flatten(1),
      role_prices_role_ids: variants.map {|v| v.role_prices.map(&:spree_role_id) }.flatten(1),
      taxon_ids: taxon_and_ancestors.map(&:id),
      store_ids: store_ids
    }

    Spree::Property.all.each do |prop|
      json.merge!(Hash[prop.name.downcase, property(prop.name)])
    end

    Spree::Taxonomy.all.each do |taxonomy|
      json.merge!(Hash["#{taxonomy.name.downcase}_ids", taxon_by_taxonomy(taxonomy.id).map(&:id)])
    end

    json
  end

  def taxon_by_taxonomy(taxonomy_id)
    taxons.joins(:taxonomy).where(spree_taxonomies: { id: taxonomy_id })
  end

  def self.autocomplete(keywords)
    if keywords
      Spree::Product.search(
        keywords,
        fields: autocomplete_fields,
        match: :word_start,
        limit: 10,
        load: false,
        misspellings: { below: 3 },
        where: search_where
      ).map(&:name).map(&:strip).uniq
    else
      Spree::Product.search(
        '*',
        fields: autocomplete_fields,
        load: false,
        misspellings: { below: 3 },
        where: search_where
      ).map(&:name).map(&:strip)
    end
  end

  def self.search_where
    {
      active: true,
      price: { not: nil }
    }
  end
end
