class PostsController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource :comment, :parent => false
  before_filter :load_requested_or_users_startup

  def index
    connection_ids = current_user.startup.second_degree_connection_ids
    connection_ids << current_user.startup_id
    # Load all comments from this person's 1st and 2nd degree connections, as well as all original posts if these are reposts
    # Groups by original id so we don't get dupes from shares
    @comments = Comment.posts.where(:startup_id => connection_ids).includes(:original).group('comments.original_id').limit(30).order('updated_at DESC').all
    @hottest_post = Comment.hottest_post_for_time(Time.now)
  end

  def show
    authorize! :read_post, Comment
    @comments = @comment.children.includes(:user).arrange(:order => 'created_at DESC') # arrange in nested order
  end

  def repost
    original = Comment.find(params[:id])
    repost = original.repost_by(current_user)
    @success = true if repost.errors.blank?
    respond_to do |format|
      format.js
    end
  end
end
