class BlogsController < ApplicationController
  # creating a controller for site wide blogs while we carry on with the redesign work 
  resources_controller_for :posts
  #before_filter :login_required, :except => [:show, :index]

  def index
    @posts = Post.by_network(@current_network).paginate(:page => params[:page], :order => "posts.id desc", :per_page=>10)
    respond_to do |format|
      format.rss do
        render :layout => false
      end
      format.html do
      end
    end
  end

  private

end
