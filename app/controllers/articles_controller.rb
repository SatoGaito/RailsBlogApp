class ArticlesController < ApplicationController

  before_action :move_to_login, only: [:new, :create, :edit, :update, :destroy]
  before_action :ensure_correct_user, only: [:destroy, :edit, :update]
  before_action :set_ranking_data, only: [:index, :show]

  def index
    @articles = Article.all.order(created_at: :desc)
  end

  def new
  end

  def create
    article = Article.create(title: article_params[:title], content: article_params[:content], user_id: current_user.id)
    redirect_to ("/articles/#{article.id}")
  end

  def show
    @article = Article.find(params[:id])

    @pv = REDIS.incr "/articles/#{@article.id}" 
    @pv_num = REDIS.zincrby "/articles/", 1, "#{@article.id}"
  end

  def edit
    @article = Article.find(params[:id])
  end

  def update
    article = Article.find(params[:id])
    article.update(article_params)
    redirect_to ("/articles/#{article.id}")
  end

  def destroy
    @article = Article.find(params[:id])
    @article.destroy 
    REDIS.zrem "/articles/", "#{@article.id}"
    REDIS.del "/articles/#{@article.id}"
    redirect_to("/")
  end

  def set_ranking_data
    @ids = REDIS.zrevrange "/articles/", 0, 2
    @ranking_articles = @ids.map{ |id| Article.find(id) }
  #   # if @ranking_articles.count < 3
  #   #   adding_articles = Article.order(publish_time: :DESC, updated_at: :DESC).where.not(id: @ids).limit(3 - @ranking_articles.count)
  #   #   @ranking_articles.concat(adding_articles)
  #   # end
  end

  private
  def article_params
    params.require(:article).permit(:title, :content)
  end

  def move_to_login
    unless user_signed_in?
      redirect_to("/users/sign_in") 
      flash[:notice] = "ログインしてください"
    end
  end

  def ensure_correct_user
    article = Article.find(params[:id])
    if current_user.id != article.user_id
      flash[:notice] = "権限がありません"
      redirect_to ("/")
    end
  end



end
