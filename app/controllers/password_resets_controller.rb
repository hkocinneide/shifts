class PasswordResetsController < ApplicationController
  before_filter :load_user_using_perishable_token, :only => [:edit, :update]
  before_filter :require_no_user, :only => [:edit, :update]
  skip_before_filter :login_or_register
  skip_before_filter CASClient::Frameworks::Rails::Filter, :if => Proc.new{|s| s.using_CAS?}


  def new
    render
  end

  def create
    @user = User.find_by_email(params[:email])
    if @user && @user.auth_type=='authlogic'
      @user.deliver_password_reset_instructions!
      flash[:notice] = "Instructions to reset the password have been emailed. "
      redirect_to @user
    else
      flash[:notice] = "No user using authlogic was found with that email address"
      render :action => :new
    end
  end

  def edit
    render
  end

  def update
    @user.login = params[:user][:login]
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    if @user.save
      flash[:notice] = "Password successfully updated"
      redirect_to login_path
    else
      render :action => :edit
    end
  end

private
  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id])
    unless @user
      flash[:notice] = "We're sorry, but we could not locate your account. " +
      "If you are having issues try copying and pasting the URL " +
      "from your email into your browser or restarting the " +
      "reset password process."
      redirect_to root_url
    end
  end
  def require_no_user
    if current_user
      flash[:notice] = "You\'re logged in. Someone resetting their password shouldn\'t be logged in, you hacker."
      redirect_to root_url
    end

  end
end