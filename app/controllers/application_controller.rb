class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :get_current_user_avator, :get_current_user_id, :is_logged_in

  # "https://enpit-tascal.herokuapp.com/herokuapp.com" から "https://tascal.app" にリダイレクト
  before_action :ensure_domain
  def ensure_domain
    return unless /\.herokuapp.com/ =~ request.host

    fqdn = 'tascal.app'

    # 主にlocalテスト用の対策80と443以外でアクセスされた場合ポート番号をURLに含める
    port = ":#{request.port}" unless [80, 443].include?(request.port)
    redirect_to "#{request.protocol}#{fqdn}#{port}#{request.path}", status: :moved_permanently
  end

  private
  def get_current_user_avator
    if current_user then
      current_user.avatar_url
    else
      nil
    end
  end

  private
  def get_current_user_id
    if current_user then
      current_user.email
    else
      nil
    end
  end

end