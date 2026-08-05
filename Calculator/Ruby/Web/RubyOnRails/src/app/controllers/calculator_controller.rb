class CalculatorController < ApplicationController
  def index
  end

  def calculate
    a = params[:a].to_f
    b = params[:b].to_f
    op = params[:operator]

    case op
    when "add"
      @result = a + b
    when "subtract"
      @result = a - b
    when "multiply"
      @result = a * b
    when "divide"
      if b.zero?
        flash.now[:alert] = "Division by zero"
      else
        @result = a / b
      end
    else
      flash.now[:alert] = "Unknown operator"
    end

    render :index
  end
end