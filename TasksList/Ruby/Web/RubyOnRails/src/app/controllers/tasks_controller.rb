class TasksController < ApplicationController
  def index
    @tasks = cache.fetch("tasks:all", expires_in: cache_ttl) do
      Task.order(:id).all
    end
  end

  def create
    title = params[:task][:title].to_s.strip
    if title.empty?
      redirect_to root_path, alert: "Title is required"
    else
      Task.create(title: title, description: params[:task][:description].to_s)
      cache.delete("tasks:all")
      redirect_to root_path, notice: "Task added"
    end
  end

  def complete
    task = Task.find_by(id: params[:id])
    task&.update(completed: true)
    cache.delete("tasks:all")
    redirect_to root_path, notice: "Task completed"
  end

  def destroy
    task = Task.find_by(id: params[:id])
    task&.destroy
    cache.delete("tasks:all")
    redirect_to root_path, notice: "Task deleted"
  end
end