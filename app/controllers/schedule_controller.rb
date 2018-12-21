# coding: utf-8
require 'date'
require 'time'
class ScheduleController < ApplicationController
  @err_id = "初期" #1:名前 2:開始日時 3:終了日時 4:終始逆 0:正常 -1:初期
  @@edit_id

  def is_valid_date year, month, day, hour, minute
    if Date.valid_date?(year,month,day) then
      begin
	      parsed_time = Time.parse(hour.to_s + ":" + minute.to_s) 
	      return true
      rescue ArgumentError => e
	      return false
      end
    else
      return false
    end
  end

  def insert
    @affected_tasks = [] # スケジュール追加によって，残り可処分時間に変化があるタスクの一時保存用

    if request.post? then
      name = params['name']
      s_year = params['s_year']
      s_month = params['s_month']
      s_day = params['s_day']
      s_hour = params['s_hour']
      s_minute = params['s_minute']

      e_year = params['e_year']
      e_month = params['e_month']
      e_day = params['e_day']
      e_hour = params['e_hour']
      e_minute = params['e_minute']
      s_elements = [s_year, s_month, s_day, s_hour, s_minute]
      e_elements = [e_year, e_month, e_day, e_hour, e_minute]

      if (name.length <= 50 && name.length > 0) then 
        if (s_elements.all? {|t| !t.empty? && !t.nil?}) then
          if (e_elements.all? {|t| !t.empty? && !t.nil?}) then
            if self.is_valid_date(s_year.to_i, s_month.to_i, s_day.to_i, s_hour.to_i, s_minute.to_i) && self.is_valid_date(e_year.to_i, e_month.to_i, e_day.to_i, e_hour.to_i, e_minute.to_i) then
              start_time = Time.zone.local(s_year.to_i, s_month.to_i, s_day.to_i, s_hour.to_i, s_minute.to_i)
              end_time = Time.zone.local(e_year.to_i, e_month.to_i, e_day.to_i, e_hour.to_i, e_minute.to_i)
              if end_time > start_time then

                tasks = TaskController.get_visible_tasks (user_signed_in? ? current_user.email : nil)

                # 予定追加「前」の各タスクの残り時間を取得
                task_times_before_insert = tasks.map {|t| Task.calc_splited_time t}

                if view_context.user_signed_in? then
                  Schedule.createRecord(name, start_time, end_time, current_user.email)
                else
                  Schedule.createRecord(name, start_time, end_time)
                end

                # 予定追加「後」の各タスクの残り時間を取得
                task_times_after_insert = tasks.map {|t| Task.calc_splited_time t}

                # 予定追加前後で残り時間が1分でも変わったタスクを抽出
                affected_task_indexes = tasks.to_a.each_index.select do |i| task_times_before_insert[i] - task_times_after_insert[i] > 1 end

                @affected_tasks = affected_task_indexes.map {|index| [tasks[index], task_times_before_insert[index], task_times_after_insert[index]]}

                @err_id = "正常"
              else
                @err_id = "終始逆"
                render nothing: true, status: 400
              end
            end
          else
          	@err_id = "終了日時"
          	render nothing: true, status: 400
          end
        else
          @err_id = "開始日時"
            render nothing: true, status: 400
        end
      else
        @err_id = "名前"
        render nothing: true, status: 400
      end
    end

    tempfile = Tempfile.open('events', File.expand_path("tmp", Dir.pwd)) do |f|
      output_json = []
      view_context.get_available_schedules.each do |schedule|
        output_json.push({
            title: schedule.name,
            start: schedule.start_time.iso8601,
            end: schedule.end_time.iso8601
        })
      end

      f.write output_json.to_json
      puts f.path
      f
    end
  end

  def display
    @err_id = "初期"
    @schedules = Schedule.all
  end

  def delete
    if params['edit'] then
      begin
        @@edit_id = params['edit']
        redirect_to :action => "edit"
        exit
      rescue SystemExit
        puts "Edit"
      end
    else
      id = params['id']
      Schedule.destroyRecord(id)
      @err_id = "初期"
      redirect_to :action =>"insert"
    end
  end

  def self.getEditScheduleName
    s = Schedule.find(@@edit_id)
    s.name
  end

  def self.getEditStartTime
    s = Schedule.find(@@edit_id)
    s.start_time
  end

  def self.getEditEndTime
    s = Schedule.find(@@edit_id)
    s.end_time
  end

  def edit
    if request.post? then
      name = params['name']
      s_year = params['s_year']
      s_month = params['s_month']
      s_day = params['s_day']
      s_hour = params['s_hour']
      s_minute = params['s_minute']

      e_year = params['e_year']
      e_month = params['e_month']
      e_day = params['e_day']
      e_hour = params['e_hour']
      e_minute = params['e_minute']
      s_elements = [s_year, s_month, s_day, s_hour, s_minute]
      e_elements = [e_year, e_month, e_day, e_hour, e_minute]
      if (name.length <= 50 && name.length > 0) then 
        if (s_elements.all? {|t| !t.empty? && !t.nil?}) then
          if (e_elements.all? {|t| !t.empty? && !t.nil?}) then
            if self.is_valid_date(s_year.to_i, s_month.to_i, s_day.to_i, s_hour.to_i, s_minute.to_i) && self.is_valid_date(e_year.to_i, e_month.to_i, e_day.to_i, e_hour.to_i, e_minute.to_i) then
            	start_time = Time.zone.local(s_year.to_i, s_month.to_i, s_day.to_i, s_hour.to_i, s_minute.to_i)
            	end_time = Time.zone.local(e_year.to_i, e_month.to_i, e_day.to_i, e_hour.to_i, e_minute.to_i)
              if end_time > start_time then
                Schedule.createRecord(name, start_time, end_time, Schedule.find_by_id(@@edit_id).user_id)
                Schedule.destroyRecord(@@edit_id)
                @err_id = "正常"
                @@edit_id = 0
                redirect_to :action =>"insert"
              else
                @err_id = "終始逆"
                render nothing: true, status: 400
              end
            end
          else
            @err_id = "終了日時"
            render nothing: true, status: 400
          end
        else
          @err_id = "開始日時"
          render nothing: true, status: 400
        end
      else
        @err_id = "名前"
        render nothing: true, status: 400
      end
    end
  end
end


