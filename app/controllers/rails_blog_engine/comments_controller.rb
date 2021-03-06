module RailsBlogEngine
  class CommentsController < RailsBlogEngine::ApplicationController
    before_filter :load_post

    load_and_authorize_resource :class => "RailsBlogEngine::Comment"
    skip_load_resource :create

    def create
      @comment = @post.comments.create(params[:comment]) do |c|
        # Record some extra information from our environment.  Most of this
        # is used by the spam filter.
        c.author_ip = request.remote_ip
        c.author_user_agent = request.env['HTTP_USER_AGENT']
        c.author_can_post = can?(:create, RailsBlogEngine::Post)
        c.referrer = request.env['HTTP_REFERER']
      end

      if @comment.valid?
        @comment.run_spam_filter
        if @comment.filtered_as_spam?
          flash[:comment_notice] = "Your comment has been held for moderation."
          redirect_to(post_permalink_path(@post) + '#comment-flash')
        else
          redirect_to(post_permalink_path(@post) + "#comment-#{@comment.id}")
        end
      else
        render "new"
      end
    end

    def mark_as_spam
      @comment.mark_as_spam!
      redirect_to(post_permalink_path(@post) + "#comment-#{@comment.id}")
    end

    def mark_as_ham
      @comment.mark_as_ham!
      redirect_to(post_permalink_path(@post) + "#comment-#{@comment.id}")
    end

    protected

    def load_post
      @post = Post.find(params[:post_id])
    end
  end
end
