require "active_support/core_ext/module/delegation"
require "active_support/core_ext/object/blank"

module Administrate
  class Search
    def initialize(scoped_resource, dashboard_class, term)
      @dashboard_class = dashboard_class
      @scoped_resource = scoped_resource
      @term = term
    end

    def run
      if @term.blank?
        dashboard_model.all
      else
        dashboard_model.where(query, *search_terms)
      end
    end

    private

    def dashboard_model
      if @scoped_resource.respond_to?(:translates?) &&
         @scoped_resource.translates?
        @scoped_resource.with_translations(I18n.locale)
      else
        @scoped_resource
      end
    end

    def query
      search_attributes.map do |attr|
        table_name = ActiveRecord::Base.connection.
          quote_table_name(@scoped_resource.table_name)
        attr_name = ActiveRecord::Base.connection.quote_column_name(attr)
        "lower(#{table_name}.#{attr_name}) LIKE ?"
      end.join(" OR ")
    end

    def search_terms
      ["%#{term.mb_chars.downcase}%"] * search_attributes.count
    end

    def search_attributes
      attribute_types.keys.select do |attribute|
        attribute_types[attribute].searchable?
      end
    end

    def attribute_types
      @dashboard_class::ATTRIBUTE_TYPES
    end

    attr_reader :resolver, :term
  end
end
