require 'spree_core'
require 'spree_searchkick/engine'
module Searchkick
  class Query  
    def set_aggregations(payload)
      aggs = options[:aggs]
      payload[:aggs] = {}

      aggs = Hash[aggs.map { |f| [f, {}] }] if aggs.is_a?(Array) # convert to more advanced syntax

      aggs.each do |field, agg_options|
        size = agg_options[:limit] ? agg_options[:limit] : 1_000
        shared_agg_options = agg_options.slice(:order, :min_doc_count)

        if agg_options[:ranges]
          payload[:aggs][field] = {
            range: {
              field: agg_options[:field] || field,
              ranges: agg_options[:ranges]
            }.merge(shared_agg_options)
          }
        elsif agg_options[:date_ranges]
          payload[:aggs][field] = {
            date_range: {
              field: agg_options[:field] || field,
              ranges: agg_options[:date_ranges]
            }.merge(shared_agg_options)
          }
        elsif agg_options[:max]
          payload[:aggs][field] = {
            max: {
              field: agg_options[:field] || field
            }.merge(shared_agg_options)
          }
        elsif agg_options[:min]
          payload[:aggs][field] = {
            min: {
              field: agg_options[:field] || field
            }.merge(shared_agg_options)
          }
        elsif histogram = agg_options[:date_histogram]
          interval = histogram[:interval]
          payload[:aggs][field] = {
            date_histogram: {
              field: histogram[:field],
              interval: interval
            }
          }
        else
          payload[:aggs][field] = {
            terms: {
              field: agg_options[:field] || field,
              size: size
            }.merge(shared_agg_options)
          }
        end

        where = {}
        where = (options[:where] || {}).reject { |k| k == field } unless options[:smart_aggs] == false
        agg_filters = where_filters(where.merge(agg_options[:where] || {}))
        if agg_filters.any?
          payload[:aggs][field] = {
            filter: {
              bool: {
                must: agg_filters
              }
            },
            aggs: {
              field => payload[:aggs][field]
            }
          }
        end
      end
    end
  end
end
