class SimpleMathGame
  attr_accessor :level, :equations, :correct_answers

  LEVELS = {
    1 => (0..30).to_a,
    2 => (0..30).to_a,
    3 => (0..30).to_a,
    4 => (0..100).to_a,
    5 => (0..1000).to_a
  }

  METHODS = {
    1 => [:+],
    2 => [:-],
    3 => [:+, :-],
    4 => [:+, :-],
    5 => [:+, :-, :*]
  }

  LEVEL_FAILED_RESPONSES = [
    "I said, choose a number between 1 and 5!",
    "Come on, its a simple task, pick a number between 1 and 5",
    "I've got things to do here, 1-5, now!",
    "Whats your problem?  pick 1,2,3,4, or 5"
  ]

  def initialize(level = 1)
    @level = level
    @equations = []
    @correct_answers = []
  end

  def create_equation
    ::SimpleEquation.new(LEVELS[level], METHODS[level]).build
  end

  def add_equation(equation)
    equations.push(equation)
  end

  def equation_exists?(equation)
    equations.detect{|e| e == equation}
  end

  def add_to_equations(equation)
    if equation_exists?(equation)
      add_to_equations(create_equation)
    else
      add_equation(equation)
    end
  end

  def find_equation_to_use
    add_to_equations(create_equation)
    equations.last
  end

  def preamble
    puts "Are you ready for some math fun!"
    puts "type 'stop' to end game at any time"
    puts "let's try this out"
  end

  def get_level
    puts "what level would you like to play? Choose a number between 1 and 5"
    level = gets.chomp
    until LEVELS.keys.map(&:to_s).include?(level)
      puts LEVEL_FAILED_RESPONSES.sample
      level = gets.chomp
    end
    level.to_i
  end

  def start_game
    preamble
    self.level = get_level
    answer = ""
    until answer.downcase == "stop" || answer.downcase == "quit"
      equation = find_equation_to_use
      puts equation.ask_question
      print "->"
      answer = equation.get_answer
      until answer == equation.result.to_s
        if (answer.downcase != 'stop' || answer.downcase == "quit") && answer != equation.result.to_s
          puts "try again"
          puts equation.ask_question
          print "->"
          answer = equation.get_answer
        else
          break
        end
      end
      puts "Good Job" unless answer.downcase == "stop" || answer.downcase == "quit"
    end
    print_results
  end

  def percentage_correct
    usable_equations = equations.reject(&:not_answered?)
    return nil if usable_equations.empty?
    correct_equations = usable_equations.select(&:answered_correctly?)
    correct_equations.size.to_f / usable_equations.size
  end

  def print_results
    puts "You answered " + (percentage_correct * 100).round.to_s + " percent correct on the first try." unless percentage_correct.nil?
    puts
    equations.each do |equation|
      if equation.answered_correctly?
        puts "Correct: " + equation.to_s + " equals " + equation.result.to_s
      elsif equation.answered_incorrectly?
        puts "This was a tough one.  You gave #{equation.answers.size} answers (#{equation.answers.join(", ")}) for #{equation}.  #{equation.result} was correct"
      else
        puts equation.to_s + " was not answered"
      end
    end
  end
end

class SimpleEquation
  attr_reader :level, :method_used, :possible_numbers, :possible_methods, :answers
  attr_accessor :equation, :left, :right

  def initialize(possible_numbers, possible_methods)
    @possible_numbers = possible_numbers
    @possible_methods = possible_methods
    @answers = []
  end

  def build
    @left, @right = possible_numbers.shuffle.take(2)
    @method_used = possible_methods.shuffle.first
    modify_values
    @equation = [left, method_used, right]
    self
  end

  def modify_values
    if method_used == :/ && right.zero?
      self.right = possible_numbers.detect{|num| !num.zero?}
    elsif method_used == :- && left < right
      self.left, self.right = right, left
    end
  end

  def ==(other)
    equation.to_s == other.to_s
  end

  def result
    left.send(method_used, right)
  end

  def ask_question
    "what does #{self.to_s} equal?"
  end

  def to_s
    "#{equation.map(&:to_s).join(" ")}"
  end

  def get_answer
    answer = gets.chomp
    answers.push(answer) unless ["stop", "quit", ""].include?(answer.strip.downcase)
    answer
  end

  def answered_correctly?
    answers.one? && answers.first == result.to_s
  end

  def not_answered?
    answers.empty?
  end

  def answered_incorrectly?
    !answered_correctly? && !not_answered?
  end
end

SimpleMathGame.new.start_game

