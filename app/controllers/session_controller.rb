class SessionController < ApplicationController
  skip_before_action :authenticate, only: [:signin, :signup]

  def signin
    user = User.find_by(email: params[:email]).try(:authenticate, params[:password])

    if user
      session[:user_id] = user.id
      flash[:notice] = 'You have signed in!'
    else
      session[:user_id] = nil
      flash[:error] = 'Unable to login with those credentials.'
    end
    redirect_to root_path
  end

  def signout
    session[:user_id] = nil
    flash[:warning] = 'You have successfully signed out.'
    redirect_to root_path
  end

  def signup
    if request.post?
      user = User.new( email: params[:email],
                       password: params[:password]
                     )
      if user.save
        if params[:remember]
          session[:user_id] = user.id
        end
        flash[:notice] = 'You have successfully signed up!'
      else
        flash[:warning] = "We were unable to sign you up. #{user.errors.full_messages.join('. ')}."
      end
      redirect_to root_path
    end
  end

end
