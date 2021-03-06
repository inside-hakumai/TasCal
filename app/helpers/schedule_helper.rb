module ScheduleHelper

  def get_available_schedules
    if user_signed_in? then
      Schedule.where(:user_id => current_user.email)
    else
      Schedule.where(:user_id => nil)
    end
  end

  
  def notify_affected_tasks
    unless @affected_tasks.empty?
      root = Nokogiri::HTML::DocumentFragment.parse('')
      Nokogiri::HTML::Builder.with(root) do |t|
        t.div class: 'notification-affected_tasks bg-warning' do
          t.p '残り時間に変化があったタスクがあります'
          t.div class: 'wrapper' do
            t.table class: 'table' do
              @affected_tasks.each do |task, before_time, after_time|
                t.tr do
                  t.th task.name, class: 'task-name'

                  pre_before_time = before_time
                  pre_after_time =  after_time
                  pre_time_diff = pre_before_time - pre_after_time

                  t.td format('%d時間%d分', (pre_after_time/60).to_i, (pre_after_time%60).to_i), class: 'task-info'
                  t.td class: 'time-diff' do
                    t.span format('%d時間%d分', (pre_time_diff/60).to_i, (pre_time_diff%60).to_i), class: 'badge'
                  end
                end
              end
            end
          end
        end
      end
      root.to_html.html_safe
    end
  end

end
