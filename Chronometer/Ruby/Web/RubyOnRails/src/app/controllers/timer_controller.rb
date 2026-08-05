class TimerController < ApplicationController
  def index
    @running = timer_state[:running]
    @elapsed = current_elapsed
    @laps = timer_state[:laps]
  end

  def start
    state = timer_state
    unless state[:running]
      state[:running] = true
      state[:start_time] = Time.now.to_f
    end
    session[:timer] = state
    redirect_to root_path
  end

  def stop
    state = timer_state
    if state[:running]
      state[:elapsed] += (Time.now.to_f - state[:start_time])
      state[:running] = false
      state[:start_time] = nil
    end
    session[:timer] = state
    redirect_to root_path
  end

  def reset
    session[:timer] = { running: false, start_time: nil, elapsed: 0.0, laps: [] }
    redirect_to root_path
  end

  def lap
    state = timer_state
    state[:laps] << current_elapsed if state[:running]
    session[:timer] = state
    redirect_to root_path
  end

  private

  def timer_state
    session[:timer] ||= { running: false, start_time: nil, elapsed: 0.0, laps: [] }
  end

  def current_elapsed
    state = timer_state
    if state[:running] && state[:start_time]
      state[:elapsed] + (Time.now.to_f - state[:start_time])
    else
      state[:elapsed]
    end
  end
end