module V1
  class AdminController < ApplicationController
    def commit
      URIService.solr.connection.commit
      head :no_content
    end
  end
end
