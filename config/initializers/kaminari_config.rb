# frozen_string_literal: true

Kaminari.configure do |config|
  config.default_per_page = URIService::DEFAULT_PER_PAGE
  config.max_per_page = URIService::MAX_PER_PAGE
  # config.window = 4
  # config.outer_window = 0
  # config.left = 0
  # config.right = 0
  # config.page_method_name = :page
  # config.param_name = :page
  # config.params_on_first_page = false
end